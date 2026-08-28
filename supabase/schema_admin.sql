-- =============================================================================
--  Mon Comptable / CAM-TAXE — administration des habilitations
-- =============================================================================
--  À exécuter après `schema.sql` et `schema_agents.sql`. Idempotent.
--
--  Trois niveaux, au lieu de deux :
--
--    Client                voit ses propres dossiers
--    Conseiller  est_agent voit les dossiers de tout le monde
--    Admin       est_admin nomme les conseillers, et rien d'autre
--
--  Le découpage suit le moindre privilège : un conseiller fait son métier
--  sans jamais pouvoir toucher aux habilitations. Un téléphone de conseiller
--  perdu reste une fuite ; il ne devient pas une prise de contrôle durable.
--
--  Une personne peut porter les deux drapeaux — ce sera votre cas si vous
--  traitez des dossiers *et* gérez l'équipe.
-- =============================================================================

-- -----------------------------------------------------------------------------
--  Le drapeau
-- -----------------------------------------------------------------------------

alter table public.profiles
  add column if not exists est_admin boolean not null default false;

--  `est_admin` n'est **jamais** accordé en écriture à `authenticated` : on ne
--  devient admin que depuis le tableau de bord. C'est la serrure que
--  l'application ne peut pas ouvrir, quoi qu'il arrive à un compte.
--
--  Rappel du piège corrigé dans `schema.sql` : un `revoke` sur une colonne
--  ne fait rien tant que le rôle détient `update` sur la table entière. Ici
--  on ne re-accorde que les colonnes autorisées, et ni `est_agent` ni
--  `est_admin` n'y figurent.
revoke update on public.profiles from anon, authenticated;
grant update (role, nom, prenom, telephone, niu)
  on public.profiles to authenticated;

-- -----------------------------------------------------------------------------
--  Reconnaître un admin
-- -----------------------------------------------------------------------------
--  `security definer` pour ne pas relire `profiles` sous RLS depuis une
--  policy de `profiles` : ce serait une récursion infinie. Même raison que
--  pour `est_agent()`.

create or replace function public.est_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.est_admin from public.profiles p where p.id = auth.uid()),
    false
  );
$$;

-- -----------------------------------------------------------------------------
--  Un admin voit la liste des comptes
-- -----------------------------------------------------------------------------
--  Sans quoi il ne pourrait désigner personne. Cela lui donne accès aux
--  profils — nom, téléphone, NIU — mais **pas** aux dossiers, aux pièces ni
--  aux conversations : les policies de ces tables ne parlent que d'`est_agent`.

drop policy if exists "profil lisible par son propriétaire ou un agent" on public.profiles;
create policy "profil lisible par son propriétaire, un agent ou un admin"
  on public.profiles for select
  using (id = auth.uid() or public.est_agent() or public.est_admin());

-- -----------------------------------------------------------------------------
--  Nommer un conseiller
-- -----------------------------------------------------------------------------
--  Pourquoi une fonction plutôt qu'une policy ?
--
--  La RLS travaille par LIGNE, pas par colonne. Si l'on accordait
--  `update (est_agent)` à `authenticated`, la policy existante
--  « profil modifiable par son propriétaire » — qui autorise un utilisateur
--  à modifier sa propre ligne — laisserait n'importe qui se promouvoir en
--  passant par elle. On rouvrirait exactement la faille corrigée dans
--  `schema.sql`.
--
--  Cette fonction contourne le problème : la colonne reste inaccessible en
--  écriture, et le seul chemin passe par un contrôle explicite.

create or replace function public.nommer_conseiller(
  cible uuid,
  conseiller boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.est_admin() then
    raise exception 'Seul un administrateur peut nommer un conseiller'
      using errcode = '42501';
  end if;

  -- Un admin ne touche pas à sa propre ligne : sans cette règle, il se
  -- nommerait conseiller en silence et la séparation des rôles ne vaudrait
  -- plus rien.
  if cible = auth.uid() then
    raise exception 'Vous ne pouvez pas modifier votre propre habilitation'
      using errcode = '42501';
  end if;

  if not exists (select 1 from public.profiles where id = cible) then
    raise exception 'Compte introuvable' using errcode = 'P0002';
  end if;

  update public.profiles set est_agent = conseiller where id = cible;
end;
$$;

--  `execute` est déjà accordé à `authenticated` par défaut ; la fonction se
--  garde elle-même. On le pose explicitement pour que ce soit lisible.
grant execute on function public.nommer_conseiller(uuid, boolean)
  to authenticated;

-- -----------------------------------------------------------------------------
--  Nommer le premier admin
-- -----------------------------------------------------------------------------
--  Il faut bien un point de départ, et il ne peut pas venir de
--  l'application : sans cela, n'importe qui se déclarerait admin.
--
--      update public.profiles set est_admin = true, est_agent = true
--       where id = (select id from auth.users where email = 'vous@cam-taxe.cm');
--
--  `est_agent` en plus si cette personne doit aussi traiter les dossiers.

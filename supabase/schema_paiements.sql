-- =============================================================================
--  Mon Comptable / CAM-TAXE — paiements mobile money déclaratifs
-- =============================================================================
--  À exécuter après `schema.sql`, `schema_agents.sql` et `schema_admin.sql`.
--  Idempotent.
--
--  Le principe, sans agrégateur ni contrat marchand :
--
--    1. l'application affiche le code USSD de l'agence ;
--    2. le client compose le code sur son téléphone et paie lui-même ;
--    3. il **déclare** ensuite son versement — opérateur, numéro, référence ;
--    4. un administrateur vérifie sur le relevé, puis **confirme**.
--
--  La distinction des étapes 3 et 4 est tout le sujet. Un client déclare,
--  il ne valide pas : sans cela, n'importe qui ferait avancer son dossier
--  en affirmant avoir payé.
-- =============================================================================

-- -----------------------------------------------------------------------------
--  Les moyens de paiement de l'agence
-- -----------------------------------------------------------------------------
--  En base et non dans le code : changer un numéro marchand ne doit pas
--  obliger tous vos clients à réinstaller l'application.

create table if not exists public.moyens_paiement (
  id            text primary key,          -- 'orange', 'mtn'
  libelle       text not null,
  code_ussd     text not null default '',
  beneficiaire  text not null default '',
  consigne      text not null default '',
  ordre         int  not null default 0,
  actif         boolean not null default false
);

--  Créés inactifs et sans code : tant que le tableau de bord ne les a pas
--  renseignés, l'application dit que le paiement n'est pas disponible
--  plutôt que d'afficher un code vide.
insert into public.moyens_paiement (id, libelle, ordre, consigne)
values
  ('orange', 'Orange Money', 1,
   'Vérifiez que le nom affiché est bien celui du bénéficiaire avant de '
   'confirmer.'),
  ('mtn', 'MTN Mobile Money', 2,
   'Après composition, vous serez invité à entrer le montant et votre code '
   'PIN.')
on conflict (id) do nothing;

-- -----------------------------------------------------------------------------
--  Les tarifs
-- -----------------------------------------------------------------------------
--  `service_id` reprend les identifiants de `lib/data/services.dart`.

create table if not exists public.tarifs (
  service_id  text primary key,
  libelle     text not null default '',
  montant     int  not null default 0 check (montant >= 0),
  actif       boolean not null default false
);

insert into public.tarifs (service_id, libelle)
values ('audit', 'Caution d''audit')
on conflict (service_id) do nothing;

-- -----------------------------------------------------------------------------
--  Les déclarations de paiement
-- -----------------------------------------------------------------------------

create table if not exists public.paiements (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles on delete cascade,
  demande_id        uuid references public.demandes on delete cascade,
  service_id        text not null,
  -- Le montant est copié depuis `tarifs` au moment de la déclaration : il ne
  -- vient jamais de l'application, qui pourrait en annoncer un autre.
  montant           int  not null,
  operateur         text not null references public.moyens_paiement,
  numero_envoyeur   text not null default '',
  reference         text not null default '',
  statut            text not null default 'declare'
                    check (statut in ('declare', 'confirme', 'rejete')),
  motif             text not null default '',
  cree_le           timestamptz not null default now(),
  statue_le         timestamptz,
  statue_par        uuid references public.profiles
);

create index if not exists paiements_demande_idx
  on public.paiements (demande_id);
create index if not exists paiements_attente_idx
  on public.paiements (statut, cree_le desc);

-- -----------------------------------------------------------------------------
--  Row Level Security
-- -----------------------------------------------------------------------------

alter table public.moyens_paiement enable row level security;
alter table public.tarifs          enable row level security;
alter table public.paiements       enable row level security;

--  Les moyens et les tarifs se lisent par tout compte connecté : il faut
--  bien afficher le code et le montant. Ils ne s'écrivent que depuis le
--  tableau de bord.
drop policy if exists "moyens lisibles par un compte" on public.moyens_paiement;
create policy "moyens lisibles par un compte"
  on public.moyens_paiement for select
  using (auth.uid() is not null);

drop policy if exists "tarifs lisibles par un compte" on public.tarifs;
create policy "tarifs lisibles par un compte"
  on public.tarifs for select
  using (auth.uid() is not null);

revoke insert, update, delete on public.moyens_paiement from anon, authenticated;
revoke insert, update, delete on public.tarifs          from anon, authenticated;

--  Un client voit ses déclarations ; conseillers et administrateurs voient
--  tout, chacun pour son usage.
drop policy if exists "paiements lisibles par leur auteur, un agent ou un admin"
  on public.paiements;
create policy "paiements lisibles par leur auteur, un agent ou un admin"
  on public.paiements for select
  using (user_id = auth.uid() or public.est_agent() or public.est_admin());

--  Aucune écriture directe : ni insertion ni mise à jour. Tout passe par les
--  deux fonctions ci-dessous, qui portent les règles.
--
--  Pourquoi pas une policy ? Parce que la RLS travaille par LIGNE, pas par
--  colonne : autoriser un client à modifier sa propre ligne lui permettrait
--  de passer `statut` à « confirme ». Même piège que pour `est_agent`.
revoke insert, update, delete on public.paiements from anon, authenticated;

-- -----------------------------------------------------------------------------
--  Déclarer un versement
-- -----------------------------------------------------------------------------

create or replace function public.declarer_paiement(
  demande uuid,
  moyen text,
  numero text,
  ref text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  service text;
  prix int;
  nouveau uuid;
begin
  -- Le dossier doit être celui de l'appelant.
  select d.service_id into service
    from public.demandes d
   where d.id = demande and d.user_id = auth.uid();
  if service is null then
    raise exception 'Dossier introuvable' using errcode = 'P0002';
  end if;

  if not exists (select 1 from public.moyens_paiement
                  where id = moyen and actif) then
    raise exception 'Ce moyen de paiement n''est pas disponible'
      using errcode = 'P0002';
  end if;

  -- Le montant vient du tarif, jamais de l'application.
  select t.montant into prix
    from public.tarifs t
   where t.service_id = service and t.actif;
  if prix is null then
    raise exception 'Aucun tarif n''est défini pour ce service'
      using errcode = 'P0002';
  end if;

  -- Une seule déclaration en attente ou confirmée par dossier : sans cela,
  -- un client pourrait en empiler à chaque hésitation.
  if exists (select 1 from public.paiements
              where demande_id = demande and statut in ('declare', 'confirme'))
  then
    raise exception 'Un paiement est déjà enregistré pour ce dossier'
      using errcode = '23505';
  end if;

  insert into public.paiements
    (user_id, demande_id, service_id, montant, operateur,
     numero_envoyeur, reference)
  values
    (auth.uid(), demande, service, prix, moyen, numero, ref)
  returning id into nouveau;

  return nouveau;
end;
$$;

grant execute on function public.declarer_paiement(uuid, text, text, text)
  to authenticated;

-- -----------------------------------------------------------------------------
--  Confirmer ou rejeter — administrateurs seulement
-- -----------------------------------------------------------------------------

create or replace function public.statuer_paiement(
  paiement uuid,
  nouveau_statut text,
  motif_rejet text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.est_admin() then
    raise exception 'Seul un administrateur confirme un encaissement'
      using errcode = '42501';
  end if;

  if nouveau_statut not in ('confirme', 'rejete') then
    raise exception 'Statut invalide' using errcode = '22023';
  end if;

  update public.paiements
     set statut = nouveau_statut,
         motif = coalesce(motif_rejet, ''),
         statue_le = now(),
         statue_par = auth.uid()
   where id = paiement and statut = 'declare';

  if not found then
    raise exception 'Déclaration introuvable ou déjà traitée'
      using errcode = 'P0002';
  end if;
end;
$$;

grant execute on function public.statuer_paiement(uuid, text, text)
  to authenticated;

-- -----------------------------------------------------------------------------
--  Régler les tarifs et les moyens de paiement — administrateurs seulement
-- -----------------------------------------------------------------------------
--  L'administrateur qui nomme les conseillers règle aussi les montants et
--  les numéros marchands, depuis l'application. Les tables restent fermées
--  en écriture directe : tout passe par ces fonctions, qui vérifient
--  l'habilitation. Une policy ne suffirait pas — la RLS travaille par ligne
--  et ne saurait pas distinguer qui modifie quoi.

create or replace function public.definir_tarif(
  service text,
  prix int,
  disponible boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.est_admin() then
    raise exception 'Seul un administrateur modifie les tarifs'
      using errcode = '42501';
  end if;
  if prix < 0 then
    raise exception 'Le montant ne peut pas être négatif'
      using errcode = '22023';
  end if;

  insert into public.tarifs (service_id, libelle, montant, actif)
  values (service, service, prix, disponible)
  on conflict (service_id) do update
    set montant = excluded.montant,
        actif = excluded.actif;
end;
$$;

grant execute on function public.definir_tarif(text, int, boolean)
  to authenticated;

create or replace function public.definir_moyen(
  moyen text,
  code text,
  nom_beneficiaire text,
  disponible boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.est_admin() then
    raise exception 'Seul un administrateur modifie les moyens de paiement'
      using errcode = '42501';
  end if;

  update public.moyens_paiement
     set code_ussd = coalesce(code, ''),
         beneficiaire = coalesce(nom_beneficiaire, ''),
         actif = disponible
   where id = moyen;

  if not found then
    raise exception 'Moyen de paiement inconnu' using errcode = 'P0002';
  end if;
end;
$$;

grant execute on function public.definir_moyen(text, text, text, boolean)
  to authenticated;

-- -----------------------------------------------------------------------------
--  Renseigner l'agence
-- -----------------------------------------------------------------------------
--  Depuis l'application : Profil → Équipe → Paiements. Ou, une fois, ici :
--
--      update public.moyens_paiement
--         set code_ussd = '#150*46*XXXXXXX#',
--             beneficiaire = 'NOM TEL QU''IL S''AFFICHE',
--             actif = true
--       where id = 'orange';
--
--      update public.moyens_paiement
--         set code_ussd = '*126*4*XXXXXX#',
--             beneficiaire = 'NOM TEL QU''IL S''AFFICHE',
--             actif = true
--       where id = 'mtn';
--
--      update public.tarifs
--         set montant = 25000, actif = true
--       where service_id = 'audit';

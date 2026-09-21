-- =============================================================================
--  Mon Comptable / CAM-TAXE — particulier ou entreprise
-- =============================================================================
--  À exécuter après `schema_facturation.sql`. Idempotent.
--
--  Le tarif ne dépend pas du rôle déclaré à l'inscription : « Personne
--  employée » désigne un salarié, qui reste un particulier. Une entreprise
--  est autre chose, et paie d'autres prix.
--
--    profiles.role         quelles pièces on demande à l'inscription
--    profiles.type_client  quel tarif s'applique
--
--  Deux dimensions distinctes, et c'est la seconde qui facture.
-- =============================================================================

-- -----------------------------------------------------------------------------
--  1. La classification
-- -----------------------------------------------------------------------------

alter table public.profiles
  add column if not exists type_client text not null default 'particulier';

do $$
begin
  alter table public.profiles
    add constraint profiles_type_client_check
    check (type_client in ('particulier', 'entreprise'));
exception
  when duplicate_object then null;
end;
$$;

--  Point capital : `type_client` n'est **pas** modifiable par le client.
--
--  Le tarif en dépend. S'il pouvait le changer lui-même, il lui suffirait de
--  se déclarer particulier pour payer le prix le plus bas. La colonne est
--  posée à l'inscription depuis les métadonnées, puis seul un administrateur
--  peut la corriger.
--
--  On re-accorde explicitement les colonnes autorisées : un `revoke` sur une
--  seule colonne ne ferait rien tant que le droit de table subsiste.
revoke update on public.profiles from anon, authenticated;
grant update (role, nom, prenom, telephone, niu)
  on public.profiles to authenticated;

-- -----------------------------------------------------------------------------
--  2. L'inscription renseigne la classification
-- -----------------------------------------------------------------------------

create or replace function public.gerer_nouvel_utilisateur()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles
    (id, role, type_client, nom, prenom, telephone, niu)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'role', 'utilisateur'),
    -- Toute valeur inattendue retombe sur « particulier » : on ne facture
    -- pas au prix entreprise sur la foi d'une métadonnée douteuse.
    case when new.raw_user_meta_data ->> 'type_client' = 'entreprise'
         then 'entreprise' else 'particulier' end,
    coalesce(new.raw_user_meta_data ->> 'nom', ''),
    coalesce(new.raw_user_meta_data ->> 'prenom', ''),
    coalesce(new.raw_user_meta_data ->> 'telephone', ''),
    coalesce(new.raw_user_meta_data ->> 'niu', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
--  3. Le tarif suit la classification, plus le rôle
-- -----------------------------------------------------------------------------

create or replace function public.emettre_facture()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  type_c text;
  prix int;
  intitule text;
begin
  select p.type_client into type_c
    from public.profiles p where p.id = new.user_id;

  select case when type_c = 'entreprise' then t.montant_entreprise
              else t.montant_particulier end,
         t.libelle
    into prix, intitule
    from public.tarifs t
   where t.service_id = new.service_id and t.actif;

  -- Gratuit, ou aucun tarif : pas de facture, et le service reste ouvert.
  if prix is null or prix = 0 then
    return new;
  end if;

  insert into public.factures
    (numero, user_id, demande_id, service_id, service_libelle, montant)
  values (
    'F-' || to_char(now(), 'YYYY') || '-' ||
      lpad(nextval('public.facture_numero_seq')::text, 4, '0'),
    new.user_id, new.id, new.service_id,
    coalesce(nullif(intitule, ''), new.service_label), prix
  );

  return new;
end;
$$;

create or replace function public.mon_tarif(service text)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select case when (select p.type_client from public.profiles p
                     where p.id = auth.uid()) = 'entreprise'
              then t.montant_entreprise
              else t.montant_particulier end
    from public.tarifs t
   where t.service_id = service and t.actif;
$$;

grant execute on function public.mon_tarif(text) to authenticated;

-- -----------------------------------------------------------------------------
--  4. Corriger la classification — administrateurs seulement
-- -----------------------------------------------------------------------------
--  Un client se trompe à l'inscription, ou une entreprise s'est déclarée
--  particulier : il faut pouvoir rectifier, sans ouvrir la porte à tous.

create or replace function public.definir_type_client(
  cible uuid,
  type_c text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.est_admin() then
    raise exception 'Seul un administrateur modifie la classification'
      using errcode = '42501';
  end if;
  if type_c not in ('particulier', 'entreprise') then
    raise exception 'Classification inconnue' using errcode = '22023';
  end if;

  update public.profiles set type_client = type_c where id = cible;

  if not found then
    raise exception 'Compte introuvable' using errcode = 'P0002';
  end if;
end;
$$;

grant execute on function public.definir_type_client(uuid, text)
  to authenticated;

-- =============================================================================
--  Mon Comptable / CAM-TAXE — tarifs par profil et facturation
-- =============================================================================
--  À exécuter après `schema_paiements.sql`. Idempotent.
--
--  Le parcours :
--
--    1. le client choisit un service et remplit son dossier ;
--    2. l'envoi du dossier **émet une facture**, dont le montant dépend du
--       service et du profil du client ;
--    3. le client règle par mobile money et déclare son versement ;
--    4. un administrateur confirme, et la facture passe à « payée ».
--
--  Deux tarifs par service, selon qui demande :
--
--    particulier   profiles.role = 'utilisateur'
--    entreprise    profiles.role = 'employe'
--
--  On s'appuie sur le rôle déclaré à l'inscription plutôt que de reposer la
--  question : c'est déjà lui qui décide des pièces qu'on réclame au client.
--  Un montant à 0 signifie « gratuit pour ce profil » — aucune facture n'est
--  alors émise, et le service reste accessible.
-- =============================================================================

-- -----------------------------------------------------------------------------
--  1. Deux montants par service
-- -----------------------------------------------------------------------------

alter table public.tarifs
  add column if not exists montant_particulier int not null default 0
    check (montant_particulier >= 0),
  add column if not exists montant_entreprise int not null default 0
    check (montant_entreprise >= 0);

--  Reprise de l'ancien montant unique, s'il existe encore.
do $$
begin
  if exists (select 1 from information_schema.columns
              where table_schema = 'public' and table_name = 'tarifs'
                and column_name = 'montant') then
    update public.tarifs
       set montant_particulier = greatest(montant_particulier, montant),
           montant_entreprise  = greatest(montant_entreprise, montant);
    alter table public.tarifs drop column montant;
  end if;
end;
$$;

--  Les 7 services, tels que `lib/data/services.dart` les nomme. Créés à 0 et
--  inactifs : rien n'est facturé tant que vous n'avez pas fixé les prix.
insert into public.tarifs (service_id, libelle) values
  ('conseil',     'Conseil fiscal'),
  ('declarer',    'Déclarer et payer vos impôts'),
  ('darp',        'DARP / IRPP'),
  ('dsf',         'DSF'),
  ('contentieux', 'Contentieux fiscal'),
  ('niu',         'Acquérir son NIU / ACF'),
  ('audit',       'Faire un audit')
on conflict (service_id) do update set libelle = excluded.libelle;

-- -----------------------------------------------------------------------------
--  2. Les factures
-- -----------------------------------------------------------------------------

create sequence if not exists public.facture_numero_seq;

create table if not exists public.factures (
  id              uuid primary key default gen_random_uuid(),
  numero          text not null unique,
  user_id         uuid not null references public.profiles on delete cascade,
  -- Une facture par dossier, et une seule.
  demande_id      uuid not null unique
                  references public.demandes on delete cascade,
  service_id      text not null,
  service_libelle text not null default '',
  montant         int  not null check (montant > 0),
  statut          text not null default 'a_payer'
                  check (statut in ('a_payer', 'payee', 'annulee')),
  cree_le         timestamptz not null default now(),
  payee_le        timestamptz
);

create index if not exists factures_user_idx
  on public.factures (user_id, cree_le desc);
create index if not exists factures_statut_idx
  on public.factures (statut, cree_le desc);

-- -----------------------------------------------------------------------------
--  3. L'émission, au dépôt du dossier
-- -----------------------------------------------------------------------------
--  Un déclencheur plutôt qu'un appel depuis l'application : une facture ne
--  doit pas dépendre du bon vouloir du client. Dès que le dossier existe,
--  la dette existe.

create or replace function public.emettre_facture()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  profil text;
  prix int;
  intitule text;
begin
  select p.role into profil
    from public.profiles p where p.id = new.user_id;

  select case when profil = 'employe' then t.montant_entreprise
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

drop trigger if exists on_demande_creee on public.demandes;
create trigger on_demande_creee
  after insert on public.demandes
  for each row execute function public.emettre_facture();

-- -----------------------------------------------------------------------------
--  4. Le paiement se rattache à la facture
-- -----------------------------------------------------------------------------

alter table public.paiements
  add column if not exists facture_id uuid references public.factures
    on delete cascade;

create index if not exists paiements_facture_idx
  on public.paiements (facture_id);

--  PostgreSQL refuse de renommer un paramètre par `create or replace` :
--  l'ancienne version prenait `demande`, celle-ci prend `facture`.
drop function if exists public.declarer_paiement(uuid, text, text, text);

create or replace function public.declarer_paiement(
  facture uuid,
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
  f public.factures;
  nouveau uuid;
begin
  select * into f from public.factures
   where id = facture and user_id = auth.uid();
  if f.id is null then
    raise exception 'Facture introuvable' using errcode = 'P0002';
  end if;
  if f.statut <> 'a_payer' then
    raise exception 'Cette facture est déjà réglée' using errcode = '23505';
  end if;

  if not exists (select 1 from public.moyens_paiement
                  where id = moyen and actif) then
    raise exception 'Ce moyen de paiement n''est pas disponible'
      using errcode = 'P0002';
  end if;

  if exists (select 1 from public.paiements
              where facture_id = facture and statut in ('declare', 'confirme'))
  then
    raise exception 'Un paiement est déjà enregistré pour cette facture'
      using errcode = '23505';
  end if;

  -- Le montant est celui de la facture, jamais celui qu'annonce
  -- l'application.
  insert into public.paiements
    (user_id, demande_id, facture_id, service_id, montant, operateur,
     numero_envoyeur, reference)
  values
    (auth.uid(), f.demande_id, f.id, f.service_id, f.montant, moyen,
     numero, ref)
  returning id into nouveau;

  return nouveau;
end;
$$;

grant execute on function public.declarer_paiement(uuid, text, text, text)
  to authenticated;

-- -----------------------------------------------------------------------------
--  5. Confirmer solde la facture
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
declare
  cible uuid;
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
   where id = paiement and statut = 'declare'
  returning facture_id into cible;

  if not found then
    raise exception 'Déclaration introuvable ou déjà traitée'
      using errcode = 'P0002';
  end if;

  -- La facture ne se solde qu'à la confirmation : c'est le seul moment où
  -- l'agence affirme avoir vu l'argent.
  if nouveau_statut = 'confirme' and cible is not null then
    update public.factures
       set statut = 'payee', payee_le = now()
     where id = cible;
  end if;
end;
$$;

grant execute on function public.statuer_paiement(uuid, text, text)
  to authenticated;

-- -----------------------------------------------------------------------------
--  6. Le tarif qui s'applique à celui qui regarde
-- -----------------------------------------------------------------------------
--  L'application ne choisit pas : elle demande, la base répond selon le
--  profil de l'appelant. C'est ce qui permet d'annoncer le prix avant même
--  que le dossier ne soit déposé.

create or replace function public.mon_tarif(service text)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select case when (select p.role from public.profiles p
                     where p.id = auth.uid()) = 'employe'
              then t.montant_entreprise
              else t.montant_particulier end
    from public.tarifs t
   where t.service_id = service and t.actif;
$$;

grant execute on function public.mon_tarif(text) to authenticated;

-- -----------------------------------------------------------------------------
--  7. Régler les prix — administrateurs seulement
-- -----------------------------------------------------------------------------

drop function if exists public.definir_tarif(text, int, boolean);

create or replace function public.definir_tarif(
  service text,
  prix_particulier int,
  prix_entreprise int,
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
  if prix_particulier < 0 or prix_entreprise < 0 then
    raise exception 'Un montant ne peut pas être négatif'
      using errcode = '22023';
  end if;

  update public.tarifs
     set montant_particulier = prix_particulier,
         montant_entreprise = prix_entreprise,
         actif = disponible
   where service_id = service;

  if not found then
    raise exception 'Service inconnu' using errcode = 'P0002';
  end if;
end;
$$;

grant execute on function public.definir_tarif(text, int, int, boolean)
  to authenticated;

-- -----------------------------------------------------------------------------
--  8. Row Level Security
-- -----------------------------------------------------------------------------

alter table public.factures enable row level security;

drop policy if exists "factures lisibles par leur client, un agent ou un admin"
  on public.factures;
create policy "factures lisibles par leur client, un agent ou un admin"
  on public.factures for select
  using (user_id = auth.uid() or public.est_agent() or public.est_admin());

--  Aucune écriture directe : une facture naît du déclencheur et se solde par
--  la confirmation d'un administrateur. Personne ne la fabrique à la main.
revoke insert, update, delete on public.factures from anon, authenticated;

-- -----------------------------------------------------------------------------
--  9. Annuler une facture restée impayée
-- -----------------------------------------------------------------------------
--  Un client remplit un formulaire puis abandonne : sa facture resterait
--  « à payer » indéfiniment et brouillerait la liste des vrais impayés.

create or replace function public.annuler_facture(facture uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.est_admin() then
    raise exception 'Seul un administrateur annule une facture'
      using errcode = '42501';
  end if;

  update public.factures
     set statut = 'annulee'
   where id = facture and statut = 'a_payer';

  if not found then
    raise exception 'Facture introuvable ou déjà réglée' using errcode = 'P0002';
  end if;
end;
$$;

grant execute on function public.annuler_facture(uuid) to authenticated;

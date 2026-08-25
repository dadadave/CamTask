-- =============================================================================
--  Mon Comptable / CAM-TAXE — schéma Supabase
-- =============================================================================
--  À exécuter dans l'éditeur SQL du projet Supabase (une seule fois).
--
--  Trois principes :
--    1. Chaque ligne appartient à un utilisateur ; la RLS empêche de voir
--       celles des autres. Les dossiers contiennent des CNI et des données
--       fiscales : rien ici n'est lisible publiquement.
--    2. `profiles.role` est déclaré par l'utilisateur à l'inscription et ne
--       donne aucun privilège. Le droit de consulter les dossiers des
--       clients vient de `profiles.est_agent`, que l'utilisateur ne peut pas
--       modifier lui-même (voir le REVOKE plus bas).
--    3. Les pièces jointes vivent dans un bucket privé, rangées sous
--       l'identifiant de leur propriétaire.
-- =============================================================================

-- -----------------------------------------------------------------------------
--  Profils
-- -----------------------------------------------------------------------------

create table if not exists public.profiles (
  id         uuid primary key references auth.users on delete cascade,
  role       text not null default 'utilisateur'
             check (role in ('utilisateur', 'employe')),
  -- Habilitation interne : seul un agent voit les dossiers de tout le monde.
  -- Se règle depuis le tableau de bord Supabase, jamais depuis l'application.
  est_agent  boolean not null default false,
  nom        text not null default '',
  prenom     text not null default '',
  telephone  text not null default '',
  niu        text not null default '',
  cree_le    timestamptz not null default now()
);

-- L'inscription passe par auth.signUp ; le profil est créé ici à partir des
-- métadonnées transmises, ce qui évite un aller-retour côté client.
create or replace function public.gerer_nouvel_utilisateur()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, nom, prenom, telephone, niu)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'role', 'utilisateur'),
    coalesce(new.raw_user_meta_data ->> 'nom', ''),
    coalesce(new.raw_user_meta_data ->> 'prenom', ''),
    coalesce(new.raw_user_meta_data ->> 'telephone', ''),
    coalesce(new.raw_user_meta_data ->> 'niu', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.gerer_nouvel_utilisateur();

-- Un agent est reconnu par cette fonction. Elle est `security definer` pour
-- ne pas relire `profiles` sous RLS depuis une policy de `profiles` : ce
-- serait une récursion infinie.
create or replace function public.est_agent()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.est_agent from public.profiles p where p.id = auth.uid()),
    false
  );
$$;

-- -----------------------------------------------------------------------------
--  Demandes (les 7 services)
-- -----------------------------------------------------------------------------

create table if not exists public.demandes (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users on delete cascade,
  service_id    text not null,
  service_label text not null,
  resume        text not null default '',
  statut        text not null default 'Envoyée'
                check (statut in ('Envoyée', 'En cours', 'Traitée')),
  cree_le       timestamptz not null default now()
);

create index if not exists demandes_user_id_idx on public.demandes (user_id, cree_le desc);

-- -----------------------------------------------------------------------------
--  Pièces jointes
-- -----------------------------------------------------------------------------
--  `demande_id` nul = pièce fournie à l'inscription (CNI, justificatif NIU…).
--  `chemin` est la clé de l'objet dans le bucket `pieces`.

create table if not exists public.pieces (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  demande_id  uuid references public.demandes on delete cascade,
  label       text not null,
  chemin      text not null,
  nom_fichier text not null default '',
  cree_le     timestamptz not null default now()
);

create index if not exists pieces_demande_id_idx on public.pieces (demande_id);
create index if not exists pieces_user_id_idx on public.pieces (user_id);

-- -----------------------------------------------------------------------------
--  Messagerie
-- -----------------------------------------------------------------------------
--  `user_id` désigne le client propriétaire de la conversation, quel que soit
--  l'auteur du message : c'est ce qui permet à un agent de répondre.

create table if not exists public.messages (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users on delete cascade,
  auteur        text not null check (auteur in ('client', 'agent')),
  texte         text not null default '',
  piece_chemin  text,
  nom_fichier   text,
  cree_le       timestamptz not null default now()
);

create index if not exists messages_user_id_idx on public.messages (user_id, cree_le);

-- -----------------------------------------------------------------------------
--  Row Level Security
-- -----------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.demandes enable row level security;
alter table public.pieces   enable row level security;
alter table public.messages enable row level security;

-- Personne ne peut se promouvoir agent depuis l'application.
--
-- Attention : un `revoke update (est_agent) … from authenticated` ne suffit
-- PAS. Postgres conserve le droit dès lors qu'un UPDATE a été accordé sur la
-- table entière — ce que Supabase fait par défaut — et la révocation par
-- colonne reste sans effet. Il faut donc figer la colonne par un déclencheur.
create or replace function public.figer_habilitation()
returns trigger
language plpgsql
-- Volontairement SECURITY INVOKER : sous SECURITY DEFINER, `current_user`
-- vaudrait le propriétaire de la fonction et non l'appelant, si bien que le
-- test ci-dessous ne verrait jamais passer un utilisateur de l'application.
set search_path = public
as $$
begin
  -- Les rôles applicatifs ne touchent jamais à l'habilitation ; le tableau de
  -- bord (postgres / service_role), lui, doit pouvoir la régler.
  if current_user in ('authenticated', 'anon') then
    new.est_agent := old.est_agent;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_figer_habilitation on public.profiles;
create trigger profiles_figer_habilitation
  before update on public.profiles
  for each row execute function public.figer_habilitation();

-- Profils ---------------------------------------------------------------------
drop policy if exists "profil lisible par son propriétaire ou un agent" on public.profiles;
create policy "profil lisible par son propriétaire ou un agent"
  on public.profiles for select
  using (id = auth.uid() or public.est_agent());

drop policy if exists "profil modifiable par son propriétaire" on public.profiles;
create policy "profil modifiable par son propriétaire"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "profil créé par son propriétaire" on public.profiles;
create policy "profil créé par son propriétaire"
  on public.profiles for insert
  with check (id = auth.uid());

-- Demandes --------------------------------------------------------------------
drop policy if exists "demandes lisibles par leur auteur ou un agent" on public.demandes;
create policy "demandes lisibles par leur auteur ou un agent"
  on public.demandes for select
  using (user_id = auth.uid() or public.est_agent());

drop policy if exists "demandes créées par leur auteur" on public.demandes;
create policy "demandes créées par leur auteur"
  on public.demandes for insert
  with check (user_id = auth.uid());

-- Le statut d'un dossier est décidé par nos services, pas par le client.
drop policy if exists "statut modifiable par un agent" on public.demandes;
create policy "statut modifiable par un agent"
  on public.demandes for update
  using (public.est_agent())
  with check (public.est_agent());

-- Pièces ----------------------------------------------------------------------
drop policy if exists "pièces lisibles par leur propriétaire ou un agent" on public.pieces;
create policy "pièces lisibles par leur propriétaire ou un agent"
  on public.pieces for select
  using (user_id = auth.uid() or public.est_agent());

drop policy if exists "pièces créées par leur propriétaire" on public.pieces;
create policy "pièces créées par leur propriétaire"
  on public.pieces for insert
  with check (user_id = auth.uid());

-- Messages --------------------------------------------------------------------
drop policy if exists "conversation lisible par son client ou un agent" on public.messages;
create policy "conversation lisible par son client ou un agent"
  on public.messages for select
  using (user_id = auth.uid() or public.est_agent());

-- Un client écrit dans sa propre conversation, et seulement en son nom.
drop policy if exists "le client écrit dans sa conversation" on public.messages;
create policy "le client écrit dans sa conversation"
  on public.messages for insert
  with check (user_id = auth.uid() and auteur = 'client');

-- Un agent répond dans n'importe quelle conversation, au nom de l'agence.
drop policy if exists "l'agent répond dans une conversation" on public.messages;
create policy "l'agent répond dans une conversation"
  on public.messages for insert
  with check (public.est_agent() and auteur = 'agent');

-- -----------------------------------------------------------------------------
--  Stockage des pièces
-- -----------------------------------------------------------------------------
--  Bucket privé : aucune URL publique. Les fichiers sont rangés sous
--  `<user_id>/…`, ce qui rend la policy lisible et sûre.

insert into storage.buckets (id, name, public)
values ('pieces', 'pieces', false)
on conflict (id) do nothing;

drop policy if exists "dépôt de pièce dans son propre dossier" on storage.objects;
create policy "dépôt de pièce dans son propre dossier"
  on storage.objects for insert
  with check (
    bucket_id = 'pieces'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "lecture d'une pièce par son propriétaire ou un agent" on storage.objects;
create policy "lecture d'une pièce par son propriétaire ou un agent"
  on storage.objects for select
  using (
    bucket_id = 'pieces'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.est_agent())
  );

-- -----------------------------------------------------------------------------
--  Temps réel sur la messagerie
-- -----------------------------------------------------------------------------

-- Idempotent : relancer le script entier ne doit pas échouer ici.
do $$
begin
  alter publication supabase_realtime add table public.messages;
exception
  when duplicate_object then null;
end;
$$;

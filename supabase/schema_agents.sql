-- =============================================================================
--  Mon Comptable / CAM-TAXE — espace conseiller
-- =============================================================================
--  Complément à `schema.sql`, à exécuter après lui dans l'éditeur SQL.
--  Idempotent : on peut le relancer.
--
--  Trois manques que l'espace conseiller met au jour :
--
--    1. Un conseiller doit pouvoir déposer un document **dans le dossier de
--       son client**. La policy d'origine l'oblige à écrire sous son propre
--       identifiant — le client ne pourrait alors pas relire le fichier.
--    2. La liste des dossiers doit afficher le nom du client. Cela suppose
--       une clé étrangère de `demandes` vers `profiles`, sans quoi PostgREST
--       refuse de joindre les deux.
--    3. Idem pour la messagerie, afin de nommer les conversations.
--    4. Une pièce doit dire dans quel sens elle va : fournie par le client,
--       ou renvoyée par l'agence. Et un conseiller doit pouvoir en déposer
--       une dans le dossier d'un client.
-- =============================================================================

-- -----------------------------------------------------------------------------
--  1. Un conseiller dépose dans le dossier de son client
-- -----------------------------------------------------------------------------
--  On ne touche pas à la policy d'origine : un client reste cantonné à son
--  propre dossier. Celle-ci s'y ajoute, et ne vaut que pour les agents.
--
--  La lecture, elle, fonctionne déjà : la policy existante autorise le
--  propriétaire du dossier — donc le client — et tout agent.

drop policy if exists "dépôt de pièce par un agent" on storage.objects;
create policy "dépôt de pièce par un agent"
  on storage.objects for insert
  with check (bucket_id = 'pieces' and public.est_agent());

-- -----------------------------------------------------------------------------
--  2. et 3. Nommer le client d'un dossier ou d'une conversation
-- -----------------------------------------------------------------------------
--  `user_id` référence déjà `auth.users`. On ajoute une seconde référence,
--  vers `profiles`, que PostgREST sait suivre pour incorporer le profil :
--
--      demandes?select=...,profiles(nom,prenom,telephone)
--
--  Le trigger `on_auth_user_created` garantit qu'un compte a toujours son
--  profil : aucune ligne existante ne peut violer la contrainte.

do $$
begin
  alter table public.demandes
    add constraint demandes_profil_fkey
    foreign key (user_id) references public.profiles (id) on delete cascade;
exception
  when duplicate_object then null;
end;
$$;

do $$
begin
  alter table public.messages
    add constraint messages_profil_fkey
    foreign key (user_id) references public.profiles (id) on delete cascade;
exception
  when duplicate_object then null;
end;
$$;

-- -----------------------------------------------------------------------------
--  Confort de lecture pour un conseiller
-- -----------------------------------------------------------------------------
--  Un agent parcourt les dossiers de tout le monde, du plus récent au plus
--  ancien, et filtre par statut. L'index de `schema.sql` est préfixé par
--  `user_id` : il ne sert pas ce parcours-là.

create index if not exists demandes_cree_le_idx
  on public.demandes (cree_le desc);

create index if not exists demandes_statut_idx
  on public.demandes (statut, cree_le desc);

-- -----------------------------------------------------------------------------
--  4. Le sens d'une pièce, et le droit d'en déposer une pour un client
-- -----------------------------------------------------------------------------
--  Jusqu'ici toutes les pièces montaient du client vers l'agence. Un dossier
--  porte désormais les deux sens, d'où cette colonne — `client` par défaut,
--  ce qui laisse les lignes existantes justes.

alter table public.pieces
  add column if not exists sens text not null default 'client';

do $$
begin
  alter table public.pieces
    add constraint pieces_sens_check check (sens in ('client', 'agence'));
exception
  when duplicate_object then null;
end;
$$;

--  `user_id` reste **le client** : c'est lui le propriétaire du dossier, quel
--  que soit l'auteur du dépôt. C'est ce qui lui permet de relire la pièce
--  sans policy supplémentaire, et ce qui range le fichier sous son
--  identifiant dans le bucket.
--
--  La policy d'origine (« pièces créées par leur propriétaire ») exige
--  `user_id = auth.uid()` : elle refuserait un dépôt fait par un conseiller.
--  Celle-ci s'y ajoute, et impose le sens `agence` pour qu'un agent ne
--  puisse pas fabriquer une pièce au nom du client.

drop policy if exists "pièce déposée par un agent pour un client" on public.pieces;
create policy "pièce déposée par un agent pour un client"
  on public.pieces for insert
  with check (public.est_agent() and sens = 'agence');

--  Symétriquement, un client ne dépose que des pièces de son propre sens.
drop policy if exists "pièces créées par leur propriétaire" on public.pieces;
create policy "pièces créées par leur propriétaire"
  on public.pieces for insert
  with check (user_id = auth.uid() and sens = 'client');

create index if not exists pieces_sens_idx on public.pieces (demande_id, sens);

-- -----------------------------------------------------------------------------
--  Nommer un conseiller
-- -----------------------------------------------------------------------------
--  Rappel : `est_agent` ne se règle que d'ici, jamais depuis l'application
--  (voir le REVOKE de `schema.sql`). Pour habiliter quelqu'un :
--
--      update public.profiles set est_agent = true
--       where id = (select id from auth.users where email = 'vous@exemple.cm');

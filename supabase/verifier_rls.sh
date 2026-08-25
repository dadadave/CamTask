#!/usr/bin/env bash
#
# Vérifie les policies de schema.sql sur un Postgres local, sans toucher au
# projet Supabase. Reproduit le strict minimum de ce que Supabase fournit
# (schémas auth et storage, rôles anon/authenticated/service_role, publication
# temps réel) puis rejoue les cas de figure qui comptent.
#
# Les droits accordés à `authenticated` reproduisent ceux de Supabase, sans
# quoi le test passerait pour de mauvaises raisons.
#
#   ./supabase/verifier_rls.sh
#
set -euo pipefail

SCHEMA="$(cd "$(dirname "$0")" && pwd)/schema.sql"
BASE="${TMPDIR:-/tmp}/camtask-rls"
SOCK="$BASE/sock"
PGBIN="$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | tail -1)"
A=11111111-1111-1111-1111-111111111111
B=22222222-2222-2222-2222-222222222222

command -v psql >/dev/null || { echo "psql introuvable (apt install postgresql)"; exit 1; }

nettoyer() { su postgres -c "$PGBIN/pg_ctl -D $BASE/pgdata stop -m immediate" >/dev/null 2>&1 || true; }
trap nettoyer EXIT

rm -rf "$BASE"; mkdir -p "$BASE/pgdata" "$SOCK"; chown -R postgres:postgres "$BASE"
su postgres -c "$PGBIN/initdb -D $BASE/pgdata -A trust" >/dev/null
su postgres -c "$PGBIN/pg_ctl -D $BASE/pgdata -o '-k $SOCK -h \"\"' -l $BASE/pg.log start" >/dev/null
sleep 2

# `|| true` : un refus de la RLS fait sortir psql en erreur, or c'est
# précisément ce que plusieurs essais attendent — sans quoi `set -e` couperait
# le script au premier cas négatif.
sql() { su postgres -c "psql -h $SOCK -d essai -tAX -v ON_ERROR_STOP=0 -c \"$1\"" 2>&1 | tr '\n' '|' || true; }

su postgres -c "psql -h $SOCK -d postgres -q -c 'create database essai;'"
su postgres -c "psql -h $SOCK -d essai -q -v ON_ERROR_STOP=1" <<'PREREQ'
do $$
begin
  if not exists (select 1 from pg_roles where rolname='anon') then create role anon; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then create role service_role; end if;
end $$;
create schema auth;
create table auth.users (
  id uuid primary key default gen_random_uuid(),
  email text,
  raw_user_meta_data jsonb default '{}'::jsonb
);
create function auth.uid() returns uuid language sql stable as
  $f$ select current_setting('request.jwt.claim.sub', true)::uuid $f$;
create schema storage;
create table storage.buckets (id text primary key, name text not null, public boolean not null default false);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets, name text not null
);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql immutable as
  $f$ select string_to_array(name, '/') $f$;
create publication supabase_realtime;
PREREQ

su postgres -c "psql -h $SOCK -d essai -q -v ON_ERROR_STOP=1 -f $SCHEMA" >/dev/null 2>&1

su postgres -c "psql -h $SOCK -d essai -q -v ON_ERROR_STOP=1" <<SEED
-- Supabase accorde ces droits par défaut : les reproduire est indispensable,
-- c'est précisément ce qui rendait un revoke par colonne inopérant.
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

insert into auth.users (id, email, raw_user_meta_data) values
  ('$A','alice@ex.cm','{"nom":"Alice"}'::jsonb),
  ('$B','bruno@ex.cm','{"nom":"Bruno"}'::jsonb);
insert into public.demandes (user_id, service_id, service_label, resume) values
  ('$A','declarer','Declarer','dossier de Alice'),
  ('$B','dsf','DSF','dossier de Bruno');
SEED

echec=0
essai() { # 1=intitulé 2=sujet 3=sql 4=motif attendu
  local out
  out=$(sql "begin; set local role authenticated; set local request.jwt.claim.sub='$2'; $3 rollback;")
  if echo "$out" | grep -qE "$4"; then
    echo "  ✅ $1"
  else
    echo "  ❌ $1"; echo "       attendu /$4/ — obtenu : $out"; echec=1
  fi
}

echo "=== Alice, simple utilisatrice ==="
essai "ne voit que son dossier (1 sur 2)"        "$A" "select count(*) from public.demandes;" '\|1\|'
essai "ne lit pas le profil de Bruno"            "$A" "select count(*) from public.profiles where id='$B';" '\|0\|'
essai "ne dépose pas au nom de Bruno"            "$A" "insert into public.demandes(user_id,service_id,service_label,resume) values('$B','x','X','usurpation');" 'row-level security'
essai "NE PEUT PAS se promouvoir agent"          "$A" "update public.profiles set est_agent=true where id='$A'; select est_agent from public.profiles where id='$A';" '\|f\|'
essai "modifie bien son nom"                     "$A" "update public.profiles set nom='Nouveau' where id='$A'; select nom from public.profiles where id='$A';" 'Nouveau'
essai "n'écrit pas au nom de l'agence"           "$A" "insert into public.messages(user_id,auteur,texte) values('$A','agent','faux');" 'row-level security'
essai "écrit bien en son nom"                    "$A" "insert into public.messages(user_id,auteur,texte) values('$A','client','bonjour');" 'INSERT 0 1'
essai "ne modifie pas le statut de son dossier"  "$A" "update public.demandes set statut='Traitée' where user_id='$A';" 'UPDATE 0'
essai "ne lit pas la conversation de Bruno"      "$A" "select count(*) from public.messages where user_id='$B';" '\|0\|'

su postgres -c "psql -h $SOCK -d essai -q -c \"update public.profiles set est_agent=true where id='$A';\""
echo "=== Alice, habilitée agent depuis le tableau de bord ==="
essai "voit les deux dossiers"                   "$A" "select count(*) from public.demandes;" '\|2\|'
essai "répond au nom de l'agence"                "$A" "insert into public.messages(user_id,auteur,texte) values('$B','agent','bonjour');" 'INSERT 0 1'
essai "fait avancer un statut"                   "$A" "update public.demandes set statut='En cours' where user_id='$B';" 'UPDATE 1'

echo "=== Idempotence ==="
if su postgres -c "psql -h $SOCK -d essai -q -v ON_ERROR_STOP=1 -f $SCHEMA" >/dev/null 2>&1; then
  echo "  ✅ schema.sql se rejoue sans erreur"
else
  echo "  ❌ schema.sql échoue à la seconde exécution"; echec=1
fi

exit $echec

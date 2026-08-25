/// Coordonnées du projet Supabase.
///
/// Rien n'est écrit en dur ici : les valeurs sont injectées au build depuis
/// `env.json`, qui n'est pas versionné.
///
///     flutter run   --dart-define-from-file=env.json
///     flutter build apk --dart-define-from-file=env.json
///
/// Copier `env.example.json` vers `env.json` et renseigner les deux valeurs
/// (tableau de bord Supabase → Settings → API).
///
/// La clé « anon » est publique par nature : ce sont les policies RLS de
/// `supabase/schema.sql` qui protègent les données, pas le secret de la clé.
/// Elle n'a malgré tout rien à faire dans l'historique Git.
const String urlSupabase = String.fromEnvironment('SUPABASE_URL');
const String cleAnonSupabase = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Les deux valeurs sont-elles présentes ?
///
/// On ne lève pas d'exception au démarrage : l'application préfère afficher
/// un écran qui dit quoi faire plutôt qu'un écran noir.
const bool supabaseConfigure = urlSupabase != '' && cleAnonSupabase != '';

const String messageConfigAbsente =
    'Configuration Supabase absente : lancez l\'application avec '
    '--dart-define-from-file=env.json (voir env.example.json).';

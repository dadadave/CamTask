import 'backend.dart';
import 'supabase_backend.dart';

export 'backend.dart';
export 'supabase_backend.dart' show supabaseConfigure;

/// Point de bascule unique.
///
/// Supabase nous sert de back-end pour cette première version. Le jour où
/// notre propre API prend le relais, il suffira d'écrire `backend_rest.dart`
/// qui implémente [Backend], puis de changer cette seule ligne :
///
///     final Backend backend = BackendRest();
///
/// Aucun écran ni [AppState] n'a à être touché.
Backend _backend = BackendSupabase();

Backend get backend => _backend;

/// Installe une autre source de données. Sert aux tests, qui branchent une
/// implémentation en mémoire plutôt que d'appeler le réseau.
void utiliserBackend(Backend autre) => _backend = autre;

import 'backend.dart';
import 'supabase_backend.dart';

export 'backend.dart';
export 'supabase_backend.dart' show BackendSupabase;

/// Point de bascule unique.
///
/// Supabase nous sert de back-end pour cette première version. Le jour où
/// notre propre API prend le relais, il suffit d'écrire une autre
/// implémentation de [Backend] et de changer cette seule ligne :
///
///     const Backend backend = BackendRest();
///
/// Aucun écran n'a à être touché.
const Backend backend = BackendSupabase();

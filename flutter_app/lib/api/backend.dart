import '../models.dart';

/// Erreur destinée à être montrée telle quelle à l'utilisateur.
///
/// Les messages techniques de Supabase sont traduits en français avant
/// d'arriver ici : voir `supabase_auth.dart`.
class ErreurBackend implements Exception {
  const ErreurBackend(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Ce que l'application attend d'un back-end pour l'authentification.
///
/// Les écrans ne connaissent pas Supabase : ils ne parlent qu'à cette
/// interface. Le jour où notre propre API prend le relais, il suffit d'en
/// écrire une autre implémentation et de changer la ligne d'export de
/// `lib/api/api.dart` — même principe que `src/api/index.ts` côté React.
abstract class BackendAuth {
  /// Le compte de la session en cours, ou `null` si personne n'est connecté.
  ///
  /// [pieces] complète le profil renvoyé : les pièces de l'inscription ne
  /// sont pas encore stockées côté serveur, elles viennent de l'appareil.
  Future<Compte?> sessionActuelle({List<Piece> pieces});

  /// Crée le compte et ouvre la session dans la foulée.
  ///
  /// [pieces] n'est pas encore téléversé : à ce stade on n'en garde que le
  /// nom de fichier, côté appareil.
  Future<Compte> inscription({
    required Role role,
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String niu,
    required String motDePasse,
    List<Piece> pieces,
  });

  Future<Compte> connexion(String email, String motDePasse);

  Future<void> deconnexion();
}

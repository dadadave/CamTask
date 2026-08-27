import '../models.dart';

/// Erreur destinée à être montrée telle quelle à l'utilisateur.
///
/// Les messages techniques de Supabase sont traduits en français avant
/// d'arriver ici : voir `supabase_backend.dart`.
class ErreurBackend implements Exception {
  const ErreurBackend(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Ce que l'application attend d'un back-end.
///
/// Les écrans ne connaissent pas Supabase : ils ne parlent qu'à cette
/// interface. Le jour où notre propre API prend le relais, il suffit d'en
/// écrire une autre implémentation et de changer la ligne d'export de
/// `lib/api/api.dart` — même principe que `src/api/index.ts` côté React.
abstract class Backend {
  /* ---------------------------------------------------------------------- */
  /*  Authentification                                                      */
  /* ---------------------------------------------------------------------- */

  /// Le compte de la session en cours, ou `null` si personne n'est connecté.
  Future<Compte?> sessionActuelle();

  /// Crée le compte, ouvre la session, puis dépose [pieces].
  Future<Compte> inscription({
    required Role role,
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String niu,
    required String motDePasse,
    List<PieceEnvoi> pieces,
  });

  Future<Compte> connexion(String email, String motDePasse);

  Future<void> deconnexion();

  /* ---------------------------------------------------------------------- */
  /*  Demandes                                                              */
  /* ---------------------------------------------------------------------- */

  /// Les demandes visibles par la session en cours, la plus récente d'abord.
  ///
  /// C'est la RLS qui décide de ce que « visible » veut dire : ses propres
  /// demandes pour un client, toutes pour un agent.
  Future<List<Demande>> listerDemandes();

  /// Enregistre la demande puis dépose ses pièces jointes.
  Future<Demande> creerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    List<PieceEnvoi> pieces,
  });
}

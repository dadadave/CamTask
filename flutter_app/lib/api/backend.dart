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

/// Annule une souscription temps réel.
typedef Annulation = void Function();

/// Ce que l'application attend d'un back-end.
///
/// Les écrans ne connaissent pas Supabase : ils ne parlent qu'à cette
/// interface. Le jour où notre propre API prend le relais, il suffit d'en
/// écrire une autre implémentation et de changer la ligne d'export de
/// `lib/api/api.dart` — même principe que `src/api/index.ts` côté React.
///
/// Plusieurs méthodes prennent un `clientId` facultatif : nul, elles portent
/// sur la personne connectée ; renseigné, sur le dossier d'un client — ce
/// que seul un conseiller a le droit de faire, et que la RLS fait respecter.
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
  /// demandes pour un client, celles de tout le monde pour un conseiller.
  Future<List<Demande>> listerDemandes();

  /// Enregistre la demande puis dépose ses pièces jointes.
  Future<Demande> creerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    List<PieceEnvoi> pieces,
  });

  /// Fait avancer un dossier. Réservé aux conseillers.
  Future<void> changerStatut(String demandeId, String statut);

  /// Dépose dans le dossier d'un client les documents que l'agence lui
  /// renvoie. Réservé aux conseillers.
  ///
  /// [clientId] est le propriétaire du dossier : c'est sous son identifiant
  /// que les fichiers sont rangés, faute de quoi il ne pourrait pas les
  /// relire.
  Future<List<Piece>> deposerPiecesAgence({
    required String demandeId,
    required String clientId,
    required List<PieceEnvoi> pieces,
  });

  /* ---------------------------------------------------------------------- */
  /*  Messagerie                                                            */
  /* ---------------------------------------------------------------------- */

  /// La conversation de la personne connectée, ou celle de [clientId] pour
  /// un conseiller. Du plus ancien message au plus récent.
  Future<List<Message>> listerMessages({String? clientId});

  /// Écrit dans la conversation. Un conseiller précise [clientId] et son
  /// message part au nom de l'agence.
  Future<Message> envoyerMessage({
    required String texte,
    FichierChoisi? fichier,
    String? clientId,
  });

  /// Prévient à chaque message entrant. Rend de quoi se désabonner.
  Annulation souscrireMessages({
    required void Function(Message) surMessage,
    String? clientId,
  });

  /// Les conversations en cours, la plus en attente d'abord. Réservé aux
  /// conseillers.
  Future<List<Conversation>> listerConversations();

  /* ---------------------------------------------------------------------- */
  /*  Administration des habilitations                                      */
  /* ---------------------------------------------------------------------- */

  /// Tous les comptes, pour l'écran Équipe. Réservé aux administrateurs.
  Future<List<MembreEquipe>> listerComptes();

  /// Donne ou retire l'habilitation de conseiller.
  ///
  /// Passe par la fonction `nommer_conseiller` de la base, qui vérifie
  /// elle-même que l'appelant est administrateur et qu'il ne modifie pas sa
  /// propre ligne. La colonne `est_agent` reste inaccessible en écriture
  /// depuis l'application : c'est ce qui empêche de rouvrir la faille où
  /// n'importe qui se promouvait en modifiant son propre profil.
  Future<void> nommerConseiller(String compteId, bool conseiller);

  /* ---------------------------------------------------------------------- */
  /*  Documents                                                             */
  /* ---------------------------------------------------------------------- */

  /// Un lien de téléchargement à durée limitée pour une pièce du bucket.
  ///
  /// Le bucket est privé : il n'existe pas d'URL publique, et c'est la RLS
  /// qui décide si le lien peut être délivré.
  Future<String> lienDocument(String chemin);
}

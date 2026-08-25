import 'package:mon_comptable/api/api.dart';
import 'package:mon_comptable/models.dart';

/// Source de données en mémoire, pour les tests.
///
/// C'est la raison d'être de l'interface [Backend] : les écrans se testent
/// sans réseau, sans projet Supabase et sans clés. Le jour où notre propre
/// API remplacera Supabase, ces tests ne bougeront pas d'une ligne.
class FauxBackend implements Backend {
  FauxBackend({this.compte, List<Demande>? demandes, List<Message>? messages})
      : _demandes = [...?demandes],
        _messages = [...?messages];

  /// Compte rendu par [connexion] et [sessionActuelle].
  Compte? compte;

  final List<Demande> _demandes;
  final List<Message> _messages;
  final List<void Function(Message)> _ecouteurs = [];

  /// Permet à un test de simuler la réponse d'un agent en temps réel.
  void reponseAgent(Message m) {
    _messages.add(m);
    for (final e in _ecouteurs) {
      e(m);
    }
  }

  @override
  bool get configure => true;

  @override
  String get messageConfiguration => '';

  @override
  Future<void> demarrer() async {}

  @override
  Future<Compte?> sessionActuelle() async => compte;

  @override
  Future<Compte> connexion(String email, String motDePasse) async {
    final c = compte ??= Compte(
      role: Role.utilisateur,
      nom: 'NGUEMA',
      prenom: 'Judicael',
      email: email,
      telephone: '699000111',
      niu: 'P123456789012A',
      pieces: const [],
      creeLe: '01/01/2026',
    );
    return c;
  }

  @override
  Future<Compte> inscription(InscriptionEntree e) async {
    return compte = Compte(
      role: e.role,
      nom: e.nom,
      prenom: e.prenom,
      email: e.email,
      telephone: e.telephone,
      niu: e.niu,
      pieces: [
        for (final p in e.pieces)
          Piece(libelle: p.libelle, fichier: p.nomFichier),
      ],
      creeLe: '01/01/2026',
    );
  }

  @override
  Future<void> deconnexion() async {
    compte = null;
  }

  @override
  Future<List<Demande>> listerDemandes() async => List.of(_demandes);

  @override
  Future<Demande> creerDemande(DemandeEntree e) async {
    final d = Demande(
      id: 'demande-${_demandes.length + 1}',
      serviceId: e.serviceId,
      serviceLibelle: e.serviceLibelle,
      resume: e.resume,
      pieces: [
        for (final p in e.pieces)
          Piece(libelle: p.libelle, fichier: p.nomFichier),
      ],
      statut: 'Envoyée',
      date: '01/01/2026',
    );
    _demandes.insert(0, d);
    return d;
  }

  @override
  Future<List<Message>> listerMessages() async => List.of(_messages);

  @override
  Future<Message> envoyerMessage(String texte, {PieceEnvoi? piece}) async {
    final m = Message(
      id: 'message-${_messages.length + 1}',
      auteur: Auteur.moi,
      texte: texte,
      fichier: piece?.nomFichier,
      heure: '09:30',
    );
    _messages.add(m);
    return m;
  }

  @override
  void Function() souscrireMessages(void Function(Message) onMessage) {
    _ecouteurs.add(onMessage);
    return () => _ecouteurs.remove(onMessage);
  }
}

/// Backend qui échoue à chaque appel : sert à vérifier que l'erreur remonte
/// bien à l'écran au lieu de passer inaperçue.
class BackendEnPanne extends FauxBackend {
  BackendEnPanne({super.compte});

  @override
  Future<Demande> creerDemande(DemandeEntree e) async =>
      throw const ErreurBackend('Le serveur est injoignable.');

  @override
  Future<Message> envoyerMessage(String texte, {PieceEnvoi? piece}) async =>
      throw const ErreurBackend('Le serveur est injoignable.');
}

/// Backend dépourvu de clés : l'application doit afficher l'écran
/// d'explication plutôt que de partir en erreur.
class BackendNonConfigure extends FauxBackend {
  @override
  bool get configure => false;

  @override
  String get messageConfiguration => 'Clés absentes.';
}

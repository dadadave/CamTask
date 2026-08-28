import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models.dart';
import '../supabase_config.dart';

const _cle = 'mon-comptable:v1';

/// Préférence d'affichage de l'utilisateur.
enum ModeTheme { systeme, clair, sombre }

/// État de l'application.
///
/// Tout le contenu vit désormais dans Supabase — comptes, dossiers, pièces,
/// messagerie. Seul le mode d'affichage reste sur l'appareil : c'est une
/// préférence, pas une donnée.
///
/// Les écrans ne touchent jamais [Backend] directement ; ils passent par
/// ici, ce qui laisse aux tests un point d'injection unique.
class AppState extends ChangeNotifier {
  /// [backendInjecte] et [configure] ne sont renseignés que par les tests,
  /// qui n'ont ni projet Supabase ni réseau. En production, les valeurs par
  /// défaut sont celles de `api.dart` et de `supabase_config.dart`.
  AppState({Backend? backendInjecte, bool? configure})
      : _backend = backendInjecte ?? backend,
        _configure = configure ?? supabaseConfigure;

  final Backend _backend;
  final bool _configure;

  Compte? _compte;
  ModeTheme _mode = ModeTheme.systeme;
  List<Demande> _demandes = [];
  List<Message> _messages = [];

  SharedPreferences? _prefs;
  String _erreurDemarrage = '';
  Annulation? _ecoute;

  Compte? get compte => _compte;
  List<Demande> get demandes => List.unmodifiable(_demandes);
  List<Message> get messages => List.unmodifiable(_messages);
  bool get connecte => _compte != null;

  /// La personne connectée est-elle un conseiller CAM-TAXE ?
  ///
  /// C'est ce qui décide de l'écran d'accueil et de la barre de navigation.
  /// Le droit réel, lui, est tenu par la RLS : un client qui forcerait
  /// l'affichage d'un écran conseiller ne verrait rien de plus.
  bool get estAgent => _compte?.estAgent ?? false;

  /// Administrateur : nomme les conseillers, sans voir les dossiers.
  bool get estAdmin => _compte?.estAdmin ?? false;

  /// La route d'accueil de la personne connectée.
  ///
  /// Un admin qui n'est pas conseiller n'a rien à faire sur les dossiers :
  /// la RLS ne lui en servirait aucun. On l'envoie directement sur l'équipe.
  String get routeAccueil {
    if (estAgent) return '/agent/dossiers';
    if (estAdmin) return '/admin/equipe';
    return '/accueil';
  }

  /// Les coordonnées du projet Supabase sont-elles présentes ?
  bool get configure => _configure;

  /// Renseignée quand le chargement a échoué (schéma non exécuté, réseau
  /// absent…). Vide le reste du temps.
  String get erreurDemarrage => _erreurDemarrage;

  /// Mode d'affichage choisi : clair, sombre ou celui du système.
  ModeTheme get mode => _mode;

  ThemeMode get themeMode => switch (_mode) {
        ModeTheme.clair => ThemeMode.light,
        ModeTheme.sombre => ThemeMode.dark,
        ModeTheme.systeme => ThemeMode.system,
      };

  void changerMode(ModeTheme m) {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    _sauver();
  }

  @override
  void dispose() {
    _ecoute?.call();
    super.dispose();
  }

  /* ---------------------------------------------------------------------- */
  /*  Chargement                                                            */
  /* ---------------------------------------------------------------------- */

  Future<void> charger() async {
    _prefs = await SharedPreferences.getInstance();
    _lireLocal();
    await _retablirSession();
    notifyListeners();
  }

  void _lireLocal() {
    final brut = _prefs?.getString(_cle);
    if (brut == null) return;
    try {
      final j = jsonDecode(brut) as Map<String, dynamic>;
      _mode = ModeTheme.values.firstWhere(
        (m) => m.name == j['mode'],
        orElse: () => ModeTheme.systeme,
      );
    } on FormatException {
      // Données illisibles : on repart du réglage par défaut.
    }
  }

  Future<void> _sauver() async {
    await _prefs?.setString(_cle, jsonEncode({'mode': _mode.name}));
  }

  /// Rétablit la session si elle est encore valide, puis charge son contenu.
  ///
  /// Un échec ici ne doit pas empêcher l'application de démarrer : on retient
  /// le message et l'utilisateur se retrouve simplement déconnecté.
  Future<void> _retablirSession() async {
    if (!_configure) return;
    try {
      _compte = await _backend.sessionActuelle();
      if (_compte != null) await _chargerContenu();
    } on ErreurBackend catch (e) {
      _compte = null;
      _erreurDemarrage = e.message;
    }
  }

  /// Charge ce que la personne connectée doit voir.
  ///
  /// Un conseiller n'a pas de conversation à lui : sa messagerie est la
  /// liste des conversations de ses clients, chargée par son écran.
  Future<void> _chargerContenu() async {
    _demandes = await _backend.listerDemandes();
    if (!estAgent) {
      _messages = await _backend.listerMessages();
      _ecouterMaConversation();
    }
  }

  /// Recharge les dossiers depuis le serveur.
  ///
  /// Un échec ne vide pas la liste déjà affichée : mieux vaut des données
  /// d'il y a une minute qu'un écran vide au premier hoquet de réseau.
  Future<void> rafraichirDemandes() async {
    if (!_configure || _compte == null) return;
    try {
      _demandes = await _backend.listerDemandes();
      _erreurDemarrage = '';
    } on ErreurBackend catch (e) {
      _erreurDemarrage = e.message;
    }
    notifyListeners();
  }

  /* ---------------------------------------------------------------------- */
  /*  Authentification                                                      */
  /* ---------------------------------------------------------------------- */

  /// Lève une [ErreurBackend] dont le message est affichable tel quel.
  Future<void> connexion(String email, String motDePasse) async {
    _compte = await _backend.connexion(email, motDePasse);
    await _chargerContenu();
    _erreurDemarrage = '';
    notifyListeners();
  }

  /// Lève une [ErreurBackend] dont le message est affichable tel quel.
  Future<void> inscription({
    required Role role,
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String niu,
    required String motDePasse,
    List<PieceEnvoi> pieces = const [],
  }) async {
    _compte = await _backend.inscription(
      role: role,
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      niu: niu,
      motDePasse: motDePasse,
      pieces: pieces,
    );
    await _chargerContenu();
    _erreurDemarrage = '';
    notifyListeners();
  }

  Future<void> seDeconnecter() async {
    _ecoute?.call();
    _ecoute = null;
    // La session locale est vidée quoi qu'il arrive : si l'appel réseau
    // échoue, l'utilisateur ne doit pas rester connecté malgré lui.
    try {
      await _backend.deconnexion();
    } on ErreurBackend {
      // Sans réseau, le jeton local est tout de même effacé par signOut.
    } finally {
      _compte = null;
      _demandes = [];
      _messages = [];
      notifyListeners();
    }
  }

  /* ---------------------------------------------------------------------- */
  /*  Demandes                                                              */
  /* ---------------------------------------------------------------------- */

  /// Enregistre la demande sur le serveur et dépose ses pièces jointes.
  ///
  /// Lève une [ErreurBackend] dont le message est affichable tel quel : la
  /// page appelante reste affichée et la saisie n'est pas perdue.
  Future<Demande> envoyerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    List<PieceEnvoi> pieces = const [],
  }) async {
    final demande = await _backend.creerDemande(
      serviceId: serviceId,
      serviceLibelle: serviceLibelle,
      resume: resume,
      pieces: pieces,
    );
    _demandes = [demande, ..._demandes];
    notifyListeners();
    return demande;
  }

  /* ---------------------------------------------------------------------- */
  /*  Messagerie du client                                                  */
  /* ---------------------------------------------------------------------- */

  Future<void> envoyerMessage(String texte, {FichierChoisi? fichier}) async {
    final message = await _backend.envoyerMessage(
      texte: texte,
      fichier: fichier,
    );
    _messages = [..._messages, message];
    notifyListeners();
  }

  /// Écoute les réponses de l'agence en direct.
  void _ecouterMaConversation() {
    _ecoute?.call();
    _ecoute = _backend.souscrireMessages(
      surMessage: (m) {
        _messages = [..._messages, m];
        notifyListeners();
      },
    );
  }

  /* ---------------------------------------------------------------------- */
  /*  Espace conseiller                                                     */
  /* ---------------------------------------------------------------------- */
  //  Rien ici ne vérifie l'habilitation : c'est la RLS qui refuse, et le
  //  refus remonte en ErreurBackend affichable. L'application décide de ce
  //  qu'elle montre, jamais de ce qui est permis.

  /// Fait avancer un dossier, et met la liste à jour sans tout recharger.
  Future<void> changerStatut(String demandeId, String statut) async {
    await _backend.changerStatut(demandeId, statut);
    _demandes = [
      for (final d in _demandes)
        if (d.id == demandeId) d.avec(statut: statut) else d,
    ];
    notifyListeners();
  }

  /// Dépose dans le dossier d'un client les documents que l'agence renvoie.
  Future<void> deposerPiecesAgence({
    required String demandeId,
    required String clientId,
    required List<PieceEnvoi> pieces,
  }) async {
    final deposees = await _backend.deposerPiecesAgence(
      demandeId: demandeId,
      clientId: clientId,
      pieces: pieces,
    );
    _demandes = [
      for (final d in _demandes)
        if (d.id == demandeId) d.avec(pieces: [...d.pieces, ...deposees]) else d,
    ];
    notifyListeners();
  }

  Future<List<Conversation>> conversations() => _backend.listerConversations();

  Future<List<Message>> messagesDe(String clientId) =>
      _backend.listerMessages(clientId: clientId);

  Future<Message> repondre(
    String clientId,
    String texte, {
    FichierChoisi? fichier,
  }) =>
      _backend.envoyerMessage(
        texte: texte,
        fichier: fichier,
        clientId: clientId,
      );

  Annulation ecouterConversation(
    String clientId,
    void Function(Message) surMessage,
  ) =>
      _backend.souscrireMessages(surMessage: surMessage, clientId: clientId);

  /* ---------------------------------------------------------------------- */
  /*  Administration des habilitations                                      */
  /* ---------------------------------------------------------------------- */

  Future<List<MembreEquipe>> comptes() => _backend.listerComptes();

  /// Donne ou retire l'habilitation de conseiller.
  ///
  /// La base refuse si l'appelant n'est pas administrateur, ou s'il vise sa
  /// propre ligne ; le refus remonte en [ErreurBackend] affichable.
  Future<void> nommerConseiller(String compteId, bool conseiller) =>
      _backend.nommerConseiller(compteId, conseiller);

  /* ---------------------------------------------------------------------- */
  /*  Documents                                                             */
  /* ---------------------------------------------------------------------- */

  /// Un lien de téléchargement à durée limitée. Le bucket étant privé, il
  /// n'existe pas d'URL permanente.
  Future<String> lienDocument(String chemin, {String? nomFichier}) =>
      _backend.lienDocument(chemin, nomFichier: nomFichier);

  static String dateDuJour() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/'
        '${n.month.toString().padLeft(2, '0')}/${n.year}';
  }
}

/// Donne accès à l'[AppState] depuis n'importe quel écran.
class PorteeApp extends InheritedNotifier<AppState> {
  const PorteeApp({super.key, required AppState etat, required super.child})
      : super(notifier: etat);

  static AppState of(BuildContext context) {
    final portee = context.dependOnInheritedWidgetOfExactType<PorteeApp>();
    assert(portee != null, 'PorteeApp introuvable dans l\'arbre de widgets');
    return portee!.notifier!;
  }
}

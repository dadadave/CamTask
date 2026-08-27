import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models.dart';
import '../supabase_config.dart';

const _cle = 'mon-comptable:v1';

/// Préférence d'affichage de l'utilisateur.
enum ModeTheme { systeme, clair, sombre }

const _messageAccueil = Message(
  id: 'bienvenue',
  auteur: Auteur.agent,
  texte:
      'Bonjour 👋 Je suis Judicaël, votre conseiller CAM-TAXE. Dites-moi en '
      'quoi je peux vous aider : déclaration, NIU/ACF, DSF, audit ou '
      'contentieux fiscal.',
  heure: '09:00',
);

/// État de l'application.
///
/// Le compte, les demandes et les pièces vivent dans Supabase ; seuls la
/// messagerie et le mode d'affichage restent pour l'instant dans les
/// préférences locales de l'appareil.
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
  List<Message> _messages = [_messageAccueil];

  SharedPreferences? _prefs;
  String _erreurDemarrage = '';

  Compte? get compte => _compte;
  List<Demande> get demandes => List.unmodifiable(_demandes);
  List<Message> get messages => List.unmodifiable(_messages);
  bool get connecte => _compte != null;

  /// Les coordonnées du projet Supabase sont-elles présentes ?
  bool get configure => _configure;

  /// Renseignée quand la session n'a pas pu être rétablie au lancement
  /// (schéma non exécuté, réseau absent…). Vide le reste du temps.
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

  /* ---------------------------------------------------------------------- */
  /*  Chargement                                                            */
  /* ---------------------------------------------------------------------- */

  Future<void> charger() async {
    _prefs = await SharedPreferences.getInstance();
    _lireLocal();
    await _retablirSession();
    notifyListeners();
  }

  /// Recharge les demandes depuis le serveur.
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

  void _lireLocal() {
    final brut = _prefs?.getString(_cle);
    if (brut == null) return;
    try {
      final j = jsonDecode(brut) as Map<String, dynamic>;
      _mode = ModeTheme.values.firstWhere(
        (m) => m.name == j['mode'],
        orElse: () => ModeTheme.systeme,
      );
      final msgs = ((j['messages'] as List<dynamic>?) ?? const [])
          .map((e) => Message.depuisJson(e as Map<String, dynamic>))
          .toList();
      if (msgs.isNotEmpty) _messages = msgs;
    } on FormatException {
      // Données illisibles : on repart d'un état vierge.
    }
  }

  /// Rétablit la session Supabase si elle est encore valide.
  ///
  /// Un échec ici ne doit pas empêcher l'application de démarrer : on
  /// retient le message et l'utilisateur se retrouve simplement déconnecté.
  Future<void> _retablirSession() async {
    if (!_configure) return;
    try {
      _compte = await _backend.sessionActuelle();
      if (_compte != null) _demandes = await _backend.listerDemandes();
    } on ErreurBackend catch (e) {
      _compte = null;
      _erreurDemarrage = e.message;
    }
  }

  Future<void> _sauver() async {
    await _prefs?.setString(
      _cle,
      jsonEncode({
        'mode': _mode.name,
        'messages': _messages.map((m) => m.versJson()).toList(),
      }),
    );
  }

  /* ---------------------------------------------------------------------- */
  /*  Authentification                                                      */
  /* ---------------------------------------------------------------------- */

  /// Lève une [ErreurBackend] dont le message est affichable tel quel.
  Future<void> connexion(String email, String motDePasse) async {
    _compte = await _backend.connexion(email, motDePasse);
    _demandes = await _backend.listerDemandes();
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
    _demandes = [];
    _erreurDemarrage = '';
    notifyListeners();
  }

  Future<void> seDeconnecter() async {
    // La session locale est vidée quoi qu'il arrive : si l'appel réseau
    // échoue, l'utilisateur ne doit pas rester connecté malgré lui.
    try {
      await _backend.deconnexion();
    } on ErreurBackend {
      // Sans réseau, le jeton local est tout de même effacé par signOut.
    } finally {
      _compte = null;
      _demandes = [];
      notifyListeners();
    }
  }

  /* ---------------------------------------------------------------------- */
  /*  Demandes (Supabase) et messagerie (stockage local)                    */
  /* ---------------------------------------------------------------------- */

  static String _identifiant() {
    final r = Random().nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().millisecondsSinceEpoch}-$r';
  }

  static String _heure() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}';
  }

  static String dateDuJour() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/'
        '${n.month.toString().padLeft(2, '0')}/${n.year}';
  }

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

  void envoyerMessage(String texte, {String? fichier}) {
    _messages = [
      ..._messages,
      Message(
        id: _identifiant(),
        auteur: Auteur.moi,
        texte: texte,
        fichier: fichier,
        heure: _heure(),
      ),
    ];
    notifyListeners();
    _sauver();

    // Réponse simulée de l'agent — le back-office sera branché plus tard.
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      _messages = [
        ..._messages,
        Message(
          id: _identifiant(),
          auteur: Auteur.agent,
          texte: 'Bien reçu, je consulte votre dossier et je reviens vers vous '
              'dans quelques instants.',
          heure: _heure(),
        ),
      ];
      notifyListeners();
      _sauver();
    });
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

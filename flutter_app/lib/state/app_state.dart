import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

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

/// État de l'application : compte, demandes et messagerie.
/// Persisté dans les préférences locales de l'appareil.
class AppState extends ChangeNotifier {
  Compte? _compte;
  ModeTheme _mode = ModeTheme.systeme;
  List<Demande> _demandes = [];
  List<Message> _messages = [_messageAccueil];
  SharedPreferences? _prefs;

  Compte? get compte => _compte;
  List<Demande> get demandes => List.unmodifiable(_demandes);
  List<Message> get messages => List.unmodifiable(_messages);
  bool get connecte => _compte != null;

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

  Future<void> charger() async {
    _prefs = await SharedPreferences.getInstance();
    final brut = _prefs?.getString(_cle);
    if (brut == null) return;
    try {
      final j = jsonDecode(brut) as Map<String, dynamic>;
      _mode = ModeTheme.values.firstWhere(
        (m) => m.name == j['mode'],
        orElse: () => ModeTheme.systeme,
      );
      final c = j['compte'];
      _compte = c == null ? null : Compte.depuisJson(c as Map<String, dynamic>);
      _demandes = ((j['demandes'] as List<dynamic>?) ?? const [])
          .map((e) => Demande.depuisJson(e as Map<String, dynamic>))
          .toList();
      final msgs = ((j['messages'] as List<dynamic>?) ?? const [])
          .map((e) => Message.depuisJson(e as Map<String, dynamic>))
          .toList();
      if (msgs.isNotEmpty) _messages = msgs;
      notifyListeners();
    } on FormatException {
      // Données illisibles : on repart d'un état vierge.
    }
  }

  Future<void> _sauver() async {
    await _prefs?.setString(
      _cle,
      jsonEncode({
        'mode': _mode.name,
        'compte': _compte?.versJson(),
        'demandes': _demandes.map((d) => d.versJson()).toList(),
        'messages': _messages.map((m) => m.versJson()).toList(),
      }),
    );
  }

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

  void seConnecter(Compte compte) {
    _compte = compte;
    notifyListeners();
    _sauver();
  }

  void seDeconnecter() {
    _compte = null;
    notifyListeners();
    _sauver();
  }

  Demande envoyerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    List<Piece> pieces = const [],
  }) {
    final demande = Demande(
      id: _identifiant(),
      serviceId: serviceId,
      serviceLibelle: serviceLibelle,
      resume: resume,
      pieces: pieces,
      statut: 'Envoyée',
      date: dateDuJour(),
    );
    _demandes = [demande, ..._demandes];
    notifyListeners();
    _sauver();
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

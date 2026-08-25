import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models.dart';

/// Le mode d'affichage reste une préférence de l'appareil : il n'a rien à
/// faire sur le serveur.
const _cleMode = 'mon-comptable:mode';

/// Préférence d'affichage de l'utilisateur.
enum ModeTheme { systeme, clair, sombre }

/// Accueil de la messagerie. Affiché tant que la conversation est vide : ce
/// n'est pas un message stocké, seulement le premier mot du conseiller.
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
///
/// Les données viennent du [backend] ; seul le mode d'affichage est conservé
/// sur l'appareil.
class AppState extends ChangeNotifier {
  Compte? _compte;
  ModeTheme _mode = ModeTheme.systeme;
  List<Demande> _demandes = [];
  List<Message> _messages = const [];
  SharedPreferences? _prefs;
  bool _pret = false;
  void Function()? _annulerEcoute;

  Compte? get compte => _compte;
  List<Demande> get demandes => List.unmodifiable(_demandes);

  /// La conversation, ou le mot d'accueil tant qu'elle est vide.
  List<Message> get messages =>
      List.unmodifiable(_messages.isEmpty ? [_messageAccueil] : _messages);

  bool get connecte => _compte != null;

  /// Faux tant que la session enregistrée n'a pas été relue au démarrage.
  bool get pret => _pret;

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
    _prefs?.setString(_cleMode, m.name);
  }

  static String dateDuJour() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/'
        '${n.month.toString().padLeft(2, '0')}/${n.year}';
  }

  /// Démarre le backend et reprend la session si l'appareil en a une.
  Future<void> charger() async {
    _prefs = await SharedPreferences.getInstance();
    final nomMode = _prefs?.getString(_cleMode);
    if (nomMode != null) {
      _mode = ModeTheme.values.firstWhere(
        (m) => m.name == nomMode,
        orElse: () => ModeTheme.systeme,
      );
    }

    try {
      await backend.demarrer();
      final compte = await backend.sessionActuelle();
      if (compte != null) await _charger(compte);
    } catch (_) {
      // Session illisible ou serveur injoignable : on démarre déconnecté.
    } finally {
      _pret = true;
      notifyListeners();
    }
  }

  /// Charge le dossier de l'utilisateur : ses demandes et sa conversation.
  Future<void> _charger(Compte compte) async {
    // Les deux requêtes partent ensemble ; on les attend séparément pour
    // garder leurs types, ce qu'un `Future.wait` sur une liste hétérogène
    // perdrait.
    final futurDemandes = backend.listerDemandes();
    final futurMessages = backend.listerMessages();
    _demandes = await futurDemandes;
    _messages = await futurMessages;
    _compte = compte;
    _ecouterMessages();
    notifyListeners();
  }

  /// Réponses des agents, en temps réel.
  void _ecouterMessages() {
    _annulerEcoute?.call();
    _annulerEcoute = backend.souscrireMessages((m) {
      if (_messages.any((x) => x.id == m.id)) return;
      _messages = [..._messages, m];
      notifyListeners();
    });
  }

  Future<void> inscription(InscriptionEntree entree) async {
    final compte = await backend.inscription(entree);
    await _charger(compte);
  }

  Future<void> connexion(String email, String motDePasse) async {
    final compte = await backend.connexion(email, motDePasse);
    await _charger(compte);
  }

  Future<void> seDeconnecter() async {
    await backend.deconnexion();
    _annulerEcoute?.call();
    _annulerEcoute = null;
    _compte = null;
    _demandes = const [];
    _messages = const [];
    notifyListeners();
  }

  Future<Demande> envoyerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    List<PieceEnvoi> pieces = const [],
  }) async {
    final demande = await backend.creerDemande(
      DemandeEntree(
        serviceId: serviceId,
        serviceLibelle: serviceLibelle,
        resume: resume,
        pieces: pieces,
      ),
    );
    _demandes = [demande, ..._demandes];
    notifyListeners();
    return demande;
  }

  Future<void> envoyerMessage(String texte, {PieceEnvoi? piece}) async {
    final mien = await backend.envoyerMessage(texte, piece: piece);
    _messages = [..._messages, mien];
    notifyListeners();
  }

  @override
  void dispose() {
    _annulerEcoute?.call();
    super.dispose();
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

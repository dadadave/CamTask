import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mon_comptable/api/api.dart';
import 'package:mon_comptable/main.dart';
import 'package:mon_comptable/models.dart';
import 'package:mon_comptable/state/app_state.dart';
import 'package:mon_comptable/theme.dart';

final _compteFactice = Compte(
  role: Role.utilisateur,
  nom: 'NGUEMA',
  prenom: 'Judicael',
  email: 'judicael@example.cm',
  telephone: '699000111',
  niu: 'P123456789012A',
  pieces: const [],
  creeLe: AppState.dateDuJour(),
);

/// Back-end en memoire : les tests n'ont ni projet Supabase ni reseau.
///
/// Les demandes creees restent dans [demandes], ce qui suffit a verifier
/// qu'un envoi remonte bien jusqu'au profil.
class _BackendFactice implements Backend {
  _BackendFactice({this.session});

  Compte? session;
  final List<Demande> demandes = [];

  @override
  Future<Compte?> sessionActuelle() async => session;

  @override
  Future<Compte> connexion(String email, String motDePasse) async =>
      session = _compteFactice;

  @override
  Future<Compte> inscription({
    required Role role,
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String niu,
    required String motDePasse,
    List<PieceEnvoi> pieces = const [],
  }) async =>
      session = _compteFactice;

  @override
  Future<void> deconnexion() async => session = null;

  /* -- Messagerie ------------------------------------------------------- */

  final List<Message> messages = [];

  @override
  Future<List<Message>> listerMessages({String? clientId}) async =>
      List.of(messages);

  @override
  Future<Message> envoyerMessage({
    required String texte,
    FichierChoisi? fichier,
    String? clientId,
  }) async {
    final m = Message(
      id: 'message-${messages.length}',
      auteur: Auteur.moi,
      texte: texte,
      fichier: fichier?.nom,
      heure: '09:00',
    );
    messages.add(m);
    return m;
  }

  @override
  Annulation souscrireMessages({
    required void Function(Message) surMessage,
    String? clientId,
  }) =>
      () {};

  @override
  Future<List<Conversation>> listerConversations() async => const [];

  /* -- Espace conseiller ------------------------------------------------ */

  @override
  Future<void> changerStatut(String demandeId, String statut) async {
    for (var i = 0; i < demandes.length; i++) {
      if (demandes[i].id == demandeId) {
        demandes[i] = demandes[i].avec(statut: statut);
      }
    }
  }

  @override
  Future<List<Piece>> deposerPiecesAgence({
    required String demandeId,
    required String clientId,
    required List<PieceEnvoi> pieces,
  }) async =>
      [
        for (final p in pieces)
          Piece(
            libelle: p.libelle,
            fichier: p.fichier.nom,
            sens: SensPiece.agence,
            chemin: '$clientId/$demandeId/${p.fichier.nom}',
          ),
      ];

  @override
  Future<String> lienDocument(String chemin) async =>
      'https://exemple.test/$chemin';

  @override
  Future<List<Demande>> listerDemandes() async => List.of(demandes);

  @override
  Future<Demande> creerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    List<PieceEnvoi> pieces = const [],
  }) async {
    final demande = Demande(
      id: 'demande-${demandes.length}',
      serviceId: serviceId,
      serviceLibelle: serviceLibelle,
      resume: resume,
      pieces: [
        for (final p in pieces)
          Piece(libelle: p.libelle, fichier: p.fichier.nom),
      ],
      statut: 'Envoyée',
      date: AppState.dateDuJour(),
    );
    demandes.insert(0, demande);
    return demande;
  }
}

final _compteAgent = Compte(
  role: Role.utilisateur,
  nom: 'MBALLA',
  prenom: 'Judicael',
  email: 'conseiller@cam-taxe.cm',
  telephone: '699000333',
  niu: '',
  pieces: const [],
  creeLe: AppState.dateDuJour(),
  estAgent: true,
);

/// Un dossier deja depose par un client, tel qu'un conseiller le voit.
final _dossierClient = Demande(
  id: 'dossier-1',
  serviceId: 'audit',
  serviceLibelle: 'Faire un audit',
  resume: 'Audit fiscal — NIU P123',
  pieces: const [
    Piece(libelle: 'Photo de la CNI', fichier: 'cni.jpg', chemin: 'u/d/cni.jpg'),
  ],
  statut: 'Envoyée',
  date: '01/01/2026',
  clientId: 'client-1',
  clientNom: 'Bout TEST',
  clientTelephone: '699000222',
);

/// [connecte] ouvre d'emblee une session, comme au retour d'un lancement
/// ou l'utilisateur s'etait deja identifie.
Future<AppState> _etatNeuf({
  bool connecte = false,
  bool agent = false,
  List<Demande> dossiers = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final faux = _BackendFactice(
    session: agent ? _compteAgent : (connecte ? _compteFactice : null),
  );
  faux.demandes.addAll(dossiers);
  final etat = AppState(backendInjecte: faux, configure: true);
  await etat.charger();
  return etat;
}

/// La tuile « Faire un audit » est la dernière de la grille : dans le
/// viewport de test elle est sous la ligne de flottaison, il faut donc
/// l'amener à l'écran avant de la toucher.
Future<void> _ouvrirAudit(WidgetTester tester) async {
  final cible = find.text('Faire un audit').last;
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("l'accueil affiche le bandeau et les 7 services",
      (tester) async {
    await tester.pumpWidget(MonComptable(etat: await _etatNeuf()));
    await tester.pumpAndSettle();

    expect(find.text('Faites vos déclarations chez nous'), findsOneWidget);
    expect(find.text('100 % sûr'), findsOneWidget);
    expect(find.text('Besoin de conseil fiscal'), findsOneWidget);
    expect(find.text('Faire un audit'), findsOneWidget);
  });

  testWidgets('la recherche filtre les services', (tester) async {
    await tester.pumpWidget(MonComptable(etat: await _etatNeuf()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'audit');
    await tester.pumpAndSettle();

    expect(find.text('Faire un audit'), findsOneWidget);
    expect(find.text('Besoin de conseil fiscal'), findsNothing);
  });

  testWidgets('un service exige un compte', (tester) async {
    await tester.pumpWidget(MonComptable(etat: await _etatNeuf()));
    await tester.pumpAndSettle();

    await _ouvrirAudit(tester);

    expect(find.text("Vous n'êtes pas connecté"), findsOneWidget);
  });

  testWidgets('avec un compte, le formulaire du service est accessible',
      (tester) async {
    final etat = await _etatNeuf(connecte: true);

    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    await _ouvrirAudit(tester);

    // Le formulaire de l'audit, dans l'ordre demandé.
    expect(find.text('Nom de la structure'), findsOneWidget);
    expect(find.text("Type d'audit"), findsOneWidget);
    expect(find.text('PAIEMENT DE CAUTION'), findsOneWidget);

    // Les sections de documents et le bouton agent sont en bas de la page :
    // la liste est paresseuse, il faut défiler pour qu'ils soient construits.
    // La page contient plusieurs zones défilantes : on vise explicitement
    // celle de l'écran.
    final page = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('« Audit fiscal (contrôle des impôts) »'),
      600,
      scrollable: page,
    );
    expect(find.text('« Audit fiscal (contrôle des impôts) »'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Discuter avec un agent'),
      600,
      scrollable: page,
    );
    expect(find.text('Discuter avec un agent'), findsOneWidget);
  });

  testWidgets('une demande envoyée apparaît dans le profil', (tester) async {
    final etat = await _etatNeuf(connecte: true);
    await etat.envoyerDemande(
      serviceId: 'dsf',
      serviceLibelle: 'DSF — Déclaration statistique et fiscale',
      resume: 'NIU P123 — DSF pour la banque',
    );

    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // La section des demandes est sous la ligne de flottaison (carte
    // d'identité, coordonnées puis réglage d'apparence la précèdent).
    await tester.scrollUntilVisible(
      find.text('Mes demandes'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mes demandes'), findsOneWidget);
    expect(find.text('Envoyée'), findsOneWidget);
  });

  _testsAgent();
  _testsTheme();
}

/// Un conseiller n'ouvre pas la meme application qu'un client : c'est le
/// point le plus facile a casser en touchant a la navigation.
void _testsAgent() {
  testWidgets("un conseiller arrive sur ses dossiers, pas sur l'accueil",
      (tester) async {
    final etat = await _etatNeuf(agent: true, dossiers: [_dossierClient]);
    expect(etat.routeAccueil, '/agent/dossiers');

    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    expect(find.text('Dossiers'), findsWidgets);
    expect(find.text('Faites vos déclarations chez nous'), findsNothing);
  });

  testWidgets("un client arrive sur l'accueil", (tester) async {
    final etat = await _etatNeuf(connecte: true);
    expect(etat.routeAccueil, '/accueil');
    expect(etat.estAgent, isFalse);
  });

  testWidgets('le conseiller voit le dossier et son client', (tester) async {
    final etat = await _etatNeuf(agent: true, dossiers: [_dossierClient]);
    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    expect(find.text('Faire un audit'), findsOneWidget);
    expect(find.text('Bout TEST'), findsOneWidget);
    expect(find.text('Envoyée'), findsOneWidget);
  });

  testWidgets('le filtre par statut masque les autres dossiers',
      (tester) async {
    final etat = await _etatNeuf(agent: true, dossiers: [_dossierClient]);
    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Traitée (0)'));
    await tester.pumpAndSettle();

    expect(find.text('Faire un audit'), findsNothing);
    expect(find.textContaining('Aucun dossier'), findsOneWidget);
  });

  testWidgets('le conseiller fait avancer un dossier', (tester) async {
    final etat = await _etatNeuf(agent: true, dossiers: [_dossierClient]);
    await etat.changerStatut('dossier-1', 'En cours');

    expect(etat.demandes.single.statut, 'En cours');
  });

  testWidgets('un client qui force la route conseiller ne voit rien',
      (tester) async {
    final etat = await _etatNeuf(connecte: true);
    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    final navigateur = tester.state<NavigatorState>(find.byType(Navigator));
    navigateur.pushNamed('/agent/dossiers');
    await tester.pumpAndSettle();

    expect(find.text('Réservé aux conseillers'), findsOneWidget);
  });
}

/// Le thème sombre doit se construire et se rendre sans casse : c'est là
/// que se voient les couleurs oubliées en dur ou l'extension absente.
void _testsTheme() {
  testWidgets('le mode sombre se rend et applique ses nuances',
      (tester) async {
    final etat = await _etatNeuf();
    etat.changerMode(ModeTheme.sombre);

    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    final contexte = tester.element(find.text('Nos services'));
    final nuances = Theme.of(contexte).extension<Nuances>();

    expect(nuances, isNotNull, reason: 'extension Nuances absente');
    expect(nuances!.sombre, isTrue);
    expect(Theme.of(contexte).brightness, Brightness.dark);
  });

  testWidgets('le mode clair reste le réglage par défaut', (tester) async {
    final etat = await _etatNeuf();
    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    final contexte = tester.element(find.text('Nos services'));
    expect(Theme.of(contexte).extension<Nuances>()!.sombre, isFalse);
    expect(etat.mode, ModeTheme.systeme);
  });

  testWidgets('le choix de thème est conservé dans l\'état', (tester) async {
    final etat = await _etatNeuf();
    etat.changerMode(ModeTheme.sombre);
    expect(etat.themeMode, ThemeMode.dark);
    etat.changerMode(ModeTheme.clair);
    expect(etat.themeMode, ThemeMode.light);
  });
}

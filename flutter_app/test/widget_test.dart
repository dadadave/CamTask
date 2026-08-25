import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mon_comptable/api/api.dart';
import 'package:mon_comptable/main.dart';
import 'package:mon_comptable/models.dart';
import 'package:mon_comptable/state/app_state.dart';
import 'package:mon_comptable/theme.dart';

import 'faux_backend.dart';

/// Chaque test part d'un backend en mémoire : ni réseau, ni projet Supabase,
/// ni clés à fournir.
Future<AppState> _etatNeuf({FauxBackend? faux, bool connecte = false}) async {
  SharedPreferences.setMockInitialValues({});
  final source = faux ?? FauxBackend();
  utiliserBackend(source);
  if (connecte) {
    source.compte = const Compte(
      role: Role.utilisateur,
      nom: 'NGUEMA',
      prenom: 'Judicael',
      email: 'judicael@example.cm',
      telephone: '699000111',
      niu: 'P123456789012A',
      pieces: [],
      creeLe: '01/01/2026',
    );
  }
  final etat = AppState();
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

  _testsTheme();
  _testsBackend();
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

/// Ce que le passage au serveur a introduit : écran de configuration,
/// attente de la session, remontée des erreurs et messagerie en temps réel.
void _testsBackend() {
  testWidgets("sans clés, l'écran d'explication remplace l'application",
      (tester) async {
    final etat = await _etatNeuf(faux: BackendNonConfigure());

    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    expect(find.text('Application non configurée'), findsOneWidget);
    expect(find.text('Clés absentes.'), findsOneWidget);
    expect(find.text('Nos services'), findsNothing);
  });

  test('la session enregistrée est relue avant de trancher', () async {
    SharedPreferences.setMockInitialValues({});
    utiliserBackend(FauxBackend());
    final etat = AppState();

    // Avant `charger`, on ne sait pas encore : c'est ce qui empêche
    // `RequiertCompte` de renvoyer vers l'inscription à chaque ouverture.
    expect(etat.pret, isFalse);
    await etat.charger();
    expect(etat.pret, isTrue);
  });

  test('une session déjà ouverte est reprise au démarrage', () async {
    final etat = await _etatNeuf(connecte: true);
    expect(etat.connecte, isTrue);
    expect(etat.compte?.email, 'judicael@example.cm');
  });

  test("l'échec du serveur remonte à l'appelant", () async {
    final etat = await _etatNeuf(faux: BackendEnPanne(), connecte: true);

    expect(
      () => etat.envoyerDemande(
        serviceId: 'dsf',
        serviceLibelle: 'DSF',
        resume: 'peu importe',
      ),
      throwsA(isA<ErreurBackend>()),
    );
  });

  test('la réponse d\'un agent arrive en temps réel', () async {
    final faux = FauxBackend();
    final etat = await _etatNeuf(faux: faux, connecte: true);

    // Conversation vide : seul le mot d'accueil est affiché.
    expect(etat.messages, hasLength(1));

    faux.reponseAgent(
      const Message(
        id: 'reponse-1',
        auteur: Auteur.agent,
        texte: 'Bonjour, je consulte votre dossier.',
        heure: '09:31',
      ),
    );

    expect(etat.messages.last.texte, 'Bonjour, je consulte votre dossier.');
    expect(etat.messages.last.auteur, Auteur.agent);
  });

  test('la déconnexion vide le dossier local', () async {
    final etat = await _etatNeuf(connecte: true);
    await etat.envoyerDemande(
      serviceId: 'dsf',
      serviceLibelle: 'DSF',
      resume: 'un dossier',
    );
    expect(etat.demandes, hasLength(1));

    await etat.seDeconnecter();

    expect(etat.connecte, isFalse);
    expect(etat.demandes, isEmpty);
  });
}

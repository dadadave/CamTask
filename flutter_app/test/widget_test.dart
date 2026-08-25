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
class _BackendFactice implements BackendAuth {
  _BackendFactice({this.session});

  Compte? session;

  @override
  Future<Compte?> sessionActuelle({List<Piece> pieces = const []}) async =>
      session;

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
    List<Piece> pieces = const [],
  }) async =>
      session = _compteFactice;

  @override
  Future<void> deconnexion() async => session = null;
}

/// [connecte] ouvre d'emblee une session, comme au retour d'un lancement
/// ou l'utilisateur s'etait deja identifie.
Future<AppState> _etatNeuf({bool connecte = false}) async {
  SharedPreferences.setMockInitialValues({});
  final etat = AppState(
    backend: _BackendFactice(session: connecte ? _compteFactice : null),
    configure: true,
  );
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
    etat.envoyerDemande(
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

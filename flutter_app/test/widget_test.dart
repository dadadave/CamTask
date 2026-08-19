import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mon_comptable/main.dart';
import 'package:mon_comptable/models.dart';
import 'package:mon_comptable/state/app_state.dart';

Future<AppState> _etatNeuf() async {
  SharedPreferences.setMockInitialValues({});
  final etat = AppState();
  await etat.charger();
  return etat;
}

/// La tuile « Faire un audit » est la dernière de la grille : dans le
/// viewport de test elle est sous la ligne de flottaison, il faut donc
/// l'amener à l'écran avant de la toucher.
Future<void> _ouvrirAudit(WidgetTester tester) async {
  final cible = find.text('FAIRE UN AUDIT');
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

    expect(find.text('faites vos declaration chez nous'), findsOneWidget);
    expect(find.text('100% sur et rapide'), findsOneWidget);
    expect(find.text('BESOIN DE CONSEIL FISCALE'), findsOneWidget);
    expect(find.text('FAIRE UN AUDIT'), findsOneWidget);
  });

  testWidgets('la recherche filtre les services', (tester) async {
    await tester.pumpWidget(MonComptable(etat: await _etatNeuf()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'audit');
    await tester.pumpAndSettle();

    expect(find.text('FAIRE UN AUDIT'), findsOneWidget);
    expect(find.text('BESOIN DE CONSEIL FISCALE'), findsNothing);
  });

  testWidgets('un service exige un compte', (tester) async {
    await tester.pumpWidget(MonComptable(etat: await _etatNeuf()));
    await tester.pumpAndSettle();

    await _ouvrirAudit(tester);

    expect(find.text("Vous n'êtes pas connecté"), findsOneWidget);
  });

  testWidgets('avec un compte, le formulaire du service est accessible',
      (tester) async {
    final etat = await _etatNeuf();
    etat.seConnecter(
      Compte(
        role: Role.utilisateur,
        nom: 'NGUEMA',
        prenom: 'Judicael',
        email: 'judicael@example.cm',
        telephone: '699000111',
        niu: 'P123456789012A',
        pieces: const [],
        creeLe: AppState.dateDuJour(),
      ),
    );

    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    await _ouvrirAudit(tester);

    // Le formulaire de l'audit, dans l'ordre demandé.
    expect(find.text('NOM DE LA STRUCTURE'), findsOneWidget);
    expect(find.text("TYPE D'AUDIT"), findsOneWidget);
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
    final etat = await _etatNeuf();
    etat.seConnecter(
      Compte(
        role: Role.utilisateur,
        nom: 'NGUEMA',
        prenom: 'Judicael',
        email: 'judicael@example.cm',
        telephone: '699000111',
        niu: 'P123456789012A',
        pieces: const [],
        creeLe: AppState.dateDuJour(),
      ),
    );
    etat.envoyerDemande(
      serviceId: 'dsf',
      serviceLibelle: 'DSF — Déclaration statistique et fiscale',
      resume: 'NIU P123 — DSF pour la banque',
    );

    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('MES DEMANDES (1)'), findsOneWidget);
    expect(find.text('ENVOYÉE'), findsOneWidget);
  });
}

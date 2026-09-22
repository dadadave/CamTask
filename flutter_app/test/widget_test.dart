import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:excel/excel.dart';

import 'package:mon_comptable/api/api.dart';
import 'package:mon_comptable/export/tableur.dart';
import 'package:mon_comptable/main.dart';
import 'package:mon_comptable/models.dart';
import 'package:mon_comptable/state/app_state.dart';
import 'package:mon_comptable/theme.dart';

final _compteFactice = Compte(
  id: 'client-1',
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
    TypeClient typeClient = TypeClient.particulier,
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
  Future<String> lienDocument(String chemin, {String? nomFichier}) async =>
      'https://exemple.test/$chemin';

  /* -- Paiements -------------------------------------------------------- */

  /// L'agence est configuree : un moyen actif et un tarif.
  final List<MoyenPaiement> moyens = const [
    MoyenPaiement(
      id: 'mtn',
      libelle: 'MTN Mobile Money',
      codeUssd: '*126*4*111111#',
      beneficiaire: 'CAM-TAXE',
      consigne: 'Entrez le montant puis votre code PIN.',
    ),
  ];

  int montantAudit = 25000;
  final List<Paiement> paiements = [];

  @override
  Future<List<MoyenPaiement>> moyensPaiement() async => List.of(moyens);

  /// Les prix des deux profils, comme en base.
  int montantAuditEntreprise = 60000;

  /// Emise au depot d'un dossier, comme le declencheur en base.
  final List<Facture> factures = [];

  @override
  Future<int?> monTarif(String serviceId) async {
    if (serviceId != 'audit') return null;
    final prix = (session?.typeClient == TypeClient.entreprise)
        ? montantAuditEntreprise
        : montantAudit;
    return prix == 0 ? null : prix;
  }

  @override
  Future<List<TarifService>> tarifs() async => [
        TarifService(
          serviceId: 'audit',
          libelle: 'Faire un audit',
          particulier: montantAudit,
          entreprise: montantAuditEntreprise,
          actif: montantAudit > 0 || montantAuditEntreprise > 0,
        ),
      ];

  /// Rejoue le declencheur : un dossier facture emet sa facture.
  Facture emettre(String demandeId, {String service = 'audit'}) {
    final prix = (session?.typeClient == TypeClient.entreprise)
        ? montantAuditEntreprise
        : montantAudit;
    final f = Facture(
      id: 'facture-${factures.length}',
      numero: 'F-2026-${(factures.length + 1).toString().padLeft(4, '0')}',
      montant: prix,
      statut: StatutFacture.aPayer,
      date: AppState.dateDuJour(),
      serviceLibelle: 'Faire un audit',
      demandeId: demandeId,
    );
    factures.add(f);
    return f;
  }

  @override
  Future<Facture?> factureDuDossier(String demandeId) async {
    for (final f in factures) {
      if (f.demandeId == demandeId) return f;
    }
    return null;
  }

  @override
  Future<List<Facture>> mesFactures() async => List.of(factures);

  @override
  Future<List<Facture>> listerFactures() async => List.of(factures);

  @override
  Future<void> annulerFacture(String factureId) async {
    if (!(session?.estAdmin ?? false)) {
      throw const ErreurBackend('Seul un administrateur annule une facture');
    }
    for (var i = 0; i < factures.length; i++) {
      if (factures[i].id != factureId) continue;
      if (!factures[i].aPayer) {
        throw const ErreurBackend('Facture introuvable ou deja reglee');
      }
      final f = factures[i];
      factures[i] = Facture(
        id: f.id,
        numero: f.numero,
        montant: f.montant,
        statut: StatutFacture.annulee,
        date: f.date,
        serviceLibelle: f.serviceLibelle,
        demandeId: f.demandeId,
      );
      return;
    }
    throw const ErreurBackend('Facture introuvable ou deja reglee');
  }

  @override
  Future<void> declarerPaiement({
    required String factureId,
    required String operateur,
    required String numeroEnvoyeur,
    required String reference,
  }) async {
    final f = factures.where((x) => x.id == factureId);
    if (f.isEmpty) throw const ErreurBackend('Facture introuvable');
    if (!f.first.aPayer) {
      throw const ErreurBackend('Cette facture est deja reglee');
    }
    // On rejoue la regle de la base : une seule declaration par facture.
    if (paiements.any((p) =>
        p.demandeId == f.first.demandeId &&
        p.statut != StatutPaiement.rejete)) {
      throw const ErreurBackend(
          'Un paiement est deja enregistre pour cette facture');
    }
    paiements.add(Paiement(
      id: 'paiement-${paiements.length}',
      // Le montant vient de la facture, jamais de l'application.
      montant: f.first.montant,
      operateur: operateur,
      statut: StatutPaiement.declare,
      date: AppState.dateDuJour(),
      numeroEnvoyeur: numeroEnvoyeur,
      reference: reference,
      demandeId: f.first.demandeId,
    ));
  }

  @override
  Future<List<Paiement>> paiementsDuDossier(String demandeId) async =>
      [for (final p in paiements) if (p.demandeId == demandeId) p];

  @override
  Future<List<Paiement>> listerPaiements() async => List.of(paiements);

  @override
  Future<void> statuerPaiement(String paiementId, bool confirme,
      {String motif = ''}) async {
    // Seul un administrateur statue : c'est la regle que porte la base.
    if (!(session?.estAdmin ?? false)) {
      throw const ErreurBackend(
          'Seul un administrateur confirme un encaissement');
    }
    for (var i = 0; i < paiements.length; i++) {
      if (paiements[i].id != paiementId) continue;
      if (!paiements[i].enAttente) {
        throw const ErreurBackend('Declaration introuvable ou deja traitee');
      }
      final p = paiements[i];
      paiements[i] = Paiement(
        id: p.id,
        montant: p.montant,
        operateur: p.operateur,
        statut:
            confirme ? StatutPaiement.confirme : StatutPaiement.rejete,
        date: p.date,
        numeroEnvoyeur: p.numeroEnvoyeur,
        reference: p.reference,
        motif: motif,
        demandeId: p.demandeId,
      );
      if (confirme) {
        for (var j = 0; j < factures.length; j++) {
          if (factures[j].demandeId != p.demandeId) continue;
          final f = factures[j];
          factures[j] = Facture(
            id: f.id,
            numero: f.numero,
            montant: f.montant,
            statut: StatutFacture.payee,
            date: f.date,
            serviceLibelle: f.serviceLibelle,
            demandeId: f.demandeId,
          );
        }
      }
      return;
    }
    throw const ErreurBackend('Declaration introuvable ou deja traitee');
  }

  @override
  Future<void> definirTypeClient(String compteId, TypeClient type) async {
    if (!(session?.estAdmin ?? false)) {
      throw const ErreurBackend(
          'Seul un administrateur modifie la classification');
    }
    for (var i = 0; i < comptes.length; i++) {
      if (comptes[i].id == compteId) {
        comptes[i] = comptes[i].avec(typeClient: type);
      }
    }
  }

  @override
  Future<void> definirTarif(
    String serviceId,
    int particulier,
    int entreprise,
    bool actif,
  ) async {
    if (!(session?.estAdmin ?? false)) {
      throw const ErreurBackend('Seul un administrateur modifie les tarifs');
    }
    if (serviceId == 'audit') {
      montantAudit = particulier;
      montantAuditEntreprise = entreprise;
    }
  }

  @override
  Future<void> definirMoyen(
    String moyenId,
    String codeUssd,
    String beneficiaire,
    bool actif,
  ) async {
    if (!(session?.estAdmin ?? false)) {
      throw const ErreurBackend(
          'Seul un administrateur modifie les moyens de paiement');
    }
  }

  /* -- Administration --------------------------------------------------- */

  final List<MembreEquipe> comptes = [
    const MembreEquipe(
      id: 'client-1',
      nom: 'NGUEMA',
      prenom: 'Judicael',
      telephone: '699000111',
      estAgent: false,
      estAdmin: false,
    ),
    const MembreEquipe(
      id: 'agent-1',
      nom: 'MBALLA',
      prenom: 'Judicael',
      telephone: '699000333',
      estAgent: true,
      estAdmin: false,
    ),
    const MembreEquipe(
      id: 'admin-1',
      nom: 'ETOUNDI',
      prenom: 'Patronne',
      telephone: '699000444',
      estAgent: false,
      estAdmin: true,
    ),
  ];

  @override
  Future<List<MembreEquipe>> listerComptes() async {
    // La base ne sert cette liste qu'a un agent ou un admin.
    if (!(session?.estAgent ?? false) && !(session?.estAdmin ?? false)) {
      throw const ErreurBackend(
          "Vous n'avez pas l'autorisation d'effectuer cette action.");
    }
    return List.of(comptes);
  }

  @override
  Future<void> nommerConseiller(String compteId, bool conseiller) async {
    // On rejoue les deux garde-fous de la fonction `nommer_conseiller`.
    if (!(session?.estAdmin ?? false)) {
      throw const ErreurBackend(
          'Seul un administrateur peut nommer un conseiller');
    }
    if (compteId == session?.id) {
      throw const ErreurBackend(
          'Vous ne pouvez pas modifier votre propre habilitation');
    }
    for (var i = 0; i < comptes.length; i++) {
      if (comptes[i].id == compteId) {
        comptes[i] = comptes[i].avec(estAgent: conseiller);
      }
    }
  }

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
  id: 'agent-1',
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

const _compteEntreprise = Compte(
  id: 'client-1',
  role: Role.utilisateur,
  typeClient: TypeClient.entreprise,
  nom: 'SARL EXEMPLE',
  prenom: '',
  email: 'contact@exemple.cm',
  telephone: '699000555',
  niu: 'M123456789012B',
  pieces: [],
  creeLe: '01/01/2026',
);

final _compteAdmin = Compte(
  id: 'admin-1',
  role: Role.utilisateur,
  nom: 'ETOUNDI',
  prenom: 'Patronne',
  email: 'admin@cam-taxe.cm',
  telephone: '699000444',
  niu: '',
  pieces: const [],
  creeLe: AppState.dateDuJour(),
  estAdmin: true,
);

/// Un dossier deja depose par un client, tel qu'un conseiller le voit.
const _dossierClient = Demande(
  id: 'dossier-1',
  serviceId: 'audit',
  serviceLibelle: 'Faire un audit',
  resume: 'Audit fiscal — NIU P123',
  pieces: [
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
  bool admin = false,
  List<Demande> dossiers = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final faux = _BackendFactice(
    session: admin
        ? _compteAdmin
        : agent
            ? _compteAgent
            : (connecte ? _compteFactice : null),
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
    // Plus de faux bouton : l'ecran annonce que la caution se regle
    // apres l'envoi, ce qui est la verite.
    expect(find.textContaining('caution est demand'), findsOneWidget);

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

  _testsDossiersClient();
  _testsLargeurEcran();
  _testsExport();
  _testsAgent();
  _testsAdmin();
  _testsPaiement();
  _testsTheme();
}

/// La colonne d'etat doit se lire sans faire defiler la table.
///
/// Les tables defilent a l'horizontale, et rien n'empeche d'y mettre plus
/// de colonnes que l'ecran n'en montre. La premiere version le faisait :
/// « En attente » et « Payee » tombaient hors champ sur un telephone, or
/// c'est precisement ce qu'on vient y lire. Ces tests tiennent la promesse.
void _testsLargeurEcran() {
  /// Le plus etroit des telephones courants.
  const largeur = 360.0;

  Future<void> surTelephone(WidgetTester tester, AppState etat) async {
    tester.view.physicalSize = const Size(largeur, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();
  }

  /// La pastille est-elle entierement dans l'ecran, sans defilement ?
  void estVisible(WidgetTester tester, Finder cible) {
    final r = tester.getRect(cible);
    expect(
      r.right,
      lessThanOrEqualTo(largeur),
      reason: 'La colonne deborde de ${(r.right - largeur).round()} px : '
          'elle exige un defilement horizontal pour se lire.',
    );
    expect(r.left, greaterThanOrEqualTo(0.0));
  }

  testWidgets("l etat d'une facture se lit sans defiler", (tester) async {
    SharedPreferences.setMockInitialValues({});
    final faux = _BackendFactice(session: _compteFactice);
    faux.demandes.add(_dossierClient);
    faux.emettre('dossier-1');
    final etat = AppState(backendInjecte: faux, configure: true);
    await etat.charger();

    await surTelephone(tester, etat);
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mes factures'));
    await tester.pumpAndSettle();

    // Dans la table, pas dans les pastilles de filtre : on vise la cellule.
    estVisible(tester, find.text('À payer').last);
  });

  testWidgets("l etat d'un dossier se lit sans defiler, cote client",
      (tester) async {
    final etat = await _etatNeuf(connecte: true, dossiers: [_dossierClient]);
    await surTelephone(tester, etat);
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mes demandes'));
    await tester.pumpAndSettle();

    estVisible(tester, find.text('Envoyée').last);
  });

  testWidgets("le conseiller lit le client et l etat sans defiler",
      (tester) async {
    final etat = await _etatNeuf(agent: true, dossiers: [_dossierClient]);
    await surTelephone(tester, etat);

    // Le nom du client vient en premier : c'est par lui qu'on repere une
    // ligne quand on voit les dossiers de tout le monde.
    estVisible(tester, find.text('Bout TEST'));
    estVisible(tester, find.text('Envoyée').last);
  });
}

/// Le classeur des transactions.
///
/// Il se teste seul : la construction ne touche ni a Flutter ni a
/// l'appareil, et c'est tout l'interet de l'avoir sortie de l'ecran.
void _testsExport() {
  Facture facture(String numero, int montant, StatutFacture statut) => Facture(
        id: numero,
        numero: numero,
        montant: montant,
        statut: statut,
        date: '21/09/2026',
        serviceLibelle: 'Faire un audit',
        demandeId: 'dossier-1',
        clientNom: 'Judicael NGUEMA',
      );

  Paiement versement(int montant, StatutPaiement statut) => Paiement(
        id: 'p-$montant',
        montant: montant,
        operateur: 'orange',
        statut: statut,
        date: '21/09/2026',
        numeroEnvoyeur: '699000111',
        reference: 'MP260921.1200.A1',
        clientNom: 'Judicael NGUEMA',
        serviceLibelle: 'Faire un audit',
      );

  test('le classeur porte les trois feuilles attendues', () {
    final octets = classeurTransactions(
      factures: [facture('F-0001', 10000, StatutFacture.payee)],
      paiements: [versement(10000, StatutPaiement.confirme)],
    );
    expect(octets, isNotNull);

    final relu = Excel.decodeBytes(octets!);
    expect(relu.sheets.keys, containsAll(<String>['Factures', 'Paiements']));
    // La feuille vide du gabarit a ete retiree.
    expect(relu.sheets.keys, isNot(contains('Sheet1')));
  });

  test('les montants partent en nombres, pas en texte', () {
    // « 25 000 FCFA » ne s'additionne pas : c'est tout l'objet de l'export.
    final octets = classeurTransactions(
      factures: [facture('F-0001', 25000, StatutFacture.aPayer)],
      paiements: const [],
    );
    final relu = Excel.decodeBytes(octets!);
    final ligne = relu.tables['Factures']!.rows[1];
    expect(ligne[4]?.value, isA<IntCellValue>());
    expect((ligne[4]!.value! as IntCellValue).value, 25000);
  });

  test('la synthese rapproche le facture et l encaisse', () {
    final octets = classeurTransactions(
      factures: [
        facture('F-0001', 10000, StatutFacture.payee),
        facture('F-0002', 15000, StatutFacture.aPayer),
      ],
      paiements: [
        versement(10000, StatutPaiement.confirme),
        versement(15000, StatutPaiement.declare),
      ],
    );
    final relu = Excel.decodeBytes(octets!);
    final lignes = relu.tables['Synthèse']!.rows;

    int valeur(String libelle) {
      for (final l in lignes) {
        if (l.isEmpty || l.first?.value == null) continue;
        if (l.first!.value.toString() == libelle) {
          return (l[2]!.value! as IntCellValue).value;
        }
      }
      fail('Ligne « $libelle » absente de la synthese.');
    }

    expect(valeur('Factures émises'), 25000);
    expect(valeur('Versements confirmés'), 10000);
    // Un versement declare n'est pas de l'argent vu : il ne compte pas.
    expect(valeur('Reste à encaisser'), 15000);
  });

  test('un classeur vide reste ouvrable', () {
    final octets = classeurTransactions(factures: const [], paiements: const []);
    expect(octets, isNotNull);
    expect(Excel.decodeBytes(octets!).sheets, isNotEmpty);
  });

  test('le nom de fichier se classe par ordre chronologique', () {
    final nom = nomFichierTransactions(DateTime(2026, 9, 21, 17, 4));
    expect(nom, 'camtaxe-transactions-20260921-1704.xlsx');
  });
}

/// Le profil annonce, il ne deroule pas.
///
/// Demandes et factures s'accumulent sans fin : les lister sur le profil
/// finissait par noyer les coordonnees et la deconnexion. Chacune a son
/// ecran, et le profil n'en garde que l'entree et le compte.
void _testsDossiersClient() {
  /// Un client avec un dossier envoye, et de quoi semer des factures.
  Future<(AppState, _BackendFactice)> clientAvecDossier() async {
    SharedPreferences.setMockInitialValues({});
    final faux = _BackendFactice(session: _compteFactice);
    faux.demandes.add(_dossierClient);
    final etat = AppState(backendInjecte: faux, configure: true);
    await etat.charger();
    return (etat, faux);
  }

  /// Ouvre le profil depuis l'onglet du bas. Les onglets inactifs
  /// n'affichent plus leur libelle : on vise l'icone.
  Future<void> ouvrirProfil(WidgetTester tester, AppState etat) async {
    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
  }

  testWidgets('le profil compte les demandes sans les derouler',
      (tester) async {
    final (etat, _) = await clientAvecDossier();
    await ouvrirProfil(tester, etat);

    // L'entree est la, avec son compte et son etat resume.
    expect(find.text('Mes demandes'), findsOneWidget);
    expect(find.text('1 en cours'), findsOneWidget);

    // Mais pas la carte du dossier : c'est tout le propos du changement.
    expect(find.text('Audit fiscal — NIU P123'), findsNothing);
  });

  testWidgets('l ecran des demandes deroule le dossier', (tester) async {
    final (etat, _) = await clientAvecDossier();
    await ouvrirProfil(tester, etat);

    await tester.tap(find.text('Mes demandes'));
    await tester.pumpAndSettle();

    expect(find.text('Audit fiscal — NIU P123'), findsOneWidget);
    expect(find.text('Envoyée'), findsOneWidget);

    // Le detail s'ouvre a la demande, et porte les documents.
    await tester.tap(find.text('Audit fiscal — NIU P123'));
    await tester.pumpAndSettle();
    expect(find.text('Ce que vous avez envoyé'), findsOneWidget);
    expect(find.text('Photo de la CNI'), findsOneWidget);
  });

  testWidgets('un seul dossier ne montre pas de filtres', (tester) async {
    final (etat, _) = await clientAvecDossier();
    await ouvrirProfil(tester, etat);
    await tester.tap(find.text('Mes demandes'));
    await tester.pumpAndSettle();

    // Les pastilles ne serviraient qu'a occuper la place de ce qu'on est
    // venu lire.
    expect(find.text('Toutes (1)'), findsNothing);
  });

  testWidgets('plusieurs dossiers filtrent par statut', (tester) async {
    final (etat, faux) = await clientAvecDossier();
    faux.demandes.add(_dossierClient.avec(statut: 'Traitée'));
    await etat.rafraichirDemandes();

    await ouvrirProfil(tester, etat);
    await tester.tap(find.text('Mes demandes'));
    await tester.pumpAndSettle();

    expect(find.text('Toutes (2)'), findsOneWidget);
    expect(find.text('Audit fiscal — NIU P123'), findsNWidgets(2));

    await tester.tap(find.text('Traitée (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Audit fiscal — NIU P123'), findsOneWidget);
  });

  testWidgets('le profil signale ce qui reste a regler', (tester) async {
    final (etat, faux) = await clientAvecDossier();
    faux.emettre('dossier-1');
    await ouvrirProfil(tester, etat);

    expect(find.text('Mes factures'), findsOneWidget);
    expect(find.text('1 à régler'), findsOneWidget);
    // Le montant reste sur l'ecran des factures, pas sur le profil.
    expect(find.textContaining('FCFA'), findsNothing);
  });

  testWidgets('la table des factures tient sur une ligne', (tester) async {
    final (etat, faux) = await clientAvecDossier();
    faux.emettre('dossier-1');
    await ouvrirProfil(tester, etat);

    await tester.tap(find.text('Mes factures'));
    await tester.pumpAndSettle();

    // Les colonnes, puis la ligne : le numero, le montant et l'etat se
    // lisent sans rien ouvrir.
    expect(find.text('Numéro'), findsOneWidget);
    expect(find.text('Montant'), findsOneWidget);
    expect(find.text('F-2026-0001'), findsOneWidget);
    expect(find.text('À payer'), findsWidgets);

    // Le bouton n'encombre pas la table : il est dans le detail.
    expect(find.text('Régler cette facture'), findsNothing);
  });

  testWidgets('la ligne ouvre le detail, qui propose de regler',
      (tester) async {
    final (etat, faux) = await clientAvecDossier();
    faux.emettre('dossier-1');
    await ouvrirProfil(tester, etat);
    await tester.tap(find.text('Mes factures'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('F-2026-0001'));
    await tester.pumpAndSettle();

    expect(find.text('Régler cette facture'), findsOneWidget);
    expect(find.text('Faire un audit'), findsWidgets);
  });

  testWidgets('la recherche retrouve une facture par son numero',
      (tester) async {
    final (etat, faux) = await clientAvecDossier();
    for (var i = 0; i < 4; i++) {
      faux.demandes.add(_dossierClient);
      faux.emettre('dossier-1');
    }
    await ouvrirProfil(tester, etat);
    await tester.tap(find.text('Mes factures'));
    await tester.pumpAndSettle();

    expect(find.text('F-2026-0001'), findsOneWidget);
    expect(find.text('F-2026-0003'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '0003');
    await tester.pumpAndSettle();

    expect(find.text('F-2026-0003'), findsOneWidget);
    expect(find.text('F-2026-0001'), findsNothing);
  });

  testWidgets('une recherche sans resultat le dit', (tester) async {
    final (etat, faux) = await clientAvecDossier();
    for (var i = 0; i < 4; i++) {
      faux.demandes.add(_dossierClient);
      faux.emettre('dossier-1');
    }
    await ouvrirProfil(tester, etat);
    await tester.tap(find.text('Mes factures'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('Aucune facture ne correspond'), findsOneWidget);
  });

  testWidgets('une facture payee ne propose plus rien', (tester) async {
    final (etat, faux) = await clientAvecDossier();
    final f = faux.emettre('dossier-1');
    await faux.declarerPaiement(
      factureId: f.id,
      operateur: 'orange',
      numeroEnvoyeur: '699000111',
      reference: 'MP260921.1200.A1',
    );
    faux.session = _compteAdmin;
    await faux.statuerPaiement(faux.paiements.single.id, true);
    faux.session = _compteFactice;

    await ouvrirProfil(tester, etat);
    await tester.tap(find.text('Mes factures'));
    await tester.pumpAndSettle();

    expect(find.text('Payée'), findsWidgets);

    await tester.tap(find.text('F-2026-0001'));
    await tester.pumpAndSettle();
    expect(find.text('Régler cette facture'), findsNothing);
  });

  testWidgets('sans facture, l ecran le dit', (tester) async {
    final (etat, _) = await clientAvecDossier();
    await ouvrirProfil(tester, etat);

    expect(find.text('Aucune facture'), findsOneWidget);
    await tester.tap(find.text('Mes factures'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune facture pour le moment'), findsOneWidget);
  });
}

/// Un client declare, il ne valide pas. C'est toute la regle : sans elle,
/// n'importe qui ferait avancer son dossier en affirmant avoir paye.
void _testsPaiement() {
  /// Un etat de client, avec son dossier deja facture.
  Future<(AppState, _BackendFactice, Facture)> facture({
    TypeClient type = TypeClient.particulier,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final faux = _BackendFactice(
      session: type == TypeClient.entreprise
          ? _compteEntreprise
          : _compteFactice,
    );
    faux.demandes.add(_dossierClient);
    final f = faux.emettre('dossier-1');
    final etat = AppState(backendInjecte: faux, configure: true);
    await etat.charger();
    return (etat, faux, f);
  }

  testWidgets('le depot emet une facture numerotee', (tester) async {
    final (_, _, f) = await facture();
    expect(f.numero, 'F-2026-0001');
    expect(f.statut, StatutFacture.aPayer);
    expect(f.montant, 25000);
  });

  testWidgets('une entreprise est facturee a son propre tarif',
      (tester) async {
    final (_, _, f) = await facture(type: TypeClient.entreprise);
    expect(f.montant, 60000);
  });

  testWidgets('un client declare un versement, sans le valider',
      (tester) async {
    final (etat, _, f) = await facture();
    await etat.declarerPaiement(
      factureId: f.id,
      operateur: 'mtn',
      numeroEnvoyeur: '699000111',
      reference: 'MP240821.1432.A1',
    );

    final liste = await etat.paiementsDuDossier('dossier-1');
    expect(liste.single.statut, StatutPaiement.declare);
    expect(liste.single.enAttente, isTrue);
  });

  testWidgets('le montant vient de la facture, pas du client',
      (tester) async {
    final (etat, _, f) = await facture();
    await etat.declarerPaiement(
      factureId: f.id,
      operateur: 'mtn',
      numeroEnvoyeur: '699000111',
      reference: 'MP.1',
    );

    final liste = await etat.paiementsDuDossier('dossier-1');
    expect(liste.single.montant, 25000);
  });

  testWidgets('on ne paie pas deux fois la meme facture', (tester) async {
    final (etat, _, f) = await facture();
    await etat.declarerPaiement(
      factureId: f.id,
      operateur: 'mtn',
      numeroEnvoyeur: '699000111',
      reference: 'MP.1',
    );

    await expectLater(
      etat.declarerPaiement(
        factureId: f.id,
        operateur: 'mtn',
        numeroEnvoyeur: '699000111',
        reference: 'MP.2',
      ),
      throwsA(isA<ErreurBackend>()),
    );
  });

  testWidgets('la confirmation solde la facture', (tester) async {
    final (etat, faux, f) = await facture();
    await etat.declarerPaiement(
      factureId: f.id,
      operateur: 'mtn',
      numeroEnvoyeur: '699000111',
      reference: 'MP.1',
    );
    faux.session = _compteAdmin;
    await etat.statuerPaiement(faux.paiements.single.id, true);

    expect(faux.factures.single.statut, StatutFacture.payee);
  });

  testWidgets('seul un administrateur annule une facture', (tester) async {
    final (etat, faux, f) = await facture();
    await expectLater(
      etat.annulerFacture(f.id),
      throwsA(isA<ErreurBackend>()),
    );

    faux.session = _compteAdmin;
    await etat.annulerFacture(f.id);
    expect(faux.factures.single.statut, StatutFacture.annulee);
  });

  testWidgets('un client ne peut PAS confirmer son propre versement',
      (tester) async {
    final faux = _BackendFactice(session: _compteFactice);
    faux.emettre('dossier-1');
    faux.paiements.add(const Paiement(
      id: 'paiement-0',
      montant: 25000,
      operateur: 'mtn',
      statut: StatutPaiement.declare,
      date: '01/01/2026',
      demandeId: 'dossier-1',
    ));
    SharedPreferences.setMockInitialValues({});
    final etat = AppState(backendInjecte: faux, configure: true);
    await etat.charger();

    await expectLater(
      etat.statuerPaiement('paiement-0', true),
      throwsA(isA<ErreurBackend>()),
    );
    expect(faux.paiements.single.statut, StatutPaiement.declare);
  });

  testWidgets('un conseiller ne peut PAS confirmer non plus', (tester) async {
    final faux = _BackendFactice(session: _compteAgent);
    faux.emettre('dossier-1');
    faux.paiements.add(const Paiement(
      id: 'paiement-0',
      montant: 25000,
      operateur: 'mtn',
      statut: StatutPaiement.declare,
      date: '01/01/2026',
      demandeId: 'dossier-1',
    ));
    SharedPreferences.setMockInitialValues({});
    final etat = AppState(backendInjecte: faux, configure: true);
    await etat.charger();

    await expectLater(
      etat.statuerPaiement('paiement-0', true),
      throwsA(isA<ErreurBackend>()),
    );
  });

  testWidgets('un administrateur confirme, puis ne peut plus y revenir',
      (tester) async {
    final faux = _BackendFactice(session: _compteAdmin);
    faux.emettre('dossier-1');
    faux.paiements.add(const Paiement(
      id: 'paiement-0',
      montant: 25000,
      operateur: 'mtn',
      statut: StatutPaiement.declare,
      date: '01/01/2026',
      demandeId: 'dossier-1',
    ));
    SharedPreferences.setMockInitialValues({});
    final etat = AppState(backendInjecte: faux, configure: true);
    await etat.charger();

    await etat.statuerPaiement('paiement-0', true);
    expect(faux.paiements.single.statut, StatutPaiement.confirme);

    // Une declaration deja traitee ne se rejoue pas.
    await expectLater(
      etat.statuerPaiement('paiement-0', false),
      throwsA(isA<ErreurBackend>()),
    );
  });

  testWidgets('seul un administrateur modifie les tarifs', (tester) async {
    final client = await _etatNeuf(connecte: true);
    await expectLater(
      client.definirTarif('audit', 50000, 90000, true),
      throwsA(isA<ErreurBackend>()),
    );

    final admin = await _etatNeuf(admin: true);
    await admin.definirTarif('audit', 50000, 90000, true);
    final t = (await admin.tarifs()).single;
    expect(t.particulier, 50000);
    expect(t.entreprise, 90000);
  });

  testWidgets('le montant s affiche avec ses milliers', (tester) async {
    expect(montantEnFcfa(25000), '25\u202F000 FCFA');
  });
}

/// Nommer un conseiller donne acces aux dossiers de tous les clients : c'est
/// le droit le plus sensible de l'application.
void _testsAdmin() {
  testWidgets('un admin arrive sur son equipe', (tester) async {
    final etat = await _etatNeuf(admin: true);
    expect(etat.estAdmin, isTrue);
    expect(etat.estAgent, isFalse);
    expect(etat.routeAccueil, '/admin/equipe');

    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    expect(find.text('Équipe'), findsWidgets);
    expect(find.text('Judicael NGUEMA'), findsOneWidget);
  });

  testWidgets('un admin nomme un conseiller', (tester) async {
    final etat = await _etatNeuf(admin: true);
    await etat.nommerConseiller('client-1', true);

    final comptes = await etat.comptes();
    expect(comptes.firstWhere((m) => m.id == 'client-1').estAgent, isTrue);
  });

  testWidgets('un conseiller ordinaire ne peut PAS nommer', (tester) async {
    final etat = await _etatNeuf(agent: true);
    await expectLater(
      etat.nommerConseiller('client-1', true),
      throwsA(isA<ErreurBackend>()),
    );
  });

  testWidgets('un client ne peut PAS nommer', (tester) async {
    final etat = await _etatNeuf(connecte: true);
    await expectLater(
      etat.nommerConseiller('client-1', true),
      throwsA(isA<ErreurBackend>()),
    );
  });

  testWidgets('un admin ne modifie pas sa propre habilitation',
      (tester) async {
    final etat = await _etatNeuf(admin: true);
    await expectLater(
      etat.nommerConseiller('admin-1', true),
      throwsA(isA<ErreurBackend>()),
    );
  });

  testWidgets('un client qui force la route equipe ne voit rien',
      (tester) async {
    final etat = await _etatNeuf(connecte: true);
    await tester.pumpWidget(MonComptable(etat: etat));
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/admin/equipe');
    await tester.pumpAndSettle();

    expect(find.text('Réservé aux administrateurs'), findsOneWidget);
  });
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

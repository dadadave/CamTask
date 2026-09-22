import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models.dart';

/// Construit le classeur des transactions de l'agence.
///
/// Trois feuilles, parce qu'on n'y cherche pas la même chose :
///
///   Factures    ce qui a été facturé — la dette émise
///   Paiements   ce qui a été déclaré et confirmé — l'argent vu
///   Synthèse    les totaux, pour rapprocher les deux
///
/// Les montants partent en **nombres**, jamais en « 25 000 FCFA » : une
/// somme écrite avec son unité ne s'additionne pas, et le tableur est
/// précisément là pour additionner. Les totaux sont des formules `SUM`, de
/// sorte qu'un filtre ou une ligne retirée les recalcule.
///
/// Rien ici ne touche à Flutter ni à l'appareil : la construction du
/// classeur se teste seule, et l'enregistrement est le problème de
/// l'écran.
Uint8List? classeurTransactions({
  required List<Facture> factures,
  required List<Paiement> paiements,
}) {
  final classeur = Excel.createExcel();

  _feuilleFactures(classeur, factures);
  _feuillePaiements(classeur, paiements);
  _feuilleSynthese(classeur, factures, paiements);

  // `createExcel` ouvre un classeur avec une feuille vide qu'on n'a pas
  // demandée : sans cela, le fichier s'ouvre sur du blanc.
  if (classeur.sheets.length > 3) classeur.delete('Sheet1');
  classeur.setDefaultSheet(_feuilleSyntheseNom);

  final octets = classeur.save();
  return octets == null ? null : Uint8List.fromList(octets);
}

const _feuilleFacturesNom = 'Factures';
const _feuillePaiementsNom = 'Paiements';
const _feuilleSyntheseNom = 'Synthèse';

/// Un nom de fichier qui se classe tout seul par ordre chronologique.
String nomFichierTransactions(DateTime quand) {
  String d(int n) => n.toString().padLeft(2, '0');
  return 'camtaxe-transactions-'
      '${quand.year}${d(quand.month)}${d(quand.day)}-'
      '${d(quand.hour)}${d(quand.minute)}.xlsx';
}

CellStyle get _styleEntete => CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
    );

CellStyle get _styleTotal => CellStyle(bold: true, fontSize: 11);

void _entete(Sheet feuille, List<String> colonnes) {
  feuille.appendRow([for (final c in colonnes) TextCellValue(c)]);
  for (var i = 0; i < colonnes.length; i++) {
    feuille
        .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        .cellStyle = _styleEntete;
  }
}

/// Élargit chaque colonne à son contenu, sinon les libellés de service
/// arrivent tronqués et il faut les élargir à la main à chaque ouverture.
void _ajuster(Sheet feuille, int colonnes) {
  for (var i = 0; i < colonnes; i++) {
    feuille.setColumnAutoFit(i);
  }
}

void _feuilleFactures(Excel classeur, List<Facture> factures) {
  final f = classeur[_feuilleFacturesNom];
  const colonnes = [
    'Numéro',
    'Date',
    'Client',
    'Service',
    'Montant (FCFA)',
    'Statut',
    'Dossier',
  ];
  _entete(f, colonnes);

  for (final x in factures) {
    f.appendRow([
      TextCellValue(x.numero),
      TextCellValue(x.date),
      TextCellValue(x.clientNom),
      TextCellValue(x.serviceLibelle),
      IntCellValue(x.montant),
      TextCellValue(x.libelleStatut),
      TextCellValue(x.demandeId),
    ]);
  }

  _totalColonneE(f, factures.length);
  _ajuster(f, colonnes.length);
}

void _feuillePaiements(Excel classeur, List<Paiement> paiements) {
  final f = classeur[_feuillePaiementsNom];
  const colonnes = [
    'Date',
    'Client',
    'Service',
    'Montant (FCFA)',
    'Opérateur',
    'Numéro émetteur',
    'Référence',
    'Statut',
    'Motif du rejet',
  ];
  _entete(f, colonnes);

  for (final p in paiements) {
    f.appendRow([
      TextCellValue(p.date),
      TextCellValue(p.clientNom),
      TextCellValue(p.serviceLibelle),
      IntCellValue(p.montant),
      TextCellValue(p.operateur.toUpperCase()),
      TextCellValue(p.numeroEnvoyeur),
      TextCellValue(p.reference),
      TextCellValue(p.libelleStatut),
      TextCellValue(p.motif),
    ]);
  }

  _totalColonne(f, colonne: 'D', premiere: 3, lignes: paiements.length);
  _ajuster(f, colonnes.length);
}

/// La ligne de total des factures : la colonne des montants y est la E.
void _totalColonneE(Sheet f, int lignes) =>
    _totalColonne(f, colonne: 'E', premiere: 4, lignes: lignes);

/// Pose « Total » et une formule `SUM` sous la dernière ligne.
///
/// Une formule plutôt qu'un nombre calculé ici : filtrer la feuille ou en
/// retirer une ligne doit changer le total, sinon il ment dès la première
/// manipulation.
void _totalColonne(
  Sheet f, {
  required String colonne,
  required int premiere,
  required int lignes,
}) {
  if (lignes == 0) return;

  // Les données commencent en ligne 2 du tableur (la 1 est l'en-tête).
  final derniere = lignes + 1;

  f.updateCell(
    CellIndex.indexByColumnRow(columnIndex: premiere - 1, rowIndex: derniere),
    TextCellValue('Total'),
    cellStyle: _styleTotal,
  );
  f.updateCell(
    CellIndex.indexByColumnRow(columnIndex: premiere, rowIndex: derniere),
    FormulaCellValue('SUM(${colonne}2:$colonne$derniere)'),
    cellStyle: _styleTotal,
  );
}

void _feuilleSynthese(
  Excel classeur,
  List<Facture> factures,
  List<Paiement> paiements,
) {
  final f = classeur[_feuilleSyntheseNom];

  int sommeF(bool Function(Facture) garde) =>
      factures.where(garde).fold(0, (s, x) => s + x.montant);
  int sommeP(StatutPaiement s) => paiements
      .where((p) => p.statut == s)
      .fold(0, (t, p) => t + p.montant);

  final facture = sommeF((_) => true);
  final encaisse = sommeP(StatutPaiement.confirme);
  final attendu = sommeF((x) => x.aPayer);

  _entete(f, const ['Indicateur', 'Nombre', 'Montant (FCFA)']);

  void ligne(String libelle, int nombre, int montant) {
    f.appendRow([
      TextCellValue(libelle),
      IntCellValue(nombre),
      IntCellValue(montant),
    ]);
  }

  ligne('Factures émises', factures.length, facture);
  ligne(
    'Factures payées',
    factures.where((x) => x.statut == StatutFacture.payee).length,
    sommeF((x) => x.statut == StatutFacture.payee),
  );
  ligne('Factures à payer', factures.where((x) => x.aPayer).length, attendu);
  ligne(
    'Factures annulées',
    factures.where((x) => x.statut == StatutFacture.annulee).length,
    sommeF((x) => x.statut == StatutFacture.annulee),
  );
  ligne(
    'Versements confirmés',
    paiements.where((p) => p.statut == StatutPaiement.confirme).length,
    encaisse,
  );
  ligne(
    'Versements en attente',
    paiements.where((p) => p.enAttente).length,
    sommeP(StatutPaiement.declare),
  );
  ligne(
    'Versements rejetés',
    paiements.where((p) => p.statut == StatutPaiement.rejete).length,
    sommeP(StatutPaiement.rejete),
  );

  // L'écart est ce qu'on vient vérifier : facturé moins encaissé. S'il ne
  // vaut pas le total des factures à payer, c'est qu'un versement confirmé
  // n'a pas soldé sa facture, et cela se voit ici.
  f.appendRow([]);
  f.appendRow([
    TextCellValue('Reste à encaisser'),
    TextCellValue(''),
    IntCellValue(facture - encaisse),
  ]);
  final derniere = f.maxRows - 1;
  for (var c = 0; c < 3; c++) {
    f
        .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: derniere))
        .cellStyle = _styleTotal;
  }

  _ajuster(f, 3);
}

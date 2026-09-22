import 'package:flutter/material.dart';

import '../theme.dart';

/// Une colonne d'une table d'administration.
///
/// [largeur] est fixe et non proportionnelle : la table défile à
/// l'horizontale, et une largeur en pourcentage n'aurait rien à quoi se
/// rapporter.
typedef ColonneTable = ({String titre, double largeur, bool aDroite});

ColonneTable colonne(String titre, double largeur, {bool aDroite = false}) =>
    (titre: titre, largeur: largeur, aDroite: aDroite);

/// Une table dense, partout où l'on lit une liste plutôt qu'un objet.
///
/// Une carte par ligne dit beaucoup d'une ligne et rend la liste illisible :
/// il fallait défiler sans fin pour rapprocher deux montants, et l'écran ne
/// montrait que trois entrées à la fois. Ici une ligne tient sur une ligne,
/// les colonnes s'alignent, et le détail s'ouvre à la demande.
///
/// Elle défile à l'horizontale quand elle est plus large que l'écran, avec
/// l'en-tête solidaire des lignes : sur un téléphone, huit colonnes ne
/// tiennent pas, et les tronquer ferait perdre la référence ou le motif
/// d'un rejet.
class TableDonnees extends StatefulWidget {
  const TableDonnees({
    super.key,
    required this.colonnes,
    required this.lignes,
    this.surLigne,
  });

  final List<ColonneTable> colonnes;

  /// Une ligne par entrée, une cellule par colonne. Les longueurs doivent
  /// correspondre à [colonnes].
  final List<LigneTable> lignes;

  /// Appelé quand on touche une ligne. Reçoit son indice.
  final void Function(int indice)? surLigne;

  @override
  State<TableDonnees> createState() => _TableDonneesState();
}

class _TableDonneesState extends State<TableDonnees> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final largeur = widget.colonnes.fold<double>(0, (s, c) => s + c.largeur);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Espaces.bord),
      child: Container(
        decoration: BoxDecoration(
          color: n.carte,
          borderRadius: Rayons.brLg,
          border: Border.all(color: n.ligne),
          boxShadow: n.ombreDouce,
        ),
        clipBehavior: Clip.antiAlias,
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: largeur,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _enTete(n),
                  for (var i = 0; i < widget.lignes.length; i++)
                    _ligne(n, i, widget.lignes[i]),
                  // La barre de défilement se pose sous la dernière ligne :
                  // sans cette marge, elle mord sur le dernier montant.
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _enTete(Nuances n) {
    return Container(
      color: n.fondDoux,
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          for (final c in widget.colonnes)
            SizedBox(
              width: c.largeur,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  c.titre,
                  textAlign: c.aDroite ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    color: n.encreDouce,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ligne(Nuances n, int indice, LigneTable ligne) {
    final contenu = Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: n.fondDoux)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.colonnes.length; i++)
            SizedBox(
              width: widget.colonnes[i].largeur,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: i < ligne.cellules.length
                    ? ligne.cellules[i]
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );

    if (widget.surLigne == null) return contenu;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.surLigne!(indice),
        child: contenu,
      ),
    );
  }
}

/// Une ligne de [TableDonnees].
class LigneTable {
  const LigneTable(this.cellules);

  final List<Widget> cellules;
}

/// Le contenu courant d'une cellule : du texte, éventuellement atone.
class CelluleTexte extends StatelessWidget {
  const CelluleTexte(
    this.texte, {
    super.key,
    this.aDroite = false,
    this.gras = false,
    this.atone = false,
    this.taille = 12.5,
  });

  final String texte;
  final bool aDroite;
  final bool gras;

  /// Une valeur absente — « non fournie », un motif vide. Elle s'efface au
  /// lieu de disparaître : la colonne doit rester lisible.
  final bool atone;

  final double taille;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Text(
      texte.isEmpty ? '—' : texte,
      textAlign: aDroite ? TextAlign.right : TextAlign.left,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: taille,
        height: 1.3,
        fontWeight: gras ? FontWeight.w800 : FontWeight.w500,
        color: (atone || texte.isEmpty) ? n.grise : n.encre,
        fontFeatures: aDroite
            // Chiffres de même chasse : sans cela, une colonne de montants
            // ne s'aligne pas et se compare mal.
            ? const [FontFeature.tabularFigures()]
            : null,
      ),
    );
  }
}

/// Une pastille d'état dans une cellule.
class CelluleEtat extends StatelessWidget {
  const CelluleEtat({
    super.key,
    required this.libelle,
    required this.accent,
    required this.fond,
  });

  final String libelle;
  final Color accent;
  final Color fond;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: fond, borderRadius: Rayons.brPilule),
        child: Text(
          libelle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ),
    );
  }
}

/// Un bandeau de totaux, au-dessus d'une table.
///
/// C'est ce qu'on vient chercher en premier sur un écran de transactions :
/// combien a été facturé, combien est rentré.
class BandeauTotaux extends StatelessWidget {
  const BandeauTotaux({super.key, required this.entrees});

  /// Libellé, valeur, et si la valeur appelle l'attention.
  final List<({String libelle, String valeur, bool alerte})> entrees;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, 0, Espaces.bord, Espaces.md),
      child: Row(
        children: [
          for (var i = 0; i < entrees.length; i++) ...[
            if (i > 0) const SizedBox(width: Espaces.sm),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Espaces.md, vertical: Espaces.md),
                decoration: BoxDecoration(
                  color: entrees[i].alerte ? n.orangeFantome : n.carte,
                  borderRadius: Rayons.brMd,
                  border: Border.all(
                    color: entrees[i].alerte ? Colors.transparent : n.ligne,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entrees[i].libelle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: entrees[i].alerte
                            ? n.accentTexte
                            : n.encreDouce,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entrees[i].valeur,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color:
                              entrees[i].alerte ? n.accentTexte : n.encre,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

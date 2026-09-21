import 'package:flutter/material.dart';

import '../theme.dart';

/// Vocabulaire visuel « bento » : dégradés maillés, grands rayons, tuiles
/// claires et pastilles cerclées.
///
/// Trois règles tiennent l'ensemble :
///   1. une seule surface colorée par écran — c'est elle qui attire l'œil ;
///   2. tout le reste est clair, et ne se distingue que par son contenu ;
///   3. des rayons amples et beaucoup de vide, pour que chaque élément
///      respire au lieu de s'entasser.
///
/// Ce sont des formes, pas des données : rien ici n'invente de chiffre ni
/// de graphique que l'application ne mesure pas.

/// Rayon des grandes cartes, plus ample que [Rayons.xl].
const double rayonBento = 30.0;
const BorderRadius brBento = BorderRadius.all(Radius.circular(rayonBento));

/* -------------------------------------------------------------------------- */
/*  Dégradé maillé                                                            */
/* -------------------------------------------------------------------------- */

/// Peint plusieurs halos colorés qui se fondent les uns dans les autres.
///
/// Un `LinearGradient` donne une transition en ligne droite, vite monotone
/// sur une grande surface. Des halos radiaux superposés produisent ces
/// nuances irrégulières qu'on voit sur les interfaces récentes, sans image
/// à charger ni flou coûteux.
class _PeintreMaille extends CustomPainter {
  const _PeintreMaille({required this.halos, required this.base});

  /// Chaque halo : sa position relative (0–1), son rayon relatif, sa teinte.
  final List<({Offset centre, double rayon, Color teinte})> halos;
  final Color base;

  @override
  void paint(Canvas toile, Size taille) {
    toile.drawRect(Offset.zero & taille, Paint()..color = base);

    for (final h in halos) {
      final centre =
          Offset(h.centre.dx * taille.width, h.centre.dy * taille.height);
      final rayon = h.rayon * taille.longestSide;
      toile.drawCircle(
        centre,
        rayon,
        Paint()
          ..shader = RadialGradient(
            colors: [h.teinte, h.teinte.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: rayon)),
      );
    }
  }

  @override
  bool shouldRepaint(_PeintreMaille ancien) =>
      ancien.halos != halos || ancien.base != base;
}

/// Fond maillé clair, pour l'en-tête des écrans.
class FondMaille extends StatelessWidget {
  const FondMaille({super.key, required this.enfant, this.hauteur});

  final Widget enfant;
  final double? hauteur;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final halos = n.sombre
        ? const [
            (centre: Offset(0.02, 0.05), rayon: 0.70, teinte: Color(0x4DC9600F)),
            (centre: Offset(0.98, 0.00), rayon: 0.60, teinte: Color(0x3DB8860B)),
            (centre: Offset(0.60, 1.00), rayon: 0.55, teinte: Color(0x2E1E5A8A)),
          ]
        : const [
            (centre: Offset(0.02, 0.05), rayon: 0.75, teinte: Color(0xFFFFD9A8)),
            (centre: Offset(0.98, 0.00), rayon: 0.65, teinte: Color(0xFFFFE9A3)),
            (centre: Offset(0.78, 1.00), rayon: 0.55, teinte: Color(0xFFFFCB8E)),
            (centre: Offset(0.22, 1.00), rayon: 0.45, teinte: Color(0xFFDCE9F7)),
          ];

    return SizedBox(
      height: hauteur,
      child: CustomPaint(
        painter: _PeintreMaille(halos: halos, base: n.fond),
        child: enfant,
      ),
    );
  }
}

/// Grande carte au dégradé maillé profond, pour la seule surface colorée
/// d'un écran.
class CarteMaille extends StatelessWidget {
  const CarteMaille({
    super.key,
    required this.enfant,
    this.hauteur,
    this.onTap,
  });

  final Widget enfant;
  final double? hauteur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: brBento,
      child: InkWell(
        borderRadius: brBento,
        onTap: onTap,
        child: Container(
          height: hauteur,
          decoration: BoxDecoration(
            borderRadius: brBento,
            boxShadow: context.cl.ombreForte,
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: const _PeintreMaille(
              // Les halos clairs restent en haut, là où il n'y a qu'une
              // icône ; le bas conserve une teinte assez profonde pour que
              // le texte blanc s'y détache (3 de contraste au minimum).
              base: Color(0xFFC2560A),
              halos: [
                (centre: Offset(0.10, 0.00), rayon: 0.60, teinte: Color(0xFFF59B3C)),
                (centre: Offset(0.95, 0.05), rayon: 0.58, teinte: Color(0xFFFFB457)),
                (centre: Offset(0.92, 0.95), rayon: 0.55, teinte: Color(0xFFAE4A08)),
                (centre: Offset(0.05, 1.00), rayon: 0.55, teinte: Color(0xFF8E3C0E)),
              ],
            ),
            child: enfant,
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  Pastilles et boutons                                                      */
/* -------------------------------------------------------------------------- */

/// Icône fine cerclée d'un trait — le motif qui revient sur chaque tuile.
class PastilleIcone extends StatelessWidget {
  const PastilleIcone({
    super.key,
    required this.icone,
    this.taille = 38,
    this.teinte,
    this.surCouleur = false,
  });

  final IconData icone;
  final double taille;
  final Color? teinte;

  /// Posée sur une surface colorée : le trait passe en blanc translucide.
  final bool surCouleur;

  @override
  Widget build(BuildContext context) {
    final t = teinte ?? (surCouleur ? Colors.white : context.cl.encreDouce);
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: surCouleur ? Colors.white.withValues(alpha: 0.14) : null,
        border: Border.all(
          color: t.withValues(alpha: surCouleur ? 0.45 : 0.30),
          width: 1.2,
        ),
      ),
      child: Icon(icone, size: taille * 0.46, color: t),
    );
  }
}

/// Bouton rond à flèche.
class BoutonFleche extends StatelessWidget {
  const BoutonFleche({
    super.key,
    this.onTap,
    this.taille = 40,
    this.clair = true,
  });

  final VoidCallback? onTap;
  final double taille;

  /// Pastille blanche sur fond coloré, ou sombre sur fond clair.
  final bool clair;

  @override
  Widget build(BuildContext context) {
    final fond = clair ? Colors.white : context.cl.encre;
    final encre = clair ? context.cl.encre : Colors.white;
    return Material(
      color: fond,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: taille,
          height: taille,
          child: Icon(Icons.arrow_outward_rounded,
              size: taille * 0.42, color: encre),
        ),
      ),
    );
  }
}

/// Pastille d'argument : une icône, un mot.
class PuceArgument extends StatelessWidget {
  const PuceArgument({
    super.key,
    required this.icone,
    required this.texte,
    this.surCouleur = false,
  });

  final IconData icone;
  final String texte;
  final bool surCouleur;

  @override
  Widget build(BuildContext context) {
    final encre = surCouleur ? Colors.white : context.cl.accentTexte;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: surCouleur
            ? Colors.white.withValues(alpha: 0.18)
            : context.cl.orangeFantome,
        borderRadius: Rayons.brPilule,
        border: surCouleur
            ? Border.all(color: Colors.white.withValues(alpha: 0.30))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: encre),
          const SizedBox(width: 5),
          Text(
            texte,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: encre,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  Tuiles                                                                    */
/* -------------------------------------------------------------------------- */

/// Tuile d'un service : une icône cerclée, son nom, sa précision.
class TuileService extends StatelessWidget {
  const TuileService({
    super.key,
    required this.icone,
    required this.libelle,
    this.sousTitre,
    this.teinte,
    this.onTap,
    this.hauteur = 138,
  });

  final IconData icone;
  final String libelle;
  final String? sousTitre;
  final Color? teinte;
  final VoidCallback? onTap;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Material(
      color: n.carte,
      borderRadius: brBento,
      child: InkWell(
        borderRadius: brBento,
        onTap: onTap,
        child: Container(
          height: hauteur,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: brBento,
            border: Border.all(color: n.ligne),
            boxShadow: n.ombreDouce,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PastilleIcone(icone: icone, taille: 38, teinte: teinte),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded, size: 16, color: n.grise),
                ],
              ),
              const Spacer(),
              Text(
                libelle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: n.encre,
                ),
              ),
              if (sousTitre != null) ...[
                const SizedBox(height: 3),
                Text(
                  sousTitre!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: n.grise),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau large, pour un élément qui mérite toute la largeur.
class BandeauBento extends StatelessWidget {
  const BandeauBento({
    super.key,
    required this.icone,
    required this.titre,
    this.sousTitre,
    this.teinte,
    this.onTap,
  });

  final IconData icone;
  final String titre;
  final String? sousTitre;
  final Color? teinte;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Material(
      color: n.carte,
      borderRadius: brBento,
      child: InkWell(
        borderRadius: brBento,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: brBento,
            border: Border.all(color: n.ligne),
            boxShadow: n.ombreDouce,
          ),
          child: Row(
            children: [
              PastilleIcone(icone: icone, taille: 40, teinte: teinte),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: n.encre,
                      ),
                    ),
                    if (sousTitre != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sousTitre!,
                        style: TextStyle(fontSize: 11.5, color: n.grise),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              BoutonFleche(onTap: onTap, taille: 38, clair: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// Intitulé de section, avec une action facultative à droite.
class TitreSection extends StatelessWidget {
  const TitreSection({super.key, required this.texte, this.action});

  final String texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texte,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: context.cl.encre,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

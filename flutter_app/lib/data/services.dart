import 'package:flutter/material.dart';

import '../theme.dart';

/// Les 7 services de l'application, dans l'ordre des maquettes.
class Service {
  const Service({
    required this.id,
    required this.libelle,
    required this.route,
    required this.icone,
    this.sousTitre,
    this.accent = Palette.orange,
  });

  final String id;
  final String libelle;
  final String route;
  final String? sousTitre;

  /// Icône affichée dans la pastille de la carte.
  final IconData icone;

  /// Teinte de la pastille — alternance orange / bleu de la charte.
  final Color accent;

  /// Fond très clair dérivé de l'accent, pour la pastille.
  Color accentFantome(BuildContext context) => accent == Palette.orange
      ? context.cl.orangeFantome
      : context.cl.bleuFantome;
}

const services = <Service>[
  Service(
    id: 'conseil',
    libelle: 'Besoin de conseil fiscal',
    route: '/service/conseil-fiscal',
    icone: Icons.lightbulb_outline_rounded,
    accent: Palette.orange,
  ),
  Service(
    id: 'declarer',
    libelle: 'Déclarer et payer vos impôts',
    route: '/service/declarer',
    icone: Icons.receipt_long_outlined,
    accent: Palette.bleuFonce,
  ),
  Service(
    id: 'darp',
    libelle: 'DARP / IRPP',
    sousTitre: 'Déclaration annuelle des revenus des particuliers',
    route: '/service/darp',
    icone: Icons.person_search_outlined,
    accent: Palette.orange,
  ),
  Service(
    id: 'dsf',
    libelle: 'DSF',
    sousTitre: 'Déclaration statistique et fiscale',
    route: '/service/dsf',
    icone: Icons.insert_chart_outlined_rounded,
    accent: Palette.bleuFonce,
  ),
  Service(
    id: 'contentieux',
    libelle: 'Contentieux fiscal',
    route: '/service/contentieux',
    icone: Icons.gavel_rounded,
    accent: Palette.orange,
  ),
  Service(
    id: 'niu-acf',
    libelle: 'Acquérir son NIU / ACF',
    route: '/service/niu-acf',
    icone: Icons.badge_outlined,
    accent: Palette.bleuFonce,
  ),
  Service(
    id: 'audit',
    libelle: 'Faire un audit',
    route: '/service/audit',
    icone: Icons.fact_check_outlined,
    accent: Palette.orange,
  ),
];

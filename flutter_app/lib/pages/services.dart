import 'package:flutter/material.dart';

import '../data/services.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/coquille.dart';

/// Le catalogue complet, dans la même charte que l'accueil : bandeaux
/// larges, icônes cerclées, grands rayons.
class PageServices extends StatelessWidget {
  const PageServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Coquille(
      titre: 'CAM-TAXE',
      sousTitre: 'Nos ${services.length} services',
      routeCourante: '/services',
      retour: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/profil'),
        ),
      ],
      enfants: [
        const SizedBox(height: Espaces.xl),
        for (final s in services)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, 0, Espaces.bord, Espaces.md),
            child: BandeauBento(
              icone: s.icone,
              titre: s.libelle,
              sousTitre: s.sousTitre,
              teinte: s.accent == Palette.orange
                  ? context.cl.accentTexte
                  : context.cl.bleuTexte,
              onTap: () => Navigator.of(context).pushNamed(s.route),
            ),
          ),
        const SizedBox(height: Espaces.md),
      ],
    );
  }
}

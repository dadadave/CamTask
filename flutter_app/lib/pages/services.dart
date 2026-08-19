import 'package:flutter/material.dart';

import '../data/services.dart';
import '../theme.dart';
import '../widgets/coquille.dart';

class PageServices extends StatelessWidget {
  const PageServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Coquille(
      titre: 'CAM-TAXE',
      routeCourante: '/services',
      retour: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => Navigator.of(context).pushNamed('/profil'),
        ),
      ],
      enfants: [
        const SizedBox(height: 16),
        for (final s in services)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Material(
              color: Palette.carte,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).pushNamed(s.route),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Palette.orangeClair,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.libelle.toUpperCase(),
                              style: Textes.titreService,
                            ),
                            if (s.sousTitre != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                s.sousTitre!.toUpperCase(),
                                style: Textes.sousTitreService,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

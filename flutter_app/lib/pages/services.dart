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
            child: _CarteService(service: s),
          ),
      ],
    );
  }
}

class _CarteService extends StatelessWidget {
  const _CarteService({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cl.carte,
      borderRadius: Rayons.brLg,
      child: InkWell(
        borderRadius: Rayons.brLg,
        onTap: () => Navigator.of(context).pushNamed(service.route),
        child: Container(
          padding: const EdgeInsets.all(Espaces.lg),
          decoration: const BoxDecoration(
            borderRadius: Rayons.brLg,
            boxShadow: context.cl.ombreCarte,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: service.accentFantome(context),
                  borderRadius: Rayons.r(14),
                ),
                child: Icon(service.icone, size: 23, color: service.accent),
              ),
              const SizedBox(width: Espaces.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.libelle, style: Textes.titreService),
                    if (service.sousTitre != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        service.sousTitre!,
                        style: Textes.sousTitreService(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Espaces.sm),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: context.cl.grise),
            ],
          ),
        ),
      ),
    );
  }
}

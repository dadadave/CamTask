import 'package:flutter/material.dart';

import '../data/services.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/coquille.dart';

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key});

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final terme = _recherche.trim().toLowerCase();
    final resultats = terme.isEmpty
        ? services
        : services
            .where((s) => '${s.libelle} ${s.sousTitre ?? ''}'
                .toLowerCase()
                .contains(terme))
            .toList();

    return Coquille(
      routeCourante: '/accueil',
      enfants: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BoutonRond(
                icone: Icons.person_outline,
                onTap: () => Navigator.of(context).pushNamed('/profil'),
              ),
              const _BoutonRond(icone: Icons.notifications_none),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Palette.carte,
            borderRadius: BorderRadius.circular(999),
            boxShadow: ombreDouce,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: Palette.encreDouce),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un service…',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) => setState(() => _recherche = v),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 26, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Palette.carte,
            border: Border.all(color: Palette.orange, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'faites vos declaration chez nous',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '100% sur et rapide',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
          child: Text(
            etat.connecte
                ? 'Bonjour ${etat.compte!.prenom.isNotEmpty ? etat.compte!.prenom : etat.compte!.nom}'
                    .toUpperCase()
                : 'NOS SERVICES',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Palette.encreDouce,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.75,
            children: [
              for (final s in resultats)
                _Tuile(
                  libelle: s.libelle,
                  onTap: () => Navigator.of(context).pushNamed(s.route),
                ),
            ],
          ),
        ),
        if (resultats.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aucun service ne correspond à « $_recherche ».',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Palette.encreDouce,
              ),
            ),
          ),
      ],
    );
  }
}

class _BoutonRond extends StatelessWidget {
  const _BoutonRond({required this.icone, this.onTap});

  final IconData icone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: Palette.carte,
          shape: BoxShape.circle,
          boxShadow: ombreDouce,
        ),
        child: Icon(icone, size: 24, color: Palette.encre),
      ),
    );
  }
}

class _Tuile extends StatelessWidget {
  const _Tuile({required this.libelle, required this.onTap});

  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.carte,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Palette.orangeClair,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  libelle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

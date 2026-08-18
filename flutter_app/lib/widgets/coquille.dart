import 'package:flutter/material.dart';

import '../theme.dart';

/// Onglets de la navigation basse, dans l'ordre des maquettes.
const _onglets = <({String route, String libelle, IconData icone})>[
  (route: '/accueil', libelle: 'Accueil', icone: Icons.home_outlined),
  (route: '/services', libelle: 'service', icone: Icons.grid_view_outlined),
  (route: '/chat', libelle: 'chat', icone: Icons.chat_bubble_outline),
  (route: '/profil', libelle: 'Profil', icone: Icons.person_outline),
];

/// Navigation basse commune, bordée d'orange comme sur les maquettes.
class NavigationBasse extends StatelessWidget {
  const NavigationBasse({super.key, required this.routeCourante});

  final String routeCourante;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.carte,
        border: Border(top: BorderSide(color: Palette.orange, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final o in _onglets)
                Expanded(
                  child: _Onglet(
                    libelle: o.libelle,
                    icone: o.icone,
                    actif: o.route == routeCourante,
                    onTap: () {
                      if (o.route == routeCourante) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        o.route,
                        (r) => false,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({
    required this.libelle,
    required this.icone,
    required this.actif,
    required this.onTap,
  });

  final String libelle;
  final IconData icone;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? Palette.orange : Palette.encre;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 22, color: couleur),
          const SizedBox(height: 3),
          Text(
            libelle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}

/// Coquille d'écran : barre supérieure orange facultative, contenu
/// défilant et navigation basse.
class Coquille extends StatelessWidget {
  const Coquille({
    super.key,
    required this.enfants,
    this.titre,
    this.routeCourante = '',
    this.actions,
    this.retour = true,
    this.navigation = true,
  });

  final List<Widget> enfants;
  final String? titre;
  final String routeCourante;
  final List<Widget>? actions;
  final bool retour;
  final bool navigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: titre == null
          ? null
          : AppBar(
              title: Text(titre!),
              automaticallyImplyLeading: retour,
              actions: actions,
            ),
      body: SafeArea(
        top: titre == null,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: enfants,
        ),
      ),
      bottomNavigationBar:
          navigation ? NavigationBasse(routeCourante: routeCourante) : null,
    );
  }
}

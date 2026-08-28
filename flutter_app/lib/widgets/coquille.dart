import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';

typedef _Onglets = ({String route, String libelle, IconData icone, IconData plein});

/// Onglets du client, dans l'ordre des maquettes.
const _ongletsClient = <_Onglets>[
  (
    route: '/accueil',
    libelle: 'Accueil',
    icone: Icons.home_outlined,
    plein: Icons.home_rounded
  ),
  (
    route: '/services',
    libelle: 'Services',
    icone: Icons.grid_view_outlined,
    plein: Icons.grid_view_rounded
  ),
  (
    route: '/chat',
    libelle: 'Chat',
    icone: Icons.chat_bubble_outline_rounded,
    plein: Icons.chat_bubble_rounded
  ),
  (
    route: '/profil',
    libelle: 'Profil',
    icone: Icons.person_outline_rounded,
    plein: Icons.person_rounded
  ),
];

/// Onglets d'un administrateur qui n'est pas conseiller : il ne gère que
/// les habilitations, il n'a ni dossiers ni conversations à traiter.
const _ongletsAdmin = <_Onglets>[
  (
    route: '/admin/equipe',
    libelle: 'Équipe',
    icone: Icons.groups_outlined,
    plein: Icons.groups_rounded
  ),
  (
    route: '/profil',
    libelle: 'Profil',
    icone: Icons.person_outline_rounded,
    plein: Icons.person_rounded
  ),
];

/// Onglets du conseiller.
///
/// Pas d'« Accueil » ni de « Services » ici : ces écrans servent à déposer
/// une demande en tant que client, ce qu'un conseiller n'a pas à faire
/// depuis son poste.
const _ongletsAgent = <_Onglets>[
  (
    route: '/agent/dossiers',
    libelle: 'Dossiers',
    icone: Icons.folder_outlined,
    plein: Icons.folder_rounded
  ),
  (
    route: '/agent/conversations',
    libelle: 'Messages',
    icone: Icons.forum_outlined,
    plein: Icons.forum_rounded
  ),
  (
    route: '/profil',
    libelle: 'Profil',
    icone: Icons.person_outline_rounded,
    plein: Icons.person_rounded
  ),
];

/// Navigation basse : barre blanche surélevée, onglet actif marqué par une
/// pastille orange animée.
class NavigationBasse extends StatelessWidget {
  const NavigationBasse({super.key, required this.routeCourante});

  final String routeCourante;

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final onglets = etat.estAgent
        ? _ongletsAgent
        : etat.estAdmin
            ? _ongletsAdmin
            : _ongletsClient;

    return Container(
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(Rayons.xl)),
        border: Border(top: BorderSide(color: context.cl.ligne)),
        boxShadow: context.cl.ombreForte,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final o in onglets)
                Expanded(
                  child: _Onglet(
                    libelle: o.libelle,
                    icone: o.icone,
                    iconePleine: o.plein,
                    actif: o.route == routeCourante,
                    onTap: () {
                      if (o.route == routeCourante) return;
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil(o.route, (r) => false);
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
    required this.iconePleine,
    required this.actif,
    required this.onTap,
  });

  final String libelle;
  final IconData icone;
  final IconData iconePleine;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? Palette.orange : context.cl.grise;

    return InkWell(
      onTap: onTap,
      borderRadius: Rayons.brMd,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            decoration: BoxDecoration(
              color: actif ? context.cl.orangeFantome : Colors.transparent,
              borderRadius: Rayons.brPilule,
            ),
            child: Icon(actif ? iconePleine : icone, size: 22, color: couleur),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
              color: couleur,
            ),
            child: Text(libelle),
          ),
        ],
      ),
    );
  }
}

/// Barre supérieure en dégradé orange, arrondie en bas.
class BarreDegrade extends StatelessWidget implements PreferredSizeWidget {
  const BarreDegrade({
    super.key,
    required this.titre,
    this.sousTitre,
    this.actions,
    this.retour = true,
  });

  final String titre;
  final String? sousTitre;
  final List<Widget>? actions;
  final bool retour;

  @override
  Size get preferredSize => Size.fromHeight(sousTitre == null ? 64 : 82);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: Degrades.orangeVif,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(Rayons.xl)),
      ),
      child: AppBar(
        title: sousTitre == null
            ? Text(titre)
            : Column(
                children: [
                  Text(titre),
                  const SizedBox(height: 2),
                  Text(
                    sousTitre!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
        toolbarHeight: preferredSize.height,
        automaticallyImplyLeading: false,
        leading: retour && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: actions,
      ),
    );
  }
}

/// Coquille d'écran : barre supérieure facultative, contenu défilant et
/// navigation basse.
class Coquille extends StatelessWidget {
  const Coquille({
    super.key,
    required this.enfants,
    this.titre,
    this.sousTitre,
    this.routeCourante = '',
    this.actions,
    this.retour = true,
    this.navigation = true,
  });

  final List<Widget> enfants;
  final String? titre;
  final String? sousTitre;
  final String routeCourante;
  final List<Widget>? actions;
  final bool retour;
  final bool navigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: titre == null
          ? null
          : BarreDegrade(
              titre: titre!,
              sousTitre: sousTitre,
              actions: actions,
              retour: retour,
            ),
      body: SafeArea(
        top: titre == null,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 28),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: enfants,
        ),
      ),
      bottomNavigationBar:
          navigation ? NavigationBasse(routeCourante: routeCourante) : null,
    );
  }
}

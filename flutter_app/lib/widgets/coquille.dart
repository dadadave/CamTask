import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'bento.dart';

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
    route: '/admin/paiements',
    libelle: 'Paiements',
    icone: Icons.receipt_long_outlined,
    plein: Icons.receipt_long_rounded
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

/// Navigation basse : une pilule flottante, détachée du bord.
///
/// L'onglet actif s'étend en pastille pleine et montre son libellé ; les
/// autres restent de simples icônes. On gagne en clarté — un seul mot à
/// lire au lieu de quatre — et la barre pèse moins dans l'écran.
class NavigationBasse extends StatelessWidget {
  const NavigationBasse({super.key, required this.routeCourante});

  final String routeCourante;

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final n = context.cl;
    final onglets = etat.estAgent
        ? _ongletsAgent
        : etat.estAdmin
            ? _ongletsAdmin
            : _ongletsClient;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaces.bord, 0, Espaces.bord, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(
            color: n.carte,
            borderRadius: Rayons.brPilule,
            border: Border.all(color: n.ligne),
            boxShadow: n.ombreForte,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final o in onglets)
                // L'onglet actif porte son libellé : il lui faut plus de
                // place que les autres, qui ne montrent qu'une icône.
                Flexible(
                  flex: o.route == routeCourante ? 3 : 1,
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
    final n = context.cl;
    final couleur = actif ? n.accentTexte : n.encreDouce;

    return Material(
      color: Colors.transparent,
      borderRadius: Rayons.brPilule,
      // Le libellé disparaît à l'écran quand l'onglet est inactif : il doit
      // rester annoncé, sans quoi la barre devient muette pour qui navigue
      // au lecteur d'écran.
      child: Semantics(
        label: libelle,
        selected: actif,
        button: true,
        child: InkWell(
          borderRadius: Rayons.brPilule,
          onTap: onTap,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: actif ? 14 : 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: actif ? n.orangeFantome : Colors.transparent,
            borderRadius: Rayons.brPilule,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(actif ? iconePleine : icone, size: 21, color: couleur),
              // Le libellé n'apparaît que sur l'onglet actif : ailleurs il
              // n'apprend rien et encombre.
              if (actif) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    libelle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: couleur,
                    ),
                  ),
                ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre supérieure : le même fond maillé que l'accueil, titre à gauche.
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
  Size get preferredSize => Size.fromHeight(sousTitre == null ? 74 : 92);

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final peutRevenir = retour && Navigator.of(context).canPop();

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(rayonBento)),
      child: AppBar(
        // Le fond maillé de l'accueil, repris ici : un seul endroit à
        // changer pour que tous les écrans se ressemblent.
        flexibleSpace: const FondMaille(enfant: SizedBox.expand()),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: peutRevenir ? 4 : Espaces.bord,
        toolbarHeight: preferredSize.height,
        // Le fond est clair : l'encre et les icônes de la barre d'état
        // doivent l'être aussi, sans quoi plus rien ne se lit.
        foregroundColor: n.encre,
        systemOverlayStyle:
            n.sombre ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: n.encre, size: 22),
        actionsIconTheme: IconThemeData(color: n.encre, size: 22),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titre,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
                color: n.encre,
              ),
            ),
            if (sousTitre != null) ...[
              const SizedBox(height: 3),
              Text(
                sousTitre!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: n.encreDouce,
                ),
              ),
            ],
          ],
        ),
        automaticallyImplyLeading: false,
        leading: peutRevenir
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

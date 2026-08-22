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

    final prenom = etat.connecte
        ? (etat.compte!.prenom.isNotEmpty
            ? etat.compte!.prenom
            : etat.compte!.nom)
        : null;

    return Scaffold(
      // L'en-tête en dégradé remonte sous la barre d'état.
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _EnTeteAccueil(
            prenom: prenom,
            onRecherche: (v) => setState(() => _recherche = v),
          ),
          const SizedBox(height: Espaces.xl),

          if (terme.isEmpty) ...[
            const _CarteAccroche(),
            const SizedBox(height: Espaces.xxl),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(Espaces.bord, 0, Espaces.bord, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  terme.isEmpty
                      ? 'Nos services'
                      : '${resultats.length} résultat'
                          '${resultats.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (terme.isEmpty)
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/services', (r) => false),
                    child: const Text('Tout voir'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Espaces.md),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Espaces.bord),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Espaces.md,
              crossAxisSpacing: Espaces.md,
              childAspectRatio: 1.05,
              children: [
                for (final s in resultats)
                  _Tuile(
                    service: s,
                    onTap: () => Navigator.of(context).pushNamed(s.route),
                  ),
              ],
            ),
          ),

          if (resultats.isEmpty) const _AucunResultat(),
        ],
      ),
      bottomNavigationBar: const NavigationBasse(routeCourante: '/accueil'),
    );
  }
}

/// En-tête orange arrondi : salutation, actions et barre de recherche.
class _EnTeteAccueil extends StatelessWidget {
  const _EnTeteAccueil({required this.prenom, required this.onRecherche});

  final String? prenom;
  final ValueChanged<String> onRecherche;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: Degrades.orange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(Rayons.xl)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Espaces.bord, Espaces.md, Espaces.bord, Espaces.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prenom == null ? 'Bienvenue' : 'Bonjour,',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prenom ?? 'CAM-TAXE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Textes.titreEcran,
                        ),
                      ],
                    ),
                  ),
                  _BoutonRond(
                    icone: Icons.notifications_none_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(width: Espaces.sm),
                  _BoutonRond(
                    icone: Icons.person_outline_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/profil'),
                  ),
                ],
              ),
              const SizedBox(height: Espaces.xl),
              _BarreRecherche(onChange: onRecherche),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarreRecherche extends StatelessWidget {
  const _BarreRecherche({required this.onChange});

  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: Espaces.lg),
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius: Rayons.brPilule,
        boxShadow: context.cl.ombreDouce,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: context.cl.grise),
          const SizedBox(width: Espaces.md),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un service…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              onChanged: onChange,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'accroche sous l'en-tête.
class _CarteAccroche extends StatelessWidget {
  const _CarteAccroche();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Espaces.bord),
      padding: const EdgeInsets.all(Espaces.xl),
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius: Rayons.brXl,
        boxShadow: context.cl.ombreCarte,
        border: Border.all(color: context.cl.ligne),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faites vos déclarations chez nous',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: Espaces.md),
                Row(
                  children: [
                    _Puce(icone: Icons.verified_rounded, texte: '100 % sûr'),
                    SizedBox(width: Espaces.sm),
                    _Puce(icone: Icons.bolt_rounded, texte: 'Rapide'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Espaces.md),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: Degrades.orange,
              borderRadius: Rayons.brMd,
              boxShadow: ombreOrange,
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _Puce extends StatelessWidget {
  const _Puce({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cl.orangeFantome,
        borderRadius: Rayons.brPilule,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: Palette.orange),
          const SizedBox(width: 5),
          Text(
            texte,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Palette.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  const _BoutonRond({required this.icone, this.onTap});

  final IconData icone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icone, size: 21, color: Colors.white),
        ),
      ),
    );
  }
}

/// Tuile de service : icône teintée, libellé, flèche.
class _Tuile extends StatelessWidget {
  const _Tuile({required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cl.carte,
      borderRadius: Rayons.brLg,
      child: InkWell(
        borderRadius: Rayons.brLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(Espaces.lg),
          decoration: BoxDecoration(
            borderRadius: Rayons.brLg,
            boxShadow: context.cl.ombreCarte,
            border: Border.all(color: context.cl.ligne),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: service.accentFantome(context),
                  borderRadius: Rayons.r(14),
                ),
                child: Icon(service.icone, size: 22, color: service.accent),
              ),
              const Spacer(),
              Text(
                service.libelle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AucunResultat extends StatelessWidget {
  const _AucunResultat();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Espaces.bord, vertical: Espaces.xxl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.cl.orangeFantome,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 30, color: Palette.orange),
          ),
          const SizedBox(height: Espaces.lg),
          const Text(
            'Aucun service ne correspond',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'Essayez un autre mot-clé.',
            style: TextStyle(fontSize: 13, color: context.cl.encreDouce),
          ),
        ],
      ),
    );
  }
}

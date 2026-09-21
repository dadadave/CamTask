import 'package:flutter/material.dart';

import '../data/services.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/coquille.dart';

/// L'accueil : l'accroche de l'agence, puis les 7 services.
///
/// La présentation a été reprise dans un style « bento » — dégradé maillé,
/// grands rayons, tuiles claires — mais l'écran dit toujours la même chose
/// et dans le même ordre : ce que nous promettons, puis ce que nous savons
/// faire.
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
        : [
            for (final s in services)
              if ('${s.libelle} ${s.sousTitre ?? ''}'
                  .toLowerCase()
                  .contains(terme))
                s,
          ];

    return Scaffold(
      backgroundColor: context.cl.fond,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _EnTete(
            compte: etat.compte,
            onRecherche: (v) => setState(() => _recherche = v),
          ),
          const SizedBox(height: Espaces.xl),
          if (terme.isEmpty) ...[
            const _Accroche(),
            const SizedBox(height: Espaces.xxl),
          ],
          _Catalogue(resultats: resultats, terme: terme),
        ],
      ),
      bottomNavigationBar: const NavigationBasse(routeCourante: '/accueil'),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  En-tête                                                                   */
/* -------------------------------------------------------------------------- */

class _EnTete extends StatelessWidget {
  const _EnTete({required this.compte, required this.onRecherche});

  final Compte? compte;
  final ValueChanged<String> onRecherche;

  String get _salutation {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final c = compte;
    final prenom =
        c == null ? null : (c.prenom.isNotEmpty ? c.prenom : c.nom);

    return FondMaille(
      enfant: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Espaces.bord, Espaces.lg, Espaces.bord, Espaces.xxl),
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
                          prenom == null
                              ? _salutation
                              : '$_salutation, $prenom',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: context.cl.encreDouce,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Mon Comptable',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.1,
                            color: context.cl.encre,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Espaces.md),
                  _Avatar(compte: c),
                ],
              ),
              const SizedBox(height: Espaces.xl),
              _Recherche(onChange: onRecherche),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.compte});

  final Compte? compte;

  @override
  Widget build(BuildContext context) {
    final c = compte;
    return Material(
      color: c == null ? context.cl.carte : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            Navigator.of(context).pushNamed(c == null ? '/auth' : '/profil'),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: c == null ? null : Degrades.orange,
            border: c == null ? Border.all(color: context.cl.ligne) : null,
            boxShadow: c == null ? null : ombreOrange,
          ),
          child: c == null
              ? Icon(Icons.person_outline_rounded,
                  size: 21, color: context.cl.encreDouce)
              : Text(
                  c.initiales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Recherche extends StatelessWidget {
  const _Recherche({required this.onChange});

  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: n.carte,
        borderRadius: Rayons.brPilule,
        border: Border.all(color: n.ligne),
        boxShadow: n.ombreDouce,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: n.grise),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              // `filled: false` est indispensable : le thème global remplit
              // et borde tous les champs, ce qui dessinait ici une seconde
              // boîte grise à l'intérieur de la pilule blanche.
              decoration: InputDecoration(
                hintText: 'Rechercher un service',
                hintStyle: TextStyle(fontSize: 13.5, color: n.grise),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              style: const TextStyle(fontSize: 13.5),
              onChanged: onChange,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  L'accroche                                                                */
/* -------------------------------------------------------------------------- */

/// La promesse de l'agence, telle qu'elle figure sur les maquettes.
///
/// C'est la première chose que lit un visiteur : elle garde sa place, ses
/// mots et ses deux arguments. Seule sa présentation a changé.
class _Accroche extends StatelessWidget {
  const _Accroche();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Espaces.bord),
      child: CarteMaille(
        hauteur: 178,
        enfant: Padding(
          padding: EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PastilleIcone(
                      icone: Icons.shield_outlined, surCouleur: true),
                  Spacer(),
                ],
              ),
              Spacer(),
              Text(
                'Faites vos déclarations chez nous',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: Espaces.md),
              Row(
                children: [
                  PuceArgument(
                      icone: Icons.verified_rounded,
                      texte: '100 % sûr',
                      surCouleur: true),
                  SizedBox(width: Espaces.sm),
                  PuceArgument(
                      icone: Icons.bolt_rounded,
                      texte: 'Rapide',
                      surCouleur: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*  Catalogue des services                                                    */
/* -------------------------------------------------------------------------- */

class _Catalogue extends StatelessWidget {
  const _Catalogue({required this.resultats, required this.terme});

  final List<Service> resultats;
  final String terme;

  @override
  Widget build(BuildContext context) {
    if (resultats.isEmpty) return const _AucunResultat();

    // Le dernier service prend toute la largeur quand le compte est impair :
    // ce déséquilibre assumé donne son allure à une grille bento, et il
    // évite la tuile orpheline de l'ancienne disposition.
    final impair = resultats.length.isOdd;
    final grille =
        impair ? resultats.sublist(0, resultats.length - 1) : resultats;
    final dernier = impair ? resultats.last : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Espaces.bord),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitreSection(
            texte: terme.isEmpty
                ? 'Nos services'
                : '${resultats.length} résultat'
                    '${resultats.length > 1 ? 's' : ''}',
            action: terme.isEmpty
                ? TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/services', (r) => false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child:
                        const Text('Tout voir', style: TextStyle(fontSize: 13)),
                  )
                : null,
          ),
          for (var i = 0; i < grille.length; i += 2) ...[
            if (i > 0) const SizedBox(height: Espaces.md),
            Row(
              children: [
                Expanded(child: _tuile(context, grille[i])),
                const SizedBox(width: Espaces.md),
                Expanded(child: _tuile(context, grille[i + 1])),
              ],
            ),
          ],
          if (dernier != null) ...[
            const SizedBox(height: Espaces.md),
            BandeauBento(
              icone: dernier.icone,
              titre: dernier.libelle,
              sousTitre: dernier.sousTitre,
              onTap: () => Navigator.of(context).pushNamed(dernier.route),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tuile(BuildContext context, Service s) => TuileService(
        icone: s.icone,
        libelle: s.libelle,
        sousTitre: s.sousTitre,
        teinte: s.accent == Palette.orange
            ? context.cl.accentTexte
            : context.cl.bleuTexte,
        onTap: () => Navigator.of(context).pushNamed(s.route),
      );
}

class _AucunResultat extends StatelessWidget {
  const _AucunResultat();

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.xxl, Espaces.bord, Espaces.xxl),
      child: Column(
        children: [
          const PastilleIcone(icone: Icons.search_off_rounded, taille: 56),
          const SizedBox(height: Espaces.lg),
          Text(
            'Aucun service ne correspond',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: n.encre,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Essayez « DSF », « audit » ou « NIU ».',
            style: TextStyle(fontSize: 13, color: n.encreDouce),
          ),
        ],
      ),
    );
  }
}

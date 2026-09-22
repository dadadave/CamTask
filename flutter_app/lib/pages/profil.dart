import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

/// Le profil : qui l'on est, et par où l'on entre.
///
/// Il ne déroule plus les demandes et les factures. Elles s'accumulent sans
/// fin, et passé quelques envois elles noyaient les coordonnées, le réglage
/// d'apparence et la déconnexion sous des dizaines de cartes. Chacune a
/// désormais son écran ; le profil n'en garde que l'entrée et le compte.
class PageProfil extends StatefulWidget {
  const PageProfil({super.key});

  @override
  State<PageProfil> createState() => _PageProfilState();
}

class _PageProfilState extends State<PageProfil> {
  List<Facture> _factures = const [];

  @override
  void initState() {
    super.initState();
    // Les compteurs des deux entrées se lisent ici : sans cette relecture,
    // une facture émise entre-temps n'apparaîtrait pas.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rafraichir());
  }

  Future<void> _rafraichir() async {
    if (!mounted) return;
    final etat = PorteeApp.of(context);
    await etat.rafraichirDemandes();
    if (!mounted || !etat.connecte) return;
    try {
      final f = await etat.mesFactures();
      if (mounted) setState(() => _factures = f);
    } on ErreurBackend {
      // Un profil qui s'affiche sans le compte de ses factures reste
      // utile : on ne bloque pas l'écran entier pour ça.
    }
  }

  /// Ouvre un écran, puis relit les compteurs à son retour — le statut d'un
  /// dossier ou d'une facture a pu changer pendant la visite.
  Future<void> _ouvrir(String route) async {
    await Navigator.of(context).pushNamed(route);
    await _rafraichir();
  }

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final compte = etat.compte;

    if (compte == null) return _deconnecte(context);

    final estEmploye = compte.role == Role.employe;
    final aRegler = _factures.where((f) => f.aPayer).length;

    return Coquille(
      titre: 'Profil',
      routeCourante: '/profil',
      retour: false,
      enfants: [
        // ── Carte d'identité ──────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(
              Espaces.bord, Espaces.xl, Espaces.bord, Espaces.lg),
          padding: const EdgeInsets.all(Espaces.xl),
          decoration: BoxDecoration(
            color: context.cl.carte,
            borderRadius: Rayons.brXl,
            boxShadow: context.cl.ombreCarte,
            border: Border.all(color: context.cl.ligne),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: Degrades.orange,
                  shape: BoxShape.circle,
                  boxShadow: ombreOrange,
                ),
                child: Text(
                  compte.initiales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: Espaces.md),
              Text(
                '${compte.prenom} ${compte.nom}'.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: Espaces.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: estEmploye
                      ? context.cl.bleuFantome
                      : context.cl.orangeFantome,
                  borderRadius: Rayons.brPilule,
                ),
                child: Text(
                  estEmploye ? 'Personne employée' : 'Utilisateur',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: estEmploye
                        ? context.cl.bleuTexte
                        : context.cl.accentTexte,
                  ),
                ),
              ),
              const SizedBox(height: Espaces.sm),
              Text(
                'Membre depuis le ${compte.creeLe}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.cl.grise,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ── Mes dossiers ──────────────────────────────────────────────
        //  Deux entrées, et rien de plus : le profil garde la même hauteur
        //  qu'on ait deux demandes ou deux cents.
        const LibelleSection(texte: 'Mes dossiers'),
        const SizedBox(height: Espaces.sm),
        LigneDossier(
          icone: Icons.folder_outlined,
          libelle: 'Mes demandes',
          detail: _detailDemandes(etat.demandes),
          compteur: etat.demandes.length,
          onTap: () => _ouvrir('/mes-demandes'),
        ),
        LigneDossier(
          icone: Icons.receipt_long_outlined,
          libelle: 'Mes factures',
          detail: aRegler == 0
              ? (_factures.isEmpty ? 'Aucune facture' : 'Tout est réglé')
              : '$aRegler à régler',
          compteur: _factures.length,
          alerte: aRegler > 0,
          onTap: () => _ouvrir('/mes-factures'),
        ),

        // ── Coordonnées ───────────────────────────────────────────────
        const LibelleSection(texte: 'Coordonnées'),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Espaces.bord, Espaces.sm, Espaces.bord, 0),
          child: Container(
            decoration: BoxDecoration(
              color: context.cl.carte,
              borderRadius: Rayons.brLg,
              boxShadow: context.cl.ombreCarte,
              border: Border.all(color: context.cl.ligne),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _Ligne(
                  icone: Icons.mail_outline_rounded,
                  libelle: 'Email',
                  valeur: compte.email,
                ),
                _Ligne(
                  icone: Icons.phone_outlined,
                  libelle: 'Téléphone',
                  valeur: compte.telephone,
                ),
                _Ligne(
                  icone: Icons.badge_outlined,
                  libelle: estEmploye ? 'N° contribuable' : 'NIU',
                  valeur: compte.niu,
                ),
                _Ligne(
                  icone: Icons.folder_outlined,
                  libelle: 'Pièces fournies',
                  valeur: '${compte.pieces.length}',
                  derniere: true,
                ),
              ],
            ),
          ),
        ),

        // ── Apparence ─────────────────────────────────────────────────
        const LibelleSection(texte: 'Apparence'),
        const SizedBox(height: Espaces.sm),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Espaces.bord),
          child: SelecteurTheme(),
        ),

        // ── Administration ────────────────────────────────────────────
        //  On ne nomme un conseiller qu'occasionnellement : ces entrées
        //  n'ont pas leur place dans la barre du bas, où elles prendraient
        //  celle d'un écran ouvert tous les jours.
        if (etat.estAdmin) ...[
          const LibelleSection(texte: 'Administration'),
          const SizedBox(height: Espaces.sm),
          LigneDossier(
            icone: Icons.groups_outlined,
            libelle: 'Gérer les conseillers',
            onTap: () => _ouvrir('/admin/equipe'),
          ),
          LigneDossier(
            icone: Icons.receipt_long_outlined,
            libelle: 'Paiements et tarifs',
            onTap: () => _ouvrir('/admin/paiements'),
          ),
        ],

        // ── Déconnexion ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Espaces.bord, Espaces.xxl, Espaces.bord, Espaces.xl),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.orange,
              side: const BorderSide(color: Palette.orange, width: 1.4),
            ),
            onPressed: () async {
              // On attend la fin de la déconnexion : sans cela l'écran
              // suivant s'afficherait avec une session encore ouverte.
              final navigateur = Navigator.of(context);
              await etat.seDeconnecter();
              navigateur.pushNamedAndRemoveUntil('/auth', (r) => false);
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Se déconnecter'),
          ),
        ),
      ],
    );
  }

  /// Ce qui se lit sous « Mes demandes », sans avoir à ouvrir l'écran.
  static String _detailDemandes(List<Demande> demandes) {
    if (demandes.isEmpty) return 'Aucune demande envoyée';
    final traitees = demandes.where((d) => d.statut == 'Traitée').length;
    if (traitees == demandes.length) return 'Toutes traitées';
    return '${demandes.length - traitees} en cours';
  }

  Widget _deconnecte(BuildContext context) {
    return Coquille(
      titre: 'Profil',
      routeCourante: '/profil',
      retour: false,
      enfants: [
        Container(
          margin: const EdgeInsets.all(Espaces.xl),
          padding: const EdgeInsets.all(Espaces.xxl),
          decoration: BoxDecoration(
            color: context.cl.carte,
            borderRadius: Rayons.brXl,
            boxShadow: context.cl.ombreCarte,
            border: Border.all(color: context.cl.ligne),
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: context.cl.orangeFantome,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded,
                    size: 32, color: Palette.orange),
              ),
              const SizedBox(height: Espaces.xl),
              const Text(
                "Vous n'êtes pas connecté",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: Espaces.sm),
              Text(
                'Il faut au préalable créer un compte pour bénéficier de nos '
                'services et suivre vos demandes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: context.cl.encreDouce,
                ),
              ),
              const SizedBox(height: Espaces.xl),
              BoutonEnvoyer(
                bloc: true,
                libelle: 'Créer un compte',
                icone: Icons.arrow_forward_rounded,
                onTap: () => Navigator.of(context).pushNamed('/auth'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.icone,
    required this.libelle,
    required this.valeur,
    this.derniere = false,
  });

  final IconData icone;
  final String libelle;
  final String valeur;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Espaces.lg, vertical: Espaces.lg),
      decoration: derniere
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: context.cl.fondDoux)),
            ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.cl.fondDoux,
              borderRadius: Rayons.r(10),
            ),
            child: Icon(icone, size: 17, color: context.cl.encreDouce),
          ),
          const SizedBox(width: Espaces.md),
          Expanded(
            child: Text(
              libelle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.cl.encreDouce,
              ),
            ),
          ),
          const SizedBox(width: Espaces.md),
          Flexible(
            child: Text(
              valeur.isEmpty ? '—' : valeur,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

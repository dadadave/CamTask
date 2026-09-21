import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';
import '../widgets/document.dart';

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
    // Le statut d'un dossier est décidé par nos services, pas par le client :
    // sans cette relecture, un passage en « Traitée » ne se verrait jamais.
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
      // Un profil qui s'affiche sans ses factures reste utile : on ne
      // bloque pas l'écran entier pour ça.
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final compte = etat.compte;

    if (compte == null) {
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

    final estEmploye = compte.role == Role.employe;

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

        // ── Coordonnées ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(Espaces.bord, 0, Espaces.bord, 0),
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
        const Padding(
          padding: EdgeInsets.fromLTRB(
              Espaces.bord, Espaces.xxl, Espaces.bord, Espaces.md),
          child: Text(
            'Apparence',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Espaces.bord),
          child: SelecteurTheme(),
        ),

        // ── Demandes ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Espaces.bord, Espaces.xxl, Espaces.bord, Espaces.md),
          child: Row(
            children: [
              const Text(
                'Mes demandes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: Espaces.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: context.cl.orangeFantome,
                  borderRadius: Rayons.brPilule,
                ),
                child: Text(
                  '${etat.demandes.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Palette.orange,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (etat.demandes.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Espaces.bord),
            padding: const EdgeInsets.all(Espaces.xxl),
            decoration: BoxDecoration(
              color: context.cl.carte,
              borderRadius: Rayons.brLg,
              boxShadow: context.cl.ombreDouce,
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 34, color: context.cl.grise),
                const SizedBox(height: Espaces.md),
                const Text(
                  "Aucune demande pour l'instant",
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  'Rendez-vous dans « Services » pour en créer une.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: context.cl.encreDouce,
                  ),
                ),
              ],
            ),
          )
        else
          for (final d in etat.demandes) _CarteDemande(demande: d),

        // ── Équipe (administrateurs seulement) ────────────────────────
        //  On ne nomme un conseiller qu'occasionnellement : cette entrée n'a
        //  pas sa place dans la barre du bas, où elle prendrait la place
        //  d'un écran ouvert tous les jours.
        if (etat.estAdmin) ...[
          const LibelleSection(texte: 'Équipe'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.sm, Espaces.bord, 0),
            child: Material(
              color: context.cl.carte,
              borderRadius: Rayons.brLg,
              child: InkWell(
                borderRadius: Rayons.brLg,
                onTap: () =>
                    Navigator.of(context).pushNamed('/admin/equipe'),
                child: Container(
                  padding: const EdgeInsets.all(Espaces.lg),
                  decoration: BoxDecoration(
                    borderRadius: Rayons.brLg,
                    border: Border.all(color: context.cl.ligne),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.cl.orangeFantome,
                          borderRadius: Rayons.r(10),
                        ),
                        child: const Icon(Icons.groups_outlined,
                            size: 19, color: Palette.orange),
                      ),
                      const SizedBox(width: Espaces.md),
                      const Expanded(
                        child: Text(
                          'Gérer les conseillers',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: context.cl.grise),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.sm, Espaces.bord, 0),
            child: Material(
              color: context.cl.carte,
              borderRadius: Rayons.brLg,
              child: InkWell(
                borderRadius: Rayons.brLg,
                onTap: () =>
                    Navigator.of(context).pushNamed('/admin/paiements'),
                child: Container(
                  padding: const EdgeInsets.all(Espaces.lg),
                  decoration: BoxDecoration(
                    borderRadius: Rayons.brLg,
                    border: Border.all(color: context.cl.ligne),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.cl.orangeFantome,
                          borderRadius: Rayons.r(10),
                        ),
                        child: Icon(Icons.receipt_long_outlined,
                            size: 19, color: context.cl.accentTexte),
                      ),
                      const SizedBox(width: Espaces.md),
                      const Expanded(
                        child: Text(
                          'Paiements et tarifs',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: context.cl.grise),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // ── Factures ──────────────────────────────────────────────────
        if (_factures.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.xxl, Espaces.bord, Espaces.md),
            child: Text(
              'Mes factures',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          for (final f in _factures)
            _CarteFacture(facture: f, surRetour: _rafraichir),
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

class _CarteDemande extends StatelessWidget {
  const _CarteDemande({required this.demande});

  final Demande demande;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          Espaces.bord, 0, Espaces.bord, Espaces.md),
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius: Rayons.brLg,
        boxShadow: context.cl.ombreCarte,
        border: Border.all(color: context.cl.ligne),
      ),
      clipBehavior: Clip.antiAlias,
      // IntrinsicHeight : le liseré gauche doit courir sur toute la hauteur
      // de la carte, or un Row "stretch" en hauteur libre force l'infini.
      child: IntrinsicHeight(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: _accent(demande.statut)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Espaces.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          demande.serviceLibelle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: Espaces.sm),
                      Text(
                        demande.date,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.cl.grise,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    demande.resume,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: context.cl.encreDouce,
                    ),
                  ),
                  // Ce que le client a envoyé : il sait déjà ce que c'est,
                  // un rappel en une ligne suffit.
                  if (demande.piecesClient.isNotEmpty) ...[
                    const SizedBox(height: Espaces.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.attach_file_rounded,
                            size: 13, color: context.cl.grise),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${demande.piecesClient.length} document(s) '
                            'envoyé(s) : '
                            '${demande.piecesClient.map((p) => p.fichier).join(', ')}',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.45,
                              color: context.cl.grise,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Ce que l'agence lui renvoie : c'est ce qu'il attend, et
                  // il doit pouvoir l'ouvrir d'un appui.
                  if (demande.piecesAgence.isNotEmpty) ...[
                    const SizedBox(height: Espaces.md),
                    Container(
                      padding: const EdgeInsets.all(Espaces.md),
                      decoration: BoxDecoration(
                        color: context.cl.bleuFantome,
                        borderRadius: Rayons.brSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.download_rounded,
                                  size: 15, color: context.cl.bleuTexte),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  demande.piecesAgence.length == 1
                                      ? 'Un document vous a été envoyé'
                                      : '${demande.piecesAgence.length} documents '
                                          'vous ont été envoyés',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: context.cl.bleuTexte,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Espaces.sm),
                          for (final p in demande.piecesAgence)
                            LigneDocument(piece: p),
                          Text(
                            'Appuyez sur un document pour le télécharger.',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.cl.grise,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Espaces.md),
                  // Le même repère visuel que dans la liste du conseiller :
                  // les deux côtés parlent ainsi le même langage.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: EtiquetteStatut(statut: demande.statut),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// La couleur du liseré, accordée au statut du dossier.
  static Color _accent(String statut) => switch (statut) {
        'En cours' => Palette.bleuFonce,
        'Traitée' => Palette.succes,
        _ => Palette.orange,
      };
}

/// Une facture du client : son numéro, son montant, et de quoi la régler.
class _CarteFacture extends StatelessWidget {
  const _CarteFacture({required this.facture, required this.surRetour});

  final Facture facture;

  /// Rappelé au retour du paiement : le statut a pu changer.
  final Future<void> Function() surRetour;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final f = facture;
    final (accent, fond) = switch (f.statut) {
      StatutFacture.payee => (n.succesTexte, n.succesFantome),
      StatutFacture.annulee => (n.grise, n.fondDoux),
      StatutFacture.aPayer => (n.accentTexte, n.orangeFantome),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(Espaces.bord, 0, Espaces.bord, 10),
      child: Container(
        padding: const EdgeInsets.all(Espaces.lg),
        decoration: BoxDecoration(
          color: n.carte,
          borderRadius: Rayons.brLg,
          border: Border.all(color: n.ligne),
          boxShadow: n.ombreCarte,
        ),
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
                        f.montantFormate,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: n.encre,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${f.numero}  •  ${f.serviceLibelle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: n.encreDouce),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: fond,
                    borderRadius: Rayons.brPilule,
                  ),
                  child: Text(
                    f.libelleStatut,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            if (f.aPayer) ...[
              const SizedBox(height: Espaces.md),
              BoutonEnvoyer(
                bloc: true,
                libelle: 'Régler cette facture',
                icone: Icons.account_balance_wallet_outlined,
                onTap: () async {
                  await Navigator.of(context).pushNamed(
                    '/paiement',
                    arguments: (
                      demandeId: f.demandeId,
                      serviceId: '',
                      serviceLibelle: f.serviceLibelle,
                    ),
                  );
                  await surRetour();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

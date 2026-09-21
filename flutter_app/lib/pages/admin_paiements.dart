import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

/// Toutes les déclarations de versement, et ce qu'on en fait.
///
/// Réservé aux administrateurs : confirmer un encaissement engage l'agence,
/// et un conseiller ne doit pas pouvoir faire avancer un dossier en
/// déclarant lui-même que l'argent est arrivé.
class PageAdminPaiements extends StatefulWidget {
  const PageAdminPaiements({super.key});

  @override
  State<PageAdminPaiements> createState() => _PageAdminPaiementsState();
}

class _PageAdminPaiementsState extends State<PageAdminPaiements> {
  List<Paiement>? _paiements;
  String _erreur = '';
  String? _occupe;

  /// Nul = tous les statuts.
  StatutPaiement? _filtre = StatutPaiement.declare;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    if (!mounted) return;
    try {
      final liste = await PorteeApp.of(context).paiements();
      if (mounted) setState(() => _paiements = liste);
    } on ErreurBackend catch (e) {
      if (mounted) {
        setState(() {
          _paiements = const [];
          _erreur = e.message;
        });
      }
    }
  }

  Future<void> _statuer(Paiement p, bool confirme) async {
    if (_occupe != null) return;

    var motif = '';
    if (!confirme) {
      final saisi = await _demanderMotif(p);
      if (saisi == null || !mounted) return;
      motif = saisi;
    } else if (!await _confirmer(p) || !mounted) {
      return;
    }

    setState(() {
      _occupe = p.id;
      _erreur = '';
    });
    try {
      await PorteeApp.of(context).statuerPaiement(p.id, confirme, motif: motif);
      await _charger();
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _occupe = null);
    }
  }

  /// Confirmer, c'est affirmer qu'on a vu l'argent. On le fait dire.
  Future<bool> _confirmer(Paiement p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'encaissement'),
        content: Text(
          'Vous attestez avoir retrouvé ${p.montantFormate} sur le relevé '
          '${p.operateur.toUpperCase()}, en provenance du '
          '${p.numeroEnvoyeur}. Le dossier de ${p.clientNom} avancera.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('J\'ai vérifié'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Le motif du rejet est lu par le client : il doit savoir quoi corriger.
  Future<String?> _demanderMotif(Paiement p) {
    final saisie = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la déclaration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.clientNom} lira ce message. Dites-lui ce qui manque.',
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: Espaces.md),
            TextField(
              controller: saisie,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Versement introuvable sur le relevé…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final v = saisie.text.trim();
              Navigator.of(context).pop(
                v.isEmpty ? 'Versement introuvable sur notre relevé.' : v,
              );
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tous = _paiements;
    final liste = tous == null
        ? const <Paiement>[]
        : [
            for (final p in tous)
              if (_filtre == null || p.statut == _filtre) p,
          ];
    final attente =
        tous?.where((p) => p.enAttente).length ?? 0;

    return Coquille(
      titre: 'Paiements',
      sousTitre: tous == null
          ? 'Chargement…'
          : attente == 0
              ? 'Aucune déclaration en attente'
              : '$attente déclaration(s) à vérifier',
      routeCourante: '/admin/paiements',
      retour: false,
      actions: [
        IconButton(
          tooltip: 'Tarifs et moyens de paiement',
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => Navigator.of(context)
              .pushNamed('/admin/reglages')
              .then((_) => _charger()),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _charger,
        ),
      ],
      enfants: [
        if (_erreur.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: _erreur),
          ),
        if (tous == null)
          const Padding(
            padding: EdgeInsets.all(Espaces.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _filtres(tous),
          if (liste.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Espaces.xxl),
              child: Column(
                children: [
                  const PastilleIcone(
                      icone: Icons.receipt_long_outlined, taille: 56),
                  const SizedBox(height: Espaces.lg),
                  Text(
                    'Aucune déclaration ici.',
                    style: TextStyle(
                        fontSize: 14, color: context.cl.encreDouce),
                  ),
                ],
              ),
            )
          else
            for (final p in liste)
              _CartePaiement(
                paiement: p,
                occupe: _occupe == p.id,
                onConfirmer: () => _statuer(p, true),
                onRejeter: () => _statuer(p, false),
              ),
        ],
        const SizedBox(height: Espaces.xl),
      ],
    );
  }

  Widget _filtres(List<Paiement> tous) {
    int compte(StatutPaiement? s) =>
        s == null ? tous.length : tous.where((p) => p.statut == s).length;
    String nom(StatutPaiement? s) => switch (s) {
          null => 'Tous',
          StatutPaiement.declare => 'En attente',
          StatutPaiement.confirme => 'Confirmés',
          StatutPaiement.rejete => 'Rejetés',
        };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.lg, Espaces.bord, Espaces.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final s in <StatutPaiement?>[
              StatutPaiement.declare,
              StatutPaiement.confirme,
              StatutPaiement.rejete,
              null,
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Pastille(
                  libelle: '${nom(s)} (${compte(s)})',
                  actif: _filtre == s,
                  onTap: () => setState(() => _filtre = s),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({
    required this.libelle,
    required this.actif,
    required this.onTap,
  });

  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Material(
      color: actif ? n.accentTexte : n.carte,
      borderRadius: Rayons.brPilule,
      child: InkWell(
        borderRadius: Rayons.brPilule,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: Rayons.brPilule,
            border: Border.all(color: actif ? n.accentTexte : n.ligne),
          ),
          child: Text(
            libelle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: actif ? Colors.white : n.encreDouce,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartePaiement extends StatelessWidget {
  const _CartePaiement({
    required this.paiement,
    required this.occupe,
    required this.onConfirmer,
    required this.onRejeter,
  });

  final Paiement paiement;
  final bool occupe;
  final VoidCallback onConfirmer;
  final VoidCallback onRejeter;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final p = paiement;
    final (accent, fond) = switch (p.statut) {
      StatutPaiement.confirme => (n.succesTexte, n.succesFantome),
      StatutPaiement.rejete => (Palette.erreur, n.orangeFantome),
      StatutPaiement.declare => (n.accentTexte, n.orangeFantome),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(Espaces.bord, 0, Espaces.bord, 10),
      child: Container(
        padding: const EdgeInsets.all(Espaces.lg),
        decoration: BoxDecoration(
          color: n.carte,
          borderRadius: brBento,
          border: Border.all(color: n.ligne),
          boxShadow: n.ombreDouce,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.montantFormate,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: n.encre,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.clientNom} — ${p.serviceLibelle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: n.encreDouce,
                        ),
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
                    p.libelleStatut,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espaces.md),
            _Detail(libelle: 'Opérateur', valeur: p.operateur.toUpperCase()),
            if (p.numeroEnvoyeur.isNotEmpty)
              _Detail(libelle: 'Depuis le', valeur: p.numeroEnvoyeur),
            _Detail(
              libelle: 'Référence',
              valeur: p.reference.isEmpty ? 'non fournie' : p.reference,
              atone: p.reference.isEmpty,
            ),
            _Detail(libelle: 'Déclaré le', valeur: p.date),
            if (p.motif.isNotEmpty) ...[
              const SizedBox(height: Espaces.sm),
              Text(
                p.motif,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: n.encreDouce,
                ),
              ),
            ],
            if (p.enAttente) ...[
              const SizedBox(height: Espaces.lg),
              if (occupe)
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.erreur,
                          side: const BorderSide(color: Palette.erreur),
                          minimumSize: const Size(0, 42),
                          shape: const RoundedRectangleBorder(
                              borderRadius: Rayons.brPilule),
                        ),
                        onPressed: onRejeter,
                        child: const Text('Rejeter'),
                      ),
                    ),
                    const SizedBox(width: Espaces.md),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: n.succesTexte,
                          minimumSize: const Size(0, 42),
                          shape: const RoundedRectangleBorder(
                              borderRadius: Rayons.brPilule),
                        ),
                        onPressed: onConfirmer,
                        child: const Text('Confirmer'),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.libelle,
    required this.valeur,
    this.atone = false,
  });

  final String libelle;
  final String valeur;
  final bool atone;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(libelle, style: TextStyle(fontSize: 12.5, color: n.grise)),
          const Spacer(),
          Flexible(
            child: Text(
              valeur,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: atone ? FontWeight.w400 : FontWeight.w700,
                fontStyle: atone ? FontStyle.italic : FontStyle.normal,
                color: atone ? n.grise : n.encre,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

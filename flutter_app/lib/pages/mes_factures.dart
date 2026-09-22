import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';
import '../widgets/table_donnees.dart';

/// Les factures du client, en table.
///
/// Séparées des demandes parce qu'on ne vient pas y chercher la même chose :
/// un dossier, on suit son avancement ; une facture, on la règle.
///
/// En table et non en cartes : une carte disait tout d'une facture et ne
/// laissait voir que deux lignes à l'écran. Ici chaque facture tient sur une
/// ligne, la colonne d'état dit d'un coup d'œil ce qui est payé et ce qui
/// attend, et le détail s'ouvre en touchant la ligne.
class PageMesFactures extends StatefulWidget {
  const PageMesFactures({super.key});

  @override
  State<PageMesFactures> createState() => _PageMesFacturesState();
}

class _PageMesFacturesState extends State<PageMesFactures> {
  final _recherche = TextEditingController();

  List<Facture> _factures = const [];
  bool _charge = false;
  String _erreur = '';
  String _terme = '';

  /// Nul = tous les statuts.
  StatutFacture? _filtre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rafraichir());
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  Future<void> _rafraichir() async {
    if (!mounted) return;
    final etat = PorteeApp.of(context);
    try {
      final f = await etat.mesFactures();
      if (mounted) setState(() => _factures = f);
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _charge = true);
    }
  }

  /// Ce qui reste à payer d'abord : c'est pour cela qu'on ouvre cet écran.
  /// Le reste n'est qu'un historique.
  List<Facture> get _visibles {
    final t = _terme.trim().toLowerCase();
    final gardees = [
      for (final f in _factures)
        if ((_filtre == null || f.statut == _filtre) &&
            (t.isEmpty ||
                '${f.numero} ${f.serviceLibelle} ${f.montant}'
                    .toLowerCase()
                    .contains(t)))
          f,
    ];
    return gardees
      ..sort((a, b) {
        if (a.aPayer != b.aPayer) return a.aPayer ? -1 : 1;
        return 0;
      });
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;

    int compte(StatutFacture? s) => s == null
        ? _factures.length
        : _factures.where((f) => f.statut == s).length;

    return Coquille(
      titre: 'Mes factures',
      sousTitre: _resume(),
      routeCourante: '/profil',
      enfants: [
        if (_erreur.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: _erreur),
          ),
        const SizedBox(height: Espaces.lg),

        // La recherche n'a rien à trier sous quelques lignes : elle ne
        // ferait qu'occuper la place de ce qu'on est venu lire.
        if (_factures.length > 3)
          ChampRecherche(
            controleur: _recherche,
            invite: 'Numéro, service, montant…',
            onChange: (v) => setState(() => _terme = v),
          ),

        if (_factures.length > 1)
          BarreFiltres(
            pastilles: [
              for (final s in <StatutFacture?>[null, ...StatutFacture.values])
                PastilleFiltre(
                  libelle: '${_libelle(s)} (${compte(s)})',
                  actif: _filtre == s,
                  onTap: () => setState(() => _filtre = s),
                ),
            ],
          ),

        if (visibles.isEmpty)
          _vide(context)
        else ...[
          TableDonnees(
            // L'ordre n'est pas indifferent : les trois premieres colonnes
            // sont celles qui doivent se lire sans faire defiler la table,
            // et l'etat en fait partie — c'est la premiere chose qu'on
            // vient verifier. Le service et la date suivent, pour qui va
            // les chercher.
            colonnes: const [
              (titre: 'Numéro', largeur: 104, aDroite: false),
              (titre: 'État', largeur: 92, aDroite: false),
              (titre: 'Montant', largeur: 104, aDroite: true),
              (titre: 'Service', largeur: 148, aDroite: false),
              (titre: 'Date', largeur: 78, aDroite: false),
            ],
            surLigne: (i) => _ouvrir(visibles[i]),
            lignes: [
              for (final f in visibles)
                LigneTable([
                  CelluleTexte(f.numero, gras: true),
                  _etat(f),
                  CelluleTexte(montantEnFcfa(f.montant),
                      aDroite: true, gras: true),
                  CelluleTexte(f.serviceLibelle),
                  CelluleTexte(f.date),
                ]),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.sm, Espaces.bord, 0),
            child: Text(
              'Touchez une ligne pour la régler ou voir son détail.',
              style: TextStyle(fontSize: 11.5, color: context.cl.grise),
            ),
          ),
        ],
        const SizedBox(height: Espaces.xl),
      ],
    );
  }

  Widget _etat(Facture f) {
    final n = context.cl;
    final (accent, fond) = switch (f.statut) {
      StatutFacture.payee => (n.succesTexte, n.succesFantome),
      StatutFacture.annulee => (n.grise, n.fondDoux),
      StatutFacture.aPayer => (n.accentTexte, n.orangeFantome),
    };
    return CelluleEtat(libelle: f.libelleStatut, accent: accent, fond: fond);
  }

  Future<void> _ouvrir(Facture f) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeuilleFacture(facture: f),
    );
    await _rafraichir();
  }

  static String _libelle(StatutFacture? s) => switch (s) {
        null => 'Toutes',
        StatutFacture.aPayer => 'À payer',
        StatutFacture.payee => 'Payées',
        StatutFacture.annulee => 'Annulées',
      };

  String _resume() {
    if (!_charge) return 'Chargement…';
    if (_factures.isEmpty) return 'Aucune facture';
    final du = _factures.where((f) => f.aPayer).toList();
    if (du.isEmpty) return '${_factures.length} facture(s), tout est réglé';
    final total = du.fold<int>(0, (s, f) => s + f.montant);
    return '${du.length} à régler — ${montantEnFcfa(total)}';
  }

  Widget _vide(BuildContext context) {
    final n = context.cl;
    // Tant que le premier chargement n'a pas rendu, « aucune facture »
    // serait un mensonge : on ne sait pas encore.
    if (!_charge) {
      return const Padding(
        padding: EdgeInsets.all(Espaces.xxl),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    final filtre = _filtre != null || _terme.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Espaces.bord),
      padding: const EdgeInsets.all(Espaces.xxl),
      decoration: BoxDecoration(
        color: n.carte,
        borderRadius: Rayons.brXl,
        boxShadow: n.ombreDouce,
        border: Border.all(color: n.ligne),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 34, color: n.grise),
          const SizedBox(height: Espaces.md),
          Text(
            filtre
                ? 'Aucune facture ne correspond'
                : 'Aucune facture pour le moment',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          if (!filtre) ...[
            const SizedBox(height: 5),
            Text(
              'Une facture est émise dès le dépôt d\'un dossier payant.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: n.encreDouce,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le détail d'une facture, et de quoi la régler.
///
/// Ce que la table ne montre pas tient ici : le tableau donne la vue
/// d'ensemble, la feuille donne l'objet.
class FeuilleFacture extends StatelessWidget {
  const FeuilleFacture({super.key, required this.facture});

  final Facture facture;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final f = facture;
    final (accent, fond) = switch (f.statut) {
      StatutFacture.payee => (n.succesTexte, n.succesFantome),
      StatutFacture.annulee => (n.grise, n.fondDoux),
      StatutFacture.aPayer => (n.accentTexte, n.orangeFantome),
    };

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(Espaces.md),
        padding: const EdgeInsets.all(Espaces.xl),
        decoration: BoxDecoration(
          color: n.carte,
          borderRadius: Rayons.brXl,
          boxShadow: n.ombreForte,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    f.montantFormate,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: n.encre,
                    ),
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
            const SizedBox(height: Espaces.lg),
            _Detail(libelle: 'Numéro', valeur: f.numero),
            _Detail(libelle: 'Service', valeur: f.serviceLibelle),
            _Detail(libelle: 'Émise le', valeur: f.date),
            if (f.aPayer) ...[
              const SizedBox(height: Espaces.xl),
              BoutonEnvoyer(
                bloc: true,
                libelle: 'Régler cette facture',
                icone: Icons.account_balance_wallet_outlined,
                onTap: () {
                  final navigateur = Navigator.of(context);
                  navigateur.pop();
                  navigateur.pushNamed(
                    '/paiement',
                    arguments: (
                      demandeId: f.demandeId,
                      serviceId: '',
                      serviceLibelle: f.serviceLibelle,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.libelle, required this.valeur});

  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(libelle, style: TextStyle(fontSize: 12.5, color: n.grise)),
          const Spacer(),
          Flexible(
            child: Text(
              valeur.isEmpty ? '—' : valeur,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

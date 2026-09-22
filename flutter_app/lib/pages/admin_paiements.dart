import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/api.dart';
import '../export/tableur.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';
import '../widgets/table_donnees.dart';

/// Les deux faces d'une transaction : ce qui a été facturé, ce qui est
/// rentré.
///
/// Réservé aux administrateurs : confirmer un encaissement engage l'agence,
/// et un conseiller ne doit pas pouvoir faire avancer un dossier en
/// déclarant lui-même que l'argent est arrivé.
///
/// Les lignes sont présentées en table et non en cartes. L'administration
/// en lit des dizaines d'affilée et cherche à comparer des colonnes ; une
/// carte par ligne l'obligeait à défiler sans fin pour rapprocher deux
/// montants.
class PageAdminPaiements extends StatefulWidget {
  const PageAdminPaiements({super.key});

  @override
  State<PageAdminPaiements> createState() => _PageAdminPaiementsState();
}

/// Ce que l'écran montre : la dette émise, ou l'argent vu.
enum _Vue { factures, paiements }

class _PageAdminPaiementsState extends State<PageAdminPaiements> {
  List<Paiement>? _paiements;
  List<Facture>? _factures;

  final _recherche = TextEditingController();

  String _erreur = '';
  String _terme = '';
  String? _occupe;
  bool _exporte = false;

  _Vue _vue = _Vue.paiements;

  /// Nul = tous les statuts.
  StatutPaiement? _filtreP = StatutPaiement.declare;
  StatutFacture? _filtreF;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  /// Le terme cherche est-il dans ce texte ?
  ///
  /// Une seule regle pour les deux tables : on tape un nom de client, un
  /// numero de facture ou une reference d'operateur, sans avoir a dire
  /// laquelle des trois.
  bool _correspond(String champs) {
    final t = _terme.trim().toLowerCase();
    return t.isEmpty || champs.toLowerCase().contains(t);
  }

  Future<void> _charger() async {
    if (!mounted) return;
    final etat = PorteeApp.of(context);
    try {
      // Les deux ensemble : l'écran bascule de l'une à l'autre sans
      // attendre, et l'export a besoin des deux quoi qu'on regarde.
      final liste = await etat.paiements();
      final fac = await etat.factures();
      if (mounted) {
        setState(() {
          _paiements = liste;
          _factures = fac;
          _erreur = '';
        });
      }
    } on ErreurBackend catch (e) {
      if (mounted) {
        setState(() {
          _paiements ??= const [];
          _factures ??= const [];
          _erreur = e.message;
        });
      }
    }
  }

  /* ----------------------------------------------------------------- */
  /*  Export                                                           */
  /* ----------------------------------------------------------------- */

  /// Écrit le classeur et laisse l'appareil décider où le ranger.
  ///
  /// Tout est exporté, pas seulement le filtre affiché : un comptable qui
  /// demande les transactions les veut toutes, et il filtrera lui-même dans
  /// son tableur.
  Future<void> _exporter() async {
    if (_exporte) return;
    final messager = ScaffoldMessenger.of(context);
    setState(() => _exporte = true);

    try {
      final octets = classeurTransactions(
        factures: _factures ?? const [],
        paiements: _paiements ?? const [],
      );
      if (octets == null) {
        messager.showSnackBar(const SnackBar(
          content: Text("Le classeur n'a pas pu être construit."),
        ));
        return;
      }

      final chemin = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer les transactions',
        fileName: nomFichierTransactions(DateTime.now()),
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: octets,
      );
      if (chemin == null) return; // Annulé.

      messager.showSnackBar(const SnackBar(
        content: Text('Classeur enregistré.'),
      ));
    } catch (e) {
      messager.showSnackBar(SnackBar(
        content: Text("Export impossible : $e"),
      ));
    } finally {
      if (mounted) setState(() => _exporte = false);
    }
  }

  /* ----------------------------------------------------------------- */
  /*  Statuer sur une déclaration                                      */
  /* ----------------------------------------------------------------- */

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

  /// La ligne touchée ouvre son détail : en table, les actions ne tiennent
  /// pas dans une cellule, et les noyer dans la grille les rendrait
  /// dangereuses à portée du pouce.
  Future<void> _ouvrirPaiement(Paiement p) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeuillePaiement(
        paiement: p,
        occupe: _occupe == p.id,
        onConfirmer: () {
          Navigator.of(context).pop();
          _statuer(p, true);
        },
        onRejeter: () {
          Navigator.of(context).pop();
          _statuer(p, false);
        },
      ),
    );
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

  /// Annule une facture restée impayée.
  Future<void> _annuler(Facture f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la facture'),
        content: Text(
          '${f.numero} — ${f.montantFormate}, au nom de ${f.clientNom}. '
          'Elle ne sera plus réclamée.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Revenir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Annuler la facture'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _occupe = f.id;
      _erreur = '';
    });
    try {
      await PorteeApp.of(context).annulerFacture(f.id);
      await _charger();
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _occupe = null);
    }
  }

  /* ----------------------------------------------------------------- */
  /*  Rendu                                                            */
  /* ----------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    final paiements = _paiements;
    final factures = _factures;
    final charge = paiements != null && factures != null;

    return Coquille(
      titre: 'Transactions',
      sousTitre: _resume(),
      routeCourante: '/admin/paiements',
      retour: false,
      actions: [
        IconButton(
          tooltip: 'Exporter vers Excel',
          icon: _exporte
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.file_download_outlined),
          onPressed: charge ? _exporter : null,
        ),
        IconButton(
          tooltip: 'Tarifs et moyens de paiement',
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => Navigator.of(context)
              .pushNamed('/admin/reglages')
              .then((_) => _charger()),
        ),
        IconButton(
          tooltip: 'Recharger',
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
        if (!charge)
          const Padding(
            padding: EdgeInsets.all(Espaces.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          const SizedBox(height: Espaces.lg),
          _bascule(),
          const SizedBox(height: Espaces.md),
          _totaux(factures, paiements),
          ChampRecherche(
            controleur: _recherche,
            invite: _vue == _Vue.paiements
                ? 'Client, référence, numéro…'
                : 'Client, numéro de facture, service…',
            onChange: (v) => setState(() => _terme = v),
          ),
          if (_vue == _Vue.paiements)
            ..._vuePaiements(paiements)
          else
            ..._vueFactures(factures),
        ],
        const SizedBox(height: Espaces.xl),
      ],
    );
  }

  String _resume() {
    final p = _paiements;
    if (p == null) return 'Chargement…';
    final attente = p.where((x) => x.enAttente).length;
    if (attente == 0) return 'Aucune déclaration en attente';
    return '$attente déclaration(s) à vérifier';
  }

  /// Le choix entre les deux faces de la transaction.
  Widget _bascule() {
    final n = context.cl;
    Widget cote(_Vue v, String libelle, IconData icone) {
      final actif = _vue == v;
      return Expanded(
        child: Material(
          color: actif ? n.carte : Colors.transparent,
          borderRadius: Rayons.brPilule,
          elevation: actif ? 1 : 0,
          shadowColor: Colors.black26,
          child: InkWell(
            borderRadius: Rayons.brPilule,
            onTap: actif
                ? null
                : () => setState(() {
                      _vue = v;
                      // Un terme laisse d'une vue a l'autre ferait croire
                      // a une table vide.
                      _terme = '';
                      _recherche.clear();
                    }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone,
                      size: 16,
                      color: actif ? n.accentTexte : n.encreDouce),
                  const SizedBox(width: 6),
                  Text(
                    libelle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: actif ? n.accentTexte : n.encreDouce,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Espaces.bord),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: n.fondDoux,
          borderRadius: Rayons.brPilule,
          border: Border.all(color: n.ligne),
        ),
        child: Row(
          children: [
            cote(_Vue.factures, 'Factures', Icons.receipt_long_outlined),
            cote(_Vue.paiements, 'Versements',
                Icons.account_balance_wallet_outlined),
          ],
        ),
      ),
    );
  }

  Widget _totaux(List<Facture> factures, List<Paiement> paiements) {
    final emis = factures.fold<int>(0, (s, f) => s + f.montant);
    final encaisse = paiements
        .where((p) => p.statut == StatutPaiement.confirme)
        .fold<int>(0, (s, p) => s + p.montant);
    final attente = paiements.where((p) => p.enAttente).length;

    return BandeauTotaux(
      entrees: [
        (libelle: 'Facturé', valeur: montantEnFcfa(emis), alerte: false),
        (libelle: 'Encaissé', valeur: montantEnFcfa(encaisse), alerte: false),
        (
          libelle: 'À vérifier',
          valeur: '$attente',
          alerte: attente > 0,
        ),
      ],
    );
  }

  /* -- Versements ---------------------------------------------------- */

  List<Widget> _vuePaiements(List<Paiement> tous) {
    final liste = [
      for (final p in tous)
        if ((_filtreP == null || p.statut == _filtreP) &&
            _correspond('${p.clientNom} ${p.reference} '
                '${p.numeroEnvoyeur} ${p.operateur} ${p.serviceLibelle}'))
          p,
    ];

    int compte(StatutPaiement? s) =>
        s == null ? tous.length : tous.where((p) => p.statut == s).length;
    String nom(StatutPaiement? s) => switch (s) {
          null => 'Tous',
          StatutPaiement.declare => 'En attente',
          StatutPaiement.confirme => 'Confirmés',
          StatutPaiement.rejete => 'Rejetés',
        };

    return [
      BarreFiltres(
        pastilles: [
          for (final s in <StatutPaiement?>[
            StatutPaiement.declare,
            StatutPaiement.confirme,
            StatutPaiement.rejete,
            null,
          ])
            PastilleFiltre(
              libelle: '${nom(s)} (${compte(s)})',
              actif: _filtreP == s,
              onTap: () => setState(() => _filtreP = s),
            ),
        ],
      ),
      if (liste.isEmpty)
        _vide(_terme.isEmpty
            ? 'Aucune déclaration ici.'
            : 'Aucune déclaration ne correspond.')
      else
        TableDonnees(
          // Le client, son etat et le montant tiennent dans la largeur
          // d'un telephone : ce sont les trois colonnes qu'on lit sans
          // rien faire defiler. Le detail de l'operation suit.
          colonnes: const [
            (titre: 'Client', largeur: 124, aDroite: false),
            (titre: 'État', largeur: 92, aDroite: false),
            (titre: 'Montant', largeur: 104, aDroite: true),
            (titre: 'Date', largeur: 78, aDroite: false),
            (titre: 'Opérateur', largeur: 78, aDroite: false),
            (titre: 'Référence', largeur: 132, aDroite: false),
          ],
          surLigne: (i) => _ouvrirPaiement(liste[i]),
          lignes: [
            for (final p in liste)
              LigneTable([
                CelluleTexte(p.clientNom, gras: true),
                _etatPaiement(p),
                CelluleTexte(montantEnFcfa(p.montant),
                    aDroite: true, gras: true),
                CelluleTexte(p.date),
                CelluleTexte(p.operateur.toUpperCase()),
                CelluleTexte(p.reference, atone: p.reference.isEmpty),
              ]),
          ],
        ),
      if (liste.isNotEmpty) _pied('Touchez une ligne pour la traiter.'),
    ];
  }

  Widget _etatPaiement(Paiement p) {
    final n = context.cl;
    final (accent, fond) = switch (p.statut) {
      StatutPaiement.confirme => (n.succesTexte, n.succesFantome),
      StatutPaiement.rejete => (Palette.erreur, n.orangeFantome),
      StatutPaiement.declare => (n.accentTexte, n.orangeFantome),
    };
    return CelluleEtat(libelle: p.libelleCourt, accent: accent, fond: fond);
  }

  /* -- Factures ------------------------------------------------------ */

  List<Widget> _vueFactures(List<Facture> tous) {
    final liste = [
      for (final f in tous)
        if ((_filtreF == null || f.statut == _filtreF) &&
            _correspond('${f.clientNom} ${f.numero} ${f.serviceLibelle}'))
          f,
    ];

    int compte(StatutFacture? s) =>
        s == null ? tous.length : tous.where((f) => f.statut == s).length;
    String nom(StatutFacture? s) => switch (s) {
          null => 'Toutes',
          StatutFacture.aPayer => 'À payer',
          StatutFacture.payee => 'Payées',
          StatutFacture.annulee => 'Annulées',
        };

    return [
      BarreFiltres(
        pastilles: [
          for (final s in <StatutFacture?>[null, ...StatutFacture.values])
            PastilleFiltre(
              libelle: '${nom(s)} (${compte(s)})',
              actif: _filtreF == s,
              onTap: () => setState(() => _filtreF = s),
            ),
        ],
      ),
      if (liste.isEmpty)
        _vide(_terme.isEmpty
            ? 'Aucune facture ici.'
            : 'Aucune facture ne correspond.')
      else
        TableDonnees(
          colonnes: const [
            (titre: 'Numéro', largeur: 104, aDroite: false),
            (titre: 'État', largeur: 92, aDroite: false),
            (titre: 'Montant', largeur: 104, aDroite: true),
            (titre: 'Client', largeur: 124, aDroite: false),
            (titre: 'Service', largeur: 148, aDroite: false),
            (titre: 'Date', largeur: 78, aDroite: false),
          ],
          surLigne: (i) {
            final f = liste[i];
            if (f.aPayer) _annuler(f);
          },
          lignes: [
            for (final f in liste)
              LigneTable([
                CelluleTexte(f.numero, gras: true),
                _etatFacture(f),
                CelluleTexte(montantEnFcfa(f.montant),
                    aDroite: true, gras: true),
                CelluleTexte(f.clientNom),
                CelluleTexte(f.serviceLibelle),
                CelluleTexte(f.date),
              ]),
          ],
        ),
      if (liste.isNotEmpty)
        _pied('Touchez une facture à payer pour l\'annuler.'),
    ];
  }

  Widget _etatFacture(Facture f) {
    final n = context.cl;
    final (accent, fond) = switch (f.statut) {
      StatutFacture.payee => (n.succesTexte, n.succesFantome),
      StatutFacture.annulee => (n.grise, n.fondDoux),
      StatutFacture.aPayer => (n.accentTexte, n.orangeFantome),
    };
    return CelluleEtat(libelle: f.libelleStatut, accent: accent, fond: fond);
  }

  /* -- Fragments communs --------------------------------------------- */

  Widget _vide(String texte) {
    return Padding(
      padding: const EdgeInsets.all(Espaces.xxl),
      child: Column(
        children: [
          const PastilleIcone(icone: Icons.receipt_long_outlined, taille: 56),
          const SizedBox(height: Espaces.lg),
          Text(
            texte,
            style: TextStyle(fontSize: 14, color: context.cl.encreDouce),
          ),
        ],
      ),
    );
  }

  Widget _pied(String texte) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.sm, Espaces.bord, 0),
      child: Text(
        texte,
        style: TextStyle(fontSize: 11.5, color: context.cl.grise),
      ),
    );
  }
}

/// Le détail d'une déclaration, et ce qu'on peut en faire.
///
/// En feuille plutôt qu'en cellule : confirmer un encaissement engage
/// l'agence, et un bouton de cette portée ne doit pas se trouver à portée
/// du pouce au milieu d'une grille qu'on fait défiler.
class _FeuillePaiement extends StatelessWidget {
  const _FeuillePaiement({
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
            Text(
              p.montantFormate,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: n.encre,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${p.clientNom} — ${p.serviceLibelle}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: n.encreDouce,
              ),
            ),
            const SizedBox(height: Espaces.lg),
            _Detail(libelle: 'Opérateur', valeur: p.operateur.toUpperCase()),
            _Detail(
              libelle: 'Depuis le',
              valeur: p.numeroEnvoyeur,
              atone: p.numeroEnvoyeur.isEmpty,
            ),
            _Detail(
              libelle: 'Référence',
              valeur: p.reference.isEmpty ? 'non fournie' : p.reference,
              atone: p.reference.isEmpty,
            ),
            _Detail(libelle: 'Déclaré le', valeur: p.date),
            _Detail(libelle: 'État', valeur: p.libelleStatut),
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
              const SizedBox(height: Espaces.xl),
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
                          minimumSize: const Size(0, 44),
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
                          minimumSize: const Size(0, 44),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(libelle, style: TextStyle(fontSize: 12.5, color: n.grise)),
          const Spacer(),
          Flexible(
            child: Text(
              valeur.isEmpty ? '—' : valeur,
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

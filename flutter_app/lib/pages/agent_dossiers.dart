import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';
import '../widgets/table_donnees.dart';

/// Tous les dossiers, pour un conseiller.
///
/// La liste n'est pas filtrée côté application : la RLS a déjà décidé de ce
/// qui est visible. Un client qui atteindrait cet écran n'y verrait que ses
/// propres dossiers.
///
/// En table, comme les listes du client et de l'administration. C'est ici
/// que cela compte le plus : le conseiller voit les dossiers de **tous** les
/// clients, et une carte par dossier lui en montrait deux par écran.
class PageAgentDossiers extends StatefulWidget {
  const PageAgentDossiers({super.key});

  @override
  State<PageAgentDossiers> createState() => _PageAgentDossiersState();
}

class _PageAgentDossiersState extends State<PageAgentDossiers> {
  final _recherche = TextEditingController();

  String _terme = '';

  /// Nul = tous les statuts.
  String? _filtre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PorteeApp.of(context).rafraichirDemandes();
    });
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final tous = etat.demandes;
    final t = _terme.trim().toLowerCase();
    final dossiers = [
      for (final d in tous)
        if ((_filtre == null || d.statut == _filtre) &&
            (t.isEmpty ||
                '${d.clientNom} ${d.clientTelephone} ${d.serviceLibelle} '
                        '${d.resume}'
                    .toLowerCase()
                    .contains(t)))
          d,
    ];

    return Coquille(
      titre: 'Dossiers',
      sousTitre: _resume(tous),
      routeCourante: '/agent/dossiers',
      retour: false,
      enfants: [
        if (etat.erreurDemarrage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: etat.erreurDemarrage),
          ),
        const SizedBox(height: Espaces.lg),

        // Un conseiller voit les dossiers de tout le monde : c'est par le
        // nom du client qu'il retrouve celui qu'il cherche, pas en défilant.
        if (tous.length > 3)
          ChampRecherche(
            controleur: _recherche,
            invite: 'Client, téléphone, service…',
            onChange: (v) => setState(() => _terme = v),
          ),

        _filtres(tous),

        if (dossiers.isEmpty)
          _vide()
        else ...[
          TableDonnees(
            colonnes: const [
              // Le client d'abord, l'état juste après : ce sont les deux
              // colonnes qui doivent se lire sans faire défiler la table.
              (titre: 'Client', largeur: 124, aDroite: false),
              (titre: 'État', largeur: 92, aDroite: false),
              (titre: 'Service', largeur: 150, aDroite: false),
              (titre: 'Objet', largeur: 168, aDroite: false),
              (titre: 'Date', largeur: 78, aDroite: false),
              (titre: 'Docs', largeur: 76, aDroite: false),
            ],
            surLigne: (i) => Navigator.of(context)
                .pushNamed('/agent/dossier', arguments: dossiers[i].id),
            lignes: [
              for (final d in dossiers)
                LigneTable([
                  CelluleTexte(d.clientNom, gras: true),
                  _etat(d),
                  CelluleTexte(d.serviceLibelle),
                  CelluleTexte(d.resume),
                  CelluleTexte(d.date),
                  _documents(d),
                ]),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.sm, Espaces.bord, 0),
            child: Text(
              'Touchez une ligne pour ouvrir le dossier.',
              style: TextStyle(fontSize: 11.5, color: context.cl.grise),
            ),
          ),
        ],
        const SizedBox(height: Espaces.xl),
      ],
    );
  }

  Widget _etat(Demande d) {
    final n = context.cl;
    final (accent, fond) = switch (d.statut) {
      'En cours' => (n.bleuTexte, n.bleuFantome),
      'Traitée' => (n.succesTexte, n.succesFantome),
      _ => (n.accentTexte, n.orangeFantome),
    };
    return CelluleEtat(libelle: d.statut, accent: accent, fond: fond);
  }

  /// Ce que le client a fourni, et ce que l'agence lui a déjà renvoyé.
  Widget _documents(Demande d) {
    final n = context.cl;
    final envoyes = d.piecesClient.length;
    final rendus = d.piecesAgence.length;
    if (envoyes == 0 && rendus == 0) return const CelluleTexte('', atone: true);

    return Row(
      children: [
        if (envoyes > 0) ...[
          Icon(Icons.attach_file_rounded, size: 13, color: n.grise),
          const SizedBox(width: 2),
          Text(
            '$envoyes',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: n.grise),
          ),
        ],
        if (rendus > 0) ...[
          const SizedBox(width: 7),
          Icon(Icons.upload_rounded, size: 13, color: n.bleuTexte),
          const SizedBox(width: 2),
          Text(
            '$rendus',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: n.bleuTexte),
          ),
        ],
      ],
    );
  }

  String _resume(List<Demande> tous) {
    if (tous.isEmpty) return 'Aucun dossier';
    final attente = tous.where((d) => d.statut == 'Envoyée').length;
    if (attente == 0) return '${tous.length} dossier(s), aucun en attente';
    return '${tous.length} dossier(s), $attente à ouvrir';
  }

  Widget _filtres(List<Demande> tous) {
    int compte(String? s) =>
        s == null ? tous.length : tous.where((d) => d.statut == s).length;

    return BarreFiltres(
      pastilles: [
        for (final s in <String?>[null, ...statutsDemande])
          PastilleFiltre(
            libelle: '${s ?? 'Tous'} (${compte(s)})',
            actif: _filtre == s,
            onTap: () => setState(() => _filtre = s),
          ),
      ],
    );
  }

  Widget _vide() {
    final cherche = _terme.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.all(Espaces.bord),
      padding: const EdgeInsets.all(Espaces.xxl),
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius: Rayons.brXl,
        border: Border.all(color: context.cl.ligne),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 34, color: context.cl.grise),
          const SizedBox(height: Espaces.md),
          Text(
            cherche
                ? 'Aucun dossier ne correspond.'
                : _filtre == null
                    ? 'Aucun dossier pour le moment.'
                    : 'Aucun dossier « $_filtre ».',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: context.cl.encreDouce),
          ),
        ],
      ),
    );
  }
}

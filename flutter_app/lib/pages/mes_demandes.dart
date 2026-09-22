import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';
import '../widgets/document.dart';
import '../widgets/table_donnees.dart';

/// Les dossiers du client, en table.
///
/// Ils vivaient au milieu du profil, en grosses cartes. Passé quelques
/// envois la page devenait interminable et l'on n'en voyait plus que deux à
/// la fois. Ici chaque dossier tient sur une ligne, la colonne d'état dit
/// où il en est, et le détail — ce qui a été envoyé, ce qu'on renvoie —
/// s'ouvre en touchant la ligne.
///
/// La barre du bas reste sur « Profil » : cet écran s'ouvre depuis le profil
/// et en fait partie, même s'il n'a pas son propre onglet.
class PageMesDemandes extends StatefulWidget {
  const PageMesDemandes({super.key});

  @override
  State<PageMesDemandes> createState() => _PageMesDemandesState();
}

class _PageMesDemandesState extends State<PageMesDemandes> {
  final _recherche = TextEditingController();

  String _terme = '';

  /// Nul = tous les statuts.
  String? _filtre;

  @override
  void initState() {
    super.initState();
    // Le statut d'un dossier est décidé par nos services, pas par le client :
    // sans cette relecture, un passage en « Traitée » ne se verrait jamais.
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
    final visibles = [
      for (final d in tous)
        if ((_filtre == null || d.statut == _filtre) &&
            (t.isEmpty ||
                '${d.serviceLibelle} ${d.resume} ${d.date}'
                    .toLowerCase()
                    .contains(t)))
          d,
    ];

    int compte(String? s) =>
        s == null ? tous.length : tous.where((d) => d.statut == s).length;

    return Coquille(
      titre: 'Mes demandes',
      sousTitre: _resume(tous),
      routeCourante: '/profil',
      enfants: [
        if (etat.erreurDemarrage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: etat.erreurDemarrage),
          ),
        const SizedBox(height: Espaces.lg),

        if (tous.length > 3)
          ChampRecherche(
            controleur: _recherche,
            invite: 'Service, objet de la demande…',
            onChange: (v) => setState(() => _terme = v),
          ),

        // Les filtres ne servent à rien tant qu'il n'y a qu'un dossier : ils
        // ne feraient qu'occuper la place de ce qu'on est venu lire.
        if (tous.length > 1)
          BarreFiltres(
            pastilles: [
              for (final s in <String?>[null, ...statutsDemande])
                PastilleFiltre(
                  libelle: '${s ?? 'Toutes'} (${compte(s)})',
                  actif: _filtre == s,
                  onTap: () => setState(() => _filtre = s),
                ),
            ],
          ),

        if (visibles.isEmpty)
          _vide(context)
        else ...[
          TableDonnees(
            // Le service et l'etat d'abord : ce sont eux qu'on lit sans
            // faire defiler la table.
            colonnes: const [
              (titre: 'Service', largeur: 150, aDroite: false),
              (titre: 'État', largeur: 92, aDroite: false),
              (titre: 'Date', largeur: 78, aDroite: false),
              (titre: 'Objet', largeur: 172, aDroite: false),
              (titre: 'Docs', largeur: 76, aDroite: false),
            ],
            surLigne: (i) => _ouvrir(visibles[i]),
            lignes: [
              for (final d in visibles)
                LigneTable([
                  CelluleTexte(d.serviceLibelle, gras: true),
                  _etat(d),
                  CelluleTexte(d.date),
                  CelluleTexte(d.resume),
                  _documents(d),
                ]),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.sm, Espaces.bord, 0),
            child: Text(
              'Touchez une ligne pour voir ses documents.',
              style: TextStyle(fontSize: 11.5, color: context.cl.grise),
            ),
          ),
        ],
        const SizedBox(height: Espaces.xl),
      ],
    );
  }

  /// Ce qu'on a envoyé, et ce qui est revenu. Le retour de l'agence est ce
  /// que le client attend : il s'annonce en couleur, le reste en gris.
  Widget _documents(Demande d) {
    final n = context.cl;
    final envoyes = d.piecesClient.length;
    final recus = d.piecesAgence.length;

    if (envoyes == 0 && recus == 0) {
      return const CelluleTexte('', atone: true);
    }

    return Row(
      children: [
        if (envoyes > 0) ...[
          Icon(Icons.attach_file_rounded, size: 13, color: n.grise),
          const SizedBox(width: 2),
          Text(
            '$envoyes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: n.grise,
            ),
          ),
        ],
        if (recus > 0) ...[
          const SizedBox(width: 8),
          Icon(Icons.download_rounded, size: 13, color: n.bleuTexte),
          const SizedBox(width: 2),
          Text(
            '$recus',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: n.bleuTexte,
            ),
          ),
        ],
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

  Future<void> _ouvrir(Demande d) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FeuilleDemande(demande: d),
      );

  String _resume(List<Demande> tous) {
    if (tous.isEmpty) return 'Aucune demande';
    final traitees = tous.where((d) => d.statut == 'Traitée').length;
    if (traitees == 0) return '${tous.length} demande(s) en cours';
    return '${tous.length} demande(s), $traitees traitée(s)';
  }

  Widget _vide(BuildContext context) {
    final n = context.cl;
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
          Icon(Icons.inbox_outlined, size: 34, color: n.grise),
          const SizedBox(height: Espaces.md),
          Text(
            filtre
                ? 'Aucune demande ne correspond'
                : "Aucune demande pour l'instant",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          if (!filtre) ...[
            const SizedBox(height: 5),
            Text(
              'Rendez-vous dans « Services » pour en créer une.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: n.encreDouce,
              ),
            ),
            const SizedBox(height: Espaces.lg),
            BoutonEnvoyer(
              libelle: 'Voir les services',
              icone: Icons.arrow_forward_rounded,
              onTap: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/services', (r) => false),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le détail d'un dossier : ce qu'on a envoyé, ce que l'agence renvoie.
///
/// Les documents ne tiennent pas dans une cellule, et ce sont eux que le
/// client vient chercher : ils ont leur place ici, en grand, avec de quoi
/// les ouvrir d'un appui.
class FeuilleDemande extends StatelessWidget {
  const FeuilleDemande({super.key, required this.demande});

  final Demande demande;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final d = demande;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(Espaces.md),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        decoration: BoxDecoration(
          color: n.carte,
          borderRadius: Rayons.brXl,
          boxShadow: n.ombreForte,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaces.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      d.serviceLibelle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.25,
                        color: n.encre,
                      ),
                    ),
                  ),
                  const SizedBox(width: Espaces.md),
                  EtiquetteStatut(statut: d.statut),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Déposée le ${d.date}',
                style: TextStyle(fontSize: 12, color: n.grise),
              ),
              const SizedBox(height: Espaces.lg),
              Text(
                d.resume,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: n.encreDouce,
                ),
              ),

              if (d.piecesClient.isNotEmpty) ...[
                const SizedBox(height: Espaces.xl),
                _titre(context, 'Ce que vous avez envoyé'),
                const SizedBox(height: Espaces.sm),
                for (final p in d.piecesClient) LigneDocument(piece: p),
              ],

              if (d.piecesAgence.isNotEmpty) ...[
                const SizedBox(height: Espaces.xl),
                _titre(context, 'Ce que l\'agence vous renvoie'),
                const SizedBox(height: Espaces.sm),
                for (final p in d.piecesAgence) LigneDocument(piece: p),
                Text(
                  'Appuyez sur un document pour le télécharger.',
                  style: TextStyle(fontSize: 11, color: n.grise),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _titre(BuildContext context, String texte) => Text(
        texte,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          color: context.cl.encreDouce,
        ),
      );
}

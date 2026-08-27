import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

/// Tous les dossiers, pour un conseiller.
///
/// La liste n'est pas filtrée côté application : la RLS a déjà décidé de ce
/// qui est visible. Un client qui atteindrait cet écran n'y verrait que ses
/// propres dossiers.
class PageAgentDossiers extends StatefulWidget {
  const PageAgentDossiers({super.key});

  @override
  State<PageAgentDossiers> createState() => _PageAgentDossiersState();
}

class _PageAgentDossiersState extends State<PageAgentDossiers> {
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
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final dossiers = [
      for (final d in etat.demandes)
        if (_filtre == null || d.statut == _filtre) d,
    ];

    return Coquille(
      titre: 'Dossiers',
      sousTitre: _resume(etat.demandes),
      routeCourante: '/agent/dossiers',
      retour: false,
      enfants: [
        if (etat.erreurDemarrage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: etat.erreurDemarrage),
          ),
        _filtres(etat.demandes),
        if (dossiers.isEmpty)
          _vide()
        else
          for (final d in dossiers) _CarteDossier(demande: d),
        const SizedBox(height: Espaces.xl),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.lg, Espaces.bord, Espaces.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final s in <String?>[null, ...statutsDemande])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Pastille(
                  libelle: '${s ?? 'Tous'} (${compte(s)})',
                  actif: _filtre == s,
                  onTap: () => setState(() => _filtre = s),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _vide() {
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
            _filtre == null
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
    return Material(
      color: actif ? Palette.orange : context.cl.carte,
      borderRadius: Rayons.brPilule,
      child: InkWell(
        borderRadius: Rayons.brPilule,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: Rayons.brPilule,
            border: Border.all(
              color: actif ? Palette.orange : context.cl.ligne,
            ),
          ),
          child: Text(
            libelle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: actif ? Colors.white : context.cl.encreDouce,
            ),
          ),
        ),
      ),
    );
  }
}

class _CarteDossier extends StatelessWidget {
  const _CarteDossier({required this.demande});

  final Demande demande;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Espaces.bord, 0, Espaces.bord, 10),
      child: Material(
        color: context.cl.carte,
        borderRadius: Rayons.brLg,
        child: InkWell(
          borderRadius: Rayons.brLg,
          onTap: () => Navigator.of(context)
              .pushNamed('/agent/dossier', arguments: demande.id),
          child: Container(
            padding: const EdgeInsets.all(Espaces.lg),
            decoration: BoxDecoration(
              borderRadius: Rayons.brLg,
              border: Border.all(color: context.cl.ligne),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        demande.serviceLibelle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    EtiquetteStatut(statut: demande.statut),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 14, color: context.cl.encreDouce),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        demande.clientNom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.cl.encreDouce,
                        ),
                      ),
                    ),
                    Text(
                      demande.date,
                      style: TextStyle(fontSize: 11.5, color: context.cl.grise),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  demande.resume,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.cl.encreDouce,
                  ),
                ),
                if (demande.pieces.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_file_rounded,
                          size: 13, color: context.cl.grise),
                      const SizedBox(width: 4),
                      Text(
                        '${demande.piecesClient.length} du client'
                        '${demande.piecesAgence.isEmpty ? '' : ', '
                            '${demande.piecesAgence.length} de l\'agence'}',
                        style:
                            TextStyle(fontSize: 11.5, color: context.cl.grise),
                      ),
                    ],
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

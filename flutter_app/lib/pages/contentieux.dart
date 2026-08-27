import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/envoi_demande.dart';
import '../widgets/coquille.dart';

/// Pièces justificatives que l'utilisateur peut joindre à son contentieux.
const _pieces = <String>[
  'Pièce justificative 1',
  'Pièce justificative 2',
  'Pièce justificative 3',
];

class PageContentieux extends StatefulWidget {
  const PageContentieux({super.key});

  @override
  State<PageContentieux> createState() => _PageContentieuxState();
}

class _PageContentieuxState extends State<PageContentieux> with EnvoiDemande {
  final _niu = TextEditingController();
  final _prejudice = TextEditingController();
  String _erreur = '';
  final _fichiers = <String, FichierChoisi>{};

  @override
  void dispose() {
    _niu.dispose();
    _prejudice.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_prejudice.text.trim().isEmpty) {
      setState(() => _erreur = 'Décrivez la nature du préjudice subi.');
      return;
    }

    await envoyerDemande(
      serviceId: 'contentieux',
      serviceLibelle: 'Contentieux fiscal',
      resume: '${_niu.text.trim().isEmpty ? '' : 'NIU ${_niu.text} — '}'
          'Préjudice : ${_prejudice.text.trim()}',
      pieces: [
        for (final e in _fichiers.entries)
          PieceEnvoi(libelle: e.key, fichier: e.value),
      ],
      confirmation: 'Votre contentieux a été transmis à un conseiller.',
      surErreur: (m) => setState(() => _erreur = m),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Coquille(
      titre: 'Contentieux fiscal',
      enfants: [
        const EnTeteService(libelle: 'Contentieux fiscal'),
        const Encadre(
          enfants: [
            Text(
              'Présentez les pièces justificatives qui, selon vous, méritent '
              'que vous vous retrouviez au-devant des procédures contentieuses '
              'fiscales.',
              style: Textes.corpsGras,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Champ(libelle: 'NIU (facultatif)', controleur: _niu),
              const SizedBox(height: 22),
              const Text(
                'QUELLE EST LA NATURE DU PRÉJUDICE SUBI ?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.bleuFonce,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              ZoneTexte(
                libelle: 'Décrivez votre préjudice…',
                controleur: _prejudice,
                lignes: 6,
              ),
              const SizedBox(height: 22),
              Text('JOINDRE VOS DOCUMENTS', style: Textes.libelle(context)),
              const SizedBox(height: 10),
              for (final p in _pieces) ...[
                Televersement(
                  libelle: p,
                  fichier: _fichiers[p],
                  onChoisi: (n) => setState(() => _fichiers[p] = n),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              if (_erreur.isNotEmpty) ...[
                TexteErreur(texte: _erreur),
                const SizedBox(height: 14),
              ],
              BoutonEnvoiDemande(
                enCours: envoiEnCours,
                enfant: BoutonEnvoyer(onTap: _envoyer),
              ),
            ],
          ),
        ),
        const DiscuterAgent(sujet: 'Contentieux fiscal'),
      ],
    );
  }
}

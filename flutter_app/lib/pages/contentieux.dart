import 'package:flutter/material.dart';

import '../api/api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
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

class _PageContentieuxState extends State<PageContentieux> {
  final _niu = TextEditingController();
  final _prejudice = TextEditingController();
  String _erreur = '';
  bool _envoi = false;
  final _fichiers = <String, PieceEnvoi>{};

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

    // Capturés avant l'attente : après un `await`, le contexte peut
    // ne plus être monté.
    final etat = PorteeApp.of(context);
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    setState(() {
      _erreur = '';
      _envoi = true;
    });
    try {
      await etat.envoyerDemande(
        serviceId: 'contentieux',
        serviceLibelle: 'Contentieux fiscal',
        resume: '${_niu.text.trim().isEmpty ? '' : 'NIU ${_niu.text} — '}'
            'Préjudice : ${_prejudice.text.trim()}',
        pieces: _fichiers.values.toList(),
      );
      messager.showSnackBar(
        const SnackBar(
          content: Text('Votre contentieux a été transmis à un conseiller.'),
        ),
      );
      navigateur.pushNamedAndRemoveUntil('/profil', (r) => false);
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
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
                  fichier: _fichiers[p]?.nomFichier,
                  onChoisi: (n) => setState(() => _fichiers[p] = n),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              if (_erreur.isNotEmpty) ...[
                TexteErreur(texte: _erreur),
                const SizedBox(height: 14),
              ],
              BoutonEnvoyer(onTap: _envoyer, enCours: _envoi),
            ],
          ),
        ),
        const DiscuterAgent(sujet: 'Contentieux fiscal'),
      ],
    );
  }
}

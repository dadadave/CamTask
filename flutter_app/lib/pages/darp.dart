import 'package:flutter/material.dart';

import '../api/api.dart';
import '../state/app_state.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

const _pieces = <String>[
  'Bulletin annuel',
  'Liste de tous les biens meubles ou non',
];

class PageDarp extends StatefulWidget {
  const PageDarp({super.key});

  @override
  State<PageDarp> createState() => _PageDarpState();
}

class _PageDarpState extends State<PageDarp> {
  final _niu = TextEditingController();
  String _erreur = '';
  bool _envoi = false;
  final _fichiers = <String, PieceEnvoi>{};

  @override
  void dispose() {
    _niu.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final manquants = <String>[
      if (_niu.text.trim().isEmpty) 'NIU ou numéro de contribuable',
      ..._pieces.where((p) => !_fichiers.containsKey(p)),
    ];
    if (manquants.isNotEmpty) {
      setState(() => _erreur = 'À compléter : ${manquants.join(', ')}.');
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
        serviceId: 'darp',
        serviceLibelle: 'DARP/IRPP',
        resume: 'Déclaration annuelle des revenus des particuliers — '
            'NIU ${_niu.text}',
        pieces: _fichiers.values.toList(),
      );
      messager.showSnackBar(
        const SnackBar(content: Text('DARP/IRPP transmise à nos services.')),
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
      titre: 'DARP/IRPP',
      enfants: [
        const EnTeteService(
          libelle: 'DARP/IRPP',
          sousTitre: 'Déclaration annuelle des revenus des particuliers',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Champ(
                libelle: 'NIU ou numéro de contribuable',
                controleur: _niu,
              ),
              const SizedBox(height: 22),
              for (final p in _pieces) ...[
                Televersement(
                  libelle: p,
                  fichier: _fichiers[p]?.nomFichier,
                  onChoisi: (n) => setState(() => _fichiers[p] = n),
                ),
                const SizedBox(height: 22),
              ],
              if (_erreur.isNotEmpty) ...[
                TexteErreur(texte: _erreur),
                const SizedBox(height: 14),
              ],
              BoutonEnvoyer(onTap: _envoyer, enCours: _envoi),
            ],
          ),
        ),
        const DiscuterAgent(sujet: 'DARP/IRPP'),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/communs.dart';
import '../widgets/envoi_demande.dart';
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

class _PageDarpState extends State<PageDarp> with EnvoiDemande {
  final _niu = TextEditingController();
  String _erreur = '';
  final _fichiers = <String, FichierChoisi>{};

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

    await envoyerDemande(
      serviceId: 'darp',
      serviceLibelle: 'DARP/IRPP',
      resume: 'Déclaration annuelle des revenus des particuliers — '
          'NIU ${_niu.text}',
      pieces: [
        for (final e in _fichiers.entries)
          PieceEnvoi(libelle: e.key, fichier: e.value),
      ],
      confirmation: 'DARP/IRPP transmise à nos services.',
      surErreur: (m) => setState(() => _erreur = m),
    );
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
                  fichier: _fichiers[p],
                  onChoisi: (n) => setState(() => _fichiers[p] = n),
                ),
                const SizedBox(height: 22),
              ],
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
        const DiscuterAgent(sujet: 'DARP/IRPP'),
      ],
    );
  }
}

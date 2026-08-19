import 'package:flutter/material.dart';

import '../data/dsf.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

class PageDsf extends StatefulWidget {
  const PageDsf({super.key});

  @override
  State<PageDsf> createState() => _PageDsfState();
}

class _PageDsfState extends State<PageDsf> {
  final _niu = TextEditingController();
  final _entreprise = TextEditingController();
  String _destination = '';
  String _erreur = '';
  final _fichiers = <String, String>{};

  @override
  void dispose() {
    _niu.dispose();
    _entreprise.dispose();
    super.dispose();
  }

  void _envoyer() {
    final manquants = <String>[
      if (_niu.text.trim().isEmpty) 'NIU',
      if (_destination.isEmpty) 'DSF pour impôt ou pour la banque',
      if (_entreprise.text.trim().isEmpty)
        "Type d'entreprise et nature de vos activités",
    ];
    if (manquants.isNotEmpty) {
      setState(() => _erreur = 'À compléter : ${manquants.join(', ')}.');
      return;
    }

    final pieces = [
      for (final e in _fichiers.entries)
        Piece(libelle: e.key, fichier: e.value),
    ];
    PorteeApp.of(context).envoyerDemande(
      serviceId: 'dsf',
      serviceLibelle: 'DSF — Déclaration statistique et fiscale',
      resume: 'NIU ${_niu.text} — $_destination — ${_entreprise.text}',
      pieces: pieces,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('DSF transmise (${pieces.length} pièce(s) jointe(s)).'),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/profil', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Coquille(
      titre: 'DSF',
      enfants: [
        const EnTeteService(
          libelle: 'DSF',
          sousTitre: 'Déclaration statistique et fiscale',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Champ(libelle: 'NIU', controleur: _niu),
              const SizedBox(height: 22),
              const Text(
                'DSF POUR IMPÔT OU DSF POUR LA BANQUE ?',
                style: Textes.libelle,
              ),
              const SizedBox(height: 10),
              Pastilles(
                options: destinationsDsf,
                selection: _destination.isEmpty ? const [] : [_destination],
                larges: true,
                onBascule: (v) => setState(() {
                  _destination = _destination == v ? '' : v;
                  _erreur = '';
                }),
              ),
              const SizedBox(height: 22),
              ZoneTexte(
                libelle: "Type d'entreprise et nature de vos activités",
                controleur: _entreprise,
                lignes: 3,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 22, 14, 16),
          child: Text(
            'Télécharger les documents en un seul PDF dans chacune des sections.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
        for (final section in sectionsDsf)
          Encadre(
            enfants: [
              TitrePanneau(texte: section.titre),
              for (final doc in section.documents) ...[
                Televersement(
                  libelle: doc,
                  fichier: _fichiers[doc],
                  onChoisi: (n) => setState(() => _fichiers[doc] = n),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_erreur.isNotEmpty) ...[
                TexteErreur(texte: _erreur),
                const SizedBox(height: 14),
              ],
              BoutonEnvoyer(onTap: _envoyer),
            ],
          ),
        ),
        const DiscuterAgent(sujet: 'DSF'),
      ],
    );
  }
}

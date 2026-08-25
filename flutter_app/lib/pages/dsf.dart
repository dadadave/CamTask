import 'package:flutter/material.dart';

import '../data/dsf.dart';
import '../api/api.dart';
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
  bool _envoi = false;
  final _fichiers = <String, PieceEnvoi>{};

  @override
  void dispose() {
    _niu.dispose();
    _entreprise.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
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

    final pieces = _fichiers.values.toList();
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
        serviceId: 'dsf',
        serviceLibelle: 'DSF — Déclaration statistique et fiscale',
        resume: 'NIU ${_niu.text} — $_destination — ${_entreprise.text}',
        pieces: pieces,
      );
      messager.showSnackBar(
        SnackBar(
          content: Text('DSF transmise (${pieces.length} pièce(s) jointe(s)).'),
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
              Text(
                'DSF POUR IMPÔT OU DSF POUR LA BANQUE ?',
                style: Textes.libelle(context),
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
                  fichier: _fichiers[doc]?.nomFichier,
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
              BoutonEnvoyer(onTap: _envoyer, enCours: _envoi),
            ],
          ),
        ),
        const DiscuterAgent(sujet: 'DSF'),
      ],
    );
  }
}

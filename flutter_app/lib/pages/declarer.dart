import 'package:flutter/material.dart';

import '../api/api.dart';
import '../state/app_state.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

const _typesImpots = <String>[
  'IRPP — Impôt sur le revenu des personnes physiques',
  'IS — Impôt sur les sociétés',
  'TVA — Taxe sur la valeur ajoutée',
  'Patente',
  'Licence',
  'Précompte sur achats',
  "Droit d'accises",
  'Taxe foncière',
  'Acompte mensuel IR',
  'TSR — Taxe spéciale sur le revenu',
  'Autre impôt ou taxe',
];

const _pieces = <String>[
  "Facture d'achats",
  'Liste des déclarations déjà effectuées',
];

class PageDeclarer extends StatefulWidget {
  const PageDeclarer({super.key});

  @override
  State<PageDeclarer> createState() => _PageDeclarerState();
}

class _PageDeclarerState extends State<PageDeclarer> {
  final _niu = TextEditingController();
  final _montant = TextEditingController();
  final _nature = TextEditingController();
  String? _type;
  String _erreur = '';
  bool _envoi = false;
  final _fichiers = <String, PieceEnvoi>{};

  @override
  void dispose() {
    _niu.dispose();
    _montant.dispose();
    _nature.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final manquants = <String>[
      if (_niu.text.trim().isEmpty) 'NIU',
      if (_type == null) "Type d'impôts",
      if (_montant.text.trim().isEmpty) 'Montant',
      if (_nature.text.trim().isEmpty) "Nature de l'activité",
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
        serviceId: 'declarer',
        serviceLibelle: 'Declarer et payer vos impots',
        resume: 'NIU ${_niu.text} — $_type — ${_montant.text} FCFA — '
            'Activité : ${_nature.text}',
        pieces: _fichiers.values.toList(),
      );
      messager.showSnackBar(
        const SnackBar(
          content: Text('Déclaration transmise. Un agent valide le montant à payer.'),
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
      titre: 'Déclarer et payer',
      enfants: [
        const EnTeteService(libelle: 'Declarer et payer vos impots'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Champ(libelle: 'NIU', controleur: _niu),
              const SizedBox(height: 22),
              Selecteur(
                libelle: "Type d'impôts",
                valeur: _type,
                options: _typesImpots,
                onChange: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 22),
              Champ(
                libelle: 'Montants',
                controleur: _montant,
                clavier: TextInputType.number,
                aide: 'Montant en FCFA',
              ),
              const SizedBox(height: 22),
              Champ(libelle: "Nature de l'activité", controleur: _nature),
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
        const DiscuterAgent(sujet: 'Declarer et payer vos impots'),
      ],
    );
  }
}

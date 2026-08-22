import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

/// L'utilisateur choisit le NIU, l'ACF, ou les deux.
const _demarches = <String>['NIU', 'ACF'];

const _typesNiu = <String>[
  'NIU pour personne physique',
  'NIU pour personne morale',
];

const _activites = <String>[
  'Salarié',
  'Commerçant',
  'Profession libérale',
  'Artisan',
  'Agriculteur / éleveur',
  'Transporteur',
  'Prestataire de services',
  'Société / entreprise',
  'Étudiant / sans emploi',
  'Autre activité',
];

/// L'ACF va de pair avec l'attestation d'immatriculation.
const _attestations = <String>[
  'ACF — Attestation de conformité fiscale',
  "Attestation d'immatriculation",
];

const _libelleCni = 'Importer votre CNI';

class PageNiuAcf extends StatefulWidget {
  const PageNiuAcf({super.key});

  @override
  State<PageNiuAcf> createState() => _PageNiuAcfState();
}

class _PageNiuAcfState extends State<PageNiuAcf> {
  final _demarchesChoisies = <String>[];
  String _erreur = '';
  final _fichiers = <String, String>{};

  // Bloc NIU
  final _telephone = TextEditingController();
  String? _activite;
  String? _typeNiu;

  // Bloc ACF / attestation d'immatriculation
  final _niu = TextEditingController();
  final _attestationsChoisies = <String>[];

  bool get _veutNiu => _demarchesChoisies.contains('NIU');
  bool get _veutAcf => _demarchesChoisies.contains('ACF');

  @override
  void dispose() {
    _telephone.dispose();
    _niu.dispose();
    super.dispose();
  }

  void _envoyer() {
    if (_demarchesChoisies.isEmpty) {
      setState(() => _erreur = 'Choisissez le NIU, l’ACF, ou les deux.');
      return;
    }

    final manquants = <String>[];
    if (_veutNiu) {
      if (_telephone.text.trim().isEmpty) manquants.add('Numéro de téléphone');
      if (_activite == null) manquants.add("Type d'activité professionnelle");
      if (_typeNiu == null) manquants.add('Type de NIU');
      if (!_fichiers.containsKey(_libelleCni)) manquants.add('CNI');
    }
    if (_veutAcf) {
      if (_niu.text.trim().isEmpty) manquants.add('NIU (pour l’ACF)');
      if (_attestationsChoisies.isEmpty) manquants.add('Document souhaité');
    }
    if (manquants.isNotEmpty) {
      setState(() => _erreur = 'À compléter : ${manquants.join(', ')}.');
      return;
    }

    PorteeApp.of(context).envoyerDemande(
      serviceId: 'niu-acf',
      serviceLibelle: 'Acquérir son ${_demarchesChoisies.join(' / ')}',
      resume: [
        if (_veutNiu)
          'NIU : $_typeNiu, activité $_activite, tél. ${_telephone.text}',
        if (_veutAcf)
          '${_attestationsChoisies.join(' + ')} — NIU ${_niu.text}',
      ].join('\n'),
      pieces: [
        for (final e in _fichiers.entries)
          Piece(libelle: e.key, fichier: e.value),
      ],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande envoyée. Un agent traite votre dossier.'),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/profil', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Coquille(
      titre: 'NIU / ACF',
      enfants: [
        const EnTeteService(libelle: 'Acquérir son NIU / ACF'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'QUE SOUHAITEZ-VOUS FAIRE ? (NIU, ACF OU LES DEUX)',
                style: Textes.libelle(context),
              ),
              const SizedBox(height: 10),
              Pastilles(
                options: _demarches,
                selection: _demarchesChoisies,
                larges: true,
                onBascule: (v) => setState(() {
                  if (_demarchesChoisies.contains(v)) {
                    _demarchesChoisies.remove(v);
                  } else {
                    _demarchesChoisies.add(v);
                  }
                  _erreur = '';
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_veutNiu)
          Encadre(
            enfants: [
              const TitrePanneau(texte: 'Acquérir son NIU'),
              Champ(
                libelle: 'Numéro de téléphone',
                controleur: _telephone,
                clavier: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              Selecteur(
                libelle: "Type d'activité professionnelle",
                valeur: _activite,
                options: _activites,
                onChange: (v) => setState(() => _activite = v),
              ),
              const SizedBox(height: 18),
              Selecteur(
                libelle: 'Type de NIU',
                valeur: _typeNiu,
                options: _typesNiu,
                encadre: true,
                onChange: (v) => setState(() => _typeNiu = v),
              ),
              const SizedBox(height: 18),
              Televersement(
                libelle: _libelleCni,
                fichier: _fichiers[_libelleCni],
                onChoisi: (n) => setState(() => _fichiers[_libelleCni] = n),
              ),
            ],
          ),
        if (_veutAcf)
          Encadre(
            enfants: [
              const TitrePanneau(
                texte: "ACF / Attestation d'immatriculation",
              ),
              Champ(libelle: 'NIU', controleur: _niu),
              const SizedBox(height: 18),
              Text('DOCUMENT SOUHAITÉ', style: Textes.libelle(context)),
              const SizedBox(height: 10),
              Pastilles(
                options: _attestations,
                selection: _attestationsChoisies,
                larges: true,
                onBascule: (v) => setState(() {
                  if (_attestationsChoisies.contains(v)) {
                    _attestationsChoisies.remove(v);
                  } else {
                    _attestationsChoisies.add(v);
                  }
                }),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
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
        const DiscuterAgent(sujet: 'Acquérir son NIU / ACF'),
      ],
    );
  }
}

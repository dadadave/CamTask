import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/illustrations.dart';

/// Pièces exigées à l'inscription, selon le profil.
const _piecesUtilisateur = <String>[
  'Photo de la CNI',
  "Numéro d'identifiant unique (NIU) — justificatif",
];

const _piecesEmploye = <String>[
  'CNI',
  'Plan de localisation',
  'Carte / attestation de numéro de contribuable',
  "CNI d'un garant qui se porte caution",
];

class PageAuth extends StatefulWidget {
  const PageAuth({super.key});

  @override
  State<PageAuth> createState() => _PageAuthState();
}

class _PageAuthState extends State<PageAuth> {
  bool _inscription = false;
  Role _role = Role.utilisateur;
  String _erreur = '';
  final _fichiers = <String, String>{};

  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _niu = TextEditingController();
  final _motDePasse = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _email, _telephone, _niu, _motDePasse]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _piecesRequises =>
      _role == Role.utilisateur ? _piecesUtilisateur : _piecesEmploye;

  List<Piece> get _pieces => [
        for (final e in _fichiers.entries)
          Piece(libelle: e.key, fichier: e.value),
      ];

  void _connexion() {
    if (_email.text.trim().isEmpty || _motDePasse.text.trim().isEmpty) {
      setState(() => _erreur = 'Renseignez votre email et votre mot de passe.');
      return;
    }
    PorteeApp.of(context).seConnecter(
      Compte(
        role: Role.utilisateur,
        nom: _nom.text.isNotEmpty ? _nom.text : _email.text.split('@').first,
        prenom: _prenom.text,
        email: _email.text,
        telephone: _telephone.text,
        niu: _niu.text,
        pieces: const [],
        creeLe: AppState.dateDuJour(),
      ),
    );
    _terminer('Bienvenue sur CAM-TAXE.');
  }

  void _inscrire() {
    final manquants = <String>[];
    if (_role == Role.utilisateur) {
      if (_nom.text.trim().isEmpty) manquants.add('Nom');
      if (_prenom.text.trim().isEmpty) manquants.add('Prénom');
    } else if (_nom.text.trim().isEmpty) {
      manquants.add('Nom et prénom');
    }
    if (_email.text.trim().isEmpty) manquants.add('Email');
    if (_telephone.text.trim().isEmpty) manquants.add('Numéro de téléphone');
    if (_niu.text.trim().isEmpty) {
      manquants.add(_role == Role.utilisateur
          ? "Numéro d'identifiant unique"
          : 'Numéro de contribuable');
    }
    if (_role == Role.utilisateur && _motDePasse.text.trim().isEmpty) {
      manquants.add('Mot de passe');
    }
    manquants.addAll(_piecesRequises.where((p) => !_fichiers.containsKey(p)));

    if (manquants.isNotEmpty) {
      setState(() => _erreur = 'À compléter : ${manquants.join(', ')}.');
      return;
    }

    PorteeApp.of(context).seConnecter(
      Compte(
        role: _role,
        nom: _nom.text,
        prenom: _prenom.text,
        email: _email.text,
        telephone: _telephone.text,
        niu: _niu.text,
        pieces: _pieces,
        creeLe: AppState.dateDuJour(),
      ),
    );
    _terminer('Compte créé. Vous pouvez maintenant utiliser nos services.');
  }

  void _terminer(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pushNamedAndRemoveUntil('/accueil', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const IllustrationTax(),
          Transform.translate(
            offset: const Offset(0, -34),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              decoration: BoxDecoration(
                color: Palette.carte,
                borderRadius: BorderRadius.circular(18),
                boxShadow: ombreCarte,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Onglet(
                        libelle: 'sign in',
                        actif: !_inscription,
                        onTap: () => setState(() {
                          _inscription = false;
                          _erreur = '';
                        }),
                      ),
                      _Onglet(
                        libelle: 'sign up',
                        actif: _inscription,
                        onTap: () => setState(() {
                          _inscription = true;
                          _erreur = '';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (_inscription) ..._champsInscription() else ..._champsConnexion(),
                  if (_erreur.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TexteErreur(texte: _erreur),
                  ],
                  const SizedBox(height: 26),
                  Center(
                    child: Material(
                      color: Palette.orangeClair,
                      borderRadius: BorderRadius.circular(999),
                      elevation: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _inscription ? _inscrire : _connexion,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 170),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          child: Text(
                            _inscription ? 'sign up' : 'sign in',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Il faut au préalable créer un compte pour bénéficier de '
                    'nos services.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Palette.encreDouce),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _champsConnexion() => [
        Champ(
          libelle: 'Email',
          controleur: _email,
          clavier: TextInputType.emailAddress,
          majuscules: false,
        ),
        const SizedBox(height: 18),
        Champ(
          libelle: 'mot de passe',
          controleur: _motDePasse,
          masque: true,
          majuscules: false,
        ),
      ];

  List<Widget> _champsInscription() => [
        Row(
          children: [
            Expanded(
              child: _BoutonRole(
                libelle: 'Utilisateur',
                actif: _role == Role.utilisateur,
                onTap: () => setState(() => _role = Role.utilisateur),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BoutonRole(
                libelle: 'Personne employée',
                actif: _role == Role.employe,
                onTap: () => setState(() => _role = Role.employe),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_role == Role.utilisateur) ...[
          Champ(libelle: 'Nom', controleur: _nom, majuscules: false),
          const SizedBox(height: 18),
          Champ(libelle: 'Prénom', controleur: _prenom, majuscules: false),
        ] else
          Champ(libelle: 'Nom et prénom', controleur: _nom, majuscules: false),
        const SizedBox(height: 18),
        Champ(
          libelle: 'Email',
          controleur: _email,
          clavier: TextInputType.emailAddress,
          majuscules: false,
        ),
        const SizedBox(height: 18),
        Champ(
          libelle: 'Numéro de téléphone',
          controleur: _telephone,
          clavier: TextInputType.phone,
          majuscules: false,
        ),
        const SizedBox(height: 18),
        Champ(
          libelle: _role == Role.utilisateur
              ? "Numéro d'identifiant unique (NIU)"
              : 'Numéro de contribuable',
          controleur: _niu,
          majuscules: false,
        ),
        if (_role == Role.utilisateur) ...[
          const SizedBox(height: 18),
          Champ(
            libelle: 'mot de passe',
            controleur: _motDePasse,
            masque: true,
            majuscules: false,
          ),
        ],
        const SizedBox(height: 20),
        const Text('PIÈCES À FOURNIR', style: Textes.libelle),
        const SizedBox(height: 10),
        for (final p in _piecesRequises) ...[
          Televersement(
            libelle: p,
            fichier: _fichiers[p],
            onChoisi: (n) => setState(() => _fichiers[p] = n),
          ),
          const SizedBox(height: 10),
        ],
      ];
}

class _Onglet extends StatelessWidget {
  const _Onglet({
    required this.libelle,
    required this.actif,
    required this.onTap,
  });

  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: actif
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Palette.orange, width: 2),
                ),
              )
            : null,
        child: Text(
          libelle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: actif ? Palette.orange : Palette.grise,
          ),
        ),
      ),
    );
  }
}

class _BoutonRole extends StatelessWidget {
  const _BoutonRole({
    required this.libelle,
    required this.actif,
    required this.onTap,
  });

  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(
          color: actif ? Palette.orange : Colors.transparent,
          border: Border.all(color: actif ? Palette.orange : Palette.ligne),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          libelle.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: actif ? Colors.white : Palette.encreDouce,
          ),
        ),
      ),
    );
  }
}

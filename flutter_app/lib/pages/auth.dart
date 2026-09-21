import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/illustrations.dart';

/// Les trois profils que l'on peut choisir à l'inscription.
///
/// Deux dimensions se cachent derrière : [Role] décide des pièces à
/// fournir, [TypeClient] décide du tarif. Un conseiller n'est pas un
/// client — il ne sera facturé de rien, et devra être validé.
enum Profil { particulier, entreprise, conseiller }

extension _ProfilDetails on Profil {
  String get libelle => switch (this) {
        Profil.particulier => 'Particulier',
        Profil.entreprise => 'Entreprise',
        Profil.conseiller => 'Conseiller',
      };

  String get precision => switch (this) {
        Profil.particulier => 'Pour moi-même',
        Profil.entreprise => 'Pour ma société',
        Profil.conseiller => 'Rejoindre l\'équipe',
      };

  Role get role =>
      this == Profil.conseiller ? Role.employe : Role.utilisateur;

  TypeClient get typeClient => this == Profil.entreprise
      ? TypeClient.entreprise
      : TypeClient.particulier;

  List<String> get pieces => switch (this) {
        Profil.particulier => const [
            'Photo de la CNI',
            "Numéro d'identifiant unique (NIU) — justificatif",
          ],
        // À confirmer : cette liste est une proposition, pas une consigne
        // de l'agence.
        Profil.entreprise => const [
            'Registre de commerce',
            "Numéro d'identifiant unique (NIU) de la société",
            'CNI du gérant',
            'Plan de localisation',
          ],
        Profil.conseiller => const [
            'CNI',
            'Plan de localisation',
            'Carte / attestation de numéro de contribuable',
            "CNI d'un garant qui se porte caution",
          ],
      };
}

class PageAuth extends StatefulWidget {
  const PageAuth({super.key});

  @override
  State<PageAuth> createState() => _PageAuthState();
}

class _PageAuthState extends State<PageAuth> {
  bool _inscription = false;
  Profil _profil = Profil.particulier;
  String _erreur = '';

  /// Un appel réseau est en cours : le bouton laisse place à une attente,
  /// ce qui évite aussi une double inscription sur double appui.
  bool _envoi = false;

  final _fichiers = <String, FichierChoisi>{};

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

  List<String> get _piecesRequises => _profil.pieces;

  List<PieceEnvoi> get _pieces => [
        for (final e in _fichiers.entries)
          PieceEnvoi(libelle: e.key, fichier: e.value),
      ];

  /// Exécute [action] en montrant l'attente, puis navigue — ou affiche le
  /// message d'erreur renvoyé par le back-end, déjà en français.
  Future<void> _executer(
    Future<void> Function() action,
    String message,
  ) async {
    setState(() {
      _envoi = true;
      _erreur = '';
    });
    try {
      await action();
      if (!mounted) return;
      _terminer(message);
    } on ErreurBackend catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _connexion() async {
    if (_email.text.trim().isEmpty || _motDePasse.text.trim().isEmpty) {
      setState(() => _erreur = 'Renseignez votre email et votre mot de passe.');
      return;
    }
    final etat = PorteeApp.of(context);
    await _executer(
      () => etat.connexion(_email.text.trim(), _motDePasse.text),
      'Bienvenue sur CAM-TAXE.',
    );
  }

  Future<void> _inscrire() async {
    final manquants = <String>[];
    if (_profil != Profil.conseiller) {
      if (_nom.text.trim().isEmpty) manquants.add('Nom');
      if (_prenom.text.trim().isEmpty) manquants.add('Prénom');
    } else if (_nom.text.trim().isEmpty) {
      manquants.add('Nom et prénom');
    }
    if (_email.text.trim().isEmpty) manquants.add('Email');
    if (_telephone.text.trim().isEmpty) manquants.add('Numéro de téléphone');
    if (_niu.text.trim().isEmpty) {
      manquants.add(_profil == Profil.conseiller
          ? 'Numéro de contribuable'
          : "Numéro d'identifiant unique");
    }
    // Le mot de passe vaut pour les deux profils : l'authentification
    // Supabase en exige un pour chaque compte.
    if (_motDePasse.text.trim().isEmpty) manquants.add('Mot de passe');
    manquants.addAll(_piecesRequises.where((p) => !_fichiers.containsKey(p)));

    if (manquants.isNotEmpty) {
      setState(() => _erreur = 'À compléter : ${manquants.join(', ')}.');
      return;
    }

    final etat = PorteeApp.of(context);
    await _executer(
      () => etat.inscription(
        role: _profil.role,
        typeClient: _profil.typeClient,
        nom: _nom.text.trim(),
        prenom: _prenom.text.trim(),
        email: _email.text.trim(),
        telephone: _telephone.text.trim(),
        niu: _niu.text.trim(),
        motDePasse: _motDePasse.text,
        pieces: _pieces,
      ),
      'Compte créé. Vous pouvez maintenant utiliser nos services.',
    );
  }

  void _terminer(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    // Chacun chez soi : un conseiller atterrit sur ses dossiers, un client
    // sur l'accueil des services.
    final route = PorteeApp.of(context).routeAccueil;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
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
              margin: const EdgeInsets.symmetric(horizontal: Espaces.bord),
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
              decoration: BoxDecoration(
                color: context.cl.carte,
                borderRadius: Rayons.brXl,
                boxShadow: context.cl.ombreForte,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.cl.fondDoux,
                      borderRadius: Rayons.brPilule,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Onglet(
                            libelle: 'Connexion',
                            actif: !_inscription,
                            onTap: () => setState(() {
                              _inscription = false;
                              _erreur = '';
                            }),
                          ),
                        ),
                        Expanded(
                          child: _Onglet(
                            libelle: 'Inscription',
                            actif: _inscription,
                            onTap: () => setState(() {
                              _inscription = true;
                              _erreur = '';
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_inscription) ..._champsInscription() else ..._champsConnexion(),
                  if (_erreur.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TexteErreur(texte: _erreur),
                  ],
                  const SizedBox(height: 26),
                  if (_envoi)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Palette.orange,
                          ),
                        ),
                      ),
                    )
                  else
                    BoutonEnvoyer(
                      bloc: true,
                      libelle:
                          _inscription ? 'Créer mon compte' : 'Se connecter',
                      icone: Icons.arrow_forward_rounded,
                      onTap: _inscription ? _inscrire : _connexion,
                    ),
                  const SizedBox(height: Espaces.lg),
                  Text(
                    'Il faut au préalable créer un compte pour bénéficier de '
                    'nos services.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: context.cl.encreDouce,
                    ),
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
        const LibelleSection(texte: 'Vous êtes'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final p in Profil.values) ...[
              if (p != Profil.values.first) const SizedBox(width: 8),
              Expanded(
                child: _BoutonRole(
                  libelle: p.libelle,
                  precision: p.precision,
                  actif: _profil == p,
                  onTap: () => setState(() {
                    _profil = p;
                    // Les pièces changent avec le profil : celles déjà
                    // choisies ne correspondent plus.
                    _fichiers.clear();
                    _erreur = '';
                  }),
                ),
              ),
            ],
          ],
        ),
        if (_profil == Profil.conseiller) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(Espaces.md),
            decoration: BoxDecoration(
              color: context.cl.bleuFantome,
              borderRadius: Rayons.brSm,
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: context.cl.bleuTexte),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Votre candidature sera examinée par CAM-TAXE. Vous '
                    'accéderez aux dossiers une fois validée.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: context.cl.encreDouce,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (_profil == Profil.particulier) ...[
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
          libelle: switch (_profil) {
            Profil.particulier => "Numéro d'identifiant unique (NIU)",
            Profil.entreprise => 'NIU de la société',
            Profil.conseiller => 'Numéro de contribuable',
          },
          controleur: _niu,
          majuscules: false,
        ),
        // Demandé aux deux profils : Supabase exige un mot de passe pour
        // chaque compte.
        const SizedBox(height: 18),
        Champ(
          libelle: 'mot de passe',
          controleur: _motDePasse,
          masque: true,
          majuscules: false,
        ),
        const SizedBox(height: 20),
        const LibelleSection(texte: 'Pièces à fournir'),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: actif ? Degrades.orange : null,
          borderRadius: Rayons.brPilule,
          boxShadow: actif ? ombreOrange : null,
        ),
        child: Text(
          libelle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: actif ? Colors.white : context.cl.encreDouce,
          ),
        ),
      ),
    );
  }
}

class _BoutonRole extends StatelessWidget {
  const _BoutonRole({
    required this.libelle,
    required this.precision,
    required this.actif,
    required this.onTap,
  });

  final String libelle;

  /// Une ligne qui lève l'ambiguïté : « Particulier » et « Entreprise » ne
  /// disent pas d'eux-mêmes qu'il s'agit de tarifs différents.
  final String precision;
  final bool actif;
  final VoidCallback onTap;

  IconData get _icone => switch (libelle) {
        'Entreprise' => Icons.business_outlined,
        'Conseiller' => Icons.badge_outlined,
        _ => Icons.person_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          color: actif ? context.cl.orangeFantome : context.cl.carte,
          border: Border.all(
            color: actif ? context.cl.accentTexte : context.cl.ligne,
            width: actif ? 1.6 : 1,
          ),
          borderRadius: Rayons.brSm,
        ),
        child: Column(
          children: [
            Icon(
              _icone,
              size: 20,
              color: actif ? context.cl.accentTexte : context.cl.grise,
            ),
            const SizedBox(height: 5),
            Text(
              libelle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: actif ? context.cl.accentTexte : context.cl.encre,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              precision,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.25,
                color: actif ? context.cl.accentTexte : context.cl.grise,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

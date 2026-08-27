import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import '../supabase_config.dart';
import 'backend.dart';

/// Back-end adossé à Supabase : Auth, Postgres et Storage.
///
/// Le profil n'est pas créé depuis l'application : le déclencheur
/// `on_auth_user_created` de `supabase/schema.sql` le construit à partir des
/// métadonnées passées à `signUp`. Cela évite un aller-retour et garantit
/// qu'un compte a toujours son profil.
class BackendSupabase implements Backend {
  const BackendSupabase();

  static const _bucket = 'pieces';

  SupabaseClient get _client {
    if (!supabaseConfigure) throw const ErreurBackend(messageConfigAbsente);
    return Supabase.instance.client;
  }

  /* ---------------------------------------------------------------------- */
  /*  Erreurs                                                               */
  /* ---------------------------------------------------------------------- */

  /// Traduit les messages techniques de Supabase en phrases affichables.
  static String _traduire(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (m.contains('email not confirmed')) {
      return "Votre email n'est pas encore confirmé. Vérifiez votre boîte de "
          'réception.';
    }
    if (m.contains('user already registered') ||
        m.contains('already been registered')) {
      return 'Un compte existe déjà avec cet email. Connectez-vous.';
    }
    if (m.contains('password should be')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (m.contains('unable to validate email') || m.contains('invalid email')) {
      return "L'adresse email n'est pas valide.";
    }
    if (m.contains('failed host lookup') ||
        m.contains('socketexception') ||
        m.contains('failed to fetch') ||
        m.contains('network')) {
      return 'Connexion au serveur impossible. Vérifiez votre accès à '
          'Internet.';
    }
    if (m.contains('row-level security') || m.contains('violates row-level')) {
      return "Vous n'avez pas l'autorisation d'effectuer cette action.";
    }
    if (m.contains('exceeded the maximum allowed size') ||
        m.contains('payload too large')) {
      return 'Ce document est trop volumineux pour être envoyé.';
    }
    // Le schéma n'a pas été exécuté sur le projet : sans ce message, on ne
    // voit qu'un code PGRST205 incompréhensible.
    if (m.contains('could not find the table') || m.contains('does not exist')) {
      return 'La base du projet Supabase est vide : exécutez '
          'supabase/schema.sql dans le SQL Editor.';
    }
    return message;
  }

  static Never _echouer(String message, [Object? cause]) {
    throw ErreurBackend(_traduire(message), cause);
  }

  /// Exécute [action] en convertissant toute erreur Supabase en
  /// [ErreurBackend]. Sans cela, une panne réseau remonterait jusqu'à
  /// l'écran sous forme de trace technique.
  static Future<T> _garder<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ErreurBackend {
      rethrow;
    } on AuthException catch (e) {
      _echouer(e.message, e);
    } on PostgrestException catch (e) {
      _echouer(e.message, e);
    } on StorageException catch (e) {
      _echouer(e.message, e);
    } catch (e) {
      _echouer(e.toString(), e);
    }
  }

  /* ---------------------------------------------------------------------- */
  /*  Utilitaires                                                           */
  /* ---------------------------------------------------------------------- */

  static final _alea = Random.secure();

  /// Identifiant aléatoire, pour qu'un même nom de fichier déposé deux fois
  /// n'écrase pas la version précédente.
  static String _jeton() {
    const chiffres = '0123456789abcdef';
    return List.generate(24, (_) => chiffres[_alea.nextInt(16)]).join();
  }

  /// Rend un nom de fichier utilisable comme clé de stockage.
  static String _assainir(String nom) {
    final sansAccent = nom
        .replaceAll(RegExp('[àáâãäå]'), 'a')
        .replaceAll(RegExp('[èéêë]'), 'e')
        .replaceAll(RegExp('[ìíîï]'), 'i')
        .replaceAll(RegExp('[òóôõö]'), 'o')
        .replaceAll(RegExp('[ùúûü]'), 'u')
        .replaceAll('ç', 'c');
    final propre = sansAccent.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
    return propre.length <= 80
        ? propre
        : propre.substring(propre.length - 80);
  }

  /// Déduit le type du document de son extension, pour que le fichier
  /// s'ouvre correctement quand on le relit depuis le bucket.
  static String? _typeMime(String nom) {
    final ext = nom.contains('.') ? nom.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => null,
    };
  }

  static String _dateFr(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<String> _idUtilisateur() async {
    final user = _client.auth.currentUser;
    if (user == null) _echouer('Votre session a expiré. Reconnectez-vous.');
    return user.id;
  }

  /* ---------------------------------------------------------------------- */
  /*  Pièces jointes                                                        */
  /* ---------------------------------------------------------------------- */

  /// Dépose les fichiers dans le bucket privé puis les référence en base.
  ///
  /// [demandeId] est nul pour les pièces fournies à l'inscription. Le chemin
  /// commence par l'identifiant du propriétaire : c'est ce que la policy de
  /// stockage vérifie.
  Future<List<Piece>> _televerser(
    String uid,
    List<PieceEnvoi> pieces,
    String? demandeId,
  ) async {
    final deposees = <Piece>[];

    for (final piece in pieces) {
      final fichier = piece.fichier;
      final dossier = demandeId ?? 'compte';
      final chemin = '$uid/$dossier/${_jeton()}-${_assainir(fichier.nom)}';

      try {
        await _client.storage.from(_bucket).uploadBinary(
              chemin,
              fichier.octets,
              fileOptions: FileOptions(contentType: _typeMime(fichier.nom)),
            );
      } on StorageException catch (e) {
        _echouer('Envoi de « ${piece.libelle} » impossible : ${e.message}', e);
      }

      await _client.from('pieces').insert({
        'user_id': uid,
        'demande_id': demandeId,
        'label': piece.libelle,
        'chemin': chemin,
        'nom_fichier': fichier.nom,
      });

      deposees.add(Piece(libelle: piece.libelle, fichier: fichier.nom));
    }

    return deposees;
  }

  /// Les pièces du compte : celles de l'inscription, sans demande rattachée.
  Future<List<Piece>> _piecesDuCompte(String uid) async {
    final lignes = await _client
        .from('pieces')
        .select('label, nom_fichier')
        .eq('user_id', uid)
        .isFilter('demande_id', null);

    return [
      for (final l in lignes)
        Piece(
          libelle: l['label'] as String? ?? '',
          fichier: l['nom_fichier'] as String? ?? '',
        ),
    ];
  }

  /* ---------------------------------------------------------------------- */
  /*  Profil                                                                */
  /* ---------------------------------------------------------------------- */

  Future<Compte> _compteDepuisProfil(String uid, String email) async {
    final ligne = await _client
        .from('profiles')
        .select('role, nom, prenom, telephone, niu, cree_le')
        .eq('id', uid)
        .single();

    return Compte(
      role: Role.values.firstWhere(
        (r) => r.name == ligne['role'],
        orElse: () => Role.utilisateur,
      ),
      nom: ligne['nom'] as String? ?? '',
      prenom: ligne['prenom'] as String? ?? '',
      email: email,
      telephone: ligne['telephone'] as String? ?? '',
      niu: ligne['niu'] as String? ?? '',
      pieces: await _piecesDuCompte(uid),
      creeLe: _dateFr(ligne['cree_le'] as String?),
    );
  }

  /* ---------------------------------------------------------------------- */
  /*  Authentification                                                      */
  /* ---------------------------------------------------------------------- */

  @override
  Future<Compte?> sessionActuelle() {
    return _garder(() async {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return _compteDepuisProfil(user.id, user.email ?? '');
    });
  }

  @override
  Future<Compte> inscription({
    required Role role,
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String niu,
    required String motDePasse,
    List<PieceEnvoi> pieces = const [],
  }) {
    return _garder(() async {
      final res = await _client.auth.signUp(
        email: email,
        password: motDePasse,
        data: {
          'role': role.name,
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'niu': niu,
        },
      );

      // Sans session, la RLS refusera le dépôt des pièces : c'est le cas
      // quand la confirmation par email est activée sur le projet.
      final user = res.user;
      if (res.session == null || user == null) {
        _echouer(
          'Compte créé. Confirmez votre email, puis connectez-vous pour '
          'transmettre vos pièces justificatives.',
        );
      }

      await _televerser(user.id, pieces, null);
      return _compteDepuisProfil(user.id, email);
    });
  }

  @override
  Future<Compte> connexion(String email, String motDePasse) {
    return _garder(() async {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: motDePasse,
      );
      final user = res.user;
      if (user == null) _echouer('Email ou mot de passe incorrect.');
      return _compteDepuisProfil(user.id, user.email ?? email);
    });
  }

  @override
  Future<void> deconnexion() => _garder(() => _client.auth.signOut());

  /* ---------------------------------------------------------------------- */
  /*  Demandes                                                              */
  /* ---------------------------------------------------------------------- */

  @override
  Future<List<Demande>> listerDemandes() {
    return _garder(() async {
      // Pas de filtre sur `user_id` : la RLS s'en charge, et c'est elle qui
      // laissera un agent voir les dossiers de tout le monde.
      final lignes = await _client
          .from('demandes')
          .select('id, service_id, service_label, resume, statut, cree_le, '
              'pieces(label, nom_fichier)')
          .order('cree_le', ascending: false);

      return [
        for (final l in lignes)
          Demande(
            id: l['id'] as String? ?? '',
            serviceId: l['service_id'] as String? ?? '',
            serviceLibelle: l['service_label'] as String? ?? '',
            resume: l['resume'] as String? ?? '',
            statut: l['statut'] as String? ?? 'Envoyée',
            date: _dateFr(l['cree_le'] as String?),
            pieces: [
              for (final p in (l['pieces'] as List<dynamic>? ?? const []))
                Piece(
                  libelle: (p as Map<String, dynamic>)['label'] as String? ?? '',
                  fichier: p['nom_fichier'] as String? ?? '',
                ),
            ],
          ),
      ];
    });
  }

  @override
  Future<Demande> creerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    List<PieceEnvoi> pieces = const [],
  }) {
    return _garder(() async {
      final uid = await _idUtilisateur();

      final ligne = await _client
          .from('demandes')
          .insert({
            'user_id': uid,
            'service_id': serviceId,
            'service_label': serviceLibelle,
            'resume': resume,
          })
          .select('id, statut, cree_le')
          .single();

      // Si un téléversement échoue, la demande existe déjà : le conseiller la
      // voit avec ses pièces manquantes plutôt que de la perdre en silence.
      final deposees = await _televerser(uid, pieces, ligne['id'] as String);

      return Demande(
        id: ligne['id'] as String,
        serviceId: serviceId,
        serviceLibelle: serviceLibelle,
        resume: resume,
        pieces: deposees,
        statut: ligne['statut'] as String? ?? 'Envoyée',
        date: _dateFr(ligne['cree_le'] as String?),
      );
    });
  }
}

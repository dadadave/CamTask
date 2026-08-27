import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import '../supabase_config.dart';
import 'backend.dart';

/// Back-end adossé à Supabase : Auth, Postgres, Storage et Realtime.
///
/// Le profil n'est pas créé depuis l'application : le déclencheur
/// `on_auth_user_created` de `supabase/schema.sql` le construit à partir des
/// métadonnées passées à `signUp`. Cela évite un aller-retour et garantit
/// qu'un compte a toujours son profil.
///
/// Aucune méthode ne vérifie elle-même qu'on a le droit de faire ce qu'on
/// demande : c'est la RLS qui tranche, et un refus remonte en
/// [ErreurBackend]. L'application n'est jamais la gardienne des droits.
class BackendSupabase implements Backend {
  const BackendSupabase();

  static const _bucket = 'pieces';

  /// Durée de validité d'un lien de téléchargement : le temps d'ouvrir le
  /// document, pas davantage.
  static const _dureeLien = Duration(minutes: 10);

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
    // Le complément « espace conseiller » n'a pas été exécuté : sans ce
    // message, on ne verrait qu'un code PGRST200 incompréhensible.
    if (m.contains('could not find a relationship') ||
        m.contains("column pieces.sens") ||
        m.contains("'sens' column")) {
      return 'Le complément supabase/schema_agents.sql n\'a pas été exécuté '
          'sur le projet.';
    }
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
    return propre.length <= 80 ? propre : propre.substring(propre.length - 80);
  }

  /// Déduit le type du document de son extension, pour qu'il s'ouvre
  /// correctement quand on le relit depuis le bucket.
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

  static String _heureFr(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  String _idUtilisateur() {
    final user = _client.auth.currentUser;
    if (user == null) _echouer('Votre session a expiré. Reconnectez-vous.');
    return user.id;
  }

  static String _nomProfil(Map<String, dynamic>? profil) {
    if (profil == null) return 'Client';
    final nom = '${profil['prenom'] ?? ''} ${profil['nom'] ?? ''}'.trim();
    return nom.isEmpty ? 'Client' : nom;
  }

  /* ---------------------------------------------------------------------- */
  /*  Pièces jointes                                                        */
  /* ---------------------------------------------------------------------- */

  /// Dépose les fichiers dans le bucket privé puis les référence en base.
  ///
  /// [proprietaire] est toujours **le client** : c'est sous son identifiant
  /// que le fichier est rangé, y compris quand c'est un conseiller qui le
  /// dépose. Sans cela le client ne pourrait pas le relire, la policy de
  /// lecture s'appuyant sur le premier segment du chemin.
  Future<List<Piece>> _televerser({
    required String proprietaire,
    required List<PieceEnvoi> pieces,
    required String? demandeId,
    SensPiece sens = SensPiece.client,
  }) async {
    final deposees = <Piece>[];

    for (final piece in pieces) {
      final fichier = piece.fichier;
      final dossier = demandeId ?? 'compte';
      final chemin =
          '$proprietaire/$dossier/${_jeton()}-${_assainir(fichier.nom)}';

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
        'user_id': proprietaire,
        'demande_id': demandeId,
        'label': piece.libelle,
        'chemin': chemin,
        'nom_fichier': fichier.nom,
        'sens': sens.name,
      });

      deposees.add(Piece(
        libelle: piece.libelle,
        fichier: fichier.nom,
        sens: sens,
        chemin: chemin,
      ));
    }

    return deposees;
  }

  /// Les pièces du compte : celles de l'inscription, sans demande rattachée.
  Future<List<Piece>> _piecesDuCompte(String uid) async {
    final lignes = await _client
        .from('pieces')
        .select('label, nom_fichier, chemin, sens')
        .eq('user_id', uid)
        .isFilter('demande_id', null);

    return [for (final l in lignes) _piece(l)];
  }

  static Piece _piece(Map<String, dynamic> l) => Piece(
        libelle: l['label'] as String? ?? '',
        fichier: l['nom_fichier'] as String? ?? '',
        chemin: l['chemin'] as String? ?? '',
        sens: SensPiece.values.firstWhere(
          (s) => s.name == l['sens'],
          orElse: () => SensPiece.client,
        ),
      );

  /* ---------------------------------------------------------------------- */
  /*  Profil                                                                */
  /* ---------------------------------------------------------------------- */

  Future<Compte> _compteDepuisProfil(String uid, String email) async {
    final ligne = await _client
        .from('profiles')
        .select('role, nom, prenom, telephone, niu, est_agent, cree_le')
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
      estAgent: ligne['est_agent'] as bool? ?? false,
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

      await _televerser(
        proprietaire: user.id,
        pieces: pieces,
        demandeId: null,
      );
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
      // laisse un conseiller voir les dossiers de tout le monde. Le profil
      // est incorporé pour nommer le client dans la liste des conseillers.
      final lignes = await _client
          .from('demandes')
          .select('id, user_id, service_id, service_label, resume, statut, '
              'cree_le, pieces(label, nom_fichier, chemin, sens), '
              'profiles(nom, prenom, telephone)')
          .order('cree_le', ascending: false);

      return [for (final l in lignes) _demande(l)];
    });
  }

  static Demande _demande(Map<String, dynamic> l) {
    final profil = l['profiles'] as Map<String, dynamic>?;
    return Demande(
      id: l['id'] as String? ?? '',
      serviceId: l['service_id'] as String? ?? '',
      serviceLibelle: l['service_label'] as String? ?? '',
      resume: l['resume'] as String? ?? '',
      statut: l['statut'] as String? ?? 'Envoyée',
      date: _dateFr(l['cree_le'] as String?),
      clientId: l['user_id'] as String? ?? '',
      clientNom: _nomProfil(profil),
      clientTelephone: profil?['telephone'] as String? ?? '',
      pieces: [
        for (final p in (l['pieces'] as List<dynamic>? ?? const []))
          _piece(p as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<Demande> creerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    List<PieceEnvoi> pieces = const [],
  }) {
    return _garder(() async {
      final uid = _idUtilisateur();

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
      final deposees = await _televerser(
        proprietaire: uid,
        pieces: pieces,
        demandeId: ligne['id'] as String,
      );

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

  @override
  Future<void> changerStatut(String demandeId, String statut) {
    return _garder(() async {
      await _client
          .from('demandes')
          .update({'statut': statut}).eq('id', demandeId);
    });
  }

  @override
  Future<List<Piece>> deposerPiecesAgence({
    required String demandeId,
    required String clientId,
    required List<PieceEnvoi> pieces,
  }) {
    return _garder(() => _televerser(
          proprietaire: clientId,
          pieces: pieces,
          demandeId: demandeId,
          sens: SensPiece.agence,
        ));
  }

  /* ---------------------------------------------------------------------- */
  /*  Messagerie                                                            */
  /* ---------------------------------------------------------------------- */

  /// Le propriétaire de la conversation : le client, toujours — même quand
  /// c'est le conseiller qui écrit.
  String _conversation(String? clientId) => clientId ?? _idUtilisateur();

  /// Qui doit apparaître à droite de l'écran ?
  ///
  /// Pour un client, ses propres messages ; pour un conseiller, ceux de
  /// l'agence. D'où cette lecture relative plutôt qu'absolue.
  static Auteur _cote(String auteur, bool jeSuisLAgence) {
    final deLAgence = auteur == 'agent';
    return deLAgence == jeSuisLAgence ? Auteur.moi : Auteur.agent;
  }

  @override
  Future<List<Message>> listerMessages({String? clientId}) {
    return _garder(() async {
      final lignes = await _client
          .from('messages')
          .select('id, auteur, texte, nom_fichier, piece_chemin, cree_le')
          .eq('user_id', _conversation(clientId))
          .order('cree_le', ascending: true);

      final jeSuisLAgence = clientId != null;
      return [
        for (final m in lignes)
          Message(
            id: m['id'] as String? ?? '',
            auteur: _cote(m['auteur'] as String? ?? '', jeSuisLAgence),
            texte: m['texte'] as String? ?? '',
            fichier: m['nom_fichier'] as String?,
            chemin: m['piece_chemin'] as String?,
            heure: _heureFr(m['cree_le'] as String?),
          ),
      ];
    });
  }

  @override
  Future<Message> envoyerMessage({
    required String texte,
    FichierChoisi? fichier,
    String? clientId,
  }) {
    return _garder(() async {
      final proprietaire = _conversation(clientId);
      final jeSuisLAgence = clientId != null;

      String? chemin;
      if (fichier != null) {
        // Rangé chez le client, quel que soit l'auteur : c'est lui qui doit
        // pouvoir le relire.
        chemin = '$proprietaire/chat/${_jeton()}-${_assainir(fichier.nom)}';
        try {
          await _client.storage.from(_bucket).uploadBinary(
                chemin,
                fichier.octets,
                fileOptions: FileOptions(contentType: _typeMime(fichier.nom)),
              );
        } on StorageException catch (e) {
          _echouer('Envoi du document impossible : ${e.message}', e);
        }
      }

      final ligne = await _client
          .from('messages')
          .insert({
            'user_id': proprietaire,
            'auteur': jeSuisLAgence ? 'agent' : 'client',
            'texte': texte,
            'piece_chemin': chemin,
            'nom_fichier': fichier?.nom,
          })
          .select('id, cree_le')
          .single();

      return Message(
        id: ligne['id'] as String? ?? '',
        auteur: Auteur.moi,
        texte: texte,
        fichier: fichier?.nom,
        chemin: chemin,
        heure: _heureFr(ligne['cree_le'] as String?),
      );
    });
  }

  @override
  Annulation souscrireMessages({
    required void Function(Message) surMessage,
    String? clientId,
  }) {
    final proprietaire = _conversation(clientId);
    final jeSuisLAgence = clientId != null;

    final canal = _client
        .channel('messages:$proprietaire')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: proprietaire,
          ),
          callback: (charge) {
            final m = charge.newRecord;
            final auteur = m['auteur'] as String? ?? '';
            // Nos propres messages sont déjà affichés par `envoyerMessage`.
            if ((auteur == 'agent') == jeSuisLAgence) return;
            surMessage(Message(
              id: m['id'] as String? ?? '',
              auteur: Auteur.agent,
              texte: m['texte'] as String? ?? '',
              fichier: m['nom_fichier'] as String?,
              chemin: m['piece_chemin'] as String?,
              heure: _heureFr(m['cree_le'] as String?),
            ));
          },
        )
        .subscribe();

    return () => _client.removeChannel(canal);
  }

  @override
  Future<List<Conversation>> listerConversations() {
    return _garder(() async {
      // La RLS ne laisse un conseiller voir que ce qu'il a le droit de voir ;
      // on regroupe ensuite par client pour n'afficher que le dernier mot.
      final lignes = await _client
          .from('messages')
          .select('user_id, auteur, texte, nom_fichier, cree_le, '
              'profiles(nom, prenom)')
          .order('cree_le', ascending: false);

      final vues = <String, Conversation>{};
      for (final m in lignes) {
        final clientId = m['user_id'] as String? ?? '';
        // Les lignes arrivent du plus récent au plus ancien : la première
        // rencontrée pour un client est donc son dernier message.
        if (vues.containsKey(clientId)) continue;

        final texte = m['texte'] as String? ?? '';
        final fichier = m['nom_fichier'] as String?;
        vues[clientId] = Conversation(
          clientId: clientId,
          clientNom: _nomProfil(m['profiles'] as Map<String, dynamic>?),
          dernierTexte: texte.isNotEmpty
              ? texte
              : (fichier != null ? '📎 $fichier' : ''),
          dernierLe: _heureFr(m['cree_le'] as String?),
          deLAgence: (m['auteur'] as String? ?? '') == 'agent',
        );
      }

      // Ceux qui attendent une réponse d'abord.
      final liste = vues.values.toList()
        ..sort((a, b) {
          if (a.deLAgence != b.deLAgence) return a.deLAgence ? 1 : -1;
          return 0;
        });
      return liste;
    });
  }

  /* ---------------------------------------------------------------------- */
  /*  Documents                                                             */
  /* ---------------------------------------------------------------------- */

  @override
  Future<String> lienDocument(String chemin) {
    return _garder(() async {
      if (chemin.isEmpty) _echouer('Ce document n\'est plus disponible.');
      return _client.storage
          .from(_bucket)
          .createSignedUrl(chemin, _dureeLien.inSeconds);
    });
  }
}

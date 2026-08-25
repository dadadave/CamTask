import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'backend.dart';

/// Renseignés à la compilation :
///
///   flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…
///
/// La clé « anon » est publique par nature : ce sont les policies RLS de
/// supabase/schema.sql qui protègent les données, pas le secret de la clé.
const _url = String.fromEnvironment('SUPABASE_URL');
const _cle = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Le nécessaire a-t-il été fourni ? L'application affiche un écran
/// d'explication plutôt que d'échouer sans un mot.
bool get supabaseConfigure => _url.isNotEmpty && _cle.isNotEmpty;

const _messageConfig =
    'Configuration Supabase absente : relancez avec --dart-define=SUPABASE_URL '
    'et --dart-define=SUPABASE_ANON_KEY.';

const _bucket = 'pieces';

class BackendSupabase implements Backend {
  @override
  bool get configure => supabaseConfigure;

  @override
  String get messageConfiguration => _messageConfig;

  SupabaseClient get _sb {
    if (!supabaseConfigure) throw const ErreurBackend(_messageConfig);
    return Supabase.instance.client;
  }

  @override
  Future<void> demarrer() async {
    if (!supabaseConfigure) return;
    await Supabase.initialize(url: _url, anonKey: _cle);
  }

  /* ---------------------------------------------------------------------- */
  /*  Utilitaires                                                           */
  /* ---------------------------------------------------------------------- */

  String get _uid {
    final id = _sb.auth.currentUser?.id;
    if (id == null) {
      throw const ErreurBackend('Votre session a expiré. Reconnectez-vous.');
    }
    return id;
  }

  static String _dateFr(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _heureFr(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  /// Rend un nom de fichier utilisable comme clé de stockage.
  static String _assainir(String nom) {
    final propre = nom.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
    return propre.length <= 80
        ? propre
        : propre.substring(propre.length - 80);
  }

  static String _identifiant() {
    final r = Random().nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().millisecondsSinceEpoch}-$r';
  }

  /// Traduit les erreurs techniques en messages affichables.
  static Never _echouer(Object e) {
    final brut = switch (e) {
      AuthException(:final message) => message,
      PostgrestException(:final message) => message,
      StorageException(:final message) => message,
      _ => e.toString(),
    };
    final m = brut.toLowerCase();
    if (m.contains('invalid login credentials')) {
      throw const ErreurBackend('Email ou mot de passe incorrect.');
    }
    if (m.contains('email not confirmed')) {
      throw const ErreurBackend(
        "Votre email n'est pas encore confirmé. Vérifiez votre boîte de réception.",
      );
    }
    if (m.contains('already registered') || m.contains('user already')) {
      throw const ErreurBackend(
        'Un compte existe déjà avec cet email. Connectez-vous.',
      );
    }
    if (m.contains('password should be')) {
      throw const ErreurBackend(
        'Le mot de passe doit contenir au moins 6 caractères.',
      );
    }
    if (m.contains('row-level security') || m.contains('violates row-level')) {
      throw const ErreurBackend(
        "Vous n'avez pas l'autorisation d'effectuer cette action.",
      );
    }
    if (m.contains('socketexception') ||
        m.contains('failed host lookup') ||
        m.contains('clientexception')) {
      throw const ErreurBackend(
        'Connexion au serveur impossible. Vérifiez votre accès à Internet.',
      );
    }
    throw ErreurBackend(brut);
  }

  /* ---------------------------------------------------------------------- */
  /*  Pièces jointes                                                        */
  /* ---------------------------------------------------------------------- */

  /// Dépose les fichiers dans le bucket privé puis les référence en base.
  /// [demandeId] est nul pour les pièces fournies à l'inscription.
  Future<List<Piece>> _televerser(
    String uid,
    List<PieceEnvoi> pieces,
    String? demandeId,
  ) async {
    final deposees = <Piece>[];

    for (final p in pieces) {
      final dossier = demandeId ?? 'compte';
      final chemin =
          '$uid/$dossier/${_identifiant()}-${_assainir(p.nomFichier)}';

      try {
        await _sb.storage.from(_bucket).uploadBinary(chemin, p.octets);
        await _sb.from('pieces').insert({
          'user_id': uid,
          'demande_id': demandeId,
          'label': p.libelle,
          'chemin': chemin,
          'nom_fichier': p.nomFichier,
        });
      } catch (e) {
        _echouer(e);
      }

      deposees.add(Piece(libelle: p.libelle, fichier: p.nomFichier));
    }

    return deposees;
  }

  Future<List<Piece>> _piecesDuCompte(String uid) async {
    try {
      final lignes = await _sb
          .from('pieces')
          .select('label, nom_fichier')
          .eq('user_id', uid)
          .isFilter('demande_id', null);
      return [
        for (final l in lignes as List<dynamic>)
          Piece(
            libelle: (l as Map<String, dynamic>)['label'] as String? ?? '',
            fichier: l['nom_fichier'] as String? ?? '',
          ),
      ];
    } catch (e) {
      _echouer(e);
    }
  }

  Future<Compte> _compteDepuisProfil(String uid, String email) async {
    try {
      final l = await _sb
          .from('profiles')
          .select('role, nom, prenom, telephone, niu, cree_le')
          .eq('id', uid)
          .single();

      return Compte(
        role: Role.values.firstWhere(
          (r) => r.name == l['role'],
          orElse: () => Role.utilisateur,
        ),
        nom: l['nom'] as String? ?? '',
        prenom: l['prenom'] as String? ?? '',
        email: email,
        telephone: l['telephone'] as String? ?? '',
        niu: l['niu'] as String? ?? '',
        pieces: await _piecesDuCompte(uid),
        creeLe: _dateFr(l['cree_le'] as String),
      );
    } catch (e) {
      _echouer(e);
    }
  }

  /* ---------------------------------------------------------------------- */
  /*  Compte                                                                */
  /* ---------------------------------------------------------------------- */

  @override
  Future<Compte?> sessionActuelle() async {
    if (!supabaseConfigure) return null;
    final user = _sb.auth.currentUser;
    if (user == null) return null;
    return _compteDepuisProfil(user.id, user.email ?? '');
  }

  @override
  Future<Compte> inscription(InscriptionEntree e) async {
    late final AuthResponse reponse;
    try {
      // Le profil est créé côté base par le déclencheur `on_auth_user_created`
      // à partir de ces métadonnées.
      reponse = await _sb.auth.signUp(
        email: e.email,
        password: e.motDePasse,
        data: {
          'role': e.role.name,
          'nom': e.nom,
          'prenom': e.prenom,
          'telephone': e.telephone,
          'niu': e.niu,
        },
      );
    } catch (err) {
      _echouer(err);
    }

    // Sans session, la RLS refusera le dépôt des pièces : c'est le cas quand
    // la confirmation par email est activée sur le projet Supabase.
    final user = reponse.session?.user;
    if (user == null) {
      throw const ErreurBackend(
        'Compte créé. Confirmez votre email puis connectez-vous pour '
        'transmettre vos pièces justificatives.',
      );
    }

    await _televerser(user.id, e.pieces, null);
    return _compteDepuisProfil(user.id, e.email);
  }

  @override
  Future<Compte> connexion(String email, String motDePasse) async {
    late final AuthResponse reponse;
    try {
      reponse = await _sb.auth
          .signInWithPassword(email: email, password: motDePasse);
    } catch (e) {
      _echouer(e);
    }
    final user = reponse.user;
    if (user == null) {
      throw const ErreurBackend('Email ou mot de passe incorrect.');
    }
    return _compteDepuisProfil(user.id, user.email ?? email);
  }

  @override
  Future<void> deconnexion() async {
    try {
      await _sb.auth.signOut();
    } catch (e) {
      _echouer(e);
    }
  }

  /* ---------------------------------------------------------------------- */
  /*  Demandes                                                              */
  /* ---------------------------------------------------------------------- */

  @override
  Future<List<Demande>> listerDemandes() async {
    try {
      final lignes = await _sb
          .from('demandes')
          .select(
            'id, service_id, service_label, resume, statut, cree_le, '
            'pieces(label, nom_fichier)',
          )
          .order('cree_le', ascending: false);

      return [
        for (final l in lignes as List<dynamic>)
          Demande(
            id: (l as Map<String, dynamic>)['id'] as String,
            serviceId: l['service_id'] as String? ?? '',
            serviceLibelle: l['service_label'] as String? ?? '',
            resume: l['resume'] as String? ?? '',
            statut: l['statut'] as String? ?? 'Envoyée',
            date: _dateFr(l['cree_le'] as String),
            pieces: [
              for (final p in (l['pieces'] as List<dynamic>? ?? const []))
                Piece(
                  libelle:
                      (p as Map<String, dynamic>)['label'] as String? ?? '',
                  fichier: p['nom_fichier'] as String? ?? '',
                ),
            ],
          ),
      ];
    } catch (e) {
      _echouer(e);
    }
  }

  @override
  Future<Demande> creerDemande(DemandeEntree e) async {
    final uid = _uid;

    late final Map<String, dynamic> ligne;
    try {
      ligne = await _sb
          .from('demandes')
          .insert({
            'user_id': uid,
            'service_id': e.serviceId,
            'service_label': e.serviceLibelle,
            'resume': e.resume,
          })
          .select('id, statut, cree_le')
          .single();
    } catch (err) {
      _echouer(err);
    }

    // Si un téléversement échoue, la demande existe déjà : l'agent la voit
    // avec ses pièces manquantes plutôt que de la perdre en silence.
    final deposees = await _televerser(uid, e.pieces, ligne['id'] as String);

    return Demande(
      id: ligne['id'] as String,
      serviceId: e.serviceId,
      serviceLibelle: e.serviceLibelle,
      resume: e.resume,
      pieces: deposees,
      statut: ligne['statut'] as String? ?? 'Envoyée',
      date: _dateFr(ligne['cree_le'] as String),
    );
  }

  /* ---------------------------------------------------------------------- */
  /*  Messagerie                                                            */
  /* ---------------------------------------------------------------------- */

  @override
  Future<List<Message>> listerMessages() async {
    try {
      final lignes = await _sb
          .from('messages')
          .select('id, auteur, texte, nom_fichier, cree_le')
          .order('cree_le', ascending: true);

      return [
        for (final l in lignes as List<dynamic>)
          Message(
            id: (l as Map<String, dynamic>)['id'] as String,
            auteur: l['auteur'] == 'agent' ? Auteur.agent : Auteur.moi,
            texte: l['texte'] as String? ?? '',
            fichier: l['nom_fichier'] as String?,
            heure: _heureFr(l['cree_le'] as String),
          ),
      ];
    } catch (e) {
      _echouer(e);
    }
  }

  @override
  Future<Message> envoyerMessage(String texte, {PieceEnvoi? piece}) async {
    final uid = _uid;

    String? chemin;
    if (piece != null) {
      chemin = '$uid/chat/${_identifiant()}-${_assainir(piece.nomFichier)}';
      try {
        await _sb.storage.from(_bucket).uploadBinary(chemin, piece.octets);
      } catch (e) {
        _echouer(e);
      }
    }

    late final Map<String, dynamic> ligne;
    try {
      ligne = await _sb
          .from('messages')
          .insert({
            'user_id': uid,
            'auteur': 'client',
            'texte': texte,
            'piece_chemin': chemin,
            'nom_fichier': piece?.nomFichier,
          })
          .select('id, cree_le')
          .single();
    } catch (e) {
      _echouer(e);
    }

    return Message(
      id: ligne['id'] as String,
      auteur: Auteur.moi,
      texte: texte,
      fichier: piece?.nomFichier,
      heure: _heureFr(ligne['cree_le'] as String),
    );
  }

  @override
  void Function() souscrireMessages(void Function(Message) onMessage) {
    if (!supabaseConfigure) return () {};
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return () {};

    final canal = _sb.channel('messages:$uid')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (charge) {
          final m = charge.newRecord;
          // Nos propres messages sont déjà affichés par `envoyerMessage`.
          if (m['auteur'] != 'agent') return;
          onMessage(
            Message(
              id: m['id'] as String,
              auteur: Auteur.agent,
              texte: m['texte'] as String? ?? '',
              fichier: m['nom_fichier'] as String?,
              heure: _heureFr(m['cree_le'] as String),
            ),
          );
        },
      )
      ..subscribe();

    return () => _sb.removeChannel(canal);
  }
}

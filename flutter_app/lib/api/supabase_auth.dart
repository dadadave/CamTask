import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import '../supabase_config.dart';
import 'backend.dart';

/// Authentification adossée à Supabase (Auth + table `profiles`).
///
/// Le profil n'est pas créé depuis l'application : le déclencheur
/// `on_auth_user_created` de `supabase/schema.sql` le construit à partir des
/// métadonnées passées à `signUp`. Cela évite un aller-retour et garantit
/// qu'un compte a toujours son profil.
class AuthSupabase implements BackendAuth {
  const AuthSupabase();

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
    if (m.contains('unable to validate email') ||
        m.contains('invalid email')) {
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
    // Le schéma n'a pas été exécuté sur le projet : sans ce message, on ne
    // voit qu'un code PGRST205 incompréhensible.
    if (m.contains('could not find the table') ||
        m.contains('does not exist')) {
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
    } catch (e) {
      _echouer(e.toString(), e);
    }
  }

  /* ---------------------------------------------------------------------- */
  /*  Profil                                                                */
  /* ---------------------------------------------------------------------- */

  static String _dateFr(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Construit le [Compte] à partir de la ligne `profiles`.
  ///
  /// [pieces] vient du stockage local : le téléversement vers le bucket
  /// privé n'est pas encore branché, on ne conserve que les noms de fichiers.
  Future<Compte> _compteDepuisProfil(
    String uid,
    String email, {
    List<Piece> pieces = const [],
  }) async {
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
      pieces: pieces,
      creeLe: _dateFr(ligne['cree_le'] as String?),
    );
  }

  /* ---------------------------------------------------------------------- */
  /*  Implémentation                                                        */
  /* ---------------------------------------------------------------------- */

  @override
  Future<Compte?> sessionActuelle({List<Piece> pieces = const []}) {
    return _garder(() async {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return _compteDepuisProfil(user.id, user.email ?? '', pieces: pieces);
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
    List<Piece> pieces = const [],
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

      // Pas de session : la confirmation par email est activée sur le projet.
      // On le dit plutôt que de laisser l'utilisateur devant un écran muet.
      final user = res.user;
      if (res.session == null || user == null) {
        _echouer(
          'Compte créé. Confirmez votre email, puis connectez-vous.',
        );
      }

      return _compteDepuisProfil(user.id, email, pieces: pieces);
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
}

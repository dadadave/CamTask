import 'dart:typed_data';

import '../models.dart';

/// Contrat que doit remplir une source de données, quelle qu'elle soit.
///
/// L'application ne connaît que cette interface : ni les écrans ni [AppState]
/// n'importent Supabase. Remplacer Supabase par notre propre API se limite
/// donc à écrire une seconde implémentation et à changer la ligne d'export de
/// `lib/api/api.dart`.
///
/// C'est le pendant exact de `src/api/types.ts` côté React : les deux clients
/// parlent au même schéma, avec le même découpage.

/// Un document choisi par l'utilisateur, avec son contenu réel.
class PieceEnvoi {
  const PieceEnvoi({
    required this.libelle,
    required this.nomFichier,
    required this.octets,
  });

  final String libelle;
  final String nomFichier;
  final Uint8List octets;
}

class InscriptionEntree {
  const InscriptionEntree({
    required this.role,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.niu,
    required this.motDePasse,
    this.pieces = const [],
  });

  final Role role;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String niu;
  final String motDePasse;
  final List<PieceEnvoi> pieces;
}

class DemandeEntree {
  const DemandeEntree({
    required this.serviceId,
    required this.serviceLibelle,
    required this.resume,
    this.pieces = const [],
  });

  final String serviceId;
  final String serviceLibelle;
  final String resume;
  final List<PieceEnvoi> pieces;
}

abstract class Backend {
  /// A-t-on de quoi fonctionner ? Faux si les clés n'ont pas été fournies.
  /// L'application affiche alors [messageConfiguration] au lieu d'échouer
  /// sans un mot.
  bool get configure;

  /// Ce qu'il manque, dit à l'utilisateur.
  String get messageConfiguration;

  /// Prépare le client (session enregistrée, etc.). Appelé une fois au
  /// démarrage, avant tout autre appel.
  Future<void> demarrer();

  /// Compte déjà connecté sur cet appareil, ou `null`.
  Future<Compte?> sessionActuelle();
  Future<Compte> inscription(InscriptionEntree entree);
  Future<Compte> connexion(String email, String motDePasse);
  Future<void> deconnexion();

  Future<List<Demande>> listerDemandes();
  Future<Demande> creerDemande(DemandeEntree entree);

  Future<List<Message>> listerMessages();
  Future<Message> envoyerMessage(String texte, {PieceEnvoi? piece});

  /// Écoute les réponses des agents. Renvoie de quoi se désabonner.
  void Function() souscrireMessages(void Function(Message) onMessage);
}

/// Erreur destinée à être affichée telle quelle à l'utilisateur.
class ErreurBackend implements Exception {
  const ErreurBackend(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Message affichable pour n'importe quelle erreur remontée par le backend.
String messageErreur(Object e) {
  if (e is ErreurBackend) return e.message;
  return 'Une erreur est survenue. Réessayez.';
}

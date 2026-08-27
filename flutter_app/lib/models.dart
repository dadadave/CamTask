import 'dart:typed_data';

/// Rôle choisi à l'inscription : client ou personne employée.
///
/// Purement déclaratif : il ne donne aucun privilège. Le droit de consulter
/// les dossiers de tout le monde vient de [Compte.estAgent].
enum Role { utilisateur, employe }

/// Un fichier choisi sur l'appareil, contenu compris.
///
/// On garde les octets plutôt qu'un chemin : c'est la seule forme qui
/// fonctionne aussi bien sur mobile que sur le web, et le téléversement
/// Supabase les prend directement.
class FichierChoisi {
  const FichierChoisi({required this.nom, required this.octets});

  final String nom;
  final Uint8List octets;
}

/// Qui a déposé une pièce : le client, ou l'agence en réponse.
enum SensPiece { client, agence }

/// Une pièce prête à partir : son libellé et le fichier choisi.
///
/// À distinguer de [Piece], qui décrit une pièce **déjà** déposée.
class PieceEnvoi {
  const PieceEnvoi({required this.libelle, required this.fichier});

  final String libelle;
  final FichierChoisi fichier;
}

/// Un document déposé : son libellé, son nom de fichier, et de quel côté il
/// vient. [chemin] est sa clé dans le bucket privé — nécessaire pour en
/// obtenir un lien de téléchargement.
class Piece {
  const Piece({
    required this.libelle,
    required this.fichier,
    this.sens = SensPiece.client,
    this.chemin = '',
  });

  final String libelle;
  final String fichier;
  final SensPiece sens;
  final String chemin;

  Map<String, dynamic> versJson() => {
        'libelle': libelle,
        'fichier': fichier,
        'sens': sens.name,
        'chemin': chemin,
      };

  factory Piece.depuisJson(Map<String, dynamic> j) => Piece(
        libelle: j['libelle'] as String? ?? '',
        fichier: j['fichier'] as String? ?? '',
        sens: SensPiece.values.firstWhere(
          (s) => s.name == j['sens'],
          orElse: () => SensPiece.client,
        ),
        chemin: j['chemin'] as String? ?? '',
      );
}

class Compte {
  const Compte({
    required this.role,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.niu,
    required this.pieces,
    required this.creeLe,
    this.estAgent = false,
  });

  final Role role;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;

  /// NIU ou numéro de contribuable.
  final String niu;
  final List<Piece> pieces;
  final String creeLe;

  /// Conseiller CAM-TAXE : voit les dossiers et les conversations de tous
  /// les clients. Ne se règle que depuis le tableau de bord Supabase.
  final bool estAgent;

  String get initiales {
    final a = prenom.isNotEmpty ? prenom[0] : '';
    final b = nom.isNotEmpty ? nom[0] : '';
    final i = '$a$b'.toUpperCase();
    return i.isEmpty ? 'U' : i;
  }

  Map<String, dynamic> versJson() => {
        'role': role.name,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'niu': niu,
        'estAgent': estAgent,
        'pieces': pieces.map((p) => p.versJson()).toList(),
        'creeLe': creeLe,
      };

  factory Compte.depuisJson(Map<String, dynamic> j) => Compte(
        role: Role.values.firstWhere(
          (r) => r.name == j['role'],
          orElse: () => Role.utilisateur,
        ),
        nom: j['nom'] as String? ?? '',
        prenom: j['prenom'] as String? ?? '',
        email: j['email'] as String? ?? '',
        telephone: j['telephone'] as String? ?? '',
        niu: j['niu'] as String? ?? '',
        estAgent: j['estAgent'] as bool? ?? false,
        pieces: ((j['pieces'] as List<dynamic>?) ?? const [])
            .map((e) => Piece.depuisJson(e as Map<String, dynamic>))
            .toList(),
        creeLe: j['creeLe'] as String? ?? '',
      );
}

/// Une demande envoyée depuis l'un des 7 services.
class Demande {
  const Demande({
    required this.id,
    required this.serviceId,
    required this.serviceLibelle,
    required this.resume,
    required this.pieces,
    required this.statut,
    required this.date,
    this.clientId = '',
    this.clientNom = '',
    this.clientTelephone = '',
  });

  final String id;
  final String serviceId;
  final String serviceLibelle;
  final String resume;
  final List<Piece> pieces;
  final String statut;
  final String date;

  /// Renseignés pour un conseiller, qui voit les dossiers de tout le monde
  /// et a besoin de savoir de qui ils viennent. Vides côté client.
  final String clientId;
  final String clientNom;
  final String clientTelephone;

  /// Les pièces fournies par le client.
  List<Piece> get piecesClient =>
      [for (final p in pieces) if (p.sens == SensPiece.client) p];

  /// Les documents renvoyés par l'agence.
  List<Piece> get piecesAgence =>
      [for (final p in pieces) if (p.sens == SensPiece.agence) p];

  Demande avec({String? statut, List<Piece>? pieces}) => Demande(
        id: id,
        serviceId: serviceId,
        serviceLibelle: serviceLibelle,
        resume: resume,
        pieces: pieces ?? this.pieces,
        statut: statut ?? this.statut,
        date: date,
        clientId: clientId,
        clientNom: clientNom,
        clientTelephone: clientTelephone,
      );

  Map<String, dynamic> versJson() => {
        'id': id,
        'serviceId': serviceId,
        'serviceLibelle': serviceLibelle,
        'resume': resume,
        'pieces': pieces.map((p) => p.versJson()).toList(),
        'statut': statut,
        'date': date,
      };

  factory Demande.depuisJson(Map<String, dynamic> j) => Demande(
        id: j['id'] as String? ?? '',
        serviceId: j['serviceId'] as String? ?? '',
        serviceLibelle: j['serviceLibelle'] as String? ?? '',
        resume: j['resume'] as String? ?? '',
        pieces: ((j['pieces'] as List<dynamic>?) ?? const [])
            .map((e) => Piece.depuisJson(e as Map<String, dynamic>))
            .toList(),
        statut: j['statut'] as String? ?? 'Envoyée',
        date: j['date'] as String? ?? '',
      );
}

/// Les trois états d'un dossier, dans l'ordre où il les traverse.
const statutsDemande = <String>['Envoyée', 'En cours', 'Traitée'];

enum Auteur { moi, agent }

class Message {
  const Message({
    required this.id,
    required this.auteur,
    required this.texte,
    required this.heure,
    this.fichier,
    this.chemin,
  });

  final String id;
  final Auteur auteur;
  final String texte;
  final String heure;

  /// Nom du document joint, s'il y en a un.
  final String? fichier;

  /// Sa clé dans le bucket privé, pour en obtenir un lien.
  final String? chemin;

  Map<String, dynamic> versJson() => {
        'id': id,
        'auteur': auteur.name,
        'texte': texte,
        'heure': heure,
        'fichier': fichier,
        'chemin': chemin,
      };

  factory Message.depuisJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String? ?? '',
        auteur: Auteur.values.firstWhere(
          (a) => a.name == j['auteur'],
          orElse: () => Auteur.agent,
        ),
        texte: j['texte'] as String? ?? '',
        heure: j['heure'] as String? ?? '',
        fichier: j['fichier'] as String?,
        chemin: j['chemin'] as String?,
      );
}

/// Une conversation vue par un conseiller : le client, et son dernier mot.
class Conversation {
  const Conversation({
    required this.clientId,
    required this.clientNom,
    required this.dernierTexte,
    required this.dernierLe,
    required this.deLAgence,
  });

  final String clientId;
  final String clientNom;
  final String dernierTexte;
  final String dernierLe;

  /// Le dernier message vient-il de l'agence ? Si non, le client attend une
  /// réponse — c'est ce qui remonte la conversation en tête de liste.
  final bool deLAgence;

  String get initiales {
    final mots = clientNom.trim().split(RegExp(r'\s+'));
    final i = mots
        .where((m) => m.isNotEmpty)
        .take(2)
        .map((m) => m[0].toUpperCase())
        .join();
    return i.isEmpty ? 'C' : i;
  }
}

import 'dart:typed_data';

/// Rôle choisi à l'inscription : client ou personne employée.
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

/// Une pièce prête à partir : son libellé et le fichier choisi.
///
/// À distinguer de [Piece], qui décrit une pièce **déjà** déposée et dont on
/// n'affiche plus que le nom.
class PieceEnvoi {
  const PieceEnvoi({required this.libelle, required this.fichier});

  final String libelle;
  final FichierChoisi fichier;
}

/// Un document téléversé (on ne conserve que le nom du fichier).
class Piece {
  const Piece({required this.libelle, required this.fichier});

  final String libelle;
  final String fichier;

  Map<String, dynamic> versJson() => {'libelle': libelle, 'fichier': fichier};

  factory Piece.depuisJson(Map<String, dynamic> j) => Piece(
        libelle: j['libelle'] as String? ?? '',
        fichier: j['fichier'] as String? ?? '',
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
  });

  final String id;
  final String serviceId;
  final String serviceLibelle;
  final String resume;
  final List<Piece> pieces;
  final String statut;
  final String date;

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

enum Auteur { moi, agent }

class Message {
  const Message({
    required this.id,
    required this.auteur,
    required this.texte,
    required this.heure,
    this.fichier,
  });

  final String id;
  final Auteur auteur;
  final String texte;
  final String heure;
  final String? fichier;

  Map<String, dynamic> versJson() => {
        'id': id,
        'auteur': auteur.name,
        'texte': texte,
        'heure': heure,
        'fichier': fichier,
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
      );
}

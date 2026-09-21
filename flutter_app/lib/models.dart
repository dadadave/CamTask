import 'dart:typed_data';

/// Ce que le client est, pour la facturation.
///
/// À ne pas confondre avec [Role], qui dit quelles pièces on lui demande :
/// un salarié coche « Personne employée » mais reste un particulier.
enum TypeClient { particulier, entreprise }

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
    required this.id,
    required this.role,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.niu,
    required this.pieces,
    required this.creeLe,
    this.estAgent = false,
    this.estAdmin = false,
    this.typeClient = TypeClient.particulier,
  });

  /// L'identifiant du compte dans `auth.users`. Sert notamment à ne pas
  /// proposer à un admin de modifier sa propre habilitation.
  final String id;

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
  /// les clients. Ne se règle que depuis le tableau de bord Supabase, ou
  /// par un [estAdmin] depuis l'écran Équipe.
  final bool estAgent;

  /// Particulier ou entreprise — c'est ce qui décide du tarif. Le client
  /// ne peut pas le changer lui-même : sans quoi il choisirait son prix.
  final TypeClient typeClient;

  /// Administrateur : nomme les conseillers, et rien d'autre. Il ne voit ni
  /// les dossiers ni les conversations, sauf s'il est aussi conseiller.
  /// Ne se règle que depuis le tableau de bord.
  final bool estAdmin;

  String get initiales {
    final a = prenom.isNotEmpty ? prenom[0] : '';
    final b = nom.isNotEmpty ? nom[0] : '';
    final i = '$a$b'.toUpperCase();
    return i.isEmpty ? 'U' : i;
  }

  Map<String, dynamic> versJson() => {
        'id': id,
        'role': role.name,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'niu': niu,
        'estAgent': estAgent,
        'estAdmin': estAdmin,
        'typeClient': typeClient.name,
        'pieces': pieces.map((p) => p.versJson()).toList(),
        'creeLe': creeLe,
      };

  factory Compte.depuisJson(Map<String, dynamic> j) => Compte(
        id: j['id'] as String? ?? '',
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
        estAdmin: j['estAdmin'] as bool? ?? false,
        typeClient: TypeClient.values.firstWhere(
          (t) => t.name == j['typeClient'],
          orElse: () => TypeClient.particulier,
        ),
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

/// Un compte, vu depuis l'écran d'administration.
///
/// L'email n'y figure pas : il vit dans `auth.users`, que l'application ne
/// lit pas. On identifie donc par le nom et le téléphone.
class MembreEquipe {
  const MembreEquipe({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.estAgent,
    required this.estAdmin,
    this.role = Role.utilisateur,
    this.typeClient = TypeClient.particulier,
  });

  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final bool estAgent;
  final bool estAdmin;
  final Role role;
  final TypeClient typeClient;

  /// A rempli le formulaire de conseiller, sans être encore habilité.
  ///
  /// C'est la pile de candidatures que l'administrateur vient valider.
  bool get estCandidat => role == Role.employe && !estAgent;

  bool get estEntreprise => typeClient == TypeClient.entreprise;

  String get nomComplet {
    final n = '$prenom $nom'.trim();
    return n.isEmpty ? 'Compte sans nom' : n;
  }

  String get initiales {
    final a = prenom.isNotEmpty ? prenom[0] : '';
    final b = nom.isNotEmpty ? nom[0] : '';
    final i = '$a$b'.toUpperCase();
    return i.isEmpty ? '?' : i;
  }

  MembreEquipe avec({bool? estAgent, TypeClient? typeClient}) =>
      MembreEquipe(
        id: id,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        estAgent: estAgent ?? this.estAgent,
        estAdmin: estAdmin,
        role: role,
        typeClient: typeClient ?? this.typeClient,
      );
}

/* -------------------------------------------------------------------------- */
/*  Paiements                                                                 */
/* -------------------------------------------------------------------------- */

/// Un moyen de paiement de l'agence, tel qu'il est enregistré en base.
///
/// Le code USSD et le bénéficiaire ne vivent pas dans l'application : un
/// changement de numéro marchand ne doit pas obliger tous les clients à
/// réinstaller.
class MoyenPaiement {
  const MoyenPaiement({
    required this.id,
    required this.libelle,
    required this.codeUssd,
    required this.beneficiaire,
    required this.consigne,
  });

  final String id;
  final String libelle;
  final String codeUssd;
  final String beneficiaire;
  final String consigne;

  bool get estOrange => id == 'orange';
}

/// Le prix d'un service.
class Tarif {
  const Tarif({
    required this.serviceId,
    required this.libelle,
    required this.montant,
  });

  final String serviceId;
  final String libelle;
  final int montant;

  String get formate => montantEnFcfa(montant);
}

/// Où en est une déclaration de versement.
enum StatutPaiement {
  /// Le client affirme avoir payé ; l'agence n'a rien vérifié.
  declare,

  /// Un administrateur a retrouvé l'opération sur le relevé.
  confirme,

  /// L'opération n'a pas été retrouvée.
  rejete,
}

/// Un versement déclaré par un client.
class Paiement {
  const Paiement({
    required this.id,
    required this.montant,
    required this.operateur,
    required this.statut,
    required this.date,
    this.numeroEnvoyeur = '',
    this.reference = '',
    this.motif = '',
    this.clientNom = '',
    this.demandeId = '',
    this.serviceLibelle = '',
  });

  final String id;
  final int montant;
  final String operateur;
  final StatutPaiement statut;
  final String date;
  final String numeroEnvoyeur;
  final String reference;

  /// Renseigné en cas de rejet.
  final String motif;

  /// Renseignés pour l'écran d'administration.
  final String clientNom;
  final String demandeId;
  final String serviceLibelle;

  bool get enAttente => statut == StatutPaiement.declare;

  String get montantFormate => montantEnFcfa(montant);

  String get libelleStatut => switch (statut) {
        StatutPaiement.declare => 'En attente de vérification',
        StatutPaiement.confirme => 'Paiement confirmé',
        StatutPaiement.rejete => 'Paiement rejeté',
      };
}

/// Où en est une facture.
enum StatutFacture { aPayer, payee, annulee }

/// Ce qu'un dossier a coûté, émis dès son dépôt.
///
/// La facture naît d'un déclencheur en base, pas d'un appel de
/// l'application : la dette ne dépend pas du bon vouloir du client.
class Facture {
  const Facture({
    required this.id,
    required this.numero,
    required this.montant,
    required this.statut,
    required this.date,
    this.serviceLibelle = '',
    this.demandeId = '',
    this.clientNom = '',
  });

  final String id;
  final String numero;
  final int montant;
  final StatutFacture statut;
  final String date;
  final String serviceLibelle;
  final String demandeId;
  final String clientNom;

  bool get aPayer => statut == StatutFacture.aPayer;

  String get montantFormate => montantEnFcfa(montant);

  String get libelleStatut => switch (statut) {
        StatutFacture.aPayer => 'À payer',
        StatutFacture.payee => 'Payée',
        StatutFacture.annulee => 'Annulée',
      };

  static StatutFacture statutDepuis(String? brut) => switch (brut) {
        'payee' => StatutFacture.payee,
        'annulee' => StatutFacture.annulee,
        _ => StatutFacture.aPayer,
      };
}

/// Le prix d'un service pour les deux profils, tel que l'administrateur le
/// règle.
class TarifService {
  const TarifService({
    required this.serviceId,
    required this.libelle,
    required this.particulier,
    required this.entreprise,
    required this.actif,
  });

  final String serviceId;
  final String libelle;
  final int particulier;
  final int entreprise;
  final bool actif;

  bool get gratuit => particulier == 0 && entreprise == 0;
}

/// « 25 000 FCFA » — espaces fines insécables entre les milliers.
String montantEnFcfa(int montant) {
  final chiffres = montant.toString();
  final tampon = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) tampon.write('\u202F');
    tampon.write(chiffres[i]);
  }
  return '$tampon FCFA';
}

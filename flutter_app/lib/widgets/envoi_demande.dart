import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';

/// Envoi d'une demande depuis un écran de service.
///
/// Les 7 services partagent le même geste : valider la saisie, envoyer, puis
/// conduire au profil. L'envoi passe maintenant par le réseau — il faut donc
/// montrer l'attente, empêcher le double appui, et surtout **rester sur la
/// page en cas d'échec** pour que la saisie et les fichiers choisis ne soient
/// pas perdus. Ce mixin tient ces trois règles en un seul endroit.
mixin EnvoiDemande<T extends StatefulWidget> on State<T> {
  bool _envoi = false;

  /// Vrai pendant l'envoi : les écrans remplacent alors leur bouton par une
  /// attente.
  bool get envoiEnCours => _envoi;

  /// Envoie la demande, puis va au profil. En cas d'échec, appelle
  /// [surErreur] avec un message déjà rédigé en français.
  ///
  /// [surSucces] permet de conduire ailleurs que vers le profil — l'audit
  /// s'en sert pour enchainer sur le reglement de la caution.
  Future<void> envoyerDemande({
    required String serviceId,
    required String serviceLibelle,
    required String resume,
    required String confirmation,
    required ValueChanged<String> surErreur,
    List<PieceEnvoi> pieces = const [],
    void Function(Demande)? surSucces,
  }) async {
    if (_envoi) return;
    setState(() => _envoi = true);

    // Capturés avant le premier `await` : après, le contexte peut avoir
    // disparu de l'arbre.
    final etat = PorteeApp.of(context);
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);

    try {
      final demande = await etat.envoyerDemande(
        serviceId: serviceId,
        serviceLibelle: serviceLibelle,
        resume: resume,
        pieces: pieces,
      );
      if (!mounted) return;
      messager.showSnackBar(SnackBar(content: Text(confirmation)));

      if (surSucces != null) {
        surSucces(demande);
        return;
      }

      // Le dépôt du dossier a pu émettre une facture : on conduit alors au
      // règlement plutôt qu'au profil. Sans cela le client serait facturé
      // sans qu'on lui propose jamais de payer.
      final facture = await etat.factureDuDossier(demande.id);
      if (!mounted) return;
      if (facture != null && facture.aPayer) {
        navigateur.pushReplacementNamed(
          '/paiement',
          arguments: (
            demandeId: demande.id,
            serviceId: serviceId,
            serviceLibelle: serviceLibelle,
          ),
        );
      } else {
        navigateur.pushNamedAndRemoveUntil('/profil', (r) => false);
      }
    } on ErreurBackend catch (e) {
      if (!mounted) return;
      surErreur(e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }
}

/// Le bouton d'envoi d'un service, ou une attente pendant le téléversement.
///
/// Les documents partent avec la demande : sur une connexion lente, l'attente
/// peut durer, d'où le libellé explicite plutôt qu'un simple cercle.
class BoutonEnvoiDemande extends StatelessWidget {
  const BoutonEnvoiDemande({
    super.key,
    required this.enCours,
    required this.enfant,
  });

  final bool enCours;

  /// Le bouton habituel de la page, affiché au repos.
  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    if (!enCours) return enfant;

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 12),
          Text('Envoi en cours…', style: TextStyle(fontSize: 13.5)),
        ],
      ),
    );
  }
}

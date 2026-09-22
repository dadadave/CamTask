import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'bento.dart';
import 'document.dart';

/// Une bulle de conversation.
///
/// [Auteur.moi] est relatif à qui regarde : ses propres messages à droite,
/// ceux d'en face à gauche. Le back-end s'en charge, l'écran n'a pas à
/// savoir s'il sert un client ou un conseiller.
///
/// Le dégradé orange de la marque marque ce qu'on dit soi-même ; ce qui
/// vient d'en face reste sur la carte neutre. Deux couleurs suffisent à
/// distinguer les deux voix, et ce sont celles du reste de l'application.
class BulleMessage extends StatelessWidget {
  const BulleMessage({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final m = message;
    final mien = m.auteur == Auteur.moi;
    final chemin = m.chemin;

    // Sur l'aplat orange on écrit en blanc ; sur la carte, à l'encre. Les
    // teintes secondaires suivent, sans quoi l'heure et le nom du document
    // deviendraient illisibles d'un côté ou de l'autre.
    final encre = mien ? Colors.white : n.encre;
    final douce = mien ? Colors.white.withValues(alpha: 0.85) : n.grise;

    return Align(
      alignment: mien ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: mien ? Degrades.orange : null,
          color: mien ? null : n.carte,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mien ? 18 : 5),
            bottomRight: Radius.circular(mien ? 5 : 18),
          ),
          // Celles d'en face portent un liseré : sur le fond sable, une
          // carte sans contour se détache mal.
          border: mien ? null : Border.all(color: n.ligne),
          boxShadow: mien ? ombreOrange : n.ombreDouce,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.texte.isNotEmpty)
              Text(
                m.texte,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: encre,
                ),
              ),
            if (m.fichier != null) ...[
              const SizedBox(height: 7),
              Material(
                color: mien
                    ? Colors.white.withValues(alpha: 0.18)
                    : n.orangeFantome,
                borderRadius: Rayons.brSm,
                child: InkWell(
                  borderRadius: Rayons.brSm,
                  onTap: (chemin == null || chemin.isEmpty)
                      ? null
                      : () => ouvrirDocument(context, chemin,
                          nomFichier: m.fichier),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 15,
                          color: mien ? Colors.white : n.accentTexte,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            m.fichier!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: mien ? Colors.white : n.accentTexte,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.download_rounded,
                          size: 14,
                          color: mien ? Colors.white70 : n.accentTexte,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                m.heure,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: douce,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La barre de saisie d'une conversation : texte, pièce jointe, envoi.
///
/// Une pilule qui flotte, et non plus un bloc plein barrant toute la
/// largeur. Le bloc à coins droits venait buter contre la pilule arrondie
/// de la navigation, et ces deux formes contraires se disputaient le bas de
/// l'écran. Même galbe pour les deux, elles se répondent.
class BarreSaisieMessage extends StatelessWidget {
  const BarreSaisieMessage({
    super.key,
    required this.saisie,
    required this.onEnvoyer,
    required this.onJoindre,
    this.enCours = false,
    this.invite = 'Votre message…',
  });

  final TextEditingController saisie;
  final VoidCallback onEnvoyer;
  final VoidCallback onJoindre;

  /// Un envoi est en cours : le bouton laisse place à une attente, ce qui
  /// évite aussi d'envoyer deux fois le même message.
  final bool enCours;
  final String invite;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;

    return SafeArea(
      top: false,
      // Quand une barre de navigation suit, elle a déjà pris la marge du
      // bas : ce SafeArea n'ajoute alors rien.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaces.bord, Espaces.sm,
            Espaces.bord, Espaces.sm),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 5, 4),
          decoration: BoxDecoration(
            color: n.carte,
            borderRadius: Rayons.brPilule,
            border: Border.all(color: n.ligne),
            boxShadow: n.ombreForte,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: saisie,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: invite,
                    hintStyle: TextStyle(color: n.grise, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.35),
                  onSubmitted: (_) => onEnvoyer(),
                ),
              ),
              IconButton(
                tooltip: 'Joindre un document',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.attach_file_rounded,
                    color: n.encreDouce, size: 21),
                onPressed: enCours ? null : onJoindre,
              ),
              const SizedBox(width: 2),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: Degrades.orange,
                  shape: BoxShape.circle,
                  boxShadow: ombreOrange,
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enCours ? null : onEnvoyer,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: enCours
                          ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le bandeau d'erreur d'une conversation.
///
/// Il n'interrompt pas la lecture : les messages déjà reçus restent
/// affichés au-dessous, et seule la dernière tentative est signalée.
class BandeauErreurChat extends StatelessWidget {
  const BandeauErreurChat({super.key, required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.md, Espaces.bord, 0),
      child: Container(
        padding: const EdgeInsets.all(Espaces.md),
        decoration: BoxDecoration(
          color: n.orangeFantome,
          borderRadius: Rayons.brMd,
          border: Border.all(color: Palette.orange.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 17, color: n.accentTexte),
            const SizedBox(width: Espaces.sm),
            Expanded(
              child: Text(
                texte,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: n.accentTexte,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'en-tête d'une conversation : l'interlocuteur, et son état.
///
/// Posé sur le fond maillé des autres écrans plutôt que sur le pavé bleu
/// qu'il était : le chat n'a pas de raison d'être le seul écran d'une autre
/// couleur que le reste de l'application.
class BarreConversation extends StatelessWidget implements PreferredSizeWidget {
  const BarreConversation({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.initiales,
    this.enLigne = false,
    this.retour = true,
  });

  final String titre;
  final String sousTitre;
  final String initiales;

  /// Affiche la pastille verte. Réservée au client : lui sait qu'une
  /// agence est ouverte, le conseiller n'a que faire de se le voir dire.
  final bool enLigne;

  final bool retour;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final peutRevenir = retour && Navigator.of(context).canPop();

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(Rayons.xl)),
      child: AppBar(
        flexibleSpace: const FondMaille(enfant: SizedBox.expand()),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: preferredSize.height,
        centerTitle: false,
        titleSpacing: peutRevenir ? 0 : Espaces.bord,
        foregroundColor: n.encre,
        iconTheme: IconThemeData(color: n.encre, size: 22),
        automaticallyImplyLeading: false,
        leading: peutRevenir
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: Degrades.orange,
                shape: BoxShape.circle,
                boxShadow: ombreOrange,
              ),
              child: Text(
                initiales,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: Espaces.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: n.encre,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (enLigne) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: n.succesTexte,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          sousTitre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: enLigne ? n.succesTexte : n.encreDouce,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Espaces.sm),
          ],
        ),
      ),
    );
  }
}

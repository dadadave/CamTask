import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'document.dart';

/// Une bulle de conversation.
///
/// [Auteur.moi] est relatif à qui regarde : ses propres messages à droite,
/// ceux d'en face à gauche. Le back-end s'en charge, l'écran n'a pas à
/// savoir s'il sert un client ou un conseiller.
class BulleMessage extends StatelessWidget {
  const BulleMessage({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final mien = m.auteur == Auteur.moi;
    final chemin = m.chemin;

    return Align(
      alignment: mien ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: mien ? Degrades.bleu : null,
          color: mien ? null : context.cl.carte,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mien ? 18 : 5),
            bottomRight: Radius.circular(mien ? 5 : 18),
          ),
          boxShadow: context.cl.ombreDouce,
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
                  color: mien ? Colors.white : context.cl.encre,
                ),
              ),
            if (m.fichier != null) ...[
              const SizedBox(height: 5),
              InkWell(
                onTap: (chemin == null || chemin.isEmpty)
                    ? null
                    : () => ouvrirDocument(context, chemin,
                        nomFichier: m.fichier),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 13,
                      color: mien ? Colors.white70 : context.cl.encreDouce,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        m.fichier!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          color:
                              mien ? Colors.white70 : context.cl.encreDouce,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                m.heure,
                style: TextStyle(
                  fontSize: 9.5,
                  color: mien ? Colors.white70 : context.cl.grise,
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
    return Container(
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(Rayons.lg)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, -4),
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.cl.fondDoux,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.cl.ligne),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: saisie,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: invite,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => onEnvoyer(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Joindre un document',
                    icon: Icon(Icons.attach_file,
                        color: context.cl.encreDouce, size: 22),
                    onPressed: enCours ? null : onJoindre,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: Degrades.bleu,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Palette.bleuFonce.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enCours ? null : onEnvoyer,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: enCours
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 21),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

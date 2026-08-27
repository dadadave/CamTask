import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

/// Les conversations en cours, vues par un conseiller.
///
/// Celles qui attendent une réponse remontent en tête : c'est le seul tri
/// qui compte quand on ouvre cet écran le matin.
class PageAgentConversations extends StatefulWidget {
  const PageAgentConversations({super.key});

  @override
  State<PageAgentConversations> createState() =>
      _PageAgentConversationsState();
}

class _PageAgentConversationsState extends State<PageAgentConversations> {
  List<Conversation>? _conversations;
  String _erreur = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    if (!mounted) return;
    final etat = PorteeApp.of(context);
    try {
      final liste = await etat.conversations();
      if (mounted) setState(() => _conversations = liste);
    } on ErreurBackend catch (e) {
      if (mounted) {
        setState(() {
          _conversations = const [];
          _erreur = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liste = _conversations;
    final attente = liste?.where((c) => !c.deLAgence).length ?? 0;

    return Coquille(
      titre: 'Messages',
      sousTitre: liste == null
          ? 'Chargement…'
          : attente == 0
              ? 'Aucune réponse en attente'
              : '$attente conversation(s) en attente',
      routeCourante: '/agent/conversations',
      retour: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _charger,
        ),
      ],
      enfants: [
        if (_erreur.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: _erreur),
          ),
        if (liste == null)
          const Padding(
            padding: EdgeInsets.all(Espaces.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (liste.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Espaces.xxl),
            child: Text(
              'Aucune conversation pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: context.cl.encreDouce),
            ),
          )
        else
          for (final c in liste)
            _CarteConversation(conversation: c, surRetour: _charger),
        const SizedBox(height: Espaces.xl),
      ],
    );
  }
}

class _CarteConversation extends StatelessWidget {
  const _CarteConversation({
    required this.conversation,
    required this.surRetour,
  });

  final Conversation conversation;

  /// Rappelé au retour du chat : le dernier message a pu changer.
  final Future<void> Function() surRetour;

  @override
  Widget build(BuildContext context) {
    final attend = !conversation.deLAgence;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Espaces.bord, Espaces.md, Espaces.bord, 0),
      child: Material(
        color: context.cl.carte,
        borderRadius: Rayons.brLg,
        child: InkWell(
          borderRadius: Rayons.brLg,
          onTap: () async {
            await Navigator.of(context).pushNamed(
              '/agent/chat',
              arguments: (
                clientId: conversation.clientId,
                clientNom: conversation.clientNom,
              ),
            );
            await surRetour();
          },
          child: Container(
            padding: const EdgeInsets.all(Espaces.lg),
            decoration: BoxDecoration(
              borderRadius: Rayons.brLg,
              border: Border.all(
                color: attend ? Palette.orange.withValues(alpha: 0.45)
                              : context.cl.ligne,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: Degrades.bleu,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    conversation.initiales,
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
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.clientNom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            conversation.dernierLe,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.cl.grise,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        conversation.dernierTexte,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              attend ? FontWeight.w600 : FontWeight.w400,
                          color: attend
                              ? context.cl.encre
                              : context.cl.encreDouce,
                        ),
                      ),
                    ],
                  ),
                ),
                if (attend) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Palette.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

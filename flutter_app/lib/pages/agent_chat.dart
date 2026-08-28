import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/conversation.dart';
import '../widgets/document.dart';

/// La conversation d'un client, côté conseiller.
///
/// L'écran reçoit en argument de route le client concerné. Rien n'est
/// vérifié ici : la RLS refuse de servir la conversation d'autrui à qui
/// n'est pas agent, et le refus s'affiche comme un message d'erreur.
class PageAgentChat extends StatefulWidget {
  const PageAgentChat({super.key});

  @override
  State<PageAgentChat> createState() => _PageAgentChatState();
}

class _PageAgentChatState extends State<PageAgentChat> {
  final _saisie = TextEditingController();
  final _defilement = ScrollController();

  List<Message> _messages = [];
  bool _charge = false;
  bool _envoi = false;
  String _erreur = '';
  Annulation? _ecoute;

  String _clientId = '';
  String _clientNom = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_charge) return;
    _charge = true;

    final args = ModalRoute.of(context)?.settings.arguments
        as ({String clientId, String clientNom})?;
    if (args == null) return;
    _clientId = args.clientId;
    _clientNom = args.clientNom;
    _ouvrir();
  }

  @override
  void dispose() {
    _ecoute?.call();
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  Future<void> _ouvrir() async {
    final etat = PorteeApp.of(context);
    try {
      final liste = await etat.messagesDe(_clientId);
      if (!mounted) return;
      setState(() => _messages = liste);
      _versLeBas();

      // Le client peut écrire pendant qu'on lit : on reste à l'écoute.
      _ecoute = etat.ecouterConversation(_clientId, (m) {
        if (!mounted) return;
        setState(() => _messages = [..._messages, m]);
        _versLeBas();
      });
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  void _versLeBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_defilement.hasClients) return;
      _defilement.animateTo(
        _defilement.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _envoyer({FichierChoisi? fichier}) async {
    final texte = _saisie.text.trim();
    if (texte.isEmpty && fichier == null) return;
    if (_envoi) return;

    setState(() {
      _envoi = true;
      _erreur = '';
    });
    final etat = PorteeApp.of(context);
    try {
      final message = await etat.repondre(
        _clientId,
        texte.isEmpty ? 'Document joint' : texte,
        fichier: fichier,
      );
      if (!mounted) return;
      setState(() => _messages = [..._messages, message]);
      _saisie.clear();
      _versLeBas();
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _joindre() async {
    final fichier = await choisirFichier();
    if (fichier == null || !mounted) return;
    await _envoyer(fichier: fichier);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cl.fondDoux,
      body: Column(
        children: [
          _enTete(),
          if (_erreur.isNotEmpty)
            Container(
              width: double.infinity,
              color: context.cl.orangeFantome,
              padding: const EdgeInsets.all(Espaces.md),
              child: Text(
                _erreur,
                style: TextStyle(
                    fontSize: 12.5, color: context.cl.accentTexte),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Espaces.xxl),
                      child: Text(
                        'Aucun message dans cette conversation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: context.cl.encreDouce,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _defilement,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) =>
                        BulleMessage(message: _messages[i]),
                  ),
          ),
          BarreSaisieMessage(
            saisie: _saisie,
            enCours: _envoi,
            invite: 'Répondre à $_clientNom…',
            onEnvoyer: _envoyer,
            onJoindre: _joindre,
          ),
        ],
      ),
    );
  }

  Widget _enTete() {
    return Container(
      decoration: const BoxDecoration(
        gradient: Degrades.bleu,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(Rayons.xl)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Palette.bleuFonce,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _clientNom.isEmpty ? 'C' : _clientNom[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _clientNom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vous répondez au nom de CAM-TAXE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

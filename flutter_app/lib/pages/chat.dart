import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/conversation.dart';
import '../widgets/coquille.dart';
import '../widgets/document.dart';

/// La conversation du client avec l'agence.
///
/// Elle se tient sur le même fond et sous la même barre que le reste de
/// l'application. Elle était jusqu'ici le seul écran bleu d'une
/// application orange, avec son en-tête fait main.
class PageChat extends StatefulWidget {
  const PageChat({super.key});

  @override
  State<PageChat> createState() => _PageChatState();
}

class _PageChatState extends State<PageChat> {
  final _saisie = TextEditingController();
  final _defilement = ScrollController();
  bool _sujetApplique = false;
  bool _envoi = false;
  String _erreur = '';

  @override
  void dispose() {
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sujetApplique) return;
    _sujetApplique = true;
    // Le sujet vient de l'écran de service d'où l'on arrive.
    final sujet = ModalRoute.of(context)?.settings.arguments as String?;
    if (sujet != null) _saisie.text = 'Bonjour, au sujet de « $sujet » : ';
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
      await etat.envoyerMessage(
        texte.isEmpty ? 'Document joint' : texte,
        fichier: fichier,
      );
      if (!mounted) return;
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
    final etat = PorteeApp.of(context);
    _versLeBas();

    return Scaffold(
      // Le même sable que les autres écrans : le chat n'a pas de raison
      // d'etre le seul d'une autre couleur.
      backgroundColor: context.cl.fond,
      appBar: const BarreConversation(
        titre: 'Conseiller CAM-TAXE',
        sousTitre: 'En ligne',
        initiales: 'CT',
        enLigne: true,
      ),
      body: Column(
        children: [
          if (_erreur.isNotEmpty) BandeauErreurChat(texte: _erreur),
          Expanded(
            child: etat.messages.isEmpty
                ? _accueil()
                : ListView.builder(
                    controller: _defilement,
                    padding: const EdgeInsets.fromLTRB(
                        Espaces.bord, Espaces.lg, Espaces.bord, Espaces.sm),
                    itemCount: etat.messages.length,
                    itemBuilder: (context, i) =>
                        BulleMessage(message: etat.messages[i]),
                  ),
          ),
          BarreSaisieMessage(
            saisie: _saisie,
            enCours: _envoi,
            onEnvoyer: _envoyer,
            onJoindre: _joindre,
          ),
        ],
      ),
      bottomNavigationBar: const NavigationBasse(routeCourante: '/chat'),
    );
  }

  /// Conversation vide.
  ///
  /// L'accueil est présenté comme un écran, non comme un message : il ne
  /// vient de personne, et le faire passer pour un mot d'un conseiller
  /// serait mentir au client sur ce qui l'attend.
  Widget _accueil() {
    final n = context.cl;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espaces.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: Degrades.orange,
                shape: BoxShape.circle,
                boxShadow: ombreOrange,
              ),
              child: const Icon(Icons.forum_rounded,
                  size: 33, color: Colors.white),
            ),
            const SizedBox(height: Espaces.xl),
            const Text(
              'Posez votre question',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: Espaces.sm),
            Text(
              'Un conseiller CAM-TAXE vous répond : déclaration, NIU/ACF, '
              'DSF, audit ou contentieux fiscal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: n.encreDouce,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

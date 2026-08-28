import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/conversation.dart';
import '../widgets/coquille.dart';
import '../widgets/document.dart';

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
            child: etat.messages.isEmpty
                ? _accueil()
                : ListView.builder(
                    controller: _defilement,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
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
                onPressed: () => Navigator.of(context).canPop()
                    ? Navigator.of(context).pop()
                    : Navigator.of(context).pushNamed('/accueil'),
              ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Palette.bleuFonce,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'J',
                  style: TextStyle(
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
                    const Text(
                      'Judicaël',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Palette.succes,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'En ligne',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.white),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Conversation vide.
  ///
  /// L'accueil est présenté comme un écran, non comme un message : il ne
  /// vient de personne, et le faire passer pour un mot de Judicaël serait
  /// mentir au client sur ce qui l'attend.
  Widget _accueil() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espaces.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.cl.bleuFantome,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined,
                  size: 29, color: Palette.bleuFonce),
            ),
            const SizedBox(height: Espaces.lg),
            const Text(
              'Posez votre question',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Espaces.sm),
            Text(
              'Un conseiller CAM-TAXE vous répond : déclaration, NIU/ACF, '
              'DSF, audit ou contentieux fiscal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: context.cl.encreDouce,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

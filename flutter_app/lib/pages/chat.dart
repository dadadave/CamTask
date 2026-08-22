import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/coquille.dart';

class PageChat extends StatefulWidget {
  const PageChat({super.key});

  @override
  State<PageChat> createState() => _PageChatState();
}

class _PageChatState extends State<PageChat> {
  final _saisie = TextEditingController();
  final _defilement = ScrollController();
  bool _sujetApplique = false;

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

  void _envoyer() {
    final texte = _saisie.text.trim();
    if (texte.isEmpty) return;
    PorteeApp.of(context).envoyerMessage(texte);
    _saisie.clear();
    _versLeBas();
  }

  Future<void> _joindre() async {
    final res = await FilePicker.platform.pickFiles(withData: false);
    if (res == null || res.files.isEmpty || !mounted) return;
    final texte = _saisie.text.trim();
    PorteeApp.of(context).envoyerMessage(
      texte.isEmpty ? 'Document joint' : texte,
      fichier: res.files.first.name,
    );
    _saisie.clear();
    _versLeBas();
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
          Expanded(
            child: ListView.builder(
              controller: _defilement,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              itemCount: etat.messages.length,
              itemBuilder: (context, i) => _bulle(etat.messages[i]),
            ),
          ),
          _barreSaisie(),
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

  Widget _bulle(Message m) {
    final mien = m.auteur == Auteur.moi;
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
            Text(
              m.texte,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: mien ? Colors.white : context.cl.encre,
              ),
            ),
            if (m.fichier != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 13,
                    color: mien ? Colors.white70 : context.cl.encreDouce,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    m.fichier!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: mien ? Colors.white70 : context.cl.encreDouce,
                    ),
                  ),
                ],
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

  Widget _barreSaisie() {
    return Container(
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Rayons.lg)),
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
                  Icon(Icons.sentiment_satisfied_alt,
                      color: context.cl.encreDouce, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _saisie,
                      decoration: const InputDecoration(
                        hintText: 'Votre message…',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _envoyer(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.photo_camera_outlined,
                        color: context.cl.encreDouce, size: 22),
                    onPressed: _joindre,
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file,
                        color: context.cl.encreDouce, size: 22),
                    onPressed: _joindre,
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
                onTap: _envoyer,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _saisie,
                    builder: (context, valeur, _) => Icon(
                      valeur.text.trim().isEmpty
                          ? Icons.mic_rounded
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

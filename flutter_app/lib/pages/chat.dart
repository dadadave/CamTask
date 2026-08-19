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
      backgroundColor: Palette.fondDoux,
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
        color: Palette.bleu,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
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
              const Expanded(
                child: Text(
                  'judicael',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
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
          color: mien ? Palette.bleu : Palette.carte,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mien ? 14 : 4),
            bottomRight: Radius.circular(mien ? 4 : 14),
          ),
          boxShadow: ombreDouce,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.texte,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: mien ? Colors.white : Palette.encre,
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
                    color: mien ? Colors.white70 : Palette.encreDouce,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    m.fichier!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: mien ? Colors.white70 : Palette.encreDouce,
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
                  color: mien ? Colors.white70 : Palette.grise,
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
      decoration: const BoxDecoration(
        color: Palette.bleu,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Palette.fondDoux,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sentiment_satisfied_alt,
                      color: Palette.encreDouce, size: 22),
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
                    icon: const Icon(Icons.photo_camera_outlined,
                        color: Palette.encreDouce, size: 22),
                    onPressed: _joindre,
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: Palette.encreDouce, size: 22),
                    onPressed: _joindre,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Palette.bleuFonce,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _envoyer,
              child: SizedBox(
                width: 46,
                height: 46,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _saisie,
                  builder: (context, valeur, _) => Icon(
                    valeur.text.trim().isEmpty ? Icons.mic : Icons.send,
                    color: Colors.white,
                    size: 22,
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

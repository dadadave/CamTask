import 'package:flutter/material.dart';

import '../data/conseil.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

class PageConseilFiscal extends StatefulWidget {
  const PageConseilFiscal({super.key});

  @override
  State<PageConseilFiscal> createState() => _PageConseilFiscalState();
}

class _PageConseilFiscalState extends State<PageConseilFiscal> {
  String? _ouverte;
  final _choix = <String>{};
  bool _autreOuvert = false;
  String _erreur = '';
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  List<String> _titresChoisis() => [
        for (final q in questionsConseil)
          for (final s in q.sousQuestions)
            if (_choix.contains(s.id)) s.titre,
      ];

  void _envoyer() {
    final titres = _titresChoisis();
    final message = _message.text.trim();
    if (titres.isEmpty && message.isEmpty) {
      setState(() => _erreur =
          'Choisissez au moins une préoccupation ou décrivez la vôtre.');
      return;
    }

    PorteeApp.of(context).envoyerDemande(
      serviceId: 'conseil',
      serviceLibelle: 'Besoin de conseil fiscale',
      resume: [
        if (titres.isNotEmpty) 'Préoccupations : ${titres.join(' • ')}',
        if (message.isNotEmpty) 'Autre préoccupation : $message',
      ].join('\n'),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Votre demande de conseil a été envoyée. '
            'Un conseiller vous répond sous peu.'),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/profil', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Coquille(
      titre: 'Conseil fiscal',
      routeCourante: '',
      enfants: [
        const EnTeteService(libelle: 'Besoin de conseil fiscale'),
        const Encadre(enfants: [Text(conseilAccroche, style: Textes.corpsGras)]),
        Encadre(
          enfants: [
            Text(conseilIntro, style: Textes.corps(context), textAlign: TextAlign.justify),
          ],
        ),
        for (final q in questionsConseil) _question(q),
        _autrePreoccupation(),
        if (_erreur.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TexteErreur(texte: _erreur),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Center(
            child: BoutonEnvoyer(onTap: _envoyer),
          ),
        ),
        Encadre(
          enfants: [
            for (final t in conseilCloture) ...[
              Text(t, style: Textes.corpsGras, textAlign: TextAlign.justify),
              const SizedBox(height: 8),
            ],
          ],
        ),
        const DiscuterAgent(sujet: 'Besoin de conseil fiscale'),
      ],
    );
  }

  Widget _question(QuestionConseil q) {
    final ouvert = _ouverte == q.id;
    final nb = q.sousQuestions.where((s) => _choix.contains(s.id)).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: context.cl.carte,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _ouverte = ouvert ? null : q.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.orange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        q.titre,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (nb > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Palette.orange,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$nb',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: ouvert ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right,
                          size: 20, color: Palette.orange),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ouvert)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Column(
                children: [
                  for (final s in q.sousQuestions)
                    _sousQuestion(s),
                ],
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sousQuestion(SousQuestion s) {
    final actif = _choix.contains(s.id);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() {
          actif ? _choix.remove(s.id) : _choix.add(s.id);
          _erreur = '';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: actif ? context.cl.orangeFantome : context.cl.fondDoux,
            border: Border.all(
              color: actif ? Palette.orange : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: actif ? Palette.orange : Palette.orangeClair,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: s.titre,
                        style: const TextStyle(
                          color: Palette.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' : ${s.detail}'),
                    ],
                  ),
                  style: const TextStyle(fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _autrePreoccupation() {
    return Encadre(
      marge: const EdgeInsets.fromLTRB(14, 6, 14, 16),
      enfants: [
        const TitrePanneau(texte: 'Autre préoccupation'),
        if (_autreOuvert)
          ZoneTexte(libelle: 'message', controleur: _message)
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Palette.orange,
                side: const BorderSide(color: Palette.orange),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => setState(() => _autreOuvert = true),
              child: const Text('Saisir ma préoccupation'),
            ),
          ),
      ],
    );
  }
}

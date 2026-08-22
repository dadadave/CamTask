import 'package:flutter/material.dart';

import '../data/audit.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

const _operateurs = <String>[
  'MTN Mobile Money',
  'Orange Money',
  'Virement bancaire',
];

class PageAudit extends StatefulWidget {
  const PageAudit({super.key});

  @override
  State<PageAudit> createState() => _PageAuditState();
}

class _PageAuditState extends State<PageAudit> {
  final _structure = TextEditingController();
  final _niu = TextEditingController();
  final _telephone = TextEditingController();
  String? _type;
  String _erreur = '';
  final _fichiers = <String, String>{};

  // Paiement de la caution
  bool _paiementOuvert = false;
  String _operateur = '';
  bool _cautionPayee = false;

  @override
  void dispose() {
    _structure.dispose();
    _niu.dispose();
    _telephone.dispose();
    super.dispose();
  }

  void _payerCaution() {
    if (_operateur.isEmpty || _telephone.text.trim().isEmpty) {
      setState(() => _erreur = 'Choisissez un moyen de paiement et saisissez '
          'le numéro à débiter.');
      return;
    }
    setState(() {
      _cautionPayee = true;
      _paiementOuvert = false;
      _erreur = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Caution enregistrée via $_operateur.')),
    );
  }

  void _envoyer() {
    final manquants = <String>[
      if (_structure.text.trim().isEmpty) 'Nom de la structure',
      if (_type == null) "Type d'audit",
      if (_niu.text.trim().isEmpty) 'NIU',
      if (!_cautionPayee) 'Paiement de caution',
    ];
    if (manquants.isNotEmpty) {
      setState(() => _erreur = 'À compléter : ${manquants.join(', ')}.');
      return;
    }

    final pieces = [
      for (final e in _fichiers.entries)
        Piece(libelle: e.key, fichier: e.value),
    ];
    PorteeApp.of(context).envoyerDemande(
      serviceId: 'audit',
      serviceLibelle: 'Faire un audit',
      resume: '$_type — ${_structure.text} — NIU ${_niu.text} — '
          'caution réglée ($_operateur)',
      pieces: pieces,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Demande d'audit envoyée "
            '(${pieces.length} document(s)).'),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/profil', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Coquille(
      titre: 'Faire un audit',
      enfants: [
        const EnTeteService(libelle: 'Faire un audit'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Champ(libelle: 'Nom de la structure', controleur: _structure),
              const SizedBox(height: 22),
              Selecteur(
                libelle: "Type d'audit",
                valeur: _type,
                options: typesAudit,
                encadre: true,
                onChange: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 22),
              Champ(libelle: 'NIU', controleur: _niu, encadre: true),
              const SizedBox(height: 22),
              Material(
                color: _cautionPayee
                    ? const Color(0xFF3F9E63)
                    : Palette.orangeClair,
                borderRadius: BorderRadius.circular(12),
                elevation: 1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      setState(() => _paiementOuvert = !_paiementOuvert),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      _cautionPayee ? '✓ CAUTION PAYÉE' : 'PAIEMENT DE CAUTION',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              if (_paiementOuvert && !_cautionPayee) ...[
                const SizedBox(height: 16),
                Encadre(
                  marge: EdgeInsets.zero,
                  enfants: [
                    Text('MOYEN DE PAIEMENT', style: Textes.libelle(context)),
                    const SizedBox(height: 10),
                    Pastilles(
                      options: _operateurs,
                      selection: _operateur.isEmpty ? const [] : [_operateur],
                      larges: true,
                      onBascule: (v) => setState(
                        () => _operateur = _operateur == v ? '' : v,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Champ(
                      libelle: 'Numéro à débiter',
                      controleur: _telephone,
                      clavier: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    BoutonEnvoyer(
                      onTap: _payerCaution,
                      libelle: 'Valider le paiement',
                      bloc: true,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Encadre(
          enfants: [
            for (final t in auditPresentation) ...[
              Text(t, style: Textes.corpsGras, textAlign: TextAlign.justify),
              const SizedBox(height: 8),
            ],
          ],
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: Text(
            auditConsigne,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
        for (final section in sectionsAudit)
          Encadre(
            enfants: [
              TitrePanneau(texte: section.titre),
              for (final doc in section.documents) ...[
                Televersement(
                  libelle: doc,
                  fichier: _fichiers[doc],
                  onChoisi: (n) => setState(() => _fichiers[doc] = n),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_erreur.isNotEmpty) ...[
                TexteErreur(texte: _erreur),
                const SizedBox(height: 14),
              ],
              BoutonEnvoyer(onTap: _envoyer),
            ],
          ),
        ),
        const DiscuterAgent(sujet: 'Faire un audit'),
      ],
    );
  }
}

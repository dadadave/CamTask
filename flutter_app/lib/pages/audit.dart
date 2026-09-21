import 'package:flutter/material.dart';

import '../data/audit.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/envoi_demande.dart';
import '../widgets/coquille.dart';

class PageAudit extends StatefulWidget {
  const PageAudit({super.key});

  @override
  State<PageAudit> createState() => _PageAuditState();
}

class _PageAuditState extends State<PageAudit> with EnvoiDemande {
  final _structure = TextEditingController();
  final _niu = TextEditingController();
  final _telephone = TextEditingController();
  String? _type;
  String _erreur = '';
  final _fichiers = <String, FichierChoisi>{};

  @override
  void dispose() {
    _structure.dispose();
    _niu.dispose();
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final manquants = <String>[
      if (_structure.text.trim().isEmpty) 'Nom de la structure',
      if (_type == null) "Type d'audit",
      if (_niu.text.trim().isEmpty) 'NIU',
    ];
    if (manquants.isNotEmpty) {
      setState(() => _erreur = 'À compléter : ${manquants.join(', ')}.');
      return;
    }

    final pieces = [
      for (final e in _fichiers.entries)
        PieceEnvoi(libelle: e.key, fichier: e.value),
    ];
    await envoyerDemande(
      serviceId: 'audit',
      serviceLibelle: 'Faire un audit',
      resume: '$_type — ${_structure.text} — NIU ${_niu.text}',
      pieces: pieces,
      confirmation: "Dossier enregistré. Réglez la caution pour qu'un "
          'conseiller le prenne en charge.',
      surErreur: (m) => setState(() => _erreur = m),
    );
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
              Container(
                padding: const EdgeInsets.all(Espaces.lg),
                decoration: BoxDecoration(
                  color: context.cl.orangeFantome,
                  borderRadius: Rayons.brLg,
                  border: Border.all(
                      color: context.cl.accentTexte.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 20, color: context.cl.accentTexte),
                    const SizedBox(width: Espaces.md),
                    Expanded(
                      child: Text(
                        'Une caution est demandée pour cet audit. Vous la '
                        'réglerez par mobile money juste après l\'envoi du '
                        'dossier.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: context.cl.encreDouce,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
              BoutonEnvoiDemande(
                enCours: envoiEnCours,
                enfant: BoutonEnvoyer(onTap: _envoyer),
              ),
            ],
          ),
        ),
        const DiscuterAgent(sujet: 'Faire un audit'),
      ],
    );
  }
}

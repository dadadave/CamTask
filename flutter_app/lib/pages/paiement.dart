import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

/// Ce que l'écran de paiement reçoit en argument de route.
typedef ArgsPaiement = ({
  String demandeId,
  String serviceId,
  String serviceLibelle,
});

/// Régler une caution par mobile money, sans passerelle.
///
/// Le client compose lui-même le code USSD de l'agence, puis **déclare**
/// son versement. Il ne le valide pas : c'est un administrateur qui
/// confirmera après l'avoir retrouvé sur le relevé. Tant que la
/// confirmation n'est pas venue, l'écran dit « en attente de vérification »
/// et rien d'autre — promettre davantage serait mentir au client.
class PagePaiement extends StatefulWidget {
  const PagePaiement({super.key});

  @override
  State<PagePaiement> createState() => _PagePaiementState();
}

class _PagePaiementState extends State<PagePaiement> {
  final _numero = TextEditingController();
  final _reference = TextEditingController();

  List<MoyenPaiement>? _moyens;
  Facture? _facture;
  Paiement? _existant;

  String _choisi = '';
  bool _atteste = false;
  bool _envoi = false;
  bool _charge = false;
  String _erreur = '';

  ArgsPaiement? _args;

  @override
  void dispose() {
    _numero.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_charge) return;
    _charge = true;
    _args = ModalRoute.of(context)?.settings.arguments as ArgsPaiement?;
    _ouvrir();
  }

  Future<void> _ouvrir() async {
    final args = _args;
    if (args == null) return;
    final etat = PorteeApp.of(context);
    try {
      final moyens = await etat.moyensPaiement();
      final facture = await etat.factureDuDossier(args.demandeId);
      final deja = await etat.paiementsDuDossier(args.demandeId);
      if (!mounted) return;
      setState(() {
        _moyens = moyens;
        _facture = facture;
        _existant = deja.where((p) => p.statut != StatutPaiement.rejete)
            .cast<Paiement?>()
            .firstWhere((p) => true, orElse: () => null);
        if (moyens.length == 1) _choisi = moyens.first.id;
      });
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  Future<void> _copier(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié.')),
    );
  }

  /// Ouvre le clavier téléphonique avec le code déjà saisi.
  ///
  /// Android n'autorise pas à composer un code USSD sans geste de
  /// l'utilisateur : on se contente de le pré-remplir.
  Future<void> _composer(String code) async {
    final messager = ScaffoldMessenger.of(context);
    final uri = Uri(scheme: 'tel', path: code);
    if (!await launchUrl(uri)) {
      messager.showSnackBar(const SnackBar(
        content: Text('Impossible d\'ouvrir le clavier. Copiez le code.'),
      ));
    }
  }

  Future<void> _declarer() async {
    final args = _args;
    if (args == null || _envoi) return;

    final facture = _facture;
    if (facture == null) return;

    // La référence est exigée : sans elle, retrouver le versement dans un
    // relevé revient à chercher un montant et un numéro à l'aveugle.
    final manquants = <String>[
      if (_choisi.isEmpty) 'Moyen de paiement',
      if (_numero.text.trim().isEmpty) 'Numéro utilisé',
      if (_reference.text.trim().isEmpty) 'Identifiant de la transaction',
    ];
    if (manquants.isNotEmpty) {
      setState(() => _erreur = 'À compléter : ${manquants.join(', ')}.');
      return;
    }
    if (!_atteste) {
      setState(() => _erreur =
          'Cochez la case pour confirmer que le versement est effectué.');
      return;
    }

    setState(() {
      _envoi = true;
      _erreur = '';
    });
    final etat = PorteeApp.of(context);
    try {
      await etat.declarerPaiement(
        factureId: facture.id,
        operateur: _choisi,
        numeroEnvoyeur: _numero.text.trim(),
        reference: _reference.text.trim(),
      );
      if (!mounted) return;
      await _ouvrir();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Déclaration enregistrée. Nous la vérifions.'),
      ));
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    final moyens = _moyens;

    return Coquille(
      titre: 'Paiement',
      sousTitre: args?.serviceLibelle,
      navigation: false,
      enfants: [
        if (_erreur.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: _erreur),
          ),
        if (moyens == null)
          const Padding(
            padding: EdgeInsets.all(Espaces.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_existant != null)
          _Recapitulatif(paiement: _existant!)
        else if (moyens.isEmpty || _facture == null)
          const _Indisponible()
        else ...[
          _Montant(facture: _facture!),
          for (final m in moyens) _CarteMoyen(
            moyen: m,
            facture: _facture!,
            onCopier: () => _copier(m.codeUssd),
            onComposer: () => _composer(m.codeUssd),
          ),
          _Declaration(
            moyens: moyens,
            facture: _facture!,
            choisi: _choisi,
            numero: _numero,
            reference: _reference,
            atteste: _atteste,
            envoi: _envoi,
            onMoyen: (v) => setState(() => _choisi = v),
            onAtteste: (v) => setState(() => _atteste = v),
            onDeclarer: _declarer,
          ),
        ],
        const SizedBox(height: Espaces.xxl),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */

class _Montant extends StatelessWidget {
  const _Montant({required this.facture});

  final Facture facture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.lg, Espaces.bord, 0),
      child: CarteMaille(
        hauteur: 148,
        enfant: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PastilleIcone(
                  icone: Icons.account_balance_wallet_outlined,
                  surCouleur: true),
              const Spacer(),
              Text(
                '${facture.numero}  •  ${facture.serviceLibelle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                facture.montantFormate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un opérateur : son code, à copier ou à composer.
class _CarteMoyen extends StatelessWidget {
  const _CarteMoyen({
    required this.moyen,
    required this.facture,
    required this.onCopier,
    required this.onComposer,
  });

  final MoyenPaiement moyen;
  final Facture facture;
  final VoidCallback onCopier;
  final VoidCallback onComposer;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final accent = moyen.estOrange ? n.accentTexte : const Color(0xFF9A7B00);
    final fond = moyen.estOrange ? n.orangeFantome : const Color(0x22D4A017);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.md, Espaces.bord, 0),
      child: Container(
        padding: const EdgeInsets.all(Espaces.lg),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: brBento,
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${moyen.libelle.toUpperCase()} — COMPOSEZ CE CODE',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: accent,
              ),
            ),
            const SizedBox(height: Espaces.md),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    moyen.codeUssd,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: n.encre,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copier',
                  icon: Icon(Icons.copy_rounded, size: 20, color: accent),
                  onPressed: onCopier,
                ),
              ],
            ),
            const SizedBox(height: Espaces.sm),
            Divider(color: accent.withValues(alpha: 0.30), height: 1),
            const SizedBox(height: Espaces.md),
            if (moyen.beneficiaire.isNotEmpty)
              _Ligne(
                libelle: 'Bénéficiaire',
                valeur: moyen.beneficiaire,
                accent: n.encre,
              ),
            _Ligne(
              libelle: 'Montant à saisir',
              valeur: facture.montantFormate,
              accent: accent,
            ),
            if (moyen.consigne.isNotEmpty) ...[
              const SizedBox(height: Espaces.sm),
              Text(
                moyen.consigne,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: n.encreDouce,
                ),
              ),
            ],
            const SizedBox(height: Espaces.md),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.55)),
                minimumSize: const Size(double.infinity, 44),
                shape: const RoundedRectangleBorder(
                    borderRadius: Rayons.brPilule),
              ),
              icon: const Icon(Icons.dialpad_rounded, size: 18),
              label: const Text('Ouvrir le clavier téléphonique'),
              onPressed: onComposer,
            ),
          ],
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.libelle,
    required this.valeur,
    required this.accent,
  });

  final String libelle;
  final String valeur;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            libelle,
            style: TextStyle(fontSize: 13, color: context.cl.encreDouce),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              valeur,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le formulaire de déclaration.
class _Declaration extends StatelessWidget {
  const _Declaration({
    required this.moyens,
    required this.facture,
    required this.choisi,
    required this.numero,
    required this.reference,
    required this.atteste,
    required this.envoi,
    required this.onMoyen,
    required this.onAtteste,
    required this.onDeclarer,
  });

  final List<MoyenPaiement> moyens;
  final Facture facture;
  final String choisi;
  final TextEditingController numero;
  final TextEditingController reference;
  final bool atteste;
  final bool envoi;
  final ValueChanged<String> onMoyen;
  final ValueChanged<bool> onAtteste;
  final VoidCallback onDeclarer;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.xxl, Espaces.bord, 0),
      child: Container(
        padding: const EdgeInsets.all(Espaces.lg),
        decoration: BoxDecoration(
          color: n.carte,
          borderRadius: brBento,
          border: Border.all(color: n.ligne),
          boxShadow: n.ombreDouce,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Une fois le versement effectué',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: n.encre,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ces informations nous permettent de retrouver votre versement '
              'sur notre relevé.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: n.grise),
            ),
            const SizedBox(height: Espaces.lg),
            const LibelleSection(texte: 'Moyen utilisé'),
            const SizedBox(height: Espaces.sm),
            Pastilles(
              options: [for (final m in moyens) m.libelle],
              selection: [
                for (final m in moyens)
                  if (m.id == choisi) m.libelle,
              ],
              onBascule: (v) => onMoyen(
                moyens.firstWhere((m) => m.libelle == v).id,
              ),
            ),
            const SizedBox(height: Espaces.lg),
            Champ(
              libelle: 'Numéro utilisé pour le versement',
              controleur: numero,
              clavier: TextInputType.phone,
              majuscules: false,
            ),
            const SizedBox(height: Espaces.lg),
            Champ(
              libelle: 'Identifiant de la transaction',
              controleur: reference,
              majuscules: false,
              aide: 'Le code reçu par SMS après votre versement. Il nous '
                  'permet de retrouver l\'opération.',
            ),
            const SizedBox(height: Espaces.lg),
            InkWell(
              borderRadius: Rayons.brSm,
              onTap: () => onAtteste(!atteste),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: atteste,
                      onChanged: (v) => onAtteste(v ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Je confirme avoir effectué le versement de '
                          '${facture.montantFormate}.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: n.encre,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Espaces.md),
            if (envoi)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              )
            else
              BoutonEnvoyer(
                bloc: true,
                libelle: 'J\'ai effectué le paiement',
                icone: Icons.check_rounded,
                onTap: onDeclarer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Ce que voit le client une fois sa déclaration enregistrée.
class _Recapitulatif extends StatelessWidget {
  const _Recapitulatif({required this.paiement});

  final Paiement paiement;

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final confirme = paiement.statut == StatutPaiement.confirme;
    final accent = confirme ? n.succesTexte : n.accentTexte;
    final fond = confirme ? n.succesFantome : n.orangeFantome;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.xl, Espaces.bord, 0),
      child: Container(
        padding: const EdgeInsets.all(Espaces.xl),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: brBento,
          border: Border.all(color: accent.withValues(alpha: 0.40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PastilleIcone(
              icone: confirme
                  ? Icons.verified_rounded
                  : Icons.hourglass_bottom_rounded,
              taille: 44,
              teinte: accent,
            ),
            const SizedBox(height: Espaces.lg),
            Text(
              paiement.libelleStatut,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              confirme
                  ? 'Nous avons retrouvé votre versement. Votre dossier suit '
                      'son cours.'
                  : 'Nous vérifions votre versement sur notre relevé. Cela '
                      'prend généralement quelques heures ouvrées.',
              style: TextStyle(fontSize: 13, height: 1.5, color: n.encreDouce),
            ),
            if (paiement.motif.isNotEmpty) ...[
              const SizedBox(height: Espaces.md),
              Text(
                paiement.motif,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: n.encre,
                ),
              ),
            ],
            const SizedBox(height: Espaces.lg),
            _Ligne(
              libelle: 'Montant',
              valeur: paiement.montantFormate,
              accent: n.encre,
            ),
            _Ligne(
              libelle: 'Déclaré le',
              valeur: paiement.date,
              accent: n.encre,
            ),
            if (paiement.numeroEnvoyeur.isNotEmpty)
              _Ligne(
                libelle: 'Depuis le',
                valeur: paiement.numeroEnvoyeur,
                accent: n.encre,
              ),
            if (paiement.reference.isNotEmpty)
              _Ligne(
                libelle: 'Référence',
                valeur: paiement.reference,
                accent: n.encre,
              ),
          ],
        ),
      ),
    );
  }
}

/// L'agence n'a pas encore renseigné ses codes.
class _Indisponible extends StatelessWidget {
  const _Indisponible();

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    return Padding(
      padding: const EdgeInsets.all(Espaces.xxl),
      child: Column(
        children: [
          const PastilleIcone(
              icone: Icons.payments_outlined, taille: 56),
          const SizedBox(height: Espaces.lg),
          Text(
            'Paiement momentanément indisponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: n.encre,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Votre dossier est bien enregistré. Un conseiller vous indiquera '
            'comment régler la caution.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: n.encreDouce),
          ),
        ],
      ),
    );
  }
}

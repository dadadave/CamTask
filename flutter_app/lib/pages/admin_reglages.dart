import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

/// Les tarifs et les numéros marchands de l'agence.
///
/// Tout vit en base : changer un code USSD ou un montant se fait d'ici, et
/// tous les clients le voient aussitôt — sans nouvelle version à installer.
class PageAdminReglages extends StatefulWidget {
  const PageAdminReglages({super.key});

  @override
  State<PageAdminReglages> createState() => _PageAdminReglagesState();
}

class _PageAdminReglagesState extends State<PageAdminReglages> {
  List<MoyenPaiement>? _moyens;
  List<TarifService> _tarifs = const [];
  String _erreur = '';
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrir());
  }

  Future<void> _ouvrir() async {
    if (!mounted) return;
    final etat = PorteeApp.of(context);
    try {
      final moyens = await etat.moyensPaiement();
      final tarifs = await etat.tarifs();
      if (!mounted) return;
      setState(() {
        _moyens = moyens;
        _tarifs = tarifs;
        _charge = true;
      });
    } on ErreurBackend catch (e) {
      if (mounted) {
        setState(() {
          _moyens = const [];
          _charge = true;
          _erreur = e.message;
        });
      }
    }
  }

  Future<void> _modifierTarif(TarifService t) async {
    final part = TextEditingController(
        text: t.particulier == 0 ? '' : t.particulier.toString());
    final ent = TextEditingController(
        text: t.entreprise == 0 ? '' : t.entreprise.toString());

    final valide = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.libelle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deux prix, en francs CFA. Un montant à 0 rend le service '
              'gratuit pour ce profil — aucune facture n\'est alors émise.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: Espaces.lg),
            TextField(
              controller: part,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Particulier',
                suffixText: 'FCFA',
              ),
            ),
            const SizedBox(height: Espaces.md),
            TextField(
              controller: ent,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Entreprise',
                suffixText: 'FCFA',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (valide != true || !mounted) return;

    final p = int.tryParse(part.text.trim()) ?? 0;
    final e = int.tryParse(ent.text.trim()) ?? 0;
    try {
      await PorteeApp.of(context).definirTarif(
        t.serviceId, p, e, p > 0 || e > 0);
      await _ouvrir();
    } on ErreurBackend catch (err) {
      if (mounted) setState(() => _erreur = err.message);
    }
  }

  Future<void> _modifierMoyen(MoyenPaiement? m, String id, String libelle) async {
    final code = TextEditingController(text: m?.codeUssd ?? '');
    final nom = TextEditingController(text: m?.beneficiaire ?? '');

    final valide = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(libelle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le code que le client composera, et le nom qu\'il doit voir '
              'à la confirmation.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: Espaces.md),
            TextField(
              controller: code,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Code USSD',
                hintText: '#150*46*0000000#',
              ),
            ),
            const SizedBox(height: Espaces.md),
            TextField(
              controller: nom,
              decoration: const InputDecoration(
                labelText: 'Bénéficiaire',
                hintText: 'Tel qu\'il s\'affiche au client',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (valide != true || !mounted) return;

    final etat = PorteeApp.of(context);
    final texte = code.text.trim();
    try {
      // Un code vide désactive le moyen : mieux vaut ne rien proposer qu'un
      // code creux que le client composerait en vain.
      await etat.definirMoyen(id, texte, nom.text.trim(), texte.isNotEmpty);
      await _ouvrir();
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = context.cl;
    final moyens = _moyens;

    return Coquille(
      titre: 'Tarifs et paiement',
      sousTitre: 'Visible immédiatement par vos clients',
      navigation: false,
      enfants: [
        if (_erreur.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: _erreur),
          ),
        if (!_charge)
          const Padding(
            padding: EdgeInsets.all(Espaces.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.xl, Espaces.bord, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TitreSection(texte: 'Tarifs des services'),
                Padding(
                  padding: const EdgeInsets.only(bottom: Espaces.md),
                  child: Text(
                    'Deux prix par service : un pour les particuliers, un '
                    'pour les entreprises. Le client ne voit que le sien.',
                    style: TextStyle(
                        fontSize: 12, height: 1.5, color: n.grise),
                  ),
                ),
                for (final t in _tarifs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Espaces.md),
                    child: BandeauBento(
                      icone: Icons.sell_outlined,
                      titre: t.libelle,
                      sousTitre: t.gratuit
                          ? 'Gratuit — aucune facture émise'
                          : 'Particulier ${montantEnFcfa(t.particulier)}'
                              '   •   Entreprise '
                              '${montantEnFcfa(t.entreprise)}',
                      teinte: t.gratuit ? null : n.succesTexte,
                      onTap: () => _modifierTarif(t),
                    ),
                  ),
                const SizedBox(height: Espaces.xxl),
                const TitreSection(texte: 'Moyens de paiement'),
                for (final (id, libelle) in const [
                  ('orange', 'Orange Money'),
                  ('mtn', 'MTN Mobile Money'),
                ]) ...[
                  Builder(builder: (context) {
                    final m = moyens
                        ?.where((x) => x.id == id)
                        .cast<MoyenPaiement?>()
                        .firstWhere((x) => true, orElse: () => null);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Espaces.md),
                      child: BandeauBento(
                        icone: Icons.smartphone_rounded,
                        titre: libelle,
                        sousTitre: m == null
                            ? 'Inactif — aucun code renseigné'
                            : '${m.codeUssd}   •   ${m.beneficiaire}',
                        teinte: m == null ? null : n.succesTexte,
                        onTap: () => _modifierMoyen(m, id, libelle),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: Espaces.md),
                Text(
                  'Tant qu\'un moyen n\'a pas de code, il n\'est pas proposé '
                  'au client : l\'écran de paiement indique alors qu\'un '
                  'conseiller le recontactera.',
                  style: TextStyle(
                      fontSize: 12, height: 1.5, color: n.grise),
                ),

              ],
            ),
          ),
        ],
        const SizedBox(height: Espaces.xxl),
      ],
    );
  }
}

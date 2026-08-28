import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';

/// Qui est conseiller, et qui ne l'est pas.
///
/// Réservé aux administrateurs. Rien n'est vérifié ici : la base refuse de
/// servir la liste à qui n'a pas le droit, et refuse toute nomination qui ne
/// vient pas d'un admin. L'écran ne fait qu'éviter de la montrer.
class PageAdminEquipe extends StatefulWidget {
  const PageAdminEquipe({super.key});

  @override
  State<PageAdminEquipe> createState() => _PageAdminEquipeState();
}

class _PageAdminEquipeState extends State<PageAdminEquipe> {
  List<MembreEquipe>? _membres;
  String _erreur = '';
  String _recherche = '';

  /// L'identifiant en cours de modification, pour n'immobiliser que sa ligne.
  String? _occupe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    if (!mounted) return;
    try {
      final liste = await PorteeApp.of(context).comptes();
      if (mounted) setState(() => _membres = liste);
    } on ErreurBackend catch (e) {
      if (mounted) {
        setState(() {
          _membres = const [];
          _erreur = e.message;
        });
      }
    }
  }

  /// Nommer quelqu'un conseiller lui ouvre les dossiers de tous les clients.
  /// Ce n'est pas un réglage anodin : on le fait dire à voix haute.
  Future<bool> _confirmer(MembreEquipe m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(m.estAgent ? 'Retirer l\'habilitation' : 'Nommer conseiller'),
        content: Text(
          m.estAgent
              ? '${m.nomComplet} n\'aura plus accès aux dossiers des clients.'
              : '${m.nomComplet} verra les dossiers, les pièces et les '
                  'conversations de TOUS vos clients — CNI et NIU compris.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(m.estAgent ? 'Retirer' : 'Confirmer'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _basculer(MembreEquipe m) async {
    if (_occupe != null) return;
    if (!await _confirmer(m) || !mounted) return;

    setState(() {
      _occupe = m.id;
      _erreur = '';
    });
    final etat = PorteeApp.of(context);
    try {
      await etat.nommerConseiller(m.id, !m.estAgent);
      if (!mounted) return;
      setState(() {
        _membres = [
          for (final x in _membres ?? const <MembreEquipe>[])
            if (x.id == m.id) x.avec(estAgent: !m.estAgent) else x,
        ];
      });
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _occupe = null);
    }
  }

  List<MembreEquipe> _filtres(List<MembreEquipe> tous) {
    final q = _recherche.trim().toLowerCase();
    if (q.isEmpty) return tous;
    return [
      for (final m in tous)
        if (m.nomComplet.toLowerCase().contains(q) ||
            m.telephone.contains(q))
          m,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final tous = _membres;
    final liste = tous == null ? const <MembreEquipe>[] : _filtres(tous);
    final conseillers = [for (final m in liste) if (m.estAgent) m];
    final autres = [for (final m in liste) if (!m.estAgent) m];

    return Coquille(
      titre: 'Équipe',
      sousTitre: tous == null
          ? 'Chargement…'
          : '${tous.where((m) => m.estAgent).length} conseiller(s) '
              'sur ${tous.length} compte(s)',
      routeCourante: '/admin/equipe',
      retour: etat.estAgent,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _charger,
        ),
      ],
      enfants: [
        if (_erreur.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.lg, Espaces.bord, 0),
            child: TexteErreur(texte: _erreur),
          ),
        if (tous == null)
          const Padding(
            padding: EdgeInsets.all(Espaces.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _barreRecherche(),
          if (liste.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Espaces.xxl),
              child: Text(
                'Aucun compte ne correspond.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: context.cl.encreDouce),
              ),
            ),
          if (conseillers.isNotEmpty) ...[
            _titre('Conseillers (${conseillers.length})'),
            for (final m in conseillers) _ligne(m, etat),
          ],
          if (autres.isNotEmpty) ...[
            _titre('Clients (${autres.length})'),
            for (final m in autres) _ligne(m, etat),
          ],
          _note(),
        ],
        const SizedBox(height: Espaces.xl),
      ],
    );
  }

  Widget _barreRecherche() => Padding(
        padding: const EdgeInsets.fromLTRB(
            Espaces.bord, Espaces.lg, Espaces.bord, Espaces.sm),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un nom ou un téléphone',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            isDense: true,
            filled: true,
            fillColor: context.cl.carte,
            border: OutlineInputBorder(
              borderRadius: Rayons.brPilule,
              borderSide: BorderSide(color: context.cl.ligne),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: Rayons.brPilule,
              borderSide: BorderSide(color: context.cl.ligne),
            ),
          ),
          style: const TextStyle(fontSize: 13.5),
          onChanged: (v) => setState(() => _recherche = v),
        ),
      );

  Widget _titre(String texte) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Espaces.bord, Espaces.lg, Espaces.bord, Espaces.sm),
        child: Text(
          texte.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: context.cl.grise,
          ),
        ),
      );

  Widget _ligne(MembreEquipe m, AppState etat) {
    // On ne modifie pas sa propre habilitation : la base le refuse, autant
    // que l'écran ne le propose pas.
    final soiMeme = m.id == etat.compte?.id;
    return _LigneMembre(
      membre: m,
      soiMeme: soiMeme,
      occupe: _occupe == m.id,
      onBasculer: soiMeme ? null : () => _basculer(m),
    );
  }

  Widget _note() => Padding(
        padding: const EdgeInsets.fromLTRB(
            Espaces.bord, Espaces.xl, Espaces.bord, 0),
        child: Text(
          'Le statut d\'administrateur, lui, ne se règle que depuis le '
          'tableau de bord Supabase — y compris le vôtre. C\'est la serrure '
          'que l\'application ne peut pas ouvrir.',
          style: TextStyle(
            fontSize: 12,
            height: 1.55,
            color: context.cl.grise,
          ),
        ),
      );
}

class _LigneMembre extends StatelessWidget {
  const _LigneMembre({
    required this.membre,
    required this.soiMeme,
    required this.occupe,
    required this.onBasculer,
  });

  final MembreEquipe membre;
  final bool soiMeme;
  final bool occupe;
  final VoidCallback? onBasculer;

  @override
  Widget build(BuildContext context) {
    final m = membre;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Espaces.bord, 0, Espaces.bord, 8),
      child: Container(
        padding: const EdgeInsets.all(Espaces.md),
        decoration: BoxDecoration(
          color: context.cl.carte,
          borderRadius: Rayons.brLg,
          border: Border.all(color: context.cl.ligne),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: m.estAgent ? Degrades.bleu : null,
                color: m.estAgent ? null : context.cl.fondDoux,
                shape: BoxShape.circle,
              ),
              child: Text(
                m.initiales,
                style: TextStyle(
                  color: m.estAgent ? Colors.white : context.cl.encreDouce,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: Espaces.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.nomComplet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (soiMeme) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(vous)',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.cl.grise,
                          ),
                        ),
                      ],
                      if (m.estAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.cl.orangeFantome,
                            borderRadius: Rayons.brPilule,
                          ),
                          child: Text(
                            'admin',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: context.cl.accentTexte,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (m.telephone.isNotEmpty)
                    Text(
                      m.telephone,
                      style:
                          TextStyle(fontSize: 11.5, color: context.cl.grise),
                    ),
                ],
              ),
            ),
            if (occupe)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Switch(
                value: m.estAgent,
                onChanged: onBasculer == null ? null : (_) => onBasculer!(),
                activeThumbColor: Colors.white,
                activeTrackColor: Palette.bleuFonce,
              ),
          ],
        ),
      ),
    );
  }
}

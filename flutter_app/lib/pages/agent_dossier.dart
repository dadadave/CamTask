import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/coquille.dart';
import '../widgets/document.dart';

/// Un dossier vu par un conseiller : ce que le client a envoyé, où en est le
/// traitement, et ce que l'agence lui renvoie.
class PageAgentDossier extends StatefulWidget {
  const PageAgentDossier({super.key});

  @override
  State<PageAgentDossier> createState() => _PageAgentDossierState();
}

class _PageAgentDossierState extends State<PageAgentDossier> {
  bool _occupe = false;
  String _erreur = '';

  /// Le dossier est relu dans l'état à chaque construction plutôt que gardé
  /// en champ : un changement de statut ou un dépôt le remplace, et l'écran
  /// doit refléter la nouvelle version.
  Demande? _dossier(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) return null;
    for (final d in PorteeApp.of(context).demandes) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> _agir(Future<void> Function() action) async {
    if (_occupe) return;
    setState(() {
      _occupe = true;
      _erreur = '';
    });
    try {
      await action();
    } on ErreurBackend catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _changerStatut(Demande d, String statut) =>
      _agir(() => PorteeApp.of(context).changerStatut(d.id, statut));

  /// Dépose un document que l'agence renvoie au client.
  ///
  /// Le libellé est demandé d'abord : sans lui, le client recevrait un nom
  /// de fichier sans savoir de quoi il s'agit.
  Future<void> _renvoyerDocument(Demande d) async {
    final libelle = await _demanderLibelle();
    if (libelle == null || !mounted) return;

    final fichier = await choisirFichier();
    if (fichier == null || !mounted) return;

    final etat = PorteeApp.of(context);
    final messager = ScaffoldMessenger.of(context);
    await _agir(() async {
      await etat.deposerPiecesAgence(
        demandeId: d.id,
        clientId: d.clientId,
        pieces: [PieceEnvoi(libelle: libelle, fichier: fichier)],
      );
      messager.showSnackBar(
        SnackBar(content: Text('« $libelle » envoyé à ${d.clientNom}.')),
      );
    });
  }

  Future<String?> _demanderLibelle() {
    final saisie = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer un document'),
        content: TextField(
          controller: saisie,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'De quoi s\'agit-il ?',
            hintText: 'Attestation, rapport, reçu…',
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final v = saisie.text.trim();
              Navigator.of(context).pop(v.isEmpty ? 'Document' : v);
            },
            child: const Text('Choisir le fichier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _dossier(context);
    if (d == null) {
      return const Coquille(
        titre: 'Dossier',
        enfants: [
          Padding(
            padding: EdgeInsets.all(Espaces.xxl),
            child: Text(
              'Ce dossier est introuvable. Il a peut-être été supprimé.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return Coquille(
      titre: d.serviceLibelle,
      sousTitre: '${d.clientNom} — ${d.date}',
      enfants: [
        _client(d),
        _statut(d),
        _detail(d),
        _pieces(d),
        if (_erreur.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Espaces.bord, Espaces.md, Espaces.bord, 0),
            child: TexteErreur(texte: _erreur),
          ),
        const SizedBox(height: Espaces.xxl),
      ],
    );
  }

  /* ------------------------------------------------------------------ */

  Widget _carte({required Widget enfant}) => Padding(
        padding:
            const EdgeInsets.fromLTRB(Espaces.bord, Espaces.lg, Espaces.bord, 0),
        child: Container(
          padding: const EdgeInsets.all(Espaces.lg),
          decoration: BoxDecoration(
            color: context.cl.carte,
            borderRadius: Rayons.brLg,
            border: Border.all(color: context.cl.ligne),
          ),
          child: enfant,
        ),
      );

  Widget _client(Demande d) => _carte(
        enfant: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: Degrades.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                d.clientNom.isEmpty ? 'C' : d.clientNom[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(width: Espaces.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.clientNom,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (d.clientTelephone.isNotEmpty)
                    Text(
                      d.clientTelephone,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.cl.encreDouce,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ouvrir la conversation',
              icon: const Icon(Icons.forum_outlined, color: Palette.bleuFonce),
              onPressed: () => Navigator.of(context).pushNamed(
                '/agent/chat',
                arguments: (clientId: d.clientId, clientNom: d.clientNom),
              ),
            ),
          ],
        ),
      );

  Widget _statut(Demande d) => _carte(
        enfant: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Avancement',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
                if (_occupe)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: Espaces.md),
            Row(
              children: [
                for (final s in statutsDemande)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _BoutonStatut(
                        libelle: s,
                        actif: d.statut == s,
                        onTap: _occupe || d.statut == s
                            ? null
                            : () => _changerStatut(d, s),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _detail(Demande d) => _carte(
        enfant: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ce que demande le client',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Espaces.sm),
            SelectableText(
              d.resume,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: context.cl.encreDouce,
              ),
            ),
          ],
        ),
      );

  Widget _pieces(Demande d) => _carte(
        enfant: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pièces fournies par le client',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Espaces.md),
            if (d.piecesClient.isEmpty)
              Text(
                'Aucune pièce jointe à ce dossier.',
                style: TextStyle(fontSize: 12.5, color: context.cl.grise),
              )
            else
              for (final p in d.piecesClient) LigneDocument(piece: p),
            const SizedBox(height: Espaces.lg),
            const Text(
              'Documents renvoyés par l\'agence',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Espaces.md),
            if (d.piecesAgence.isEmpty)
              Text(
                'Rien encore. Le client verra ici ce que vous lui envoyez.',
                style: TextStyle(fontSize: 12.5, color: context.cl.grise),
              )
            else
              for (final p in d.piecesAgence) LigneDocument(piece: p),
            const SizedBox(height: Espaces.md),
            BoutonEnvoyer(
              bloc: true,
              libelle: 'Envoyer un document au client',
              icone: Icons.upload_file_rounded,
              onTap: _occupe ? () {} : () => _renvoyerDocument(d),
            ),
          ],
        ),
      );
}

class _BoutonStatut extends StatelessWidget {
  const _BoutonStatut({
    required this.libelle,
    required this.actif,
    required this.onTap,
  });

  final String libelle;
  final bool actif;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (libelle) {
      'En cours' => Palette.bleuFonce,
      'Traitée' => Palette.succes,
      _ => Palette.orange,
    };

    return Material(
      color: actif ? accent : context.cl.fondDoux,
      borderRadius: Rayons.brSm,
      child: InkWell(
        borderRadius: Rayons.brSm,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: Rayons.brSm,
            border: Border.all(color: actif ? accent : context.cl.ligne),
          ),
          child: Text(
            libelle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: actif ? Colors.white : context.cl.encreDouce,
            ),
          ),
        ),
      ),
    );
  }
}

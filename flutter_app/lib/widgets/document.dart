import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Ouvre un document du bucket privé.
///
/// Il n'existe pas d'URL permanente : on demande au serveur un lien signé,
/// valable quelques minutes, et c'est la RLS qui décide de le délivrer.
Future<void> ouvrirDocument(
  BuildContext context,
  String chemin, {
  String? nomFichier,
}) async {
  final etat = PorteeApp.of(context);
  final messager = ScaffoldMessenger.of(context);
  try {
    final lien = await etat.lienDocument(chemin, nomFichier: nomFichier);
    if (!await launchUrl(Uri.parse(lien),
        mode: LaunchMode.externalApplication)) {
      messager.showSnackBar(const SnackBar(
        content: Text("Aucune application ne peut ouvrir ce document."),
      ));
    }
  } on ErreurBackend catch (e) {
    messager.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Choisit un fichier sur l'appareil, contenu compris.
///
/// Rend `null` si l'utilisateur annule. `withData: true` est ce qui permet
/// de téléverser pour de vrai, et la seule forme qui marche sur le web.
Future<FichierChoisi?> choisirFichier() async {
  final res = await FilePicker.platform.pickFiles(withData: true);
  if (res == null || res.files.isEmpty) return null;
  final f = res.files.first;
  final octets = f.bytes;
  if (octets == null) return null;
  return FichierChoisi(nom: f.name, octets: octets);
}

/// Une pièce d'un dossier, cliquable pour l'ouvrir.
///
/// Les documents de l'agence se distinguent au premier coup d'œil de ceux
/// fournis par le client : ce sont les deux sens d'un même dossier.
class LigneDocument extends StatelessWidget {
  const LigneDocument({super.key, required this.piece});

  final Piece piece;

  @override
  Widget build(BuildContext context) {
    final deLAgence = piece.sens == SensPiece.agence;
    // Aplat de la pastille d'un côté, teinte d'écriture de l'autre : le
    // premier porte du blanc, la seconde se lit sur fond clair.
    final aplat = deLAgence ? Palette.bleuFonce : Palette.orange;
    final accent = deLAgence ? context.cl.bleuTexte : context.cl.accentTexte;
    final fond =
        deLAgence ? context.cl.bleuFantome : context.cl.orangeFantome;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: fond,
        borderRadius: Rayons.brSm,
        child: InkWell(
          borderRadius: Rayons.brSm,
          onTap: piece.chemin.isEmpty
              ? null
              : () => ouvrirDocument(context, piece.chemin,
                  nomFichier: piece.fichier),
          child: Padding(
            padding: const EdgeInsets.all(Espaces.md),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: aplat,
                    borderRadius: Rayons.r(9),
                  ),
                  child: Icon(
                    deLAgence
                        ? Icons.description_outlined
                        : Icons.attach_file_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: Espaces.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        piece.libelle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        piece.fichier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.cl.encreDouce,
                        ),
                      ),
                    ],
                  ),
                ),
                if (piece.chemin.isNotEmpty)
                  Icon(Icons.open_in_new_rounded, size: 16, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

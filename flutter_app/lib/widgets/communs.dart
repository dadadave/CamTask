import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'illustrations.dart';

/// En-tête de service : pastille orange + libellé, comme sur les maquettes.
class EnTeteService extends StatelessWidget {
  const EnTeteService({super.key, required this.libelle, this.sousTitre});

  final String libelle;
  final String? sousTitre;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 18, 14, 22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Palette.carte,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ombreCarte,
      ),
      child: Row(
        children: [
          const _Pastille(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(libelle.toUpperCase(), style: Textes.titreService),
                if (sousTitre != null) ...[
                  const SizedBox(height: 2),
                  Text(sousTitre!.toUpperCase(), style: Textes.sousTitreService),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Palette.orangeClair,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Champ de saisie souligné (ou encadré avec [encadre]).
class Champ extends StatelessWidget {
  const Champ({
    super.key,
    required this.libelle,
    required this.controleur,
    this.clavier,
    this.masque = false,
    this.encadre = false,
    this.aide,
    this.majuscules = true,
  });

  final String libelle;
  final TextEditingController controleur;
  final TextInputType? clavier;
  final bool masque;
  final bool encadre;
  final String? aide;

  /// Les maquettes affichent les libellés de service en majuscules, mais
  /// ceux de la carte de connexion en minuscules.
  final bool majuscules;

  @override
  Widget build(BuildContext context) {
    final invite = majuscules ? libelle.toUpperCase() : libelle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controleur,
          keyboardType: clavier,
          obscureText: masque,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: invite,
            hintStyle: TextStyle(
              color: Palette.grise,
              fontSize: majuscules ? 13 : 14,
              letterSpacing: 0.2,
            ),
            isDense: true,
            filled: encadre,
            fillColor: Palette.carte,
            contentPadding: encadre
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 13)
                : const EdgeInsets.only(top: 6, bottom: 8),
            border: encadre ? _bordureEncadree() : _bordureSoulignee(),
            enabledBorder: encadre ? _bordureEncadree() : _bordureSoulignee(),
            focusedBorder: encadre
                ? _bordureEncadree(couleur: Palette.orange)
                : _bordureSoulignee(couleur: Palette.orange),
          ),
        ),
        if (aide != null) ...[
          const SizedBox(height: 4),
          Text(aide!,
              style: const TextStyle(fontSize: 11, color: Palette.encreDouce)),
        ],
      ],
    );
  }

  static InputBorder _bordureSoulignee({Color couleur = Palette.ligne}) =>
      UnderlineInputBorder(borderSide: BorderSide(color: couleur));

  static InputBorder _bordureEncadree({Color couleur = Palette.ligne}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: couleur),
      );
}

/// Zone de texte multiligne encadrée.
class ZoneTexte extends StatelessWidget {
  const ZoneTexte({
    super.key,
    required this.libelle,
    required this.controleur,
    this.lignes = 5,
  });

  final String libelle;
  final TextEditingController controleur;
  final int lignes;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controleur,
      maxLines: lignes,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: libelle,
        hintStyle: const TextStyle(color: Palette.grise, fontSize: 14),
        filled: true,
        fillColor: Palette.carte,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.ligne),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.ligne),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.orange),
        ),
      ),
    );
  }
}

/// Liste déroulante au même style que les champs.
class Selecteur extends StatelessWidget {
  const Selecteur({
    super.key,
    required this.libelle,
    required this.valeur,
    required this.options,
    required this.onChange,
    this.encadre = false,
  });

  final String libelle;
  final String? valeur;
  final List<String> options;
  final ValueChanged<String?> onChange;
  final bool encadre;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: valeur,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Palette.encreDouce),
      hint: Text(
        libelle.toUpperCase(),
        style: const TextStyle(color: Palette.grise, fontSize: 13),
      ),
      style: const TextStyle(fontSize: 14, color: Palette.encre),
      decoration: InputDecoration(
        isDense: true,
        filled: encadre,
        fillColor: Palette.carte,
        contentPadding: encadre
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 13)
            : const EdgeInsets.only(top: 6, bottom: 8),
        border: encadre
            ? Champ._bordureEncadree()
            : Champ._bordureSoulignee(),
        enabledBorder: encadre
            ? Champ._bordureEncadree()
            : Champ._bordureSoulignee(),
        focusedBorder: encadre
            ? Champ._bordureEncadree(couleur: Palette.orange)
            : Champ._bordureSoulignee(couleur: Palette.orange),
      ),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o,
            child: Text(o, style: const TextStyle(fontSize: 13)),
          ),
      ],
      onChanged: onChange,
    );
  }
}

/// Barre orange de téléversement d'un document.
class Televersement extends StatelessWidget {
  const Televersement({
    super.key,
    required this.libelle,
    required this.fichier,
    required this.onChoisi,
  });

  final String libelle;
  final String? fichier;
  final ValueChanged<String> onChoisi;

  Future<void> _choisir() async {
    final res = await FilePicker.platform.pickFiles(withData: false);
    if (res == null || res.files.isEmpty) return;
    onChoisi(res.files.first.name);
  }

  @override
  Widget build(BuildContext context) {
    final choisi = fichier != null;
    return Material(
      color: choisi ? const Color(0xFF3F9E63) : Palette.orangeClair,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _choisir,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libelle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (choisi) ...[
                      const SizedBox(height: 3),
                      Text(
                        '✓ $fichier',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                choisi ? Icons.check : Icons.download,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastilles de sélection (simple ou multiple).
class Pastilles extends StatelessWidget {
  const Pastilles({
    super.key,
    required this.options,
    required this.selection,
    required this.onBascule,
    this.larges = false,
  });

  final List<String> options;
  final List<String> selection;
  final ValueChanged<String> onBascule;
  final bool larges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final o in options)
          _Pastille2(
            libelle: o,
            actif: selection.contains(o),
            large: larges,
            onTap: () => onBascule(o),
          ),
      ],
    );
  }
}

class _Pastille2 extends StatelessWidget {
  const _Pastille2({
    required this.libelle,
    required this.actif,
    required this.large,
    required this.onTap,
  });

  final String libelle;
  final bool actif;
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contenu = Material(
      color: actif ? Palette.orange : Palette.carte,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: actif ? Palette.orange : Palette.ligne),
          ),
          child: Text(
            libelle.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: actif ? Colors.white : Palette.encreDouce,
            ),
          ),
        ),
      ),
    );

    if (!large) return contenu;
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        width: (c.maxWidth - 10) / 2,
        child: contenu,
      ),
    );
  }
}

/// Bouton ENVOYER arrondi.
class BoutonEnvoyer extends StatelessWidget {
  const BoutonEnvoyer({
    super.key,
    required this.onTap,
    this.libelle = 'Envoyer',
    this.bloc = false,
  });

  final VoidCallback onTap;
  final String libelle;
  final bool bloc;

  @override
  Widget build(BuildContext context) {
    final bouton = Material(
      color: Palette.orangeClair,
      borderRadius: BorderRadius.circular(999),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: bloc ? 14 : 10),
          child: Text(
            libelle.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: bloc ? 16 : 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );

    if (bloc) return SizedBox(width: double.infinity, child: bouton);
    return Align(alignment: Alignment.centerLeft, child: bouton);
  }
}

/// Encadré orange contenant du texte (accroche, présentation, clôture).
class Encadre extends StatelessWidget {
  const Encadre({super.key, required this.enfants, this.marge});

  final List<Widget> enfants;
  final EdgeInsets? marge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: marge ?? const EdgeInsets.fromLTRB(14, 0, 14, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.carte,
        border: Border.all(color: Palette.orange, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: enfants,
      ),
    );
  }
}

/// Titre encadré utilisé en tête des sections de documents.
class TitrePanneau extends StatelessWidget {
  const TitrePanneau({super.key, required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Palette.orange, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texte,
        textAlign: TextAlign.center,
        style: Textes.titrePanneau,
      ),
    );
  }
}

/// Bouton flottant « Discuter avec un agent ».
class DiscuterAgent extends StatelessWidget {
  const DiscuterAgent({super.key, this.sujet});

  final String? sujet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 26, 14, 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () =>
              Navigator.of(context).pushNamed('/chat', arguments: sujet),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AvatarAgent(taille: 84),
              SizedBox(height: 2),
              Text(
                'Discuter avec un agent',
                style: TextStyle(fontSize: 13, color: Palette.encreDouce),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message d'erreur de validation sous un formulaire.
class TexteErreur extends StatelessWidget {
  const TexteErreur({super.key, required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) =>
      Text(texte, style: Textes.erreur);
}

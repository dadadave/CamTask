import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'illustrations.dart';

/// En-tête de service : pastille en dégradé + libellé, sur une carte douce.
class EnTeteService extends StatelessWidget {
  const EnTeteService({
    super.key,
    required this.libelle,
    this.sousTitre,
    this.icone = Icons.description_outlined,
  });

  final String libelle;
  final String? sousTitre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.lg, Espaces.bord, Espaces.xl),
      padding: const EdgeInsets.all(Espaces.lg),
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius: Rayons.brLg,
        boxShadow: context.cl.ombreCarte,
        border: Border.all(color: context.cl.ligne),
      ),
      child: Row(
        children: [
          _PastilleIcone(icone: icone),
          const SizedBox(width: Espaces.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(libelle, style: Textes.titreService),
                if (sousTitre != null) ...[
                  const SizedBox(height: 3),
                  Text(sousTitre!, style: Textes.sousTitreService(context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille ronde en dégradé orange contenant une icône blanche.
class _PastilleIcone extends StatelessWidget {
  const _PastilleIcone({required this.icone});

  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: Degrades.orange,
        shape: BoxShape.circle,
        boxShadow: ombreOrange,
      ),
      child: Icon(icone, color: Colors.white, size: 23),
    );
  }
}

/// Libellé de section, avec un petit trait orange devant.
class LibelleSection extends StatelessWidget {
  const LibelleSection({super.key, required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Espaces.md),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              color: context.cl.accentTexte,
              borderRadius: Rayons.r(2),
            ),
          ),
          const SizedBox(width: Espaces.sm),
          Text(texte.toUpperCase(), style: Textes.libelle(context)),
        ],
      ),
    );
  }
}

/// Champ de saisie sur fond doux, arrondi.
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
    this.icone,
  });

  final String libelle;
  final TextEditingController controleur;
  final TextInputType? clavier;
  final bool masque;

  /// Conservé pour compatibilité : tous les champs sont désormais encadrés.
  final bool encadre;
  final String? aide;

  /// Conservé pour compatibilité ; les libellés ne sont plus mis en capitales.
  final bool majuscules;

  /// Icône facultative en tête de champ.
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controleur,
          keyboardType: clavier,
          obscureText: masque,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: context.cl.encre,
          ),
          decoration: InputDecoration(
            hintText: libelle,
            prefixIcon: icone == null
                ? null
                : Icon(icone, size: 20, color: context.cl.grise),
          ),
        ),
        if (aide != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: context.cl.grise),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  aide!,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: context.cl.encreDouce,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Zone de texte multiligne.
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
      style: const TextStyle(
        fontSize: 14.5,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(hintText: libelle),
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
      initialValue: valeur,
      isExpanded: true,
      borderRadius: Rayons.brSm,
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: context.cl.encreDouce),
      hint: Text(
        libelle,
        style: TextStyle(
          color: context.cl.grise,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: context.cl.encre,
      ),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o,
            child: Text(o, style: const TextStyle(fontSize: 14)),
          ),
      ],
      onChanged: onChange,
    );
  }
}

/// Carte de téléversement d'un document.
class Televersement extends StatelessWidget {
  const Televersement({
    super.key,
    required this.libelle,
    required this.fichier,
    required this.onChoisi,
  });

  final String libelle;
  final FichierChoisi? fichier;
  final ValueChanged<FichierChoisi> onChoisi;

  /// `withData: true` : on récupère le contenu, pas seulement un chemin.
  /// C'est ce qui permet de téléverser le document pour de vrai, et la
  /// seule forme qui marche aussi sur le web.
  Future<void> _choisir() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    final octets = f.bytes;
    if (octets == null) return;
    onChoisi(FichierChoisi(nom: f.name, octets: octets));
  }

  @override
  Widget build(BuildContext context) {
    final choisi = fichier != null;
    final accent = choisi ? Palette.succes : Palette.orange;
    final fond = choisi ? context.cl.succesFantome : context.cl.orangeFantome;

    return Material(
      color: fond,
      borderRadius: Rayons.brSm,
      child: InkWell(
        borderRadius: Rayons.brSm,
        onTap: _choisir,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Espaces.md, vertical: Espaces.md),
          decoration: BoxDecoration(
            borderRadius: Rayons.brSm,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: Rayons.r(10),
                ),
                child: Icon(
                  choisi
                      ? Icons.check_rounded
                      : Icons.file_upload_outlined,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: Espaces.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libelle,
                      style: TextStyle(
                        color: context.cl.encre,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      choisi ? fichier!.nom : 'Appuyez pour choisir un fichier',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: choisi ? Palette.succes : context.cl.encreDouce,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
      spacing: Espaces.sm,
      runSpacing: Espaces.sm,
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
    final contenu = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: actif ? Degrades.orange : null,
        color: actif ? null : context.cl.carte,
        borderRadius: Rayons.brPilule,
        border: Border.all(color: actif ? Palette.orange : context.cl.ligne),
        boxShadow: actif ? ombreOrange : context.cl.ombreDouce,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: Rayons.brPilule,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Espaces.lg, vertical: Espaces.md),
            child: Row(
              mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (actif) ...[
                  const Icon(Icons.check_rounded,
                      size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    libelle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: actif ? Colors.white : context.cl.encreDouce,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!large) return contenu;
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        width: (c.maxWidth - Espaces.sm) / 2,
        child: contenu,
      ),
    );
  }
}

/// Bouton principal : pilule en dégradé orange avec ombre colorée.
class BoutonEnvoyer extends StatelessWidget {
  const BoutonEnvoyer({
    super.key,
    required this.onTap,
    this.libelle = 'Envoyer',
    this.bloc = false,
    this.icone,
  });

  final VoidCallback onTap;
  final String libelle;
  final bool bloc;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final bouton = DecoratedBox(
      decoration: BoxDecoration(
        gradient: Degrades.orange,
        borderRadius: Rayons.brPilule,
        boxShadow: ombreOrange,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: Rayons.brPilule,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Espaces.xxl,
              vertical: bloc ? 16 : 13,
            ),
            child: Row(
              mainAxisSize: bloc ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  libelle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: bloc ? 15.5 : 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                if (icone != null) ...[
                  const SizedBox(width: Espaces.sm),
                  Icon(icone, color: Colors.white, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (bloc) return SizedBox(width: double.infinity, child: bouton);
    return Align(alignment: Alignment.centerLeft, child: bouton);
  }
}

/// Carte douce contenant du texte (accroche, présentation, clôture).
class Encadre extends StatelessWidget {
  const Encadre({super.key, required this.enfants, this.marge, this.accent});

  final List<Widget> enfants;
  final EdgeInsets? marge;

  /// Teinte facultative du liseré gauche.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? Palette.orange;
    return Container(
      margin: marge ??
          const EdgeInsets.fromLTRB(
              Espaces.bord, 0, Espaces.bord, Espaces.lg),
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius: Rayons.brLg,
        boxShadow: context.cl.ombreCarte,
        border: Border.all(color: context.cl.ligne),
      ),
      clipBehavior: Clip.antiAlias,
      // IntrinsicHeight : sans lui, le Row « stretch » réclamerait une
      // hauteur infinie dans une liste défilante.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Espaces.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: enfants,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre de section utilisé en tête des groupes de documents.
class TitrePanneau extends StatelessWidget {
  const TitrePanneau({super.key, required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Espaces.md),
      padding: const EdgeInsets.symmetric(
          horizontal: Espaces.md, vertical: Espaces.md),
      decoration: BoxDecoration(
        color: context.cl.orangeFantome,
        borderRadius: Rayons.brSm,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: Palette.orange,
              borderRadius: Rayons.r(2),
            ),
          ),
          const SizedBox(width: Espaces.md),
          Expanded(child: Text(texte, style: Textes.titrePanneau)),
        ],
      ),
    );
  }
}

/// Bandeau « Discuter avec un agent ».
class DiscuterAgent extends StatelessWidget {
  const DiscuterAgent({super.key, this.sujet});

  final String? sujet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Espaces.bord, Espaces.xl, Espaces.bord, Espaces.md),
      child: Material(
        color: context.cl.carte,
        borderRadius: Rayons.brLg,
        child: InkWell(
          borderRadius: Rayons.brLg,
          onTap: () =>
              Navigator.of(context).pushNamed('/chat', arguments: sujet),
          child: Container(
            padding: const EdgeInsets.all(Espaces.lg),
            decoration: BoxDecoration(
              borderRadius: Rayons.brLg,
              boxShadow: context.cl.ombreCarte,
              border: Border.all(color: context.cl.ligne),
            ),
            child: Row(
              children: [
                const AvatarAgent(taille: 52),
                const SizedBox(width: Espaces.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discuter avec un agent',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Un conseiller vous répond directement.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.cl.encreDouce,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.cl.orangeFantome,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      size: 17, color: Palette.orange),
                ),
              ],
            ),
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Espaces.sm),
      padding: const EdgeInsets.symmetric(horizontal: Espaces.md, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.erreur.withValues(alpha: 0.08),
        borderRadius: Rayons.r(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 15, color: Palette.erreur),
          const SizedBox(width: 7),
          Expanded(child: Text(texte, style: Textes.erreur)),
        ],
      ),
    );
  }
}

/// Sélecteur d'apparence : clair, sombre ou réglage du système.
class SelecteurTheme extends StatelessWidget {
  const SelecteurTheme({super.key});

  static const _options = <({ModeTheme mode, String libelle, IconData icone})>[
    (mode: ModeTheme.clair, libelle: 'Clair', icone: Icons.light_mode_rounded),
    (mode: ModeTheme.sombre, libelle: 'Sombre', icone: Icons.dark_mode_rounded),
    (
      mode: ModeTheme.systeme,
      libelle: 'Système',
      icone: Icons.brightness_auto_rounded
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.cl.carte,
        borderRadius: Rayons.brPilule,
        border: Border.all(color: context.cl.ligne),
        boxShadow: context.cl.ombreDouce,
      ),
      child: Row(
        children: [
          for (final o in _options)
            Expanded(
              child: GestureDetector(
                onTap: () => etat.changerMode(o.mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: etat.mode == o.mode ? Degrades.orange : null,
                    borderRadius: Rayons.brPilule,
                    boxShadow: etat.mode == o.mode ? ombreOrange : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        o.icone,
                        size: 16,
                        color: etat.mode == o.mode
                            ? Colors.white
                            : context.cl.encreDouce,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          o.libelle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: etat.mode == o.mode
                                ? Colors.white
                                : context.cl.encreDouce,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// L'état d'un dossier, d'un coup d'œil.
///
/// Une couleur par état : ce qui vient d'arriver appelle l'attention, ce qui
/// est traité s'efface. Partagé par le profil du client et la liste du
/// conseiller, pour que les deux parlent le même langage.
class EtiquetteStatut extends StatelessWidget {
  const EtiquetteStatut({super.key, required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    // Les teintes d'écriture, pas celles de marque : sur fond clair,
    // l'orange des aplats ne dépasse pas 2,46 de contraste.
    final (accent, fond) = switch (statut) {
      'En cours' => (context.cl.bleuTexte, context.cl.bleuFantome),
      'Traitée' => (context.cl.succesTexte, context.cl.succesFantome),
      _ => (context.cl.accentTexte, context.cl.orangeFantome),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fond, borderRadius: Rayons.brPilule),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            statut,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

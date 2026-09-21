import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Couleurs de marque CAM-TAXE — identiques en clair et en sombre.
class Palette {
  const Palette._();

  static const orange = Color(0xFFF5893F);
  static const orangeClair = Color(0xFFFBA05C);

  /// Orangés du dégradé des boutons. Plus profonds que [orange] : le blanc
  /// posé dessus n'atteignait que 2,46 de contraste, sous le minimum de 3
  /// exigé pour un texte de cette taille. Ceux-ci le portent à 3,05–3,98.
  static const orangeProfond = Color(0xFFEC7014);
  static const orangeBraise = Color(0xFFD25C0C);

  /// Orange d'écriture sur fond clair. [orange] n'y offre que 2,46 de
  /// contraste ; celui-ci atteint 4,52. Réservé au texte et aux icônes,
  /// jamais aux aplats — la marque reste [orange].
  static const orangeEncre = Color(0xFFB8500A);

  /// Bleu et vert d'écriture sur fond clair, mêmes raisons.
  static const bleuEncre = Color(0xFF0F76DC);
  static const succesEncre = Color(0xFF358554);
  static const bleu = Color(0xFF5DA9F5);
  static const bleuFonce = Color(0xFF1E88F0);
  static const succes = Color(0xFF3F9E63);
  static const erreur = Color(0xFFD64C2B);

  /// Orange légèrement éclairci : meilleure lisibilité sur fond sombre.
  static const orangeSombre = Color(0xFFFF9E55);
}

/// Rayons d'arrondi.
class Rayons {
  const Rayons._();

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 26.0;
  static const pilule = 999.0;

  static BorderRadius r(double v) => BorderRadius.circular(v);
  static const brSm = BorderRadius.all(Radius.circular(sm));
  static const brMd = BorderRadius.all(Radius.circular(md));
  static const brLg = BorderRadius.all(Radius.circular(lg));
  static const brXl = BorderRadius.all(Radius.circular(xl));
  static const brPilule = BorderRadius.all(Radius.circular(pilule));
}

/// Échelle d'espacement (multiples de 4).
class Espaces {
  const Espaces._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const bord = 18.0;
}

/// Dégradés de marque.
class Degrades {
  const Degrades._();

  static const orange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Palette.orangeProfond, Palette.orangeBraise],
  );

  static const orangeVif = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Palette.orangeBraise, Palette.orangeProfond],
  );

  static const bleu = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Palette.bleu, Palette.bleuFonce],
  );
}

/// Ombre colorée sous les éléments orange — valable dans les deux thèmes.
final ombreOrange = <BoxShadow>[
  BoxShadow(
    color: Palette.orange.withValues(alpha: 0.32),
    blurRadius: 18,
    offset: const Offset(0, 8),
    spreadRadius: -4,
  ),
];

/// Nuances neutres : elles changent entre le thème clair et le thème sombre.
@immutable
class Nuances extends ThemeExtension<Nuances> {
  const Nuances({
    required this.fond,
    required this.carte,
    required this.carteHaute,
    required this.fondDoux,
    required this.encre,
    required this.encreDouce,
    required this.grise,
    required this.ligne,
    required this.orangeFantome,
    required this.bleuFantome,
    required this.succesFantome,
    required this.accentTexte,
    required this.bleuTexte,
    required this.succesTexte,
    required this.ombreCarte,
    required this.ombreDouce,
    required this.ombreForte,
    required this.sombre,
  });

  /// Fond général de l'écran.
  final Color fond;

  /// Surface des cartes.
  final Color carte;

  /// Surface légèrement surélevée (feuilles, menus).
  final Color carteHaute;

  /// Remplissage des champs de saisie.
  final Color fondDoux;

  final Color encre;
  final Color encreDouce;
  final Color grise;
  final Color ligne;

  /// Fonds teintés des pastilles.
  final Color orangeFantome;
  final Color bleuFantome;
  final Color succesFantome;

  /// Les mêmes couleurs, mais pour **écrire**.
  ///
  /// Sur fond clair il faut les assombrir : l'orange de marque n'offre que
  /// 2,46 de contraste sur blanc, très en dessous des 4,5 nécessaires à un
  /// texte courant. Sur fond sombre les teintes vives passent déjà, et on
  /// les garde telles quelles.
  final Color accentTexte;
  final Color bleuTexte;
  final Color succesTexte;

  final List<BoxShadow> ombreCarte;
  final List<BoxShadow> ombreDouce;
  final List<BoxShadow> ombreForte;

  final bool sombre;

  /// Accent de marque. Volontairement identique dans les deux thèmes :
  /// l'orange reste lisible sur fond sombre, et deux nuances différentes
  /// jureraient avec les nombreux usages directs de [Palette.orange].
  Color get accent => Palette.orange;

  // ── Thème clair ────────────────────────────────────────────────────
  // Le fond est un sable chaud : il se marie à l'orange de la marque et
  // détache nettement les cartes blanches, qui se confondaient avec un
  // fond quasi blanc.
  static const clair = Nuances(
    fond: Color(0xFFF1ECE6),
    carte: Color(0xFFFFFFFF),
    carteHaute: Color(0xFFFFFFFF),
    fondDoux: Color(0xFFF7F3EF),
    encre: Color(0xFF10100F),
    encreDouce: Color(0xFF55524F),
    grise: Color(0xFF726A62),
    ligne: Color(0xFFE3DCD4),
    orangeFantome: Color(0xFFFFF1E4),
    bleuFantome: Color(0xFFE8F2FE),
    succesFantome: Color(0xFFEAF6EF),
    accentTexte: Palette.orangeEncre,
    bleuTexte: Palette.bleuEncre,
    succesTexte: Palette.succesEncre,
    ombreCarte: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 18,
        offset: Offset(0, 6),
        spreadRadius: -2,
      ),
      BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
    ombreDouce: [
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 12,
        offset: Offset(0, 3),
        spreadRadius: -1,
      ),
    ],
    ombreForte: [
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 28,
        offset: Offset(0, 12),
        spreadRadius: -6,
      ),
    ],
    sombre: false,
  );

  // ── Thème sombre ───────────────────────────────────────────────────
  // Gris chauds (teintés vers l'orange) plutôt que gris neutres, pour
  // rester dans la même famille chromatique que le thème clair.
  static const sombreN = Nuances(
    fond: Color(0xFF131110),
    carte: Color(0xFF1E1B19),
    carteHaute: Color(0xFF262220),
    fondDoux: Color(0xFF262220),
    encre: Color(0xFFF6F2EE),
    encreDouce: Color(0xFFB4ACA4),
    grise: Color(0xFF837A72),
    ligne: Color(0xFF352F2B),
    orangeFantome: Color(0xFF3A2617),
    bleuFantome: Color(0xFF16283C),
    succesFantome: Color(0xFF17301F),
    accentTexte: Palette.orangeSombre,
    bleuTexte: Palette.bleu,
    succesTexte: Palette.succes,
    // En sombre l'ombre portée ne se voit plus : on l'assombrit fortement
    // et la séparation vient surtout du contraste des surfaces.
    ombreCarte: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 16,
        offset: Offset(0, 6),
        spreadRadius: -4,
      ),
    ],
    ombreDouce: [
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 10,
        offset: Offset(0, 3),
        spreadRadius: -2,
      ),
    ],
    ombreForte: [
      BoxShadow(
        color: Color(0x8A000000),
        blurRadius: 30,
        offset: Offset(0, 14),
        spreadRadius: -8,
      ),
    ],
    sombre: true,
  );

  @override
  Nuances copyWith({
    Color? fond,
    Color? carte,
    Color? carteHaute,
    Color? fondDoux,
    Color? encre,
    Color? encreDouce,
    Color? grise,
    Color? ligne,
    Color? orangeFantome,
    Color? bleuFantome,
    Color? succesFantome,
    Color? accentTexte,
    Color? bleuTexte,
    Color? succesTexte,
    List<BoxShadow>? ombreCarte,
    List<BoxShadow>? ombreDouce,
    List<BoxShadow>? ombreForte,
    bool? sombre,
  }) {
    return Nuances(
      fond: fond ?? this.fond,
      carte: carte ?? this.carte,
      carteHaute: carteHaute ?? this.carteHaute,
      fondDoux: fondDoux ?? this.fondDoux,
      encre: encre ?? this.encre,
      encreDouce: encreDouce ?? this.encreDouce,
      grise: grise ?? this.grise,
      ligne: ligne ?? this.ligne,
      orangeFantome: orangeFantome ?? this.orangeFantome,
      bleuFantome: bleuFantome ?? this.bleuFantome,
      succesFantome: succesFantome ?? this.succesFantome,
      accentTexte: accentTexte ?? this.accentTexte,
      bleuTexte: bleuTexte ?? this.bleuTexte,
      succesTexte: succesTexte ?? this.succesTexte,
      ombreCarte: ombreCarte ?? this.ombreCarte,
      ombreDouce: ombreDouce ?? this.ombreDouce,
      ombreForte: ombreForte ?? this.ombreForte,
      sombre: sombre ?? this.sombre,
    );
  }

  @override
  Nuances lerp(ThemeExtension<Nuances>? autre, double t) {
    if (autre is! Nuances) return this;
    return Nuances(
      fond: Color.lerp(fond, autre.fond, t)!,
      carte: Color.lerp(carte, autre.carte, t)!,
      carteHaute: Color.lerp(carteHaute, autre.carteHaute, t)!,
      fondDoux: Color.lerp(fondDoux, autre.fondDoux, t)!,
      encre: Color.lerp(encre, autre.encre, t)!,
      encreDouce: Color.lerp(encreDouce, autre.encreDouce, t)!,
      grise: Color.lerp(grise, autre.grise, t)!,
      ligne: Color.lerp(ligne, autre.ligne, t)!,
      orangeFantome: Color.lerp(orangeFantome, autre.orangeFantome, t)!,
      bleuFantome: Color.lerp(bleuFantome, autre.bleuFantome, t)!,
      succesFantome: Color.lerp(succesFantome, autre.succesFantome, t)!,
      accentTexte: Color.lerp(accentTexte, autre.accentTexte, t)!,
      bleuTexte: Color.lerp(bleuTexte, autre.bleuTexte, t)!,
      succesTexte: Color.lerp(succesTexte, autre.succesTexte, t)!,
      ombreCarte: t < 0.5 ? ombreCarte : autre.ombreCarte,
      ombreDouce: t < 0.5 ? ombreDouce : autre.ombreDouce,
      ombreForte: t < 0.5 ? ombreForte : autre.ombreForte,
      sombre: t < 0.5 ? sombre : autre.sombre,
    );
  }
}

/// Raccourci : `context.cl.carte`.
extension NuancesContexte on BuildContext {
  Nuances get cl =>
      Theme.of(this).extension<Nuances>() ?? Nuances.clair;
}

// ── Construction des thèmes ────────────────────────────────────────────

ThemeData construireTheme() => _construire(Nuances.clair, Brightness.light);

ThemeData construireThemeSombre() =>
    _construire(Nuances.sombreN, Brightness.dark);

ThemeData _construire(Nuances n, Brightness luminosite) {
  final base = ThemeData(brightness: luminosite, useMaterial3: true);
  final accent = n.accent;

  final schema = ColorScheme.fromSeed(
    seedColor: Palette.orange,
    brightness: luminosite,
    primary: accent,
    onPrimary: luminosite == Brightness.dark
        ? const Color(0xFF231404)
        : Colors.white,
    secondary: Palette.bleuFonce,
    onSecondary: Colors.white,
    surface: n.carte,
    onSurface: n.encre,
    error: Palette.erreur,
  );

  return base.copyWith(
    scaffoldBackgroundColor: n.fond,
    colorScheme: schema,
    canvasColor: n.fond,
    splashFactory: InkSparkle.splashFactory,
    extensions: [n],
    textTheme: _typo(base.textTheme, n),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 22),
    ),

    cardTheme: CardThemeData(
      color: n.carte,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: Rayons.brLg),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const RoundedRectangleBorder(borderRadius: Rayons.brPilule),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: n.encre,
        minimumSize: const Size(0, 52),
        side: BorderSide(color: n.ligne),
        shape: const RoundedRectangleBorder(borderRadius: Rayons.brPilule),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: n.fondDoux,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: n.grise,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: _bordure(n.ligne),
      enabledBorder: _bordure(n.ligne),
      focusedBorder: _bordure(accent, 1.6),
      errorBorder: _bordure(Palette.erreur),
      focusedErrorBorder: _bordure(Palette.erreur, 1.6),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(n.carteHaute),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Rayons.brSm),
        ),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: n.carteHaute,
      shape: const RoundedRectangleBorder(borderRadius: Rayons.brSm),
    ),

    dividerTheme: DividerThemeData(color: n.ligne, thickness: 1, space: 1),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: n.sombre ? n.carteHaute : const Color(0xFF232120),
      contentTextStyle: TextStyle(
        color: n.sombre ? n.encre : Colors.white,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: Rayons.r(Rayons.sm)),
      insetPadding: const EdgeInsets.all(16),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: n.carteHaute,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Rayons.xl)),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: n.carteHaute,
      shape: const RoundedRectangleBorder(borderRadius: Rayons.brLg),
    ),
  );
}

InputBorder _bordure(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: Rayons.brSm,
      borderSide: BorderSide(color: c, width: w),
    );

/// Attention au piège : `apply` pose une couleur sur tous les styles, mais
/// le `copyWith` qui suit **remplace** entièrement ceux qu'il nomme. Un style
/// redéfini sans `color` repart donc sur le blanc par défaut de Material, et
/// tout texte qui s'en sert devient invisible sur fond clair. Chaque style
/// redéfini ici porte donc sa couleur explicitement.
TextTheme _typo(TextTheme base, Nuances n) =>
    base.apply(bodyColor: n.encre, displayColor: n.encre).copyWith(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: -0.4,
            color: n.encre,
          ),
          titleLarge: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.3,
            letterSpacing: -0.2,
            color: n.encre,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: n.encre,
          ),
          bodyMedium: TextStyle(fontSize: 14, height: 1.55, color: n.encre),
          bodySmall: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: n.encreDouce,
          ),
        );

/// Styles de texte réutilisés dans les écrans.
///
/// Ceux qui portent une couleur neutre sont des méthodes prenant le
/// contexte, afin de suivre le thème clair / sombre.
class Textes {
  const Textes._();

  /// Sans couleur : il hérite de `bodyMedium`, désormais encré.
  static const titreService = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.1,
  );

  static const corpsGras = TextStyle(
    fontSize: 14,
    height: 1.6,
    fontWeight: FontWeight.w600,
  );

  static const titrePanneau = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    height: 1.35,
    letterSpacing: -0.1,
  );

  static const titreEcran = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.4,
    color: Colors.white,
  );

  static const erreur = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: Palette.erreur,
  );

  static TextStyle sousTitreService(BuildContext c) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: c.cl.encreDouce,
        height: 1.35,
      );

  static TextStyle libelle(BuildContext c) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: c.cl.encreDouce,
        letterSpacing: 0.6,
      );

  static TextStyle corps(BuildContext c) => TextStyle(
        fontSize: 14,
        height: 1.6,
        color: c.cl.encreDouce,
      );
}

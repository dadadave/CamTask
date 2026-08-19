import 'package:flutter/material.dart';

/// Charte graphique des maquettes CAM-TAXE.
class Palette {
  const Palette._();

  static const orange = Color(0xFFF5893F);
  static const orangeClair = Color(0xFFFBA05C);
  static const orangeFantome = Color(0xFFFFF3EA);
  static const bleu = Color(0xFF5DA9F5);
  static const bleuFonce = Color(0xFF1E88F0);

  static const fond = Color(0xFFEDEDED);
  static const fondDoux = Color(0xFFF6F6F6);
  static const carte = Colors.white;
  static const encre = Color(0xFF10100F);
  static const encreDouce = Color(0xFF55524F);
  static const grise = Color(0xFFA9A6A3);
  static const ligne = Color(0xFFDCD9D6);
}

/// Ombre portée commune aux cartes.
const ombreCarte = <BoxShadow>[
  BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4)),
];

const ombreDouce = <BoxShadow>[
  BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
];

ThemeData construireTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: Palette.fond,
    colorScheme: base.colorScheme.copyWith(
      primary: Palette.orange,
      secondary: Palette.orangeClair,
      surface: Palette.carte,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Palette.encre,
      displayColor: Palette.encre,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.orange,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF232120),
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Styles de texte réutilisés dans les écrans.
class Textes {
  const Textes._();

  static const titreService = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  static const sousTitreService = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Palette.encreDouce,
    height: 1.3,
  );

  static const libelle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Palette.encreDouce,
    letterSpacing: 0.3,
  );

  static const corps = TextStyle(fontSize: 12.5, height: 1.55);

  static const corpsGras = TextStyle(
    fontSize: 12.5,
    height: 1.55,
    fontWeight: FontWeight.w600,
  );

  static const titrePanneau = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    height: 1.35,
  );

  static const erreur = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFFD64C2B),
  );
}

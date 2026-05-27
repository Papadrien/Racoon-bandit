import 'package:flutter/material.dart';


class AppTheme {
  AppTheme._();

  static const Color primary   = Color(0xFF7C4DFF);
  static const Color textMuted = Color(0xFF6B5744);

  // ── Responsive helpers ────────────────────────────────────────────────────

  /// Padding horizontal standard selon la largeur d'écran.
  static double horizontalPadding(double screenWidth) {
    if (screenWidth < 340) return 12.0;
    if (screenWidth < 360) return 16.0;
    return 24.0;
  }

  /// Vrai si l'écran est étroit (< 360 dp).
  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  /// Vrai si l'écran est petit en hauteur (< 640 dp).
  static bool isShortScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 640;

  /// Couleur accent (orange fixe).
  static const Color accent = Color(0xFFFF6D00);

  static const Color background = Color(0xFFEECDAD);

  static final ThemeData dark = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: Color(0xFFFF6D00), // valeur initiale, remplacée dynamiquement
    ),
    scaffoldBackgroundColor: background,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        color: Color(0xFF2D1A0E),
      ),
    ),
  );
}

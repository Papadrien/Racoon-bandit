import 'package:flutter/material.dart';

import 'app_theme_provider.dart';

class AppTheme {
  AppTheme._();

  static const Color primary   = Color(0xFF7C4DFF);
  static const Color textMuted = Color(0xFF9E9E9E);

  /// Couleur accent courante — change selon le dos équipé.
  /// Utiliser [AppThemeProvider.instance.accent] pour réagir aux changements.
  static Color get accent => AppThemeProvider.instance.accent;

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: Color(0xFFFF6D00), // valeur initiale, remplacée dynamiquement
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        color: Colors.white,
      ),
    ),
  );
}

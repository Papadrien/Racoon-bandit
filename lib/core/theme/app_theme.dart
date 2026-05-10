import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF15171C);
  static const Color surface = Color(0xFF1F2229);
  static const Color primary = Color(0xFFFFB23F);
  static const Color accent = Color(0xFFE85D5D);
  static const Color textPrimary = Color(0xFFF5F1E8);
  static const Color textMuted = Color(0xFF8C8F98);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(color: textPrimary),
          labelLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            elevation: 6,
          ),
        ),
      );
}

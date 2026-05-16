import 'package:flutter/material.dart';

class AppAssets {
  AppAssets._();

  // ── Dos de cartes (assets définitifs) ───────────────────────────────────
  static const cardBackPurple = 'assets/images/cards/card_back_purple.png';
  static const cardBackBlue   = 'assets/images/cards/card_back_blue.png';
  static const cardBackGreen  = 'assets/images/cards/card_back_green.png';
  static const cardBackPink   = 'assets/images/cards/card_back_pink.png';
  static const cardBackYellow = 'assets/images/cards/card_back_yellow.png';

  // Alias legacy conservé pour compatibilité
  static const cardBackClassic = cardBackPurple;

  /// Retourne le chemin asset pour un dos de carte donné.
  static String cardBackAsset(String cardBackId) => switch (cardBackId) {
        'purple'  => cardBackPurple,
        'blue'    => cardBackBlue,
        'green'   => cardBackGreen,
        'pink'    => cardBackPink,
        'yellow'  => cardBackYellow,
        'classic' => cardBackPurple,  // legacy
        _         => cardBackPurple,
      };

  /// Couleur de fallback affichée dans les widgets colorés (ex. sélecteur).
  static Color cardBackFallbackColor(String cardBackId) => switch (cardBackId) {
        'purple'  => const Color(0xFF7C4DFF),
        'blue'    => const Color(0xFF2196F3),
        'green'   => const Color(0xFF4CAF50),
        'pink'    => const Color(0xFFE91E8C),
        'yellow'  => const Color(0xFFFFC107),
        'classic' => const Color(0xFF7C4DFF),
        _         => const Color(0xFF37474F),
      };
}

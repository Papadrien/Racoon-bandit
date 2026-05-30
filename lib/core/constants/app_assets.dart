import 'package:flutter/material.dart';

import '../models/card_type.dart';

class AppAssets {
  AppAssets._();

  // ── Faces avant de cartes ────────────────────────────────────────────────
  static const cardFrontFood       = 'assets/images/icon_food.png';
  static const cardFrontTrash      = 'assets/images/icon_trash.png';
  static const cardFrontRaccoon    = 'assets/images/card_front_raccoon.png';
  static const cardFrontPince      = 'assets/images/card_front_pince.png';
  static const cardFrontVacuum     = 'assets/images/card_front_vacuum.png';
  static const cardFrontBanquet    = 'assets/images/card_front_banquet.png';
  static const cardFrontBabyRaccoon = 'assets/images/card_front_baby_raccoon.png';

  /// Chemin de l'icône sticker pour une face avant de carte.
  static String cardFrontIcon(CardType type) => switch (type) {
    CardType.food        => cardFrontFood,
    CardType.trash       => cardFrontTrash,
    CardType.raccoon     => cardFrontRaccoon,
    CardType.pince       => cardFrontPince,
    CardType.vacuum      => cardFrontVacuum,
    CardType.banquet     => cardFrontBanquet,
    CardType.babyRaccoon => cardFrontBabyRaccoon,
  };

  /// Couleur de fond unique pour chaque face avant de carte.
  static Color cardFrontColor(CardType type) => switch (type) {
    CardType.food        => const Color(0xFF7CB87A),
    CardType.trash       => const Color(0xFF78909C),
    CardType.raccoon     => const Color(0xFFFFAB40),
    CardType.pince       => const Color(0xFF7C4DFF),
    CardType.vacuum      => const Color(0xFF29B6F6),
    CardType.banquet     => const Color(0xFFEF5350),
    CardType.babyRaccoon => const Color(0xFFBA68C8),
  };

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

// Extension ajoutée dans lib/core/constants/app_assets.dart
// Les constantes audio sont centralisées dans AudioService._sounds
// (lib/core/services/audio_service.dart)

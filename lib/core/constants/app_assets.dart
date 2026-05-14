import 'package:flutter/material.dart';

class AppAssets {
  AppAssets._();

  // ── Dos de cartes (assets réels) ─────────────────────────────────────────
  static const cardBackClassic = 'assets/images/cards/card_back_classic.png';
  static const cardBackPurple  = 'assets/images/cards/card_back_purple.png';

  /// Retourne le chemin asset pour un dos de carte donné.
  ///
  /// Les dos sans image dédiée retournent le fallback [cardBackPurple]
  /// pour garantir un aperçu toujours cohérent dans les popups.
  static String? cardBackAsset(String cardBackId) => switch (cardBackId) {
        'classic'  => cardBackClassic,
        'purple'   => cardBackPurple,
        // Dos débloqués par progression → fallback visuel sur purple
        'bandit'   => cardBackPurple,
        'gold'     => cardBackPurple,
        'champion' => cardBackPurple,
        _          => cardBackPurple,
      };

  /// Couleur de fallback affichée dans les widgets colorés (ex. sélecteur).
  static Color cardBackFallbackColor(String cardBackId) => switch (cardBackId) {
        'classic'  => const Color(0xFF2E7D32),
        'bandit'   => const Color(0xFF1565C0),
        'gold'     => const Color(0xFFF9A825),
        'champion' => const Color(0xFF6A1B9A),
        'purple'   => const Color(0xFF6A1B9A),
        _          => const Color(0xFF37474F),
      };
}

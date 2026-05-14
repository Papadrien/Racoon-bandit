import 'package:flutter/material.dart';

class AppAssets {
  AppAssets._();

  static const cardBackPurple = 'assets/images/cards/card_back_purple.png';

  /// Retourne le chemin asset pour un dos de carte donné, ou null si absent.
  static String? cardBackAsset(String cardBackId) => switch (cardBackId) {
        'purple' => cardBackPurple,
        _ => null,
      };

  /// Couleur de fallback affichée quand aucun asset image n'existe pour ce dos.
  static Color cardBackFallbackColor(String cardBackId) => switch (cardBackId) {
        'classic' => const Color(0xFF2E7D32),
        'blue'    => const Color(0xFF1565C0),
        'green'   => const Color(0xFF00695C),
        'gold'    => const Color(0xFFF9A825),
        'purple'  => const Color(0xFF6A1B9A),
        _         => const Color(0xFF37474F),
      };
}

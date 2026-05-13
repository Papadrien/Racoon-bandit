import 'dart:async';

import 'package:flutter/services.dart';

import 'settings_service.dart';

enum HapticType {
  /// Bouton UI, sélection légère.
  selection,

  /// Carte piochée.
  light,

  /// Effet notable (vol, frigo détruite).
  medium,

  /// Fin de partie.
  heavy,
}

/// Retours haptiques centralisés et conditionnels (respecte le toggle
/// vibrations dans les paramètres).
class HapticService {
  HapticService._();

  static void trigger(HapticType type) {
    if (!SettingsService.vibrationEnabled) return;
    unawaited(_fire(type));
  }

  static Future<void> _fire(HapticType type) async {
    try {
      switch (type) {
        case HapticType.selection:
          await HapticFeedback.selectionClick();
        case HapticType.light:
          await HapticFeedback.lightImpact();
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
        case HapticType.heavy:
          await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      // Haptique indisponible → silencieux
    }
  }
}

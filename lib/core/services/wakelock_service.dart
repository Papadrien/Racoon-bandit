import 'package:wakelock_plus/wakelock_plus.dart';

/// Empêche la mise en veille de l'écran pendant une partie active.
///
/// Usage :
///   WakelockService.enable();   // début de partie
///   WakelockService.disable();  // fin / quitter / dispose
class WakelockService {
  WakelockService._();

  /// Active le wakelock (écran toujours allumé).
  static Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Silencieux si indisponible (émulateur, iOS simulator…)
    }
  }

  /// Désactive le wakelock (comportement système normal).
  static Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Silencieux si indisponible
    }
  }
}

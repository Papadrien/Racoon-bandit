import 'package:shared_preferences/shared_preferences.dart';

/// Paramètres persistants de l'application (son, vibrations).
/// Initialiser avec [load()] au démarrage avant [runApp].
class SettingsService {
  SettingsService._();

  static const _keySoundEnabled = 'sound_enabled';
  static const _keyVibrationEnabled = 'vibration_enabled';

  static bool soundEnabled = true;
  static bool vibrationEnabled = true;

  /// À appeler une fois dans main(), avant runApp.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? true;
    } catch (_) {
      // Valeurs par défaut si SharedPreferences indisponible
    }
  }

  static Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, value);
    } catch (_) {}
  }

  static Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyVibrationEnabled, value);
    } catch (_) {}
  }
}

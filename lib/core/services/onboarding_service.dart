import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion de l'onboarding premier lancement.
///
/// Stocke un flag [onboardingCompleted] dans SharedPreferences.
/// L'onboarding n'est affiché qu'une seule fois (premier lancement).
///
/// Debug : [resetForDebug] permet de forcer la réapparition de l'onboarding.
class OnboardingService {
  OnboardingService._();

  static const _keyOnboardingCompleted = 'onboarding_completed_v1';

  static bool _onboardingCompleted = false;

  /// Vrai si l'onboarding a déjà été vu / skippé.
  static bool get onboardingCompleted => _onboardingCompleted;

  /// Vrai si l'onboarding doit être affiché (premier lancement uniquement).
  static bool get shouldShowOnboarding => !_onboardingCompleted;

  /// À appeler dans main(), avant runApp.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingCompleted = prefs.getBool(_keyOnboardingCompleted) ?? false;
    } catch (_) {
      _onboardingCompleted = false;
    }
  }

  /// Marque l'onboarding comme terminé/skippé.
  /// À appeler quand le joueur clique "Terminer" ou "Passer".
  static Future<void> markCompleted() async {
    _onboardingCompleted = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingCompleted, true);
    } catch (_) {}
  }

  /// Reset debug — force la réapparition de l'onboarding au prochain lancement.
  static Future<void> resetForDebug() async {
    _onboardingCompleted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOnboardingCompleted);
    } catch (_) {}
  }
}

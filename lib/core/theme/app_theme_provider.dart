import 'package:flutter/material.dart';

/// Fournisseur de thème dynamique lié au dos de carte équipé.
///
/// Le violet reste toujours la couleur primaire/fond principal.
/// Seule la couleur accent (anciennement orange) change selon le dos.
class AppThemeProvider extends ChangeNotifier {
  AppThemeProvider._();

  static final AppThemeProvider instance = AppThemeProvider._();

  // ── Accent par dos de carte ──────────────────────────────────────────────

  /// Retourne la couleur accent correspondant à un dos de carte.
  static Color accentForCardBack(String cardBackId) => switch (cardBackId) {
        'purple' => const Color(0xFFFF6D00),   // orange (défaut)
        'blue'   => const Color(0xFF2196F3),   // bleu
        'green'  => const Color(0xFF4CAF50),   // vert
        'pink'   => const Color(0xFFE91E8C),   // rose
        'yellow' => const Color(0xFFFFC107),   // jaune
        _        => const Color(0xFFFF6D00),   // orange fallback
      };

  // ── État courant ─────────────────────────────────────────────────────────

  Color _accent = const Color(0xFFFF6D00);

  /// Couleur accent courante (change selon le dos équipé).
  Color get accent => _accent;

  /// Met à jour l'accent selon le dos équipé et notifie les listeners.
  void updateFromCardBack(String cardBackId) {
    final newAccent = accentForCardBack(cardBackId);
    if (newAccent == _accent) return;
    _accent = newAccent;
    notifyListeners();
  }

  /// Initialise sans notifier (utilisé au démarrage).
  void initFromCardBack(String cardBackId) {
    _accent = accentForCardBack(cardBackId);
  }
}

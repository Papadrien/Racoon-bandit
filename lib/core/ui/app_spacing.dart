/// Espacements, radius et paddings récurrents — Raccoon Bandit.
///
/// Objectif : uniformiser progressivement les futurs écrans.
/// Ne pas surcharger. Ajouter uniquement ce qui est réellement utilisé.
abstract class AppSpacing {
  AppSpacing._();

  // ── Radius ────────────────────────────────────────────────────────────────

  /// 8 dp — petits éléments, chips, badges.
  static const double radiusSmall = 8.0;

  /// 14 dp — boutons flottants, inputs, éléments secondaires.
  static const double radiusMedium = 14.0;

  /// 20 dp — conteneurs principaux (vies, cartes, panneaux).
  static const double radiusLarge = 20.0;

  /// 28 dp — éléments arrondis forts, bouton Jouer (avant coupe diagonale).
  static const double radiusXLarge = 28.0;

  // ── Spacing vertical ──────────────────────────────────────────────────────

  /// 4 dp
  static const double xs = 4.0;

  /// 8 dp
  static const double sm = 8.0;

  /// 12 dp
  static const double md = 12.0;

  /// 16 dp
  static const double lg = 16.0;

  /// 24 dp
  static const double xl = 24.0;

  /// 32 dp
  static const double xxl = 32.0;

  // ── Padding horizontal standard (responsive) ─────────────────────────────

  /// Padding horizontal — écran étroit (< 340 dp).
  static const double hPadNarrowest = 12.0;

  /// Padding horizontal — écran standard étroit (< 360 dp).
  static const double hPadNarrow = 16.0;

  /// Padding horizontal — écran standard.
  static const double hPadNormal = 24.0;

  /// Padding horizontal — écran large.
  static const double hPadWide = 32.0;

  // ── Hauteurs composants ───────────────────────────────────────────────────

  /// Hauteur bouton principal (Jouer, actions primaires).
  static const double buttonHeight = 74.0;

  /// Hauteur bouton secondaire (ElevatedButton standard).
  static const double buttonHeightSecondary = 52.0;

  /// Hauteur bouton flottant carré (icônes).
  static const double floatingButtonSize = 40.0;

  // ── Lecture confortable (légal / texte long) ──────────────────────────────

  /// Largeur de lecture confortable pour les textes longs sur mobile.
  /// Clampée entre 240 et 560 dp selon la largeur d'écran disponible.
  static double readingMaxWidth(double screenWidth, {double hPad = 48.0}) =>
      (screenWidth - hPad).clamp(240.0, 560.0);
}

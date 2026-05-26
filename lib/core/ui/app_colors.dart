import 'package:flutter/material.dart';

/// Palette centralisée — Raccoon Bandit, style sticker casual premium.
///
/// Le projet est LIGHT ONLY. Aucun support dark/light mode.
/// Ne pas ajouter de ThemeMode ni de variantes adaptatives.
abstract class AppColors {
  AppColors._();

  // ── Fond ──────────────────────────────────────────────────────────────────

  /// Beige chaud — fond principal de tous les écrans.
  static const Color background = Color(0xFFEECDAD);

  /// Beige légèrement plus clair — surfaces secondaires, cartes intérieures.
  static const Color backgroundLight = Color(0xFFF5E6D3);

  // ── Sticker / surfaces blanches ───────────────────────────────────────────

  /// Blanc pur — fond des composants sticker (boutons flottants, vies, cartes).
  static const Color stickerWhite = Colors.white;

  /// Blanc cassé chaud — coin replié du bouton Jouer, surfaces secondaires.
  static const Color stickerWarm = Color(0xFFDDCFBF);

  // ── Bouton principal (orange) ─────────────────────────────────────────────

  /// Orange principal — bouton Jouer, accent principal.
  static const Color orange = Color(0xFFE16713);

  /// Orange foncé — bord bas du dégradé bouton, ombres intérieures.
  static const Color orangeDark = Color(0xFFB84D0A);

  /// Orange clair — highlight haut du dégradé bouton.
  static const Color orangeLight = Color(0xFFEF8C3C);

  // ── Logo / violet ─────────────────────────────────────────────────────────

  /// Violet principal — logo, couleur primaire Flutter theme.
  static const Color violet = Color(0xFF7C4DFF);

  // ── Texte ─────────────────────────────────────────────────────────────────

  /// Brun chaud — texte secondaire, icônes neutres, timer.
  static const Color textMuted = Color(0xFF6B5744);

  /// Brun foncé — texte principal sur fond beige.
  static const Color textDark = Color(0xFF2D1A0E);

  // ── Cœurs / accent dynamique ──────────────────────────────────────────────

  /// Rouge — cœurs actifs (vies). Valeur de fallback ;
  /// utiliser [AppTheme.accent] pour la couleur dynamique réelle.
  static const Color heartRed = Color(0xFFE53935);

  // ── Ombres (couleurs seules, sans BoxShadow) ──────────────────────────────

  /// Ombre standard — noir à 15% d'opacité.
  static const Color shadowStandard = Color(0x26000000);

  /// Ombre douce — noir à 10% d'opacité.
  static const Color shadowSoft = Color(0x1A000000);

  /// Ombre légère — noir à 6% d'opacité.
  static const Color shadowSubtle = Color(0x0F000000);

  /// Ombre bouton — noir à 25% d'opacité.
  static const Color shadowButton = Color(0x40000000);

  // ── Glow (très atténués, non néon) ───────────────────────────────────────

  /// Glow blanc doux — reflet pill bouton Jouer.
  static const Color glowWhiteSoft = Color(0x4DFFFFFF);

  /// Glow blanc léger — highlight secondaire.
  static const Color glowWhiteLight = Color(0x33FFFFFF);
}

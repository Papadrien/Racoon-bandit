import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';

/// Décorations partagées — style sticker casual premium.
///
/// Toutes les décorations sont [const] ou des fonctions légères.
/// Éviter de recréer inutilement des objets à chaque build.
abstract class AppDecorations {
  AppDecorations._();

  // ── Sticker flottant ──────────────────────────────────────────────────────

  /// Décoration sticker flottante — surface blanche avec ombre prononcée.
  /// Pour les composants visuels forts : cartes, panneaux, badges.
  static const BoxDecoration floatingSticker = BoxDecoration(
    color: AppColors.stickerWhite,
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLarge)),
    boxShadow: AppShadows.sticker,
  );

  /// Décoration sticker flottante avec radius personnalisé.
  static BoxDecoration floatingStickerR(double radius) => BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.sticker,
      );

  // ── Sticker blanc (léger) ─────────────────────────────────────────────────

  /// Décoration sticker blanche légère — composants secondaires.
  /// Ombre douce, séparation subtile du fond.
  /// Utilisée par : LivesIndicator, badges, chips.
  static const BoxDecoration whiteSticker = BoxDecoration(
    color: AppColors.stickerWhite,
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLarge)),
    boxShadow: AppShadows.soft,
  );

  // ── Bouton flottant (icône carré) ─────────────────────────────────────────

  /// Fond blanc sticker — boutons flottants (settings, premium, etc.).
  /// Légère ombre flottante, effet "décollé" du fond.
  static BoxDecoration floatingButton({
    double radius = AppSpacing.radiusMedium,
  }) =>
      BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.floating,
      );

  // ── Bouton principal (ElevatedButton standard) ────────────────────────────

  /// Décoration de base pour les boutons primaires non-sticker.
  /// Utilisée par PrimaryButton, _RewardAdButton, etc.
  static BoxDecoration primaryButton({Color? color}) => BoxDecoration(
        color: color ?? AppColors.orange,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSpacing.radiusMedium)),
        boxShadow: AppShadows.button,
      );

  // ── Conteneurs génériques ─────────────────────────────────────────────────

  /// Conteneur blanc avec coins arrondis moyens — usage général.
  static const BoxDecoration card = BoxDecoration(
    color: AppColors.stickerWhite,
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMedium)),
    boxShadow: AppShadows.floating,
  );

  // ── Alias de compatibilité (utilisés dans home_screen / lives_indicator) ──

  /// Alias → [whiteSticker]. Pour les conteneurs de vies.
  static const BoxDecoration livesContainer = whiteSticker;

  // ── Settings sub-screens ──────────────────────────────────────────────────

  /// Décoration section settings — identique à [card], utilisée pour
  /// les cartes de sous-écrans (ToggleTile, NavTile, PolicyCard).
  static const BoxDecoration sectionCard = BoxDecoration(
    color: AppColors.stickerWhite,
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLarge)),
    boxShadow: AppShadows.floating,
  );

  /// Icône badge settings — fond légèrement teinté, radius small.
  static BoxDecoration settingsIconBadge(Color tint) => BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      );
}

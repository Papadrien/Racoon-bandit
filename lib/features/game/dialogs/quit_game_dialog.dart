import 'package:flutter/material.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/app_shadows.dart';
import '../../../core/ui/app_spacing.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

/// Affiche un dialog de confirmation pour quitter la partie en cours.
/// Retourne `true` si l'utilisateur confirme, `false` sinon.
Future<bool> showQuitGameDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.stickerWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
          boxShadow: AppShadows.floating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.orange,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Titre
            Text(
              l10n.gameQuitDialogTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Contenu
            Text(
              l10n.gameQuitDialogContent,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Boutons
            Row(
              children: [
                // Annuler
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      AudioService.instance.playButtonSound();
                      Navigator.of(ctx).pop(false);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        border: Border.all(
                          color: AppColors.shadowSoft,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          l10n.gameQuitCancel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Quitter
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      AudioService.instance.playButtonSound();
                      Navigator.of(ctx).pop(true);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        boxShadow: AppShadows.subtleGlow(AppColors.orange),
                      ),
                      child: Center(
                        child: Text(
                          l10n.gameQuitConfirm,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return confirmed ?? false;
}

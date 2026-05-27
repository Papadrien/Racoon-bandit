import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../../../core/ui/app_shadows.dart';
import '../../../core/ui/app_spacing.dart';

/// Header secondaire unifié — utilisé par tous les sous-écrans settings.
///
/// Composant mutualisé : bouton retour sticker + titre centré.
/// Style léger, respirant, cohérent avec le Home Screen et le Settings principal.
class SettingsSecondaryHeader extends StatelessWidget {
  /// Titre affiché dans la top bar. Sera mis en majuscules automatiquement.
  final String title;

  /// Widget optionnel en position trailing (ex: icône d'action).
  final Widget? trailing;

  const SettingsSecondaryHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          // ── Bouton retour sticker ──────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: AppSpacing.floatingButtonSize,
              height: AppSpacing.floatingButtonSize,
              decoration: BoxDecoration(
                color: AppColors.stickerWhite,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                boxShadow: AppShadows.floating,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // ── Titre centré (s'étend entre bouton retour et trailing) ─────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // ── Trailing optionnel ─────────────────────────────────────────
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

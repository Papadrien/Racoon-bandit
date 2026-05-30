import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_decorations.dart';
import '../core/ui/app_shadows.dart';
import '../core/ui/app_spacing.dart';

/// Barre de statut en jeu : parties restantes, timer, bouton pub.
///
/// Style : fond blanc sticker, ombres douces, cohérent avec la Home Screen.
class LivesBar extends StatelessWidget {
  final int lives;
  final VoidCallback? onAdBonus;

  static const int maxLives = 1;

  const LivesBar({
    super.key,
    required this.lives,
    this.onAdBonus,
  }) : assert(lives >= 0 && lives <= maxLives);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.stickerWhite,
        border: Border(
          bottom: BorderSide(
            color: Color(0x14000000),
            width: 1,
          ),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          _LivesRow(lives: lives),
          const Spacer(),
          const _TimerPlaceholder(),
          const Spacer(),
          if (lives < maxLives)
            _AdButton(onPressed: onAdBonus)
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }
}

class _LivesRow extends StatelessWidget {
  final int lives;
  const _LivesRow({required this.lives});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(LivesBar.maxLives, (i) {
        final filled = i < lives;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: Icon(
            filled ? Icons.circle_rounded : Icons.circle_outlined,
            size: 14,
            color: filled
                ? AppColors.orange.withValues(alpha: 0.85)
                : AppColors.textMuted.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}

class _TimerPlaceholder extends StatelessWidget {
  const _TimerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.violet.withValues(alpha: 0.35),
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSpacing.radiusSmall),
        ),
      ),
      child: const Text(
        '0:30',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.violet,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _AdButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _AdButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: AppDecorations.floatingButton(
        radius: AppSpacing.radiusSmall,
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.smart_display,
          size: 16,
          color: AppTheme.accent,
        ),
        label: Text(
          l10n.livesAdButton,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppSpacing.radiusSmall),
            ),
          ),
        ),
      ),
    );
  }
}

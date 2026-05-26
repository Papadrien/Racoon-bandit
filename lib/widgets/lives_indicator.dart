import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_decorations.dart';
import '../core/ui/app_spacing.dart';

class LivesIndicator extends StatelessWidget {
  final int lives;
  final Duration remainingDuration;

  static const int _maxLives = 3;

  const LivesIndicator({
    super.key,
    required this.lives,
    required this.remainingDuration,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.radiusMedium,
        vertical: AppSpacing.sm + 1,
      ),
      decoration: AppDecorations.livesContainer,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 cœurs : rouge rempli = vie active, gris contour = vie vide
          ...List.generate(_maxLives, (i) {
            final filled = i < lives;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs - 1),
              child: Icon(
                filled ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: filled
                    ? AppTheme.accent
                    : AppColors.textMuted.withValues(alpha: 0.35),
              ),
            );
          }),
          // Timer de recharge
          if (remainingDuration > Duration.zero) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              _formatDuration(remainingDuration),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

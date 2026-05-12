import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

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
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 cœurs visuels : rouge rempli = vie active, gris contour = vie vide
          ...List.generate(_maxLives, (i) {
            final filled = i < lives;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(
                filled ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: filled
                    ? AppTheme.accent
                    : AppTheme.textMuted.withValues(alpha: 0.4),
              ),
            );
          }),
          // Timer de recharge
          if (remainingDuration > Duration.zero) ...[
            const SizedBox(width: 8),
            Text(
              _formatDuration(remainingDuration),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

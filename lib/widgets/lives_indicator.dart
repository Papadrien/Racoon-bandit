import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class LivesIndicator extends StatelessWidget {
  final int lives;
  final Duration remainingDuration;

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
          const Icon(
            Icons.favorite,
            color: AppTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$lives/3',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (remainingDuration > Duration.zero) ...[
            const SizedBox(width: 10),
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

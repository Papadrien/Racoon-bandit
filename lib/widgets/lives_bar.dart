import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core/theme/app_theme.dart';

/// Barre de statut en jeu : vies restantes, timer, bouton pub.
class LivesBar extends StatelessWidget {
  final int lives;
  final VoidCallback? onAdBonus;

  static const int maxLives = 3;

  const LivesBar({
    super.key,
    required this.lives,
    this.onAdBonus,
  }) : assert(lives >= 0 && lives <= maxLives);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2C2C2C)),
        ),
      ),
      child: Row(
        children: [
          // Vies
          _LivesRow(lives: lives),
          const Spacer(),
          // Timer placeholder
          const _TimerPlaceholder(),
          const Spacer(),
          // Bouton Pub +1 vie
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
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            filled ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: filled
                ? AppTheme.accent
                : AppTheme.textMuted.withValues(alpha: 0.4),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '0:30',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
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
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.smart_display, size: 16, color: AppTheme.accent),
      label: Text(
        l10n.livesAdButton,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.accent,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

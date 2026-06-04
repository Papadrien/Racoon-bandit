import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../../../core/ui/app_shadows.dart';
import '../../../core/ui/app_spacing.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

/// Barre de contrôles supérieure du game screen.
/// Contient le bouton Quitter (gauche) et le compteur de cartes restantes (droite).
class GameControlsBar extends StatelessWidget {
  const GameControlsBar({
    super.key,
    required this.remainingCards,
    required this.quitEnabled,
    required this.onQuitPressed,
  });

  final int remainingCards;
  final bool quitEnabled;
  final VoidCallback onQuitPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton Quitter
          GestureDetector(
            onTap: quitEnabled ? onQuitPressed : null,
            child: Opacity(
              opacity: quitEnabled ? 1.0 : 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.stickerWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  boxShadow: AppShadows.floating,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.exit_to_app, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      l10n.gameQuitConfirm,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // Compteur cartes restantes
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: remainingCards == 0
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(remainingCards),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.stickerWhite,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      boxShadow: AppShadows.floating,
                    ),
                    child: Text(
                      l10n.gameRemainingCards(remainingCards),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

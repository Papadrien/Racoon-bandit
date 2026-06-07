import 'package:flutter/material.dart';

import '../../../core/models/game_card.dart';
import '../../../core/models/player_state.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/app_decorations.dart';
import '../../../core/ui/app_spacing.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';
import 'game_deck_card.dart';

/// Zone centrale du game screen :
/// - label "Tour de X"
/// - deck de cartes (background + active)
/// - texte d'effet résolu
class GameCenterArea extends StatelessWidget {
  const GameCenterArea({
    super.key,
    required this.deckKey,
    required this.constraints,
    required this.displayPlayerName,
    required this.currentPlayerName,
    required this.effectText,
    required this.isAnimating,
    required this.remainingCards,
    required this.revealedCard,
    required this.deckStickerPlayer,
    required this.currentPlayer,
    required this.cardWidth,
    required this.cardHeight,
    required this.cardRadius,
    required this.flipController,
    required this.slideController,
    required this.appearController,
    required this.appearOffset,
    required this.appearOpacity,
    required this.onDrawCard,
  });

  final GlobalKey deckKey;
  final BoxConstraints constraints;

  final String? displayPlayerName;
  final String currentPlayerName;
  final String effectText;

  final bool isAnimating;
  final int remainingCards;
  final GameCard? revealedCard;
  final PlayerState? deckStickerPlayer;
  final PlayerState currentPlayer;

  final double cardWidth;
  final double cardHeight;
  final double cardRadius;

  final AnimationController flipController;
  final AnimationController slideController;
  final AnimationController appearController;
  final Animation<double> appearOffset;
  final Animation<double> appearOpacity;

  final VoidCallback onDrawCard;

  @override
  Widget build(BuildContext context) {
    final showBackgroundCard =
        isAnimating ? remainingCards > 0 : remainingCards > 1;
    final titleFontSize = (constraints.maxWidth * 0.062).clamp(14.0, 22.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tour du joueur
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: AppDecorations.floatingStickerR(AppSpacing.radiusLarge),
          child: Text(
            AppLocalizations.of(context)!.gameTurnOf(
              displayPlayerName ?? currentPlayerName,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Deck
        SizedBox(
          key: deckKey,
          width: cardWidth + 16,
          height: cardHeight + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (showBackgroundCard)
                Transform.translate(
                  offset: const Offset(0, 6),
                  child: Opacity(
                    opacity: 0.65,
                    child: GameDeckCard(
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                      cardRadius: cardRadius,
                      flipController: flipController,
                      slideController: slideController,
                      appearController: appearController,
                      appearOffset: appearOffset,
                      appearOpacity: appearOpacity,
                      revealedCard: revealedCard,
                      deckStickerPlayer: deckStickerPlayer,
                      currentPlayer: currentPlayer,
                      remainingCards: remainingCards,
                      backgroundCard: true,
                      onTap: null,
                    ),
                  ),
                ),
              GameDeckCard(
                cardWidth: cardWidth,
                cardHeight: cardHeight,
                cardRadius: cardRadius,
                flipController: flipController,
                slideController: slideController,
                appearController: appearController,
                appearOffset: appearOffset,
                appearOpacity: appearOpacity,
                revealedCard: revealedCard,
                deckStickerPlayer: deckStickerPlayer,
                currentPlayer: currentPlayer,
                remainingCards: remainingCards,
                backgroundCard: false,
                onTap: onDrawCard,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Texte effet
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, maxHeight: 48),
          child: Text(
            effectText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

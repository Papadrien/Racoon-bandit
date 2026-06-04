import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/models/game_card.dart';
import '../../../core/models/player_state.dart';
import '../../../core/services/progression_service.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/app_shadows.dart';
import '../../../widgets/card_front_widget.dart';
import '../../../widgets/player_avatar.dart';

/// Widget représentant une carte du deck (dos ou face) avec animations.
///
/// Supporte deux modes :
/// - [backgroundCard] = true  → carte fantôme en arrière-plan (pile)
/// - [backgroundCard] = false → carte active piochable/retournée
class GameDeckCard extends StatelessWidget {
  const GameDeckCard({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.cardRadius,
    required this.flipController,
    required this.slideController,
    required this.appearController,
    required this.appearOffset,
    required this.appearOpacity,
    required this.revealedCard,
    required this.deckStickerPlayer,
    required this.currentPlayer,
    required this.remainingCards,
    required this.backgroundCard,
    required this.onTap,
  });

  final double cardWidth;
  final double cardHeight;
  final double cardRadius;

  final AnimationController flipController;
  final AnimationController slideController;
  final AnimationController appearController;
  final Animation<double> appearOffset;
  final Animation<double> appearOpacity;

  final GameCard? revealedCard;
  final PlayerState? deckStickerPlayer;
  final PlayerState currentPlayer;
  final int remainingCards;
  final bool backgroundCard;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final deckExhausted = remainingCards == 0 && revealedCard == null;

    return GestureDetector(
      onTap: backgroundCard || deckExhausted ? null : onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([flipController, slideController, appearController]),
        builder: (context, child) {
          final flip = flipController.value;
          final slide = slideController.value;
          final angle = flip * math.pi;
          final showFront = angle > math.pi / 2;
          final isBack = !deckExhausted && !(showFront && revealedCard != null);

          final nearEdge = !backgroundCard &&
              angle > math.pi / 2 - 0.08 &&
              angle < math.pi / 2 + 0.08;

          final isFlipping = flip > 0.0;
          final appearDy = (backgroundCard || isFlipping) ? 0.0 : appearOffset.value * 10.0;
          final appearAlpha = (backgroundCard || isFlipping) ? 1.0 : appearOpacity.value;

          if (deckExhausted && !backgroundCard) {
            return const SizedBox.shrink();
          }

          return Opacity(
            opacity: nearEdge ? 0.0 : appearAlpha,
            child: Transform.translate(
              offset: backgroundCard
                  ? const Offset(0, 0)
                  : Offset(0, slide * 600 + appearDy),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(backgroundCard ? 0 : angle),
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(
                      color: Colors.white,
                      width: 7.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cardRadius - 7.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: isBack || backgroundCard
                              ? _CardBackWidget()
                              : (showFront && revealedCard != null)
                                  ? CardFrontWidget(
                                      cardType: revealedCard!.type,
                                      flipHorizontal: true,
                                    )
                                  : const SizedBox.shrink(),
                        ),
                        if (!backgroundCard && !showFront && !deckExhausted)
                          Positioned.fill(
                            child: Center(
                              child: _CurrentPlayerSticker(
                                player: deckStickerPlayer ?? currentPlayer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardBackWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final id = ProgressionService.progression.selectedCardBackId;
    final assetPath = AppAssets.cardBackAsset(id);
    return Image.asset(
      assetPath,
      fit: BoxFit.fill,
      errorBuilder: (_, a, b) =>
          ColoredBox(color: AppAssets.cardBackFallbackColor(id)),
    );
  }
}

class _CurrentPlayerSticker extends StatelessWidget {
  const _CurrentPlayerSticker({required this.player});

  final PlayerState player;

  @override
  Widget build(BuildContext context) {
    final color = player.profileColor;
    const double size = 62.9;
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.stickerWhite,
        border: Border.all(color: color, width: 2.5),
        boxShadow: AppShadows.subtleGlow(color),
      ),
      child: Center(
        child: PlayerAvatar(
          emoji: player.emoji,
          color: color,
          size: size,
        ),
      ),
    );
  }
}

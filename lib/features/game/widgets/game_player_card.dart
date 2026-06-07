import 'package:flutter/material.dart';

import '../../../core/models/player_state.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/app_shadows.dart';
import '../../../core/ui/app_spacing.dart';
import '../../../widgets/player_avatar.dart';

/// Widget représentant un joueur sur le plateau :
/// avatar flottant + carte sticker + zone ressources.
class GamePlayerCard extends StatelessWidget {
  const GamePlayerCard({
    super.key,
    required this.player,
    required this.active,
    required this.displayFoodCount,
    required this.displayTrashCount,
    required this.playerKey,
    required this.foodZoneKey,
    required this.fridgeZoneKey,
    required this.maxWidth,
  });

  final PlayerState player;
  final bool active;
  final int displayFoodCount;
  final int displayTrashCount;
  final GlobalKey playerKey;
  final GlobalKey foodZoneKey;
  final GlobalKey fridgeZoneKey;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isCompact = maxWidth < 115;
    final avatarSize = isCompact ? 36.0 : 45.6;
    final avatarRingSize = avatarSize + 6.0;
    final nameFontSize = isCompact ? 10.0 : 12.0;
    final resourceIconSize = isCompact ? 18.0 : 20.0;

    final resourceZoneHeight = (resourceIconSize * 2 + 4) * 2 + 6.0;
    const double avatarOverlap = 8.0;
    final cardInnerHeight = isCompact ? 25.6 : 30.4;

    return SizedBox(
      width: maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar flottant
          Container(
            width: avatarRingSize,
            height: avatarRingSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.stickerWhite,
              border: active
                  ? Border.all(color: player.profileColor, width: 2.5)
                  : null,
              boxShadow: active
                  ? AppShadows.subtleGlow(player.profileColor)
                  : AppShadows.floating,
            ),
            child: Center(
              child: PlayerAvatar(
                emoji: player.emoji,
                color: player.profileColor,
                size: avatarSize,
              ),
            ),
          ),

          // Carte sticker nom
          Transform.translate(
            offset: const Offset(0, -avatarOverlap),
            child: Container(
              key: playerKey,
              width: maxWidth,
              height: cardInnerHeight + avatarOverlap + (isCompact ? 4 : 6),
              padding: EdgeInsets.fromLTRB(
                isCompact ? 4 : 6,
                avatarOverlap + 2,
                isCompact ? 4 : 6,
                isCompact ? 3 : 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.stickerWhite,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: active
                    ? Border.all(color: player.profileColor, width: 2)
                    : null,
                boxShadow: AppShadows.sticker,
              ),
              child: Center(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: nameFontSize,
                  ),
                ),
              ),
            ),
          ),

          // Zone ressources fixe
          Transform.translate(
            offset: const Offset(0, -avatarOverlap + 2),
            child: SizedBox(
              width: maxWidth,
              height: resourceZoneHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nourriture
                  SizedBox(
                    key: foodZoneKey,
                    width: maxWidth,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 3,
                      runSpacing: 3,
                      children: displayFoodCount > 0
                          ? List.generate(
                              displayFoodCount.clamp(0, 8),
                              (_) => SizedBox(
                                width: resourceIconSize,
                                height: resourceIconSize,
                                child: Image.asset(
                                  'assets/images/icon_food.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : const [],
                    ),
                  ),
                  if (displayTrashCount > 0) ...[
                    const SizedBox(height: 2),
                    SizedBox(
                      key: fridgeZoneKey,
                      width: maxWidth,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 3,
                        runSpacing: 3,
                        children: List.generate(
                          displayTrashCount.clamp(0, 6),
                          (_) => SizedBox(
                            width: resourceIconSize,
                            height: resourceIconSize,
                            child: Image.asset(
                              'assets/images/icon_trash.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(key: fridgeZoneKey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

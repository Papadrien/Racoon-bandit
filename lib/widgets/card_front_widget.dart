import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/models/card_type.dart';

/// Face avant d'une carte : fond uni + icône centrée en sticker (avec marge).
///
/// Le rendu : fond [color], contour blanc (hérité du parent), icône centrée
/// à ~65 % de la carte avec une légère ombre pour l'effet autocollant.
class CardFrontWidget extends StatelessWidget {
  const CardFrontWidget({
    super.key,
    required this.cardType,
    this.borderRadius,
  });

  final CardType cardType;

  /// BorderRadius appliqué au fond coloré (optionnel, sinon zéro).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = AppAssets.cardFrontColor(cardType);
    final icon  = AppAssets.cardFrontIcon(cardType);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: ColoredBox(
        color: color,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              icon,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

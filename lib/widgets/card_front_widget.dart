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
    this.flipHorizontal = false,
  });

  final CardType cardType;

  /// BorderRadius appliqué au fond coloré (optionnel, sinon zéro).
  final BorderRadius? borderRadius;

  /// Si true, applique un miroir horizontal à l'icône sticker.
  final bool flipHorizontal;

  @override
  Widget build(BuildContext context) {
    final color = AppAssets.cardFrontColor(cardType);
    final icon  = AppAssets.cardFrontIcon(cardType);

    Widget image = Image.asset(
      icon,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      // En release, le décodage de l'image peut prendre une frame même après
      // precacheImage (taille différente, éviction cache). frameBuilder garantit
      // que l'image n'est affichée qu'une fois prête — pas de flash gris visible.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        // Image pas encore décodée : on affiche un placeholder invisible mais de
        // même taille, pour éviter tout artefact gris pendant le flip.
        return const SizedBox.expand();
      },
    );

    if (flipHorizontal) {
      image = Transform.scale(scaleX: -1, child: image);
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: ColoredBox(
        color: color,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: image,
          ),
        ),
      ),
    );
  }
}

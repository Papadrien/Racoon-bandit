import 'package:flutter/material.dart';

/// Stickers décoratifs positionnés sur les bords et coins du game screen.
class GameBackgroundStickers extends StatelessWidget {
  const GameBackgroundStickers({super.key});

  static const _pine  = 'assets/images/sticker_pine_tree.png';
  static const _cone  = 'assets/images/sticker_pine_cone.png';
  static const _cabin = 'assets/images/sticker_cabin.png';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        _GameSticker(
          asset: _pine,
          size: w * 0.18,
          left: -w * 0.04,
          top: h * 0.06,
          angle: -0.10,
          opacity: 0.55,
        ),
        _GameSticker(
          asset: _cabin,
          size: w * 0.14,
          right: -w * 0.02,
          top: h * 0.08,
          angle: 0.07,
          opacity: 0.45,
        ),
        _GameSticker(
          asset: _cone,
          size: w * 0.08,
          left: w * 0.02,
          top: h * 0.52,
          angle: -0.15,
          opacity: 0.40,
        ),
        _GameSticker(
          asset: _pine,
          size: w * 0.17,
          right: -w * 0.05,
          top: h * 0.42,
          angle: 0.06,
          opacity: 0.40,
        ),
        _GameSticker(
          asset: _pine,
          size: w * 0.16,
          left: -w * 0.03,
          top: h * 0.76,
          angle: -0.05,
          opacity: 0.50,
        ),
        _GameSticker(
          asset: _cone,
          size: w * 0.09,
          right: w * 0.03,
          top: h * 0.80,
          angle: 0.20,
          opacity: 0.40,
        ),
      ],
    );
  }
}

class _GameSticker extends StatelessWidget {
  final String asset;
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double angle;
  final double opacity;

  const _GameSticker({
    required this.asset,
    required this.size,
    this.left,
    this.right,
    this.top,
    this.angle = 0.0,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          opacity: AlwaysStoppedAnimation(opacity),
        ),
      ),
    );
  }
}

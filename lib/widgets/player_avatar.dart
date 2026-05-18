import 'package:flutter/material.dart';

/// Widget avatar joueur réutilisable : cercle coloré + emoji centré.
///
/// Utilisé dans : lobby, gameplay, classement, popups.
class PlayerAvatar extends StatelessWidget {
  final String emoji;
  final Color color;

  /// Diamètre du cercle.
  final double size;

  const PlayerAvatar({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: size * 0.04),
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.48),
          ),
        ),
      ),
    );
  }
}

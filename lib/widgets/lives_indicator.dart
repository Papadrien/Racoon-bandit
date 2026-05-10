import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class LivesIndicator extends StatelessWidget {
  final int lives;
  const LivesIndicator({super.key, required this.lives});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lives, (i) {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.favorite,
            size: 18,
            color: AppTheme.accent.withOpacity(0.85),
          ),
        );
      }),
    );
  }
}

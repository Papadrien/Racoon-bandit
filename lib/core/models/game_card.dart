import 'package:flutter/material.dart';

import 'card_type.dart';

class GameCard {
  final int id;
  final CardType type;
  final String name;
  final String description;
  final String? assetPath;

  const GameCard({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    this.assetPath,
  });

  String get emoji => switch (type) {
        CardType.food => '🍎',
        CardType.trash => '🗑️',
        CardType.raccoon => '🦝',
        CardType.bandit => '🥷',
      CardType.banquet => '🍽️',
      CardType.babyRaccoon => '🦝',
      CardType.vacuum => '🧹',
      };

  Color get color => switch (type) {
        CardType.food => const Color(0xFF4CAF50),
        CardType.trash => const Color(0xFF757575),
        CardType.raccoon => const Color(0xFFFF9800),
        CardType.bandit => const Color(0xFF7C4DFF),
      CardType.banquet => const Color(0xFFE91E63),
      CardType.babyRaccoon => const Color(0xFFFFB74D),
      CardType.vacuum => const Color(0xFF29B6F6),
      };
}

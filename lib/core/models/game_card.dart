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

  String get emoji {
    switch (type) {
      case CardType.food:
        return '🍎';
      case CardType.trash:
        return '🗑️';
      case CardType.raccoon:
        return '🦝';
      case CardType.bandit:
        return '🥷';
    }
  }

  Color get color {
    switch (type) {
      case CardType.food:
        return const Color(0xFF4CAF50);
      case CardType.trash:
        return const Color(0xFF757575);
      case CardType.raccoon:
        return const Color(0xFFFF9800);
      case CardType.bandit:
        return const Color(0xFF7C4DFF);
    }
  }
}

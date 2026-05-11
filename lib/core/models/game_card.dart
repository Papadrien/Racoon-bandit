import 'card_type.dart';

class GameCard {
  final int id;
  final CardType type;

  const GameCard({required this.id, required this.type});

  String get label {
    switch (type) {
      case CardType.food:
        return '🍎 Nourriture';
      case CardType.trash:
        return '🗑️ Poubelle';
      case CardType.raccoon:
        return '🦝 Raton';
      case CardType.bandit:
        return '🥷 Bandit';
    }
  }
}

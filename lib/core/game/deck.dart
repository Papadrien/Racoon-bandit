import 'dart:math';

import '../models/card_type.dart';
import '../models/game_card.dart';

const int totalCards = 45;

const Map<CardType, int> deckComposition = {
  CardType.food: 30,
  CardType.raccoon: 6,
  CardType.trash: 3,
  CardType.bandit: 6,
};

List<GameCard> buildShuffledDeck() {
  final deck = <GameCard>[];
  int id = 0;

  for (final entry in deckComposition.entries) {
    for (int i = 0; i < entry.value; i++) {
      deck.add(
        GameCard(
          id: id++,
          type: entry.key,
          name: _cardName(entry.key),
          description: _cardDescription(entry.key),
        ),
      );
    }
  }

  deck.shuffle(Random());
  return deck;
}

String _cardName(CardType type) {
  switch (type) {
    case CardType.food:
      return 'Nourriture';
    case CardType.raccoon:
      return 'Raton';
    case CardType.trash:
      return 'Poubelle';
    case CardType.bandit:
      return 'Bandit';
  }
}

String _cardDescription(CardType type) {
  switch (type) {
    case CardType.food:
      return '+1 nourriture';
    case CardType.raccoon:
      return 'Mange toute la nourriture';
    case CardType.trash:
      return 'Protège votre nourriture';
    case CardType.bandit:
      return 'Vole un autre joueur';
  }
}

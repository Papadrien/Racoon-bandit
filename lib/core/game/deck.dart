import 'dart:math';

import '../models/card_type.dart';
import '../models/game_card.dart';

const int totalCards = 35;

const Map<CardType, int> deckComposition = {
  CardType.food: 20,
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

String _cardName(CardType type) => switch (type) {
      CardType.food => 'Nourriture',
      CardType.raccoon => 'Raton',
      CardType.trash => 'Poubelle',
      CardType.bandit => 'Bandit',
    };

String _cardDescription(CardType type) => switch (type) {
      CardType.food => '+1 nourriture',
      CardType.raccoon => 'Mange toute la nourriture',
      CardType.trash => 'Protège votre nourriture',
      CardType.bandit => 'Vole un autre joueur',
    };

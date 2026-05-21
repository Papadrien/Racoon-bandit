import 'dart:math';

import '../models/card_type.dart';
import '../models/game_card.dart';

const int totalCards = 35;

const Map<CardType, int> deckComposition = {
  CardType.food: 20,
  CardType.raccoon: 6,
  CardType.trash: 3,
  CardType.pince: 6,
};

const Map<CardType, int> chaosDeckComposition = {
  CardType.food: 17,
  CardType.raccoon: 6,
  CardType.trash: 3,
  CardType.pince: 6,
  CardType.banquet: 1,
  CardType.babyRaccoon: 1,
  CardType.vacuum: 1,
};

List<GameCard> buildShuffledDeck({bool chaosMode = false}) {
  final composition = chaosMode ? chaosDeckComposition : deckComposition;

  final deck = <GameCard>[];
  int id = 0;

  for (final entry in composition.entries) {
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
      CardType.trash => 'Poubelle sécurisée',
      CardType.pince => 'Pince',
      CardType.banquet => 'Banquet',
      CardType.babyRaccoon => 'Bébé Raton',
      CardType.vacuum => 'Aspirateur',
    };

String _cardDescription(CardType type) => switch (type) {
      CardType.food => '+1 nourriture',
      CardType.raccoon => 'Mange toute la nourriture',
      CardType.trash => 'Protège votre nourriture',
      CardType.pince => 'Vole un autre joueur',
      CardType.banquet => '+2 nourritures',
      CardType.babyRaccoon => 'Retire 2 nourritures à un joueur',
      CardType.vacuum => 'Vole 1 nourriture à chaque joueur',
    };

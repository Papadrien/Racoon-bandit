import 'dart:math';

import '../models/card_type.dart';
import '../models/game_card.dart';

/// Composition du deck : 8 nourritures, 4 poubelles, 4 ratons, 4 bandits = 20 cartes
List<GameCard> buildShuffledDeck() {
  final counts = {
    CardType.food: 8,
    CardType.trash: 4,
    CardType.raccoon: 4,
    CardType.bandit: 4,
  };

  final deck = <GameCard>[];
  int id = 0;
  for (final entry in counts.entries) {
    for (int i = 0; i < entry.value; i++) {
      deck.add(GameCard(id: id++, type: entry.key));
    }
  }
  deck.shuffle(Random());
  return deck;
}

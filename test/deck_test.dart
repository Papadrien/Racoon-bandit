import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon_bandit/core/game/deck.dart';
import 'package:raccoon_bandit/core/models/card_type.dart';
import 'package:raccoon_bandit/core/models/game_card.dart';

void main() {
  group('buildShuffledDeck', () {
    test('crée un deck de 35 cartes en mode normal', () {
      final deck = buildShuffledDeck();

      expect(deck, hasLength(totalCards));
      expect(deck.length, 35);
    });

    test('respecte la composition du deck normal', () {
      final deck = buildShuffledDeck();

      _expectCount(deck, CardType.food, 20);
      _expectCount(deck, CardType.raccoon, 6);
      _expectCount(deck, CardType.trash, 3);
      _expectCount(deck, CardType.pince, 6);
    });

    test('crée un deck de 35 cartes en mode chaos', () {
      final deck = buildShuffledDeck(chaosMode: true);

      expect(deck, hasLength(totalCards));
    });

    test('respecte la composition du deck chaos', () {
      final deck = buildShuffledDeck(chaosMode: true);

      _expectCount(deck, CardType.food, 17);
      _expectCount(deck, CardType.raccoon, 6);
      _expectCount(deck, CardType.trash, 3);
      _expectCount(deck, CardType.pince, 6);
      _expectCount(deck, CardType.banquet, 1);
      _expectCount(deck, CardType.babyRaccoon, 1);
      _expectCount(deck, CardType.vacuum, 1);
    });

    test('donne un identifiant unique à chaque carte', () {
      final deck = buildShuffledDeck();

      final ids = deck.map((card) => card.id).toSet();
      expect(ids, hasLength(deck.length));
    });
  });
}

void _expectCount(
  List<GameCard> deck,
  CardType type,
  int expected,
) {
  final count = deck.where((card) => card.type == type).length;
  expect(count, expected, reason: 'Nombre de cartes $type');
}

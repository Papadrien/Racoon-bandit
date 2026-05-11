import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/player_state.dart';
import 'deck.dart';

class GameState {
  final List<PlayerState> players;
  int currentPlayerIndex;
  List<GameCard> remainingDeck;
  GameCard? revealedCard;
  bool isGameOver;

  GameState({required this.players})
      : currentPlayerIndex = 0,
        remainingDeck = buildShuffledDeck(),
        revealedCard = null,
        isGameOver = false;

  PlayerState get currentPlayer => players[currentPlayerIndex];

  int get remainingCards => remainingDeck.length;

  /// Pioche une carte, applique son effet, passe au joueur suivant.
  void drawCard() {
    if (remainingDeck.isEmpty) {
      isGameOver = true;
      return;
    }

    revealedCard = remainingDeck.removeLast();
    _applyEffect(revealedCard!);

    if (remainingDeck.isEmpty) {
      isGameOver = true;
    } else {
      _advance();
    }
  }

  void _applyEffect(GameCard card) {
    final player = players[currentPlayerIndex];
    switch (card.type) {
      case CardType.food:
        player.foodCount++;

      case CardType.trash:
        player.hasTrash = true;

      case CardType.raccoon:
        // La poubelle protège : elle absorbe le raton et est détruite.
        if (player.hasTrash) {
          player.hasTrash = false;
        } else {
          player.foodCount = 0;
        }

      case CardType.bandit:
        // TODO: implémenter l'effet bandit
        break;
    }
  }

  void _advance() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  List<PlayerState> get ranking {
    final sorted = List<PlayerState>.from(players);
    sorted.sort((a, b) => b.foodCount.compareTo(a.foodCount));
    return sorted;
  }
}

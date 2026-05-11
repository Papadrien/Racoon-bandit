import 'dart:math';

import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/player_state.dart';
import 'deck.dart';

class CardResolution {
  final String message;
  final int? targetPlayerId;
  final bool trashDestroyed;
  final bool foodStolen;

  const CardResolution({
    required this.message,
    this.targetPlayerId,
    this.trashDestroyed = false,
    this.foodStolen = false,
  });
}

class GameState {
  final List<PlayerState> players;
  int currentPlayerIndex;
  List<GameCard> remainingDeck;
  GameCard? revealedCard;
  bool isGameOver;
  final Random _random = Random();

  GameState({required this.players})
      : currentPlayerIndex = 0,
        remainingDeck = buildShuffledDeck(),
        revealedCard = null,
        isGameOver = false;

  PlayerState get currentPlayer => players[currentPlayerIndex];

  int get remainingCards => remainingDeck.length;

  CardResolution drawCard() {
    if (remainingDeck.isEmpty) {
      isGameOver = true;
      return const CardResolution(message: 'Fin de partie');
    }

    revealedCard = remainingDeck.removeLast();
    final result = _applyEffect(revealedCard!);

    if (remainingDeck.isEmpty) {
      isGameOver = true;
    } else {
      _advance();
    }

    return result;
  }

  CardResolution _applyEffect(GameCard card) {
    final player = players[currentPlayerIndex];

    switch (card.type) {
      case CardType.food:
        player.foodCount++;
        return CardResolution(message: '${player.name} gagne 1 nourriture');

      case CardType.trash:
        player.hasTrash = true;
        return CardResolution(message: '${player.name} pose une poubelle');

      case CardType.raccoon:
        if (player.hasTrash) {
          player.hasTrash = false;
          return CardResolution(
            message: 'Le raton détruit la poubelle',
            targetPlayerId: player.id,
            trashDestroyed: true,
          );
        }

        player.foodCount = 0;
        return CardResolution(
          message: 'Le raton mange toute la nourriture',
          targetPlayerId: player.id,
          foodStolen: true,
        );

      case CardType.bandit:
        final validTargets = players
            .where((p) => p.id != player.id && p.foodCount > 0)
            .toList();

        if (validTargets.isEmpty) {
          return const CardResolution(message: 'Aucune cible valide');
        }

        final target = validTargets[_random.nextInt(validTargets.length)];

        if (target.hasTrash) {
          target.hasTrash = false;
          return CardResolution(
            message: 'Bandit détruit la poubelle de ${target.name}',
            targetPlayerId: target.id,
            trashDestroyed: true,
          );
        }

        player.foodCount += target.foodCount;
        target.foodCount = 0;

        return CardResolution(
          message: 'Bandit vole toute la nourriture de ${target.name}',
          targetPlayerId: target.id,
          foodStolen: true,
        );
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

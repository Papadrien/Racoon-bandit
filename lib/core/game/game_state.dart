import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_session_stats.dart';
import '../models/player_state.dart';
import '../models/saved_game.dart';
import 'deck.dart';

class CardResolution {
  final String message;
  final int? targetPlayerId;
  final bool trashDestroyed;
  final bool foodStolen;

  /// Bandit uniquement : vrai si l'UI doit présenter le choix de cible.
  /// Dans ce cas, l'effet n'est pas encore appliqué en logique.
  final bool needsTargetSelection;

  const CardResolution({
    required this.message,
    this.targetPlayerId,
    this.trashDestroyed = false,
    this.foodStolen = false,
    this.needsTargetSelection = false,
  });
}

class GameState {
  final List<PlayerState> players;
  int currentPlayerIndex;
  List<GameCard> remainingDeck;
  GameCard? revealedCard;
  bool isGameOver;
  bool _gameOverHandled = false;
  final GameSessionStats sessionStats = GameSessionStats();

  /// Index du joueur actif au moment où la carte a été tirée.
  /// Conservé pour que la résolution différée (Bandit) utilise
  /// le bon joueur même si currentPlayerIndex a avancé.
  int? _resolvedPlayerIndex;

  // ── Constructeurs ─────────────────────────────────────────────────────────

  GameState({required this.players})
      : currentPlayerIndex = 0,
        remainingDeck = buildShuffledDeck(),
        revealedCard = null,
        isGameOver = false;

  /// Constructeur de restauration depuis une [SavedGame].
  GameState.fromSave(SavedGame save)
      : currentPlayerIndex = save.currentPlayerIndex,
        revealedCard = null,
        isGameOver = false,
        players = save.players
            .map(
              (s) => PlayerState(
                id: s.id,
                name: s.name,
                profileId: s.profileId,
                emoji: s.emoji,
                colorValue: s.colorValue,
                foodCount: s.foodCount,
                trashCount: s.trashCount,
              ),
            )
            .toList(),
        remainingDeck = _rebuildDeck(save.remainingDeckTypes);

  static List<GameCard> _rebuildDeck(List<String> typeNames) {
    int id = 0;
    return typeNames.map((name) {
      final type = CardType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => CardType.food,
      );
      return GameCard(
        id: id++,
        type: type,
        name: _cardName(type),
        description: _cardDescription(type),
      );
    }).toList();
  }

  static String _cardName(CardType type) => switch (type) {
        CardType.food => 'Nourriture',
        CardType.raccoon => 'Raton',
        CardType.trash => 'Poubelle',
        CardType.bandit => 'Bandit',
      };

  static String _cardDescription(CardType type) => switch (type) {
        CardType.food => '+1 nourriture',
        CardType.raccoon => 'Mange toute la nourriture',
        CardType.trash => 'Protège votre nourriture',
        CardType.bandit => 'Vole un autre joueur',
      };

  // ── Sérialisation ─────────────────────────────────────────────────────────

  SavedGame toSave() => SavedGame(
        version: SavedGame.schemaVersion,
        savedAt: DateTime.now(),
        players: players
            .map(
              (p) => SavedPlayerState(
                id: p.id,
                name: p.name,
                profileId: p.profileId,
                emoji: p.emoji,
                colorValue: p.colorValue,
                foodCount: p.foodCount,
                trashCount: p.trashCount,
              ),
            )
            .toList(),
        currentPlayerIndex: currentPlayerIndex,
        remainingDeckTypes: remainingDeck.map((c) => c.type.name).toList(),
      );

  // ── Accesseurs ────────────────────────────────────────────────────────────

  PlayerState get currentPlayer => players[currentPlayerIndex];

  int get remainingCards => remainingDeck.length;

  // ─── Détection cibles Bandit ──────────────────────────────────────────────

  List<PlayerState> banditValidTargets() {
    final active = players[currentPlayerIndex];
    return players
        .where((p) => p.id != active.id && p.foodCount > 0)
        .toList();
  }

  // ─── Tirage de carte ──────────────────────────────────────────────────────

  CardResolution drawCard() {
    if (remainingDeck.isEmpty) {
      _markGameOver();
      return const CardResolution(message: 'Fin de partie');
    }

    _resolvedPlayerIndex = currentPlayerIndex;
    revealedCard = remainingDeck.removeLast();
    final result = _applyEffect(revealedCard!);

    if (!result.needsTargetSelection) {
      if (remainingDeck.isEmpty) {
        isGameOver = true;
      } else {
        _advance();
      }
    }

    return result;
  }

  // ─── Résolution différée Bandit ───────────────────────────────────────────

  CardResolution resolveBandit(PlayerState target) {
    final playerIdx = _resolvedPlayerIndex ?? currentPlayerIndex;
    final player = players[playerIdx];

    player.foodCount++;
    target.foodCount--;
    sessionStats.foodStolen++;

    if (remainingDeck.isEmpty) {
      _markGameOver();
    } else {
      _advance();
    }

    return CardResolution(
      message: '${player.name} vole 1 nourriture à ${target.name}',
      targetPlayerId: target.id,
      foodStolen: true,
    );
  }

  // ─── Application effets ───────────────────────────────────────────────────

  CardResolution _applyEffect(GameCard card) {
    sessionStats.cardsPlayed++;
    final player = players[currentPlayerIndex];

    switch (card.type) {
      case CardType.food:
        player.foodCount++;
        sessionStats.foodGained++;
        return CardResolution(message: '${player.name} gagne 1 nourriture');

      case CardType.trash:
        player.trashCount++;
        return CardResolution(message: '${player.name} pose une frigo');

      case CardType.raccoon:
        if (player.trashCount > 0) {
          player.trashCount--;
          return CardResolution(
            message: 'Le Raccoon est bloqué par une frigo !',
            targetPlayerId: player.id,
            trashDestroyed: true,
          );
        }

        sessionStats.raccoonCardsPlayed++;
        sessionStats.foodStolen += player.foodCount;
        player.foodCount = 0;
        return CardResolution(
          message: 'Le raton mange toute la nourriture de ${player.name}',
          targetPlayerId: player.id,
          foodStolen: true,
        );

      case CardType.bandit:
        sessionStats.banditCardsPlayed++;
        final validTargets = banditValidTargets();

        if (validTargets.isEmpty) {
          return const CardResolution(
            message: 'Personne à voler…',
          );
        }

        if (validTargets.length == 1) {
          final target = validTargets.first;
          player.foodCount++;
          target.foodCount--;
          sessionStats.foodStolen++;
          return CardResolution(
            message: '${player.name} vole 1 nourriture à ${target.name}',
            targetPlayerId: target.id,
            foodStolen: true,
          );
        }

        return const CardResolution(
          message: '',
          needsTargetSelection: true,
        );
    }
  }

  void _advance() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  void _markGameOver() {
    if (_gameOverHandled) return;
    _gameOverHandled = true;
    isGameOver = true;
  }

  List<PlayerState> get ranking {
    final sorted = List<PlayerState>.from(players);
    sorted.sort((a, b) => b.foodCount.compareTo(a.foodCount));
    return sorted;
  }
}

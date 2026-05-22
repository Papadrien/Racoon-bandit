import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_session_stats.dart';
import '../models/player_state.dart';
import 'deck.dart';

class CardResolution {
  final String message;
  final int? targetPlayerId;
  final bool trashDestroyed;
  final bool foodStolen;

  /// Bandit uniquement : vrai si l'UI doit présenter le choix de cible.
  /// Dans ce cas, l'effet n'est pas encore appliqué en logique.
  final bool needsTargetSelection;
  final CardType? pendingTargetCardType;

  const CardResolution({
    required this.message,
    this.targetPlayerId,
    this.trashDestroyed = false,
    this.foodStolen = false,
    this.needsTargetSelection = false,
    this.pendingTargetCardType,
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
  final bool chaosMode;

  /// Index du joueur actif au moment où la carte a été tirée.
  /// Conservé pour que la résolution différée (Bandit) utilise
  /// le bon joueur même si currentPlayerIndex a avancé.
  int? _resolvedPlayerIndex;

  // ── Constructeurs ─────────────────────────────────────────────────────────

  GameState({required this.players, this.chaosMode = false})
      : currentPlayerIndex = 0,
        remainingDeck = buildShuffledDeck(chaosMode: chaosMode),
        revealedCard = null,
        isGameOver = false;

  // ── Accesseurs ────────────────────────────────────────────────────────────

  PlayerState get currentPlayer => players[currentPlayerIndex];

  int get remainingCards => remainingDeck.length;

  // ─── Détection cibles Bandit ──────────────────────────────────────────────

  List<PlayerState> pinceValidTargets() {
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



  void _gainFood(PlayerState player, int amount) {
    if (amount <= 0) return;
    player.foodCount += amount;
    sessionStats.foodGained += amount;
  }

  int _removeFood(PlayerState player, int amount) {
    final removed = amount > player.foodCount ? player.foodCount : amount;
    player.foodCount -= removed;
    return removed;
  }

  CardResolution resolveTargetedSpecial(
    CardType type,
    PlayerState target,
  ) {
    switch (type) {
      case CardType.babyRaccoon:
        final stolen = _removeFood(target, 2);

        if (remainingDeck.isEmpty) {
          _markGameOver();
        } else {
          _advance();
        }

        return CardResolution(
          message: stolen > 0
              ? '${target.name} perd $stolen nourriture${stolen > 1 ? 's' : ''}'
              : 'Aucune nourriture à voler',
          targetPlayerId: target.id,
          foodStolen: stolen > 0,
        );

      default:
        return resolvePince(target);
    }
  }

  CardResolution resolvePince(PlayerState target) {
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
        _gainFood(player, 1);
        return CardResolution(message: '${player.name} gagne 1 nourriture');

      case CardType.trash:
        player.trashCount++;
        return CardResolution(message: '${player.name} pose une poubelle sécurisée');

      case CardType.raccoon:
        if (player.trashCount > 0) {
          player.trashCount--;
          return CardResolution(
            message: 'Le Raccoon est bloqué par une poubelle sécurisée !',
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

      case CardType.banquet:
        _gainFood(player, 2);
        return CardResolution(
          message: '${player.name} gagne 2 nourritures',
        );

      case CardType.babyRaccoon:
        // En mode pagaille : le joueur actif perd 2 nourritures
        if (chaosMode) {
          final removed = _removeFood(player, 2);
          if (remainingDeck.isEmpty) {
            _markGameOver();
          } else {
            _advance();
          }
          return CardResolution(
            message: removed > 0
                ? '${player.name} perd $removed nourriture${removed > 1 ? 's' : ''}'
                : 'Aucune nourriture à retirer',
            targetPlayerId: player.id,
            foodStolen: removed > 0,
          );
        }

        final validTargets = pinceValidTargets();

        if (validTargets.isEmpty) {
          return const CardResolution(
            message: 'Aucune nourriture à retirer',
          );
        }

        if (validTargets.length == 1) {
          final target = validTargets.first;
          final removed = _removeFood(target, 2);

          return CardResolution(
            message:
                '${target.name} perd $removed nourriture${removed > 1 ? 's' : ''}',
            targetPlayerId: target.id,
            foodStolen: removed > 0,
          );
        }

        return const CardResolution(
          message: '',
          needsTargetSelection: true,
          pendingTargetCardType: CardType.babyRaccoon,
        );

      case CardType.vacuum:
        int stolenTotal = 0;

        for (final target in players.where((p) => p.id != player.id)) {
          final stolen = _removeFood(target, 1);
          stolenTotal += stolen;
        }

        _gainFood(player, stolenTotal);

        return CardResolution(
          message: stolenTotal > 0
              ? '${player.name} vole $stolenTotal nourriture${stolenTotal > 1 ? 's' : ''}'
              : 'Aucune nourriture à aspirer',
          foodStolen: stolenTotal > 0,
        );

      case CardType.pince:
        sessionStats.pinceCardsPlayed++;
        final validTargets = pinceValidTargets();

        if (validTargets.isEmpty) {
          return const CardResolution(
            message: 'Personne à voler…',
          );
        }

        if (validTargets.length == 1) {
          final target = validTargets.first;
          _gainFood(player, 1);
          _removeFood(target, 1);
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
          pendingTargetCardType: CardType.pince,
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

import '../models/card_type.dart';
import '../models/game_card.dart';
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


  /// Index du joueur actif au moment où la carte a été tirée.
  /// Conservé pour que la résolution différée (Bandit) utilise
  /// le bon joueur même si currentPlayerIndex a avancé.
  int? _resolvedPlayerIndex;

  GameState({required this.players})
      : currentPlayerIndex = 0,
        remainingDeck = buildShuffledDeck(),
        revealedCard = null,
        isGameOver = false;

  PlayerState get currentPlayer => players[currentPlayerIndex];

  int get remainingCards => remainingDeck.length;

  // ─── Détection cibles Bandit ──────────────────────────────────────────────

  /// Retourne les joueurs valides pour le vol Bandit :
  /// tous sauf le joueur actif, ayant au moins 1 nourriture.
  List<PlayerState> banditValidTargets() {
    final active = players[currentPlayerIndex];
    return players
        .where((p) => p.id != active.id && p.foodCount > 0)
        .toList();
  }

  // ─── Tirage de carte ──────────────────────────────────────────────────────

  /// Tire une carte et applique son effet.
  ///
  /// Pour le Bandit avec plusieurs cibles, retourne un [CardResolution]
  /// avec [needsTargetSelection] == true : la logique de vol n'est pas
  /// encore appliquée. Appeler [resolveBandit] une fois la cible connue.
  CardResolution drawCard() {
    if (remainingDeck.isEmpty) {
      isGameOver = true;
      return const CardResolution(message: 'Fin de partie');
    }

    _resolvedPlayerIndex = currentPlayerIndex;
    revealedCard = remainingDeck.removeLast();
    final result = _applyEffect(revealedCard!);

    // On n'avance PAS si le Bandit nécessite une sélection de cible :
    // _advance() sera appelé dans resolveBandit().
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

  /// Applique l'effet Bandit sur la cible choisie par l'UI.
  /// À appeler uniquement après [drawCard] lorsque
  /// [CardResolution.needsTargetSelection] est true.
  CardResolution resolveBandit(PlayerState target) {
    final playerIdx = _resolvedPlayerIndex ?? currentPlayerIndex;
    final player = players[playerIdx];

    player.foodCount++;
    target.foodCount--;

    if (remainingDeck.isEmpty) {
      isGameOver = true;
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
    final player = players[currentPlayerIndex];

    switch (card.type) {
      case CardType.food:
        player.foodCount++;
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

        player.foodCount = 0;
        return CardResolution(
          message: 'Le raton mange toute la nourriture de ${player.name}',
          targetPlayerId: player.id,
          foodStolen: true,
        );

      case CardType.bandit:
        final validTargets = banditValidTargets();

        if (validTargets.isEmpty) {
          return const CardResolution(
            message: 'Personne à voler…',
          );
        }

        // Cible unique → sélection automatique, résolution immédiate
        if (validTargets.length == 1) {
          final target = validTargets.first;
          player.foodCount++;
          target.foodCount--;
          return CardResolution(
            message: '${player.name} vole 1 nourriture à ${target.name}',
            targetPlayerId: target.id,
            foodStolen: true,
          );
        }

        // Plusieurs cibles → UI doit choisir
        return const CardResolution(
          message: '',
          needsTargetSelection: true,
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

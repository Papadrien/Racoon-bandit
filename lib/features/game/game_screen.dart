import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/card_type.dart';
import '../../core/models/game_card.dart';
import '../../core/models/player_state.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _gameState = ModalRoute.of(context)!.settings.arguments as GameState;
      _initialized = true;
    }
  }

  void _drawCard() {
    setState(() => _gameState.drawCard());

    if (_gameState.isGameOver) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: _gameState,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    final player = _gameState.currentPlayer;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _PlayerBar(gameState: _gameState),
            const SizedBox(height: 8),
            Text(
              '${_gameState.remainingCards} cartes restantes',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(player.avatarIcon, color: player.avatarColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${player.name} pioche…',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: player.avatarColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: _CardSlot(card: _gameState.revealedCard),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _drawCard,
                  icon: const Icon(Icons.style, size: 24),
                  label: const Text(
                    'PIOCHER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSlot extends StatelessWidget {
  const _CardSlot({required this.card});
  final GameCard? card;

  @override
  Widget build(BuildContext context) {
    if (card == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'Appuie sur PIOCHER',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    final (color, description) = _cardInfo(card!.type);

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card!.label, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _cardInfo(CardType type) {
    switch (type) {
      case CardType.food:
        return (Colors.greenAccent, '+1 nourriture');
      case CardType.trash:
        return (Colors.blueAccent, 'Protection activée !\n(protège du prochain raton)');
      case CardType.raccoon:
        return (Colors.orangeAccent, 'Toute ta nourriture est volée !\n(ou poubelle détruite)');
      case CardType.bandit:
        return (Colors.redAccent, 'TODO – Bandit');
    }
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({required this.gameState});
  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: gameState.players.map((p) => _PlayerChip(
          player: p,
          isCurrent: p.id == gameState.currentPlayer.id,
        )).toList(),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.player, required this.isCurrent});
  final PlayerState player;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          player.name,
          style: TextStyle(
            fontSize: 11,
            color: isCurrent ? player.avatarColor : AppTheme.textMuted,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🍎${player.foodCount}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrent ? player.avatarColor : Colors.white,
              ),
            ),
            if (player.hasTrash) const Text(' 🗑️', style: TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

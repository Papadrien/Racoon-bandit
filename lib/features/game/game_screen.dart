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
    setState(() {
      _gameState.drawCard();
    });

    if (_gameState.isGameOver) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: _gameState,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Raccoon Bandit'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _CurrentPlayerBanner(player: _gameState.currentPlayer),
              const SizedBox(height: 16),
              Text(
                '${_gameState.remainingCards} cartes restantes',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ..._gameState.players.map(
                      (player) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PlayerZone(
                          player: player,
                          isActive:
                              player.id == _gameState.currentPlayer.id,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CenterBoard(card: _gameState.revealedCard),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: _gameState.isGameOver ? null : _drawCard,
                        child: Container(
                          width: 120,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                offset: Offset(0, 4),
                                color: Colors.black38,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.style_rounded,
                                size: 42,
                                color: Colors.white,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'PIOCHE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlayerBanner extends StatelessWidget {
  const _CurrentPlayerBanner({required this.player});

  final PlayerState player;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: player.avatarColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: player.avatarColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(player.avatarIcon, color: player.avatarColor),
          const SizedBox(width: 10),
          Text(
            'Tour de ${player.name}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: player.avatarColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterBoard extends StatelessWidget {
  const _CenterBoard({required this.card});

  final GameCard? card;

  @override
  Widget build(BuildContext context) {
    final data = _cardData(card?.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Text(
            'Carte révélée',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 140,
            height: 180,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: data.color, width: 2),
            ),
            child: card == null
                ? const Center(
                    child: Text(
                      'Pioche une carte',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(card!.label, style: const TextStyle(fontSize: 54)),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          data.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: data.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  ({Color color, String label}) _cardData(CardType? type) {
    switch (type) {
      case CardType.food:
        return (color: Colors.greenAccent, label: '+1 nourriture');
      case CardType.trash:
        return (color: Colors.lightBlueAccent, label: 'Poubelle active');
      case CardType.raccoon:
        return (color: Colors.orangeAccent, label: 'Le raton attaque');
      case CardType.bandit:
        return (color: Colors.redAccent, label: 'Bandit');
      case null:
        return (color: Colors.white24, label: '');
    }
  }
}

class _PlayerZone extends StatelessWidget {
  const _PlayerZone({required this.player, required this.isActive});

  final PlayerState player;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? player.avatarColor.withOpacity(0.16)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? player.avatarColor : Colors.white12,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: const Center(
                    child: Text(
                      '🍎',
                      style: TextStyle(fontSize: 34),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          player.avatarIcon,
                          color: player.avatarColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.white
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nourriture : ${player.foodCount}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: player.hasTrash
                  ? Colors.blue.withOpacity(0.15)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: player.hasTrash
                    ? Colors.lightBlueAccent
                    : Colors.white24,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🗑️', style: TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                Text(
                  player.hasTrash ? 'ACTIVE' : 'VIDE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: player.hasTrash
                        ? Colors.lightBlueAccent
                        : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

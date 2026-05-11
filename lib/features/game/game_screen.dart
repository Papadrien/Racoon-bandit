import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game/game_state.dart';
import '../../core/models/card_type.dart';
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
  bool _isAnimating = false;
  String _effectText = '';
  Offset _trashOffset = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _gameState = ModalRoute.of(context)!.settings.arguments as GameState;
      _initialized = true;
    }
  }

  Future<void> _drawCard() async {
    if (_isAnimating || _gameState.isGameOver) return;

    setState(() {
      _isAnimating = true;
      _effectText = '';
    });

    HapticFeedback.lightImpact();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final result = _gameState.drawCard();

    setState(() {
      _effectText = result.message;
      _trashOffset = result.trashDestroyed
          ? const Offset(120, 120)
          : result.foodStolen
              ? const Offset(-120, -60)
              : Offset.zero;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1400));

    setState(() {
      _trashOffset = Offset.zero;
      _isAnimating = false;
    });

    if (_gameState.isGameOver && mounted) {
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    ),
                    child: const Text('Accueil'),
                  ),
                  Text(
                    '${_gameState.remainingCards} cartes',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tour de ${_gameState.currentPlayer.name}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _gameState.players.length,
                  itemBuilder: (context, index) {
                    final player = _gameState.players[index];
                    final active = index == _gameState.currentPlayerIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primary.withOpacity(0.22)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppTheme.primary : Colors.white12,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(
                                    player.foodCount,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      margin: const EdgeInsets.only(right: 4),
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text('🍎 ${player.foodCount}'),
                              const SizedBox(height: 12),
                              AnimatedSlide(
                                duration: const Duration(milliseconds: 500),
                                offset: player.hasTrash
                                    ? Offset.zero
                                    : _trashOffset,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity: player.hasTrash ? 1 : 0.2,
                                  child: const Icon(
                                    Icons.delete,
                                    size: 34,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _effectText.isEmpty ? 0 : 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _effectText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              AnimatedScale(
                scale: _isAnimating ? 1 : 0.92,
                duration: const Duration(milliseconds: 350),
                child: Container(
                  width: 170,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 16),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _cardLabel(),
                          style: const TextStyle(fontSize: 44),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _gameState.revealedCard?.name ?? 'Pioche',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _gameState.revealedCard?.description ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _drawCard,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isAnimating
                        ? Colors.grey.shade700
                        : AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.style, size: 52),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Pioche'),
            ],
          ),
        ),
      ),
    );
  }

  String _cardLabel() {
    switch (_gameState.revealedCard?.type) {
      case CardType.food:
        return '🍎';
      case CardType.trash:
        return '🗑️';
      case CardType.raccoon:
        return '🦝';
      case CardType.bandit:
        return '🥷';
      default:
        return '?';
    }
  }
}

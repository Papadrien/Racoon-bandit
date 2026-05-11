import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
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
      _gameState =
          ModalRoute.of(context)!.settings.arguments as GameState;
      _initialized = true;
    }
  }

  void _answer(bool correct) {
    setState(() {
      if (correct) {
        _gameState.correctAnswer();
      } else {
        _gameState.wrongAnswer();
      }
    });

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
    final round = _gameState.currentRound;
    final totalRounds = _gameState.roundsPerPlayer;
    final turnInRound = _gameState.currentPlayerIndex + 1;
    final totalPlayers = _gameState.players.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ScoreBar(gameState: _gameState),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Round $round / $totalRounds  •  Tour $turnInRound / $totalPlayers',
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    player.avatarIcon,
                    color: player.avatarColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    player.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: player.avatarColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.4),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.style, size: 64, color: AppTheme.primary),
                        SizedBox(height: 16),
                        Text(
                          'CARTE',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'placeholder',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _AnswerButton(
                      label: 'MAUVAISE\nRÉPONSE',
                      icon: Icons.close,
                      color: Colors.redAccent,
                      onPressed: () => _answer(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AnswerButton(
                      label: 'BONNE\nRÉPONSE',
                      icon: Icons.check,
                      color: Colors.greenAccent,
                      onPressed: () => _answer(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.gameState});
  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: gameState.players.map((p) {
          final isCurrent = p.id == gameState.currentPlayer.id;
          return Column(
            children: [
              Text(
                p.name,
                style: TextStyle(
                  fontSize: 11,
                  color: isCurrent ? p.avatarColor : AppTheme.textMuted,
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                '${p.score}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? p.avatarColor : Colors.white,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 20),
        minimumSize: const Size(0, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

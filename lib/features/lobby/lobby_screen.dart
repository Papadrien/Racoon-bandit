import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/player_model.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _playerCount = 2;

  List<PlayerModel> _generatePlayers(int count) {
    return List.generate(
      count,
      (i) => PlayerModel(id: i + 1, name: 'Joueur ${i + 1}'),
    );
  }

  void _startGame() {
    final gameState = GameState(players: _generatePlayers(_playerCount));
    Navigator.pushNamed(context, AppRoutes.game, arguments: gameState);
  }

  @override
  Widget build(BuildContext context) {
    const playerColors = [
      AppTheme.primary,
      AppTheme.accent,
      Color(0xFF00BCD4),
      Color(0xFF4CAF50),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('LOBBY'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.people, size: 72, color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text(
                'Nombre de joueurs',
                style: TextStyle(fontSize: 18, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [2, 3, 4].map((count) {
                  final selected = count == _playerCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _playerCount = count),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : Colors.transparent,
                          border: Border.all(
                            color: selected ? AppTheme.primary : AppTheme.textMuted,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              ...List.generate(_playerCount, (i) {
                final color = playerColors[i % playerColors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Joueur ${i + 1}',
                        style: TextStyle(color: color, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
              const Spacer(),
              PrimaryButton(label: 'COMMENCER', onPressed: _startGame),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

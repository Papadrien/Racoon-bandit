import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/player_state.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = ModalRoute.of(context)!.settings.arguments as GameState;
    final ranking = gameState.ranking;
    final winner = ranking.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Résultats')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.accent, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 72,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${winner.name} gagne !',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score : ${winner.foodCount} nourritures',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Classement final',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: ranking.length,
                  itemBuilder: (context, index) {
                    return _RankingTile(
                      player: ranking[index],
                      rank: index + 1,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.lobby,
                      (route) => route.settings.name == AppRoutes.home,
                    );
                  },
                  child: const Text('REJOUER'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                  child: const Text('RETOUR ACCUEIL'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.player, required this.rank});

  final PlayerState player;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: player.avatarColor.withOpacity(0.18),
            child: Text(
              '$rank',
              style: TextStyle(
                color: player.avatarColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Icon(player.avatarIcon, color: player.avatarColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '🍎 ${player.foodCount}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

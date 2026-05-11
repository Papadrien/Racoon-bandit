import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/player_model.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState =
        ModalRoute.of(context)!.settings.arguments as GameState;
    final ranking = gameState.ranking;
    final winner = ranking.first;

    return Scaffold(
      appBar: AppBar(title: const Text('RÉSULTATS')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 64,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 12),
              Text(
                '${winner.name} gagne !',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${winner.score} point${winner.score > 1 ? 's' : ''}',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              ...ranking.asMap().entries.map(
                    (entry) => _RankRow(
                      rank: entry.key + 1,
                      player: entry.value,
                      isWinner: entry.key == 0,
                    ),
                  ),
              const Spacer(),
              PrimaryButton(
                label: 'REJOUER',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.lobby,
                  (r) => r.settings.name == AppRoutes.home,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (r) => false,
                ),
                child: const Text('Retour au menu'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.player,
    required this.isWinner,
  });

  final int rank;
  final PlayerModel player;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWinner ? AppTheme.accent : AppTheme.textMuted,
                fontSize: 16,
              ),
            ),
          ),
          Icon(
            isWinner ? Icons.emoji_events : player.avatarIcon,
            color: isWinner ? AppTheme.accent : player.avatarColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
          Text(
            '${player.score} pt${player.score > 1 ? 's' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWinner ? AppTheme.accent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

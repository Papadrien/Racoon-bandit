import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/player_state.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/primary_button.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = ModalRoute.of(context)!.settings.arguments as GameState;
    final ranking = gameState.ranking;
    final winner = ranking.first;

    return Scaffold(
      appBar: AppBar(title: const Text('RÉSULTATS')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, size: 64, color: AppTheme.accent),
              const SizedBox(height: 12),
              // Avatar + nom du gagnant
              PlayerAvatar(
                emoji: winner.emoji,
                color: winner.profileColor,
                size: 72,
              ),
              const SizedBox(height: 10),
              Text(
                '${winner.name} gagne !',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '🍎 ${winner.foodCount} nourriture${winner.foodCount > 1 ? 's' : ''}',
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
  const _RankRow({required this.rank, required this.player, required this.isWinner});

  final int rank;
  final PlayerState player;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final rankLabel = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Médaille / rang
          SizedBox(
            width: 36,
            child: Text(
              rankLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWinner ? AppTheme.accent : AppTheme.textMuted,
                fontSize: rank <= 3 ? 22 : 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Avatar profil
          PlayerAvatar(
            emoji: player.emoji,
            color: player.profileColor,
            size: 40,
          ),
          const SizedBox(width: 12),
          // Nom profil (ellipsis si long)
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
          // Score
          Text(
            '🍎 ${player.foodCount}',
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

import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/primary_button.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ModalRoute.of(context)!.settings.arguments as GameState;
    final ranking = gameState.ranking;
    final winner = ranking.first;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 72, color: AppTheme.accent),
                      const SizedBox(height: 12),
                      PlayerAvatar(
                        emoji: winner.emoji,
                        color: winner.profileColor,
                        size: 84,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${winner.name} remporte la partie !',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: ranking.asMap().entries.map((entry) {
                                final player = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Text('#${entry.key + 1}'),
                                      const SizedBox(width: 12),
                                      PlayerAvatar(
                                        emoji: player.emoji,
                                        color: player.profileColor,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(player.name, overflow: TextOverflow.ellipsis)),
                                      Text('🍎 ${player.foodCount}'),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Résumé de partie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 12),
                                _StatLine(label: 'Cartes jouées', value: '${gameState.sessionStats.cardsPlayed}'),
                                _StatLine(label: 'Nourriture gagnée', value: '${gameState.sessionStats.foodGained}'),
                                _StatLine(label: 'Nourriture volée', value: '${gameState.sessionStats.foodStolen}'),
                                _StatLine(label: 'Bandits joués', value: '${gameState.sessionStats.banditCardsPlayed}'),
                                _StatLine(label: 'Raccoons joués', value: '${gameState.sessionStats.raccoonCardsPlayed}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'REJOUER',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.lobby,
                    (r) => r.settings.name == AppRoutes.home,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (r) => false,
                  ),
                  child: const Text('Retour lobby'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [Expanded(child: Text(label)), Text(value)],
      ),
    );
  }
}

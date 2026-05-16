import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/result_screen_args.dart';
import '../../core/navigation/app_router.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/reward_unlock_dialog.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Empêche double-tap et navigation simultanée depuis cet écran.
  bool _navigationInProgress = false;

  static const String _tag = 'ResultScreen';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    // Afficher les popups de récompense après le rendu initial
    WidgetsBinding.instance.addPostFrameCallback((_) => _showRewardPopups());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showRewardPopups() async {
    if (!mounted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! ResultScreenArgs) return;
    if (args.newUnlocks.isEmpty) return;

    // Légère pause pour laisser l'écran de résultat s'afficher d'abord
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await RewardUnlockDialog.showAll(context, args.newUnlocks);
  }

  GameState _getGameState(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is ResultScreenArgs) return args.gameState;
    // Compatibilité ascendante : arguments directs (ancien chemin)
    return args as GameState;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = _getGameState(context);
    final ranking = gameState.ranking;
    final winner = ranking.first;

    // L'écran résultat autorise le retour Android (→ home).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationGuard.log(_tag, 'back pressed — retour home');
        _goHome();
      },
      child: Scaffold(
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
                  onPressed: _goLobby,
                ),
                TextButton(
                  onPressed: _goHome,
                  child: const Text('Retour accueil'),
                ),
              ],
            ),
          ),
        ),
      ),
    ), // PopScope
    );
  }

  void _goLobby() {
    if (_navigationInProgress || !mounted) return;
    _navigationInProgress = true;
    NavigationGuard.log(_tag, 'navigation → lobby');
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.lobby,
      (r) => r.settings.name == AppRoutes.home,
    );
  }

  void _goHome() {
    if (_navigationInProgress || !mounted) return;
    _navigationInProgress = true;
    NavigationGuard.log(_tag, 'navigation → home');
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (r) => false,
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

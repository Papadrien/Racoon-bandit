import 'package:flutter/material.dart';

import '../../core/game/game_state.dart';
import '../../core/models/result_screen_args.dart';
import '../../core/navigation/app_router.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../core/services/audio_service.dart';
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

  bool _navigationInProgress = false;

  static const String _tag = 'ResultScreen';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

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

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await RewardUnlockDialog.showAll(context, args.newUnlocks);
  }

  GameState _getGameState(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is ResultScreenArgs) return args.gameState;
    return args as GameState;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = _getGameState(context);
    final ranking = gameState.ranking;
    final winner = ranking.first;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationGuard.log(_tag, 'back pressed — retour home');
        _goHome();
      },
      child: Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final hPad = isNarrow ? 12.0 : 20.0;
                final winnerAvatarSize = (constraints.maxWidth * 0.22).clamp(56.0, 84.0);
                final trophySize = (constraints.maxWidth * 0.19).clamp(48.0, 72.0);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                  child: Column(
                    children: [
                      // ── Gagnant ─────────────────────────────────────────
                      ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: trophySize,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(height: 8),
                            PlayerAvatar(
                              emoji: winner.emoji,
                              color: winner.profileColor,
                              size: winnerAvatarSize,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${winner.name} remporte la partie !',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize:
                                    (constraints.maxWidth * 0.062).clamp(16.0, 24.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Classement & stats ───────────────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: ranking.asMap().entries.map((entry) {
                                      final player = entry.value;
                                      final avatarSize =
                                          (constraints.maxWidth * 0.10).clamp(32.0, 40.0);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 28,
                                              child: Text(
                                                '#${entry.key + 1}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            PlayerAvatar(
                                              emoji: player.emoji,
                                              color: player.profileColor,
                                              size: avatarSize,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                player.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text('🍎 ${player.foodCount}'),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Résumé de partie',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _StatLine(
                                        label: 'Cartes jouées',
                                        value:
                                            '${gameState.sessionStats.cardsPlayed}',
                                      ),
                                      _StatLine(
                                        label: 'Nourriture gagnée',
                                        value:
                                            '${gameState.sessionStats.foodGained}',
                                      ),
                                      _StatLine(
                                        label: 'Nourriture volée',
                                        value:
                                            '${gameState.sessionStats.foodStolen}',
                                      ),
                                      _StatLine(
                                        label: 'Bandits joués',
                                        value:
                                            '${gameState.sessionStats.banditCardsPlayed}',
                                      ),
                                      _StatLine(
                                        label: 'Raccoons joués',
                                        value:
                                            '${gameState.sessionStats.raccoonCardsPlayed}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Actions ──────────────────────────────────────────
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'REJOUER',
                        onPressed: _goLobby,
                      ),
                      TextButton(
                        onPressed: () {
                          AudioService.instance.playButtonSound();
                          _goHome();
                        },
                        child: const Text('Retour accueil'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

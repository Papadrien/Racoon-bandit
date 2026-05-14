import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/services/game_save_service.dart';
import '../../core/services/life_system_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/lives_indicator.dart';
import '../../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LifeSystemService _lifeSystemService = LifeSystemService();

  Timer? _timer;
  bool _isLoading = true;

  // La sauvegarde est lue depuis GameSaveService (déjà chargé dans main).
  bool get _hasSavedGame => GameSaveService.hasSavedGame;

  @override
  void initState() {
    super.initState();
    _initializeLives();
  }

  Future<void> _initializeLives() async {
    await _lifeSystemService.load();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _lifeSystemService.updateLivesFromTime();
      if (mounted) setState(() {});
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startGame() async {
    await _lifeSystemService.consumeLife();
    if (!mounted) return;
    setState(() {});
    Navigator.pushNamed(context, AppRoutes.lobby);
  }

  /// Reprend la partie sauvegardée sans repasser par le lobby.
  /// Aucun argument passé : GameScreen détecte GameSaveService.current.
  void _resumeGame() {
    Navigator.pushNamed(context, AppRoutes.game);
  }

  @override
  Widget build(BuildContext context) {
    final remainingDuration =
        _lifeSystemService.getRemainingRechargeDuration();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isLoading)
                    LivesIndicator(
                      lives: _lifeSystemService.currentLives,
                      remainingDuration: remainingDuration,
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.workspace_premium),
                        color: AppTheme.accent,
                        tooltip: 'Premium',
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.premium),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: AppTheme.textMuted,
                        tooltip: 'Paramètres',
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.settings),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              const _Logo(),
              const Spacer(),

              // ── Bouton Reprendre (visible uniquement si sauvegarde présente) ──
              if (_hasSavedGame) ...[
                _ResumeButton(onPressed: _resumeGame),
                const SizedBox(height: 12),
              ],

              PrimaryButton(
                label: _lifeSystemService.currentLives > 0
                    ? 'JOUER'
                    : 'PLUS DE VIES',
                onPressed: _isLoading || _lifeSystemService.currentLives <= 0
                    ? null
                    : _startGame,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bouton Reprendre ────────────────────────────────────────────────────────

class _ResumeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResumeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Reprendre la partie'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accent,
          side: const BorderSide(color: AppTheme.accent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Logo ────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'RACCOON',
          style: Theme.of(context)
              .textTheme
              .displayLarge
              ?.copyWith(color: AppTheme.primary),
        ),
        Text(
          'BANDIT',
          style: Theme.of(context)
              .textTheme
              .displayLarge
              ?.copyWith(color: AppTheme.accent),
        ),
        const SizedBox(height: 12),
        const Text(
          'multijoueur local',
          style: TextStyle(
            color: AppTheme.textMuted,
            letterSpacing: 3,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

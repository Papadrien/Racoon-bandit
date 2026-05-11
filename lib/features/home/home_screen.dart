import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeLives();
  }

  Future<void> _initializeLives() async {
    await _lifeSystemService.load();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _lifeSystemService.updateLivesFromTime();

      if (mounted) {
        setState(() {});
      }
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

    if (!mounted) {
      return;
    }

    setState(() {});

    Navigator.pushNamed(context, AppRoutes.lobby);
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
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.premium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: AppTheme.textMuted,
                        tooltip: 'Paramètres',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.settings,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              const _Logo(),
              const Spacer(),
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

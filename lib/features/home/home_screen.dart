import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/services/game_save_service.dart';
import '../../core/services/life_system_service.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/lives_indicator.dart';
import '../../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final LifeSystemService _lifeSystemService = LifeSystemService();

  Timer? _timer;
  bool _isLoading = true;
  bool _isRewardLoading = false;

  late final AnimationController _rewardAnimationController;

  bool get _hasSavedGame => GameSaveService.hasSavedGame;

  @override
  void initState() {
    super.initState();

    _rewardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 1,
      upperBound: 1.1,
    );

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
    _rewardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    await _lifeSystemService.consumeLife();
        if (!mounted) return;
    setState(() {});
    Navigator.pushNamed(context, AppRoutes.lobby);
  }

  Future<void> _watchAdForLife() async {
    if (_isRewardLoading || RewardedAdService.instance.isBusy) {
      return;
    }

    setState(() {
      _isRewardLoading = true;
    });

    await RewardedAdService.instance.showRewardedLifeAd(
          onRewardEarned: () async {
        await _lifeSystemService.restoreLife();
        
        if (!mounted) return;

        await _rewardAnimationController.forward();
                await _rewardAnimationController.reverse();
        
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1 vie gagnée !'),
          ),
        );
      },
      onError: (message) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isRewardLoading = false;
      });
    }
  }

  void _resumeGame() {
    Navigator.pushNamed(context, AppRoutes.game);
  }

  @override
  Widget build(BuildContext context) {
    final remainingDuration =
        _lifeSystemService.getRemainingRechargeDuration();

    final noLives = _lifeSystemService.currentLives <= 0;

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
                    ScaleTransition(
                      scale: _rewardAnimationController,
                      child: LivesIndicator(
                        lives: _lifeSystemService.currentLives,
                        remainingDuration: remainingDuration,
                      ),
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
              if (_hasSavedGame) ...[
                _ResumeButton(onPressed: _resumeGame),
                const SizedBox(height: 12),
              ],
              if (noLives)
                _RewardAdButton(
                  isLoading: _isRewardLoading,
                  onPressed: _watchAdForLife,
                )
              else
                PrimaryButton(
                  label: 'JOUER',
                  onPressed: _isLoading ? null : _startGame,
                ),
              const SizedBox(height: 16),
              if (noLives)
                const Text(
                  'Regardez une publicité complète pour récupérer 1 vie.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardAdButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RewardAdButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.ondemand_video_rounded),
        label: Text(
          isLoading
              ? 'Chargement de la publicité...'
              : 'Regarder une publicité',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

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

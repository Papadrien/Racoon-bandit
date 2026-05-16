import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../core/services/game_save_service.dart';
import '../../core/services/life_system_service.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_provider.dart';
import '../../widgets/lives_indicator.dart';
import '../../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final LifeSystemService _lifeSystemService = LifeSystemService();

  Timer? _timer;
  bool _isLoading = true;
  bool _isRewardLoading = false;

  late final AnimationController _rewardAnimationController;

  bool get _hasSavedGame => GameSaveService.hasSavedGame;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _rewardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 1,
      upperBound: 1.1,
    );

    _initializeLives();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Recharge la sauvegarde et les vies au retour de l'app
      GameSaveService.load().then((_) {
        if (mounted) {
          _lifeSystemService.updateLivesFromTime().then((_) {
            if (mounted) setState(() {});
          });
        }
      });
    }
  }

  Future<void> _initializeLives() async {
    await _lifeSystemService.load();
    await RewardedAdService.instance.preloadAd();

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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _rewardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    Navigator.pushNamed(context, AppRoutes.lobby);
  }

  Future<void> _watchAdForLife() async {
    if (_isRewardLoading || RewardedAdService.instance.isBusy) {
      return;
    }

    setState(() {
      _isRewardLoading = true;
    });

    // Capture le ScaffoldMessenger avant les appels async
    final messenger = ScaffoldMessenger.of(context);

    await RewardedAdService.instance.showRewardedLifeAd(
      onRewardEarned: () async {
        await _lifeSystemService.restoreLife();

        if (!mounted) return;

        await _rewardAnimationController.forward();
        await _rewardAnimationController.reverse();

        setState(() {});

        messenger.showSnackBar(
          const SnackBar(
            content: Text('1 vie gagnée !'),
          ),
        );
      },
      onError: (message) {
        if (!mounted) return;

        messenger.showSnackBar(
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

  Future<void> _resumeGame() async {
    await GameSaveService.load();
    if (!mounted) return;

    if (!GameSaveService.hasSavedGame) {
      setState(() {});
      return;
    }

    Navigator.pushNamed(context, AppRoutes.game);
  }

  @override
  Widget build(BuildContext context) {
    final remainingDuration =
        _lifeSystemService.getRemainingRechargeDuration();

    final noLives = _lifeSystemService.currentLives <= 0;

    return ListenableBuilder(
      listenable: AppThemeProvider.instance,
      builder: (context, _) => _buildScaffold(
        context,
        remainingDuration: remainingDuration,
        noLives: noLives,
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required Duration? remainingDuration,
    required bool noLives,
  }) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (kDebugMode && didPop) {
          NavigationGuard.log('HomeScreen', 'back pressed — quitte l\'app');
        }
      },
      child: Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final hPad = isNarrow ? 16.0 : 32.0;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                child: Column(
                  children: [
                    // ── Top bar ───────────────────────────────────────────
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
                          )
                        else
                          const SizedBox.shrink(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                    // ── Logo ──────────────────────────────────────────────
                    const _Logo(),
                    const Spacer(),
                    // ── Actions ───────────────────────────────────────────
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
                    const SizedBox(height: 12),
                    if (noLives)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Regardez une publicité complète pour récupérer 1 vie.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 360).clamp(0.75, 1.0);
        return Column(
          children: [
            Text(
              'RACCOON',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize:
                        (Theme.of(context).textTheme.displayLarge?.fontSize ??
                                48) *
                            scale,
                  ),
            ),
            Text(
              'BANDIT',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.accent,
                    fontSize:
                        (Theme.of(context).textTheme.displayLarge?.fontSize ??
                                48) *
                            scale,
                  ),
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
      },
    );
  }
}

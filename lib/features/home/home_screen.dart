import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/game_save_service.dart';
import '../../core/services/life_system_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_provider.dart';
import '../../widgets/lives_indicator.dart';
import '../../widgets/primary_button.dart';
import '../onboarding/onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final LifeSystemService _lifeSystemService = LifeSystemService();

  // Onboarding — premier lancement uniquement
  bool _showOnboarding = false;

  Timer? _timer;
  bool _isLoading = true;
  bool _isRewardLoading = false;

  late final AnimationController _rewardAnimationController;
  // Controller pour le feedback press du bouton Jouer
  late final AnimationController _playButtonPressController;
  late final Animation<double> _playButtonScale;

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

    _playButtonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _playButtonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _playButtonPressController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _initializeLives();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
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
        // Déclencher l'onboarding au bon moment : après chargement, avant UI
        _showOnboarding = OnboardingService.shouldShowOnboarding;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _rewardAnimationController.dispose();
    _playButtonPressController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    await _playButtonPressController.forward();
    await _playButtonPressController.reverse();
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.lobby);
  }

  Future<void> _watchAdForLife() async {
    if (_isRewardLoading || RewardedAdService.instance.isBusy) {
      return;
    }

    setState(() {
      _isRewardLoading = true;
    });

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
    // Onboarding premier lancement — affiché AVANT l'écran principal
    if (_showOnboarding) {
      return OnboardingScreen(
        onDone: () {
          if (mounted) setState(() => _showOnboarding = false);
        },
      );
    }

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
        body: Stack(
          children: [
            // ── Hero image ancrée en bas avec animation idle ─────────────
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _HeroImage(),
            ),

            // ── Top bar (SafeArea) ────────────────────────────────────────
            SafeArea(
              minimum: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final hPad = isNarrow ? 16.0 : 32.0;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Top bar ─────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (!_isLoading)
                                ScaleTransition(
                                  scale: _rewardAnimationController,
                                  child: LivesIndicator(
                                    lives: _lifeSystemService.currentLives,
                                    remainingDuration:
                                        remainingDuration ?? Duration.zero,
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
                                    onPressed: () {
                                      AudioService.instance.playButtonSound();
                                      Navigator.pushNamed(
                                          context, AppRoutes.premium);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.settings),
                                    color: AppTheme.textMuted,
                                    tooltip: 'Paramètres',
                                    onPressed: () {
                                      AudioService.instance.playButtonSound();
                                      Navigator.pushNamed(
                                          context, AppRoutes.settings);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Titre ────────────────────────────────────────
                        const SizedBox(height: 12),
                        const _Logo(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Bouton Jouer positionné à ~10% du bas, responsive ────────
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.sizeOf(context).height * 0.10,
              child: SafeArea(
                top: false,
                child: _PlayButtonArea(
                  hasSavedGame: _hasSavedGame,
                  noLives: noLives,
                  isLoading: _isLoading,
                  isRewardLoading: _isRewardLoading,
                  playButtonScale: _playButtonScale,
                  onPlay: _startGame,
                  onResume: _resumeGame,
                  onWatchAd: _watchAdForLife,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone boutons repositionnée (Partie 1 & 3)
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButtonArea extends StatelessWidget {
  final bool hasSavedGame;
  final bool noLives;
  final bool isLoading;
  final bool isRewardLoading;
  final Animation<double> playButtonScale;
  final VoidCallback onPlay;
  final VoidCallback onResume;
  final VoidCallback onWatchAd;

  const _PlayButtonArea({
    required this.hasSavedGame,
    required this.noLives,
    required this.isLoading,
    required this.isRewardLoading,
    required this.playButtonScale,
    required this.onPlay,
    required this.onResume,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final hPad = isNarrow ? 16.0 : 32.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSavedGame) ...[
            _ResumeButton(onPressed: onResume),
            const SizedBox(height: 12),
          ],
          if (noLives)
            _RewardAdButton(
              isLoading: isRewardLoading,
              onPressed: onWatchAd,
            )
          else
            ScaleTransition(
              scale: playButtonScale,
              child: PrimaryButton(
                label: 'JOUER',
                onPressed: isLoading ? null : onPlay,
              ),
            ),
          if (noLives) ...[
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Regardez une publicité complète pour récupérer 1 vie.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero image avec animation idle (Partie 2)
// ─────────────────────────────────────────────────────────────────────────────

/// Image hero pleine largeur, ancrée en bas de l'écran,
/// avec un léger flottement vertical (idle breathing).
class _HeroImage extends StatefulWidget {
  const _HeroImage();

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // Amplitude : 6px max, courbe sinusoïdale douce
    _floatAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        // translateY de -6px à 0 (vers le haut puis retour)
        final dy = -6.0 * math.sin(_floatAnimation.value * math.pi);
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: SizedBox(
        height: screenH * 0.65,
        child: Image.asset(
          'assets/images/raccoon_bandit_hero.png',
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
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
        onPressed: isLoading
            ? null
            : () {
                AudioService.instance.playButtonSound();
                onPressed();
              },
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
        onPressed: () {
          AudioService.instance.playButtonSound();
          onPressed();
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Reprendre la partie'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accent,
          side: BorderSide(color: AppTheme.accent),
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
          ],
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/navigation/navigation_guard.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/life_system_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_provider.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';
import '../../widgets/lives_indicator.dart';
import '../../widgets/raccoon_bandit_logo.dart';
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
      _lifeSystemService.updateLivesFromTime().then((_) {
        if (mounted) {
          _ensureAdPreloaded();
          setState(() {});
        }
      });
    }
  }

  Future<void> _initializeLives() async {
    await _lifeSystemService.load();
    _ensureAdPreloaded();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _lifeSystemService.updateLivesFromTime();
      if (mounted) {
        _ensureAdPreloaded();
        setState(() {});
      }
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Déclencher l'onboarding au bon moment : après chargement, avant UI
        _showOnboarding = OnboardingService.shouldShowOnboarding;
      });
    }
  }

  /// Déclenche le preload de la pub uniquement si le bouton est visible.
  /// Sans effet si déjà chargée ou en cours de chargement.
  void _ensureAdPreloaded() {
    if (_lifeSystemService.currentLives < LifeSystemService.maxLives) {
      RewardedAdService.instance.preloadAd();
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
    if (_isRewardLoading) {
      return;
    }

    setState(() {
      _isRewardLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    await RewardedAdService.instance.showRewardedLifeAd(
      onRewardEarned: () async {
        await _lifeSystemService.restoreLife();

        if (!mounted) return;

        await _rewardAnimationController.forward();
        await _rewardAnimationController.reverse();

        setState(() {});

        messenger.showSnackBar(
          SnackBar(content: Text(l10n.lifeEarned)),
        );
      },
      onError: (message) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(message)));
      },
    );

    if (mounted) {
      setState(() {
        _isRewardLoading = false;
      });
    }
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
            // bottom: -6 pour que le bas de l'image dépasse légèrement
            // et évite toute séparation visible entre l'image et le bord.
            const Positioned(
              left: 0,
              right: 0,
              bottom: -6,
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
                                    tooltip: AppLocalizations.of(context)!.tooltipPremium,
                                    onPressed: () {
                                      AudioService.instance.playButtonSound();
                                      Navigator.pushNamed(
                                          context, AppRoutes.premium);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.settings),
                                    color: AppTheme.textMuted,
                                    tooltip: AppLocalizations.of(context)!.tooltipSettings,
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
                        const RaccoonBanditLogo(),
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
                maintainBottomViewPadding: true,
                child: _PlayButtonArea(
                  noLives: noLives,
                  isLoading: _isLoading,
                  isRewardLoading: _isRewardLoading,
                  playButtonScale: _playButtonScale,
                  onPlay: _startGame,
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
  final bool noLives;
  final bool isLoading;
  final bool isRewardLoading;
  final Animation<double> playButtonScale;
  final VoidCallback onPlay;
  final VoidCallback onWatchAd;

  const _PlayButtonArea({
    required this.noLives,
    required this.isLoading,
    required this.isRewardLoading,
    required this.playButtonScale,
    required this.onPlay,
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
          if (noLives)
            _RewardAdButton(
              isLoading: isRewardLoading,
              onPressed: onWatchAd,
            )
          else
            ScaleTransition(
              scale: playButtonScale,
              child: _StickerPlayButton(
                label: AppLocalizations.of(context)!.play,
                onPressed: isLoading ? null : onPlay,
              ),
            ),
          if (noLives) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                AppLocalizations.of(context)!.noLivesAdHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
        // +12px de marge basse pour compenser les 6px d'amplitude de
        // l'animation vers le haut — évite de voir le bas de l'image
        height: screenH * 0.65 + 12,
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
              ? AppLocalizations.of(context)!.adLoading
              : AppLocalizations.of(context)!.watchAdButton,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// _Logo remplacé par RaccoonBanditLogo (lib/widgets/raccoon_bandit_logo.dart)

// ─────────────────────────────────────────────────────────────────────────────
// Bouton Jouer style sticker (image 2)
// ─────────────────────────────────────────────────────────────────────────────

class _StickerPlayButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _StickerPlayButton({required this.label, required this.onPressed});

  static const _orange = Color(0xFFE16713);
  static const _orangeDark = Color(0xFFC05510);
  static const _foldSize = 18.0;
  static const _height = 56.0;
  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return GestureDetector(
      onTap: enabled
          ? () {
              HapticService.trigger(HapticType.selection);
              AudioService.instance.playSfx(SoundEffect.button);
              onPressed!();
            }
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Ombre portée ──────────────────────────────────────────────────
          Positioned(
            left: 4,
            top: 4,
            right: 0,
            bottom: 0,
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: _orangeDark.withOpacity(0.55),
                borderRadius: BorderRadius.circular(_radius),
              ),
            ),
          ),

          // ── Corps principal du bouton ──────────────────────────────────────
          CustomPaint(
            painter: _FoldPainter(
              color: enabled ? _orange : _orange.withOpacity(0.5),
              darkColor: _orangeDark,
              foldSize: _foldSize,
              radius: _radius,
            ),
            child: SizedBox(
              width: double.infinity,
              height: _height,
              child: Center(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),

          // ── Sparkles (traits décoratifs haut-gauche) ──────────────────────
          Positioned(
            top: -4,
            left: 10,
            child: _Sparkles(color: _orange),
          ),
        ],
      ),
    );
  }
}

// ── CustomPainter : rectangle arrondi + coin replié bas-droit ────────────────

class _FoldPainter extends CustomPainter {
  final Color color;
  final Color darkColor;
  final double foldSize;
  final double radius;

  const _FoldPainter({
    required this.color,
    required this.darkColor,
    required this.foldSize,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final f = foldSize;
    final r = radius;
    final paint = Paint()..color = color;

    // Chemin principal : rectangle arrondi avec coin bas-droit découpé
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r),
          radius: Radius.circular(r), clockwise: true)
      ..lineTo(size.width, size.height - f)
      ..lineTo(size.width - f, size.height)
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r),
          radius: Radius.circular(r), clockwise: false)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0),
          radius: Radius.circular(r), clockwise: true)
      ..close();

    canvas.drawPath(path, paint);

    // Triangle du pli (coin replié, teinte sombre)
    final foldPaint = Paint()..color = darkColor.withOpacity(0.75);
    final foldPath = Path()
      ..moveTo(size.width - f, size.height)
      ..lineTo(size.width, size.height - f)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(foldPath, foldPaint);
  }

  @override
  bool shouldRepaint(_FoldPainter old) =>
      old.color != color || old.foldSize != foldSize;
}

// ── Petits traits décoratifs (sparkles) ─────────────────────────────────────

class _Sparkles extends StatelessWidget {
  final Color color;
  const _Sparkles({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Tick(color: color, angle: -0.5),
        const SizedBox(width: 3),
        _Tick(color: color, angle: 0.0),
        const SizedBox(width: 3),
        _Tick(color: color, angle: 0.5),
      ],
    );
  }
}

class _Tick extends StatelessWidget {
  final Color color;
  final double angle;
  const _Tick({required this.color, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 3,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

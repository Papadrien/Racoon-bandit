import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
// Hero image — style autocollant CustomPainter (contour blanc lisse + ombre)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatefulWidget {
  const _HeroImage();

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage> {
  ui.Image? _uiImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/images/raccoon_bandit_hero.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _uiImage = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final heroHeight = screenH * 0.65 * 0.5;

    if (_uiImage == null) {
      return SizedBox(height: heroHeight);
    }

    return SizedBox(
      height: heroHeight,
      child: CustomPaint(
        painter: _StickerPainter(image: _uiImage!),
        size: Size.infinite,
      ),
    );
  }
}

/// Peint l'image avec :
/// 1. Une ombre ovale douce centrée sous les pieds
/// 2. Un contour blanc lisse (dilatation alpha via MaskFilter.blur)
/// 3. L'image originale par-dessus
class _StickerPainter extends CustomPainter {
  final ui.Image image;
  static const double _outlineWidth = 10.0;

  const _StickerPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    // Calcul du rect de destination (BoxFit.contain centré)
    final scale = (size.width / imgW).clamp(0.0, size.height / imgH);
    final dstW = imgW * scale;
    final dstH = imgH * scale;
    final dstRect = Rect.fromLTWH(
      (size.width - dstW) / 2,
      (size.height - dstH) / 2,
      dstW,
      dstH,
    );

    // ── 1. Ombre ovale centrée sous les pieds ─────────────────────────────
    final shadowRect = Rect.fromCenter(
      center: Offset(size.width / 2, dstRect.bottom - 4),
      width: dstW * 0.55,
      height: dstH * 0.06,
    );
    final shadowPaint = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(shadowRect, shadowPaint);

    // ── 2. Contour blanc : image teintée blanc + MaskFilter dilatation ────
    // On peint l'image dans un layer isolé avec un ColorFilter blanc,
    // puis un MaskFilter.blur pour l'étaler, ce qui donne un contour lisse.
    final outlinePaint = Paint()
      ..colorFilter = const ColorFilter.matrix(<double>[
        0, 0, 0, 0, 255, // R toujours 255
        0, 0, 0, 0, 255, // G toujours 255
        0, 0, 0, 0, 255, // B toujours 255
        0, 0, 0, 1, 0,   // A inchangé
      ])
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, _outlineWidth * 0.6);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgW, imgH),
      dstRect,
      outlinePaint,
    );

    // ── 3. Image originale ────────────────────────────────────────────────
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgW, imgH),
      dstRect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_StickerPainter old) => old.image != image;
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
// Bouton Jouer style sticker
// ─────────────────────────────────────────────────────────────────────────────

class _StickerPlayButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _StickerPlayButton({required this.label, required this.onPressed});

  static const _orange     = Color(0xFFE16713);
  static const _orangeDark = Color(0xFFB84D0A);
  static const _foldSize   = 22.0;
  static const _height     = 62.0;
  static const _radius     = 18.0;
  static const _border     = 5.0;  // épaisseur contour blanc

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
          // ── Contour blanc sticker (layer derrière) ────────────────────────
          CustomPaint(
            painter: _StickerBorderPainter(
              foldSize: _foldSize,
              radius: _radius + _border,
              border: _border,
            ),
            child: SizedBox(
              width: double.infinity,
              height: _height + _border * 2,
            ),
          ),

          // ── Ombre sous le bouton (décalée vers le bas) ────────────────────
          Positioned(
            left: _border,
            right: _border,
            top: _border + 5,
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: [
                  BoxShadow(
                    color: _orangeDark.withOpacity(0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),

          // ── Corps principal du bouton ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(_border),
            child: CustomPaint(
              painter: _ButtonBodyPainter(
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
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: Color(0x55000000),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Sparkles haut-gauche ──────────────────────────────────────────
          Positioned(
            top: -2,
            left: 6,
            child: _Sparkles(color: _orange),
          ),
        ],
      ),
    );
  }
}

// ── Contour blanc sticker avec coin replié ────────────────────────────────────

class _StickerBorderPainter extends CustomPainter {
  final double foldSize;
  final double radius;
  final double border;

  const _StickerBorderPainter({
    required this.foldSize,
    required this.radius,
    required this.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final f = foldSize + border;
    final r = radius;

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

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_StickerBorderPainter old) => false;
}

// ── Corps du bouton : fond orange dégradé + reflet + coin replié ──────────────

class _ButtonBodyPainter extends CustomPainter {
  final Color color;
  final Color darkColor;
  final double foldSize;
  final double radius;

  const _ButtonBodyPainter({
    required this.color,
    required this.darkColor,
    required this.foldSize,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final f = foldSize;
    final r = radius;

    // Silhouette principale avec coin replié
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

    // Dégradé vertical orange clair → orange foncé
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(color, Colors.white, 0.18)!,
        color,
        darkColor,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // Reflet brillant en haut (ellipse blanche semi-transparente)
    canvas.save();
    canvas.clipPath(path);
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.2),
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.55),
      highlightPaint,
    );
    canvas.restore();

    // Bordure intérieure sombre en bas (relief)
    canvas.save();
    canvas.clipPath(path);
    final innerShadow = Paint()
      ..color = darkColor.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35),
      innerShadow,
    );
    canvas.restore();

    // Triangle du coin replié — couleur crème (face dessous du papier)
    final foldPaint = Paint()..color = const Color(0xFFF5E6C8);
    final foldPath = Path()
      ..moveTo(size.width - f, size.height)
      ..lineTo(size.width, size.height - f)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(foldPath, foldPaint);

    // Ligne de pliure subtile
    final creasePaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width - f, size.height),
      Offset(size.width, size.height - f),
      creasePaint,
    );
  }

  @override
  bool shouldRepaint(_ButtonBodyPainter old) =>
      old.color != color || old.foldSize != foldSize;
}

// ── Sparkles ──────────────────────────────────────────────────────────────────

class _Sparkles extends StatelessWidget {
  final Color color;
  const _Sparkles({required this.color});

  @override
  Widget build(BuildContext context) {
    // Reproduction fidèle des 3 traits de l'image : éventail vers le haut-gauche
    return SizedBox(
      width: 24,
      height: 28,
      child: CustomPaint(painter: _SparklesPainter(color: color)),
    );
  }
}

class _SparklesPainter extends CustomPainter {
  final Color color;
  const _SparklesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width * 0.75;
    final cy = size.height * 0.85;

    // 3 traits rayonnants (gauche, centre, droite)
    final lines = [
      [Offset(cx, cy), Offset(cx - 14, cy - 20)],
      [Offset(cx, cy), Offset(cx - 2,  cy - 24)],
      [Offset(cx, cy), Offset(cx + 10, cy - 18)],
    ];

    for (final l in lines) {
      canvas.drawLine(l[0], l[1], paint);
    }
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => old.color != color;
}

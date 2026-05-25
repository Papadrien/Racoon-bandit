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
    _playButtonScale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
            // ── Stickers décoratifs en fond ───────────────────────────────
            const Positioned.fill(child: _BackgroundStickers()),

            // ── Hero image centrée verticalement entre logo et bouton ──
            const Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: _HeroImage(),
              ),
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
    final hPad = isNarrow ? 8.0 : 16.0;

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
            AnimatedBuilder(
              animation: playButtonScale,
              builder: (context, _) => Transform.scale(
                scale: playButtonScale.value,
                child: _StickerPlayButton(
                  label: AppLocalizations.of(context)!.play,
                  onPressed: isLoading ? null : onPlay,
                  shadowScale: playButtonScale.value,
                ),
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

/// Peint l'image avec un contour blanc via saveLayer + blur et l'image originale
class _StickerPainter extends CustomPainter {
  final ui.Image image;
  static const double _outlineWidth = 10.0;

  const _StickerPainter({required this.image});

  Rect _fitRect(Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final scaleX = size.width / imgW;
    final scaleY = size.height / imgH;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dstW = imgW * scale;
    final dstH = imgH * scale;
    return Rect.fromLTWH(
      (size.width - dstW) / 2,
      (size.height - dstH) / 2,
      dstW,
      dstH,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final dstRect = _fitRect(size);

    // ── Contour sticker blanc uniforme via saveLayer + blur ─────────────────
    // Peindre l'image en blanc avec un blur de dilatation dans un layer isolé
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Passe dilatée : blanc avec blur pour remplir uniformément autour
    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      Paint()
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn)
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, _outlineWidth * 0.8),
    );

    // Repasse l'image par-dessus pour effacer l'intérieur du contour
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    canvas.restore();

    // ── Image originale ──────────────────────────────────────────────────────
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
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
  final double shadowScale;

  const _StickerPlayButton({
    required this.label,
    required this.onPressed,
    this.shadowScale = 1.0,
  });

  static const _orange     = Color(0xFFE16713);
  static const _orangeDark = Color(0xFFB84D0A);
  static const _cutSize    = 36.0; // plus grande = base du triangle plus large // taille de la coupe diagonale bas-droit
  static const _tabSize    = 20.0; // taille du triangle-rebord
  static const _height     = 74.0;
  static const _radius     = 22.0;
  static const _border     = 8.0;  // épaisseur contour blanc

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
              cutSize: _cutSize,
              radius: _radius + _border,
              border: _border,
              shadowScale: shadowScale,
            ),
            child: const SizedBox(
              width: double.infinity,
              height: _height + _border * 2,
            ),
          ),

          // ── Corps principal du bouton ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(_border),
            child: CustomPaint(
              painter: _ButtonBodyPainter(
                color: enabled ? _orange : _orange.withValues(alpha: 0.5),
                darkColor: _orangeDark,
                cutSize: _cutSize,
                tabSize: _tabSize,
                radius: _radius,
                border: _border,
              ),
              child: SizedBox(
                width: double.infinity,
                height: _height,
                child: Center(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
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
        ],
      ),
    );
  }
}

// ── Contour blanc sticker avec coupe diagonale bas-droit ─────────────────────

class _StickerBorderPainter extends CustomPainter {
  final double cutSize;
  final double radius;
  final double border;
  final double shadowScale;

  const _StickerBorderPainter({
    required this.cutSize,
    required this.radius,
    required this.border,
    this.shadowScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = cutSize + border; // coupe diagonale agrandie pour le contour
    final r = radius;

    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r),
          radius: Radius.circular(r), clockwise: true)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r),
          radius: Radius.circular(r), clockwise: true)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0),
          radius: Radius.circular(r), clockwise: true)
      ..close();

    // ── Ombre portée style logo (décalée bas-droite, réduite à la pression) ──
    // shadowScale va de 1.0 (repos) à ~0.96 (pressé), on mappe sur [1.0, 0.0]
    final shadowOpacity = ((shadowScale - 0.96) / 0.04).clamp(0.0, 1.0);
    if (shadowOpacity > 0) {
      final shadowPaint = Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.45 * shadowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * shadowOpacity);
      canvas.drawPath(
        path.shift(const Offset(5, 7)),
        shadowPaint,
      );
    }

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_StickerBorderPainter old) =>
      old.shadowScale != shadowScale;
}

// ── Corps du bouton : fond orange dégradé + reflet pill + coupe diagonale ────

class _ButtonBodyPainter extends CustomPainter {
  final Color color;
  final Color darkColor;
  final double cutSize;
  final double tabSize;
  final double radius;
  final double border;

  const _ButtonBodyPainter({
    required this.color,
    required this.darkColor,
    required this.cutSize,
    required this.tabSize,
    required this.radius,
    required this.border,
  });

  Path _buildPath(Size size) {
    final c = cutSize;
    final r = radius;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r),
          radius: Radius.circular(r), clockwise: true)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r),
          radius: Radius.circular(r), clockwise: true)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0),
          radius: Radius.circular(r), clockwise: true)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = cutSize;
    final t = tabSize;
    final path = _buildPath(size);

    // ── Ombre portée style logo (sombre, décalée bas-droite) ─────────────
    // ── Fond dégradé orange ───────────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.15)!,
            color,
            darkColor,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // ── Reflet pill en haut (style bouton jeu) ────────────────────────────
    canvas.save();
    canvas.clipPath(path);

    final highlightW = size.width * 0.55;
    final highlightH = size.height * 0.28;
    final highlightRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.2),
      width: highlightW,
      height: highlightH,
    );
    canvas.drawOval(
      highlightRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(highlightRect),
    );

    // ── Ombre intérieure basse (relief 3D) ───────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      Paint()
        ..color = darkColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.restore();

    // ── Triangle-rebord bas-droit (coin replié style page) ───────────────
    // On translate le canvas de +border vers bas-droit pour que la base
    // du triangle coïncide avec la diagonale du contour blanc extérieur.
    canvas.save();
    canvas.translate(border / 2, border / 2);

    final p1 = Offset(size.width - c, size.height);
    final p2 = Offset(size.width, size.height - c);
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

    // Pointe vers l'intérieur (haut-gauche), profondeur = tabSize
    const inward = Offset(-0.7071, -0.7071);
    final tip = Offset(mid.dx + inward.dx * t, mid.dy + inward.dy * t);

    // Vecteur normalisé côté p1→tip
    final leg1Dx = tip.dx - p1.dx;
    final leg1Dy = tip.dy - p1.dy;
    final leg1Len = Offset(leg1Dx, leg1Dy).distance;
    final leg1Nx = leg1Dx / leg1Len;
    final leg1Ny = leg1Dy / leg1Len;

    // Vecteur normalisé côté p2→tip
    final leg2Dx = tip.dx - p2.dx;
    final leg2Dy = tip.dy - p2.dy;
    final leg2Len = Offset(leg2Dx, leg2Dy).distance;
    final leg2Nx = leg2Dx / leg2Len;
    final leg2Ny = leg2Dy / leg2Len;

    // Rayon de l'arc concave à la pointe — ne pas modifier
    const tipRadius = 10.0;

    // arcEntry : recule sur le côté p1→tip depuis la pointe
    final arcEntry = Offset(tip.dx - leg1Nx * tipRadius, tip.dy - leg1Ny * tipRadius);
    // arcExit  : recule sur le côté p2→tip depuis la pointe
    final arcExit  = Offset(tip.dx - leg2Nx * tipRadius, tip.dy - leg2Ny * tipRadius);

    // Tracé : p1 → arcEntry → arc concave → arcExit → p2 → diagonale (close)
    final tabPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(arcEntry.dx, arcEntry.dy)
      ..arcToPoint(arcExit,
          radius: const Radius.circular(tipRadius), clockwise: true)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    // Couleur blanc cassé chaud, 10% plus foncée que 0xFFF5EBE0
    canvas.drawPath(
      tabPath,
      Paint()
        ..color = const Color(0xFFDDCFBF)
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ButtonBodyPainter old) =>
      old.color != color || old.cutSize != cutSize || old.border != border;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stickers décoratifs en fond — reproduit le layout de la maquette
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundStickers extends StatelessWidget {
  const _BackgroundStickers();

  static const _pine  = 'assets/images/sticker_pine_tree.png';
  static const _cone  = 'assets/images/sticker_pine_cone.png';
  static const _cabin = 'assets/images/sticker_cabin.png';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Sapins gauche ────────────────────────────────────────────────
        _Sticker(asset: _pine,  size: w * 0.22, left: -w * 0.04, top:  h * 0.08),
        _Sticker(asset: _pine,  size: w * 0.26, left: -w * 0.02, top:  h * 0.27),
        _Sticker(asset: _pine,  size: w * 0.20, left:  w * 0.01, top:  h * 0.78),

        // ── Sapins droite ────────────────────────────────────────────────
        _Sticker(asset: _pine,  size: w * 0.20, right: -w * 0.02, top:  h * 0.38),
        _Sticker(asset: _pine,  size: w * 0.24, right: -w * 0.04, top:  h * 0.52),
        _Sticker(asset: _pine,  size: w * 0.20, right:  w * 0.02, top:  h * 0.68),

        // ── Cabane haut-droit ─────────────────────────────────────────────
        _Sticker(asset: _cabin, size: w * 0.22, right:  w * 0.02, top:  h * 0.10,
            angle: 0.05),

        // ── Cabane bas-droit ──────────────────────────────────────────────
        _Sticker(asset: _cabin, size: w * 0.26, right: -w * 0.01, top:  h * 0.76,
            angle: -0.04),

        // ── Pomme de pin droite milieu ────────────────────────────────────
        _Sticker(asset: _cone,  size: w * 0.13, right:  w * 0.10, top:  h * 0.31,
            angle: 0.15),

        // ── Pomme de pin bas-gauche ───────────────────────────────────────
        _Sticker(asset: _cone,  size: w * 0.12, left:  w * 0.04, top:  h * 0.68,
            angle: -0.10),
      ],
    );
  }
}

class _Sticker extends StatelessWidget {
  final String asset;
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double angle;

  const _Sticker({
    required this.asset,
    required this.size,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.angle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = Transform.rotate(
      angle: angle,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        opacity: const AlwaysStoppedAnimation(0.90),
      ),
    );

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: img,
    );
  }
}

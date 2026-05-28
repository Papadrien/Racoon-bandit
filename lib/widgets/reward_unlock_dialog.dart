import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../core/constants/app_assets.dart';
import '../core/models/reward_unlock.dart';
import '../core/services/audio_service.dart';
import '../core/services/progression_service.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_shadows.dart';
import '../core/ui/app_spacing.dart';
import 'primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Couleur accent par dos (cohérente avec AppAssets.cardBackFallbackColor)
// ─────────────────────────────────────────────────────────────────────────────

Color _accentForId(String id) => AppAssets.cardBackFallbackColor(id);

// ─────────────────────────────────────────────────────────────────────────────
// Popup principale
// ─────────────────────────────────────────────────────────────────────────────

class RewardUnlockDialog extends StatefulWidget {
  const RewardUnlockDialog({
    super.key,
    required this.reward,
    required this.onTryNow,
    required this.onLater,
  });

  final RewardUnlock reward;
  final VoidCallback onTryNow;
  final VoidCallback onLater;

  static Future<bool> show(BuildContext context, RewardUnlock reward) async {
    AudioService.instance.playSfx(SoundEffect.popupRecompense);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => RewardUnlockDialog(
        reward: reward,
        onTryNow: () => Navigator.of(ctx).pop(true),
        onLater: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  static Future<void> showAll(
    BuildContext context,
    List<RewardUnlock> rewards,
  ) async {
    for (final reward in rewards) {
      if (!context.mounted) return;
      final tryNow = await show(context, reward);
      if (tryNow) await ProgressionService.selectCardBack(reward.id);
    }
  }

  @override
  State<RewardUnlockDialog> createState() => _RewardUnlockDialogState();
}

class _RewardUnlockDialogState extends State<RewardUnlockDialog>
    with TickerProviderStateMixin {
  // Entrée popup — scale + fade avec bounce élastique
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryFade;

  // Flottement lent de la carte
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatOffset;

  // Étoiles décoratives (légères, non néon)
  late final AnimationController _starsCtrl;

  late final Color _accent;

  @override
  void initState() {
    super.initState();
    _accent = _accentForId(widget.reward.id);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entryScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final maxH = (size.height - padding.vertical - 48) * 0.92;
    final maxW = math.min(size.width - 40.0, 340.0);

    return FadeTransition(
      opacity: _entryFade,
      child: Center(
        child: ScaleTransition(
          scale: _entryScale,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: Material(
              color: Colors.transparent,
              child: _DialogBody(
                reward: widget.reward,
                accent: _accent,
                floatOffset: _floatOffset,
                starsCtrl: _starsCtrl,
                onTryNow: widget.onTryNow,
                onLater: widget.onLater,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Corps de la dialog — séparé pour éviter rebuilds inutiles
// ─────────────────────────────────────────────────────────────────────────────

class _DialogBody extends StatelessWidget {
  const _DialogBody({
    required this.reward,
    required this.accent,
    required this.floatOffset,
    required this.starsCtrl,
    required this.onTryNow,
    required this.onLater,
  });

  final RewardUnlock reward;
  final Color accent;
  final Animation<double> floatOffset;
  final AnimationController starsCtrl;
  final VoidCallback onTryNow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background, // beige chaud — cohérent avec l'accueil
        borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
        boxShadow: AppShadows.dialog(accent),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Fond décoratif blob (même logique que ResultScreen) ─────────
          Positioned.fill(child: _BlobBackground(accent: accent)),

          // ── Étoiles décoratives légères ────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: starsCtrl,
                builder: (_, _) => CustomPaint(
                  painter: _StarsPainter(starsCtrl.value, accent),
                ),
              ),
            ),
          ),

          // ── Contenu principal ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge titre style sticker
                _StickerBadge(accent: accent, l10n: l10n),
                const SizedBox(height: AppSpacing.xl),

                // Carte flottante
                AnimatedBuilder(
                  animation: floatOffset,
                  builder: (_, _) => Transform.translate(
                    offset: Offset(0, floatOffset.value),
                    child: _CardDisplay(reward: reward, accent: accent),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Nom du dos
                Text(
                  reward.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),

                // Hint de déblocage
                if (reward.unlockHint != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    reward.unlockHint!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Bouton ESSAYER — style sticker orange cohérent avec PrimaryButton
                _TryButton(accent: accent, l10n: l10n, onPressed: onTryNow),
                const SizedBox(height: AppSpacing.xs),

                // Bouton Plus tard
                TextButton(
                  onPressed: () {
                    AudioService.instance.playButtonSound();
                    onLater();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                  ),
                  child: Text(
                    l10n.laterButton,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fond blob décoratif (même approche que ResultScreen._BackgroundPainter)
// ─────────────────────────────────────────────────────────────────────────────

class _BlobBackground extends StatelessWidget {
  const _BlobBackground({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BlobPainter(accent));
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Blob haut teinté accent
    final topPaint = Paint()
      ..color = accent.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final topPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
          size.width * 0.65, size.height * 0.18, size.width, size.height * 0.06)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // Blob bas-gauche beige foncé
    final botPaint = Paint()
      ..color = AppColors.orangeDark.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final botPath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
          size.width * 0.35, size.height * 0.78, size.width * 0.60, size.height)
      ..close();
    canvas.drawPath(botPath, botPaint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.accent != accent;
}

// ─────────────────────────────────────────────────────────────────────────────
// Étoiles décoratives légères (identique à ResultScreen._StickerPainter)
// ─────────────────────────────────────────────────────────────────────────────

class _StarsPainter extends CustomPainter {
  const _StarsPainter(this.t, this.accent);

  final double t;
  final Color accent;

  static const _stars = [
    [0.05, 0.08, 9.0, 1.0, 0.0],
    [0.90, 0.05, 7.0, 0.7, 0.4],
    [0.88, 0.30, 5.0, 1.3, 0.7],
    [0.04, 0.50, 6.0, 0.8, 0.2],
    [0.78, 0.85, 8.0, 1.1, 0.9],
    [0.18, 0.88, 5.5, 0.6, 0.5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final x = size.width * s[0];
      final y = size.height * s[1];
      final sz = s[2];
      final speed = s[3];
      final phase = s[4];
      final pulse = 0.5 + 0.5 * math.sin((t * speed + phase) * 2 * math.pi);
      _drawStar(canvas, Offset(x, y), sz * pulse,
          accent.withValues(alpha: 0.22 * pulse));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    const points = 4;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = (i % 2 == 0) ? 1.0 : 0.4;
      final x = center.dx + size * r * math.cos(angle);
      final y = center.dy + size * r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.t != t || old.accent != accent;
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge titre style sticker
// ─────────────────────────────────────────────────────────────────────────────

class _StickerBadge extends StatelessWidget {
  const _StickerBadge({required this.accent, required this.l10n});

  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.stickerWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: accent.withValues(alpha: 0.30),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨', style: TextStyle(fontSize: 14, color: accent)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            l10n.newCardBackUnlocked,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('✨', style: TextStyle(fontSize: 14, color: accent)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte avec glow accent
// ─────────────────────────────────────────────────────────────────────────────

class _CardDisplay extends StatelessWidget {
  const _CardDisplay({required this.reward, required this.accent});

  final RewardUnlock reward;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final assetPath = reward.assetPath ?? AppAssets.cardBackAsset(reward.id);

    return Container(
      width: 140,
      height: 196,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: AppShadows.accentGlowStrong(accent),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 2.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _CardPlaceholder(
          reward: reward,
          accent: accent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder si asset absent
// ─────────────────────────────────────────────────────────────────────────────

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({required this.reward, required this.accent});

  final RewardUnlock reward;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.25),
            accent.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_rounded, color: accent, size: 44),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reward.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouton ESSAYER — style sticker blanc + contour accent (cohérent avec accueil)
// ─────────────────────────────────────────────────────────────────────────────

/// Bouton ESSAYER — délègue à [OrangeButton] (style unifié bouton Jouer).
class _TryButton extends StatelessWidget {
  const _TryButton({
    required this.accent,
    required this.l10n,
    required this.onPressed,
  });

  // [accent] conservé pour compatibilité API ; OrangeButton utilise le dégradé standard.
  final Color accent;
  final AppLocalizations l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OrangeButton(
      label: l10n.tryButton,
      icon: Icons.style_rounded,
      onPressed: onPressed,
      height: AppSpacing.buttonHeightSecondary,
      fontSize: 15,
      letterSpacing: 1.5,
    );
  }
}

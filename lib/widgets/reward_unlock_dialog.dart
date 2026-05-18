import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/models/reward_unlock.dart';
import '../core/services/audio_service.dart';
import '../core/services/progression_service.dart';
import '../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Couleur accent par dos
// ─────────────────────────────────────────────────────────────────────────────

Color _accentForId(String id) => switch (id) {
      'blue'   => const Color(0xFF2196F3),
      'green'  => const Color(0xFF4CAF50),
      'pink'   => const Color(0xFFE91E8C),
      'yellow' => const Color(0xFFFFC107),
      _        => const Color(0xFFFF6D00), // purple / fallback
    };

// ─────────────────────────────────────────────────────────────────────────────
// Popup principale
// ─────────────────────────────────────────────────────────────────────────────

/// Popup plein écran affichée lors du déblocage d'un nouveau dos de carte.
///
/// Appeler via [RewardUnlockDialog.show] pour enchaîner plusieurs récompenses.
///
/// Bouton "Essayer"   → équipe immédiatement le dos et ferme la popup.
/// Bouton "Plus tard" → ferme la popup sans changer l'équipement.
///
/// Structure extensible : [RewardUnlock] peut recevoir de futurs types
/// (skin, badge, événement…) sans refactoriser cette popup.
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

  /// Affiche la popup et retourne `true` si "Essayer" a été choisi.
  static Future<bool> show(
    BuildContext context,
    RewardUnlock reward,
  ) async {
    AudioService.instance.playSfx(SoundEffect.popupRecompense);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (ctx) => RewardUnlockDialog(
        reward: reward,
        onTryNow: () => Navigator.of(ctx).pop(true),
        onLater:  () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  /// Affiche les popups en séquence et équipe immédiatement si "Essayer".
  static Future<void> showAll(
    BuildContext context,
    List<RewardUnlock> rewards,
  ) async {
    for (final reward in rewards) {
      if (!context.mounted) return;
      final tryNow = await show(context, reward);
      if (tryNow) {
        await ProgressionService.selectCardBack(reward.id);
      }
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

  // Glow pulsant de la carte
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // Particules décoratives
  late final AnimationController _particlesCtrl;

  late final Color _accent;

  @override
  void initState() {
    super.initState();
    _accent = _accentForId(widget.reward.id);

    // ── Entrée popup (500 ms, bounce élastique) ───────────────────────────
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    // ── Flottement carte (3 s, loop infini) ──────────────────────────────
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // ── Glow pulsant (2 s, loop infini) ──────────────────────────────────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // ── Particules (3 s, loop infini) ────────────────────────────────────
    _particlesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _particlesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Hauteur max safe : 90% de l'écran moins les insets (encoche, barre nav)
    final verticalInsets = MediaQuery.of(context).viewInsets.vertical +
        MediaQuery.of(context).padding.vertical;
    final maxDialogHeight = (size.height - verticalInsets) * 0.90;

    return FadeTransition(
      opacity: _entryFade,
      child: Center(
        child: ScaleTransition(
          scale: _entryScale,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(size.width - 40, 360),
              maxHeight: maxDialogHeight,
            ),
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Fond popup (s'étire au contenu via Positioned.fill) ─
                  Positioned.fill(
                    child: _PopupBackground(accent: _accent),
                  ),

                  // ── Particules décoratives ──────────────────────────────
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: AnimatedBuilder(
                        animation: _particlesCtrl,
                        builder: (_, w) => CustomPaint(
                          painter: _ParticlesPainter(
                            progress: _particlesCtrl.value,
                            color: _accent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Contenu ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge titre
                        _UnlockBadge(accent: _accent),
                        const SizedBox(height: 32),

                        // Carte flottante avec glow pulsant
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _floatCtrl,
                            _glowCtrl,
                          ]),
                          builder: (_, w) {
                            return Transform.translate(
                              offset: Offset(0, _floatOffset.value),
                              child: _CardDisplay(
                                reward: widget.reward,
                                accent: _accent,
                                glowStrength: _glowAnim.value,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // Nom du dos
                        Text(
                          widget.reward.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Hint de déblocage
                        if (widget.reward.unlockHint != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              widget.reward.unlockHint!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),

                        // Bouton Essayer
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              AudioService.instance.playButtonSound();
                              widget.onTryNow();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.style_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('ESSAYER'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Bouton Plus tard
                        TextButton(
                          onPressed: () {
                            AudioService.instance.playButtonSound();
                            widget.onLater();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                          ),
                          child: const Text(
                            'Plus tard',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fond de popup
// ─────────────────────────────────────────────────────────────────────────────

class _PopupBackground extends StatelessWidget {
  const _PopupBackground({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E38), Color(0xFF16162A)],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.20),
            blurRadius: 50,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge titre
// ─────────────────────────────────────────────────────────────────────────────

class _UnlockBadge extends StatelessWidget {
  const _UnlockBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NOUVEAU DOS DÉBLOQUÉ',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grande carte avec glow pulsant
// ─────────────────────────────────────────────────────────────────────────────

class _CardDisplay extends StatelessWidget {
  const _CardDisplay({
    required this.reward,
    required this.accent,
    required this.glowStrength,
  });

  final RewardUnlock reward;
  final Color accent;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    final assetPath = reward.assetPath ?? AppAssets.cardBackAsset(reward.id);

    return Container(
      width: 150,
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          // Halo pulsant extérieur
          BoxShadow(
            color: accent.withValues(alpha: 0.20 + glowStrength * 0.35),
            blurRadius: 40 + glowStrength * 20,
            spreadRadius: 4 + glowStrength * 6,
          ),
          // Glow rapproché
          BoxShadow(
            color: accent.withValues(alpha: 0.35 + glowStrength * 0.20),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          // Ombre de profondeur
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: accent.withValues(alpha: 0.5 + glowStrength * 0.4),
          width: 2.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, a, b) => _CardPlaceholder(
            reward: reward,
            accent: accent,
          ),
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
            accent.withValues(alpha: 0.30),
            accent.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_rounded, color: accent, size: 48),
            const SizedBox(height: 10),
            Text(
              reward.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particules décoratives (CustomPainter léger, déterministe)
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  // Positions et vitesses fixes (déterministes, sans Random)
  static const _particles = [
    (x: 0.15, y: 0.12, speed: 0.45, size: 2.5),
    (x: 0.85, y: 0.08, speed: 0.30, size: 2.0),
    (x: 0.05, y: 0.55, speed: 0.60, size: 1.8),
    (x: 0.90, y: 0.40, speed: 0.50, size: 2.2),
    (x: 0.25, y: 0.85, speed: 0.35, size: 1.5),
    (x: 0.72, y: 0.80, speed: 0.55, size: 2.8),
    (x: 0.50, y: 0.06, speed: 0.40, size: 1.6),
    (x: 0.10, y: 0.78, speed: 0.65, size: 2.0),
    (x: 0.80, y: 0.65, speed: 0.28, size: 1.4),
    (x: 0.40, y: 0.92, speed: 0.48, size: 2.3),
    (x: 0.60, y: 0.15, speed: 0.38, size: 1.9),
    (x: 0.20, y: 0.35, speed: 0.55, size: 1.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      // Phase décalée par vitesse → mouvement indépendant entre particules
      final phase = (progress * p.speed) % 1.0;
      final alpha = math.sin(phase * math.pi); // fade in → out

      if (alpha <= 0.01) continue;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha * 0.50)
        ..style = PaintingStyle.fill;

      // Déplacement vertical vers le haut
      final dy = ((p.y - phase * 0.5) % 1.0).abs();

      canvas.drawCircle(
        Offset(p.x * size.width, dy * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) =>
      old.progress != progress || old.color != color;
}

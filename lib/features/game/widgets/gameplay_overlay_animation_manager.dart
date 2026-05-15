import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modèle d'animation
// ─────────────────────────────────────────────────────────────────────────────

enum OverlayAnimationType {
  /// Trajectoire standard : start → end (food gain, fridge, bandit steal).
  travelTo,

  /// Raton laveur : la particule est aspirée depuis [start] vers [end].
  /// Utilise une courbe "easeInExpo" pour l'effet magnétique.
  raccoonDevour,
}

class GameplayOverlayAnimation {
  final int id;
  final String emoji;
  final Offset start;
  final Offset end;
  final Duration duration;
  final double beginScale;
  final double endScale;
  final OverlayAnimationType type;

  /// Délai avant le démarrage (utilisé pour décaler les particules raton).
  final Duration delay;

  const GameplayOverlayAnimation({
    required this.id,
    required this.emoji,
    required this.start,
    required this.end,
    required this.duration,
    this.beginScale = 2.2,
    this.endScale = 0.7,
    this.type = OverlayAnimationType.travelTo,
    this.delay = Duration.zero,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Manager — écoute un ValueNotifier<List> pour éviter tout setState externe
// ─────────────────────────────────────────────────────────────────────────────

class GameplayOverlayAnimationManager extends StatelessWidget {
  const GameplayOverlayAnimationManager({
    super.key,
    required this.animationsNotifier,
  });

  final ValueNotifier<List<GameplayOverlayAnimation>> animationsNotifier;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<List<GameplayOverlayAnimation>>(
        valueListenable: animationsNotifier,
        builder: (context, animations, _) {
          return Stack(
            children: animations
                .map(
                  (animation) => _AnimatedOverlayItem(
                    key: ValueKey(animation.id),
                    animation: animation,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item animé — gère les deux types de trajectoire
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedOverlayItem extends StatefulWidget {
  const _AnimatedOverlayItem({
    super.key,
    required this.animation,
  });

  final GameplayOverlayAnimation animation;

  @override
  State<_AnimatedOverlayItem> createState() => _AnimatedOverlayItemState();
}

class _AnimatedOverlayItemState extends State<_AnimatedOverlayItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animation.duration,
    );

    if (widget.animation.delay == Duration.zero) {
      _controller.forward();
      _started = true;
    } else {
      Future<void>.delayed(widget.animation.delay, () {
        if (!mounted) return;
        // setState local à _AnimatedOverlayItem uniquement — pas de rebuild GameScreen
        setState(() => _started = true);
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        double dx;
        double dy;
        double scale;
        double opacity;

        switch (widget.animation.type) {
          case OverlayAnimationType.travelTo:
            final curved = Curves.easeOutCubic.transform(t);
            dx = widget.animation.start.dx +
                ((widget.animation.end.dx - widget.animation.start.dx) *
                    curved);
            dy = widget.animation.start.dy +
                ((widget.animation.end.dy - widget.animation.start.dy) *
                    curved);
            scale = widget.animation.beginScale +
                ((widget.animation.endScale - widget.animation.beginScale) *
                    curved);
            opacity = 1.0 - (t * 0.15);

          case OverlayAnimationType.raccoonDevour:
            // Phase 1 (0→0.55) : légère dérive/flottement
            // Phase 2 (0.55→1.0) : aspiration magnétique rapide vers la carte
            const double phase1End = 0.55;
            if (t < phase1End) {
              final p = t / phase1End;
              final curved = Curves.easeOut.transform(p);
              dx = widget.animation.start.dx +
                  (widget.animation.end.dx - widget.animation.start.dx) *
                      curved *
                      0.12;
              dy = widget.animation.start.dy -
                  math.sin(curved * math.pi) * 18;
              scale = widget.animation.beginScale -
                  (widget.animation.beginScale - 1.3) * curved;
              opacity = 1.0;
            } else {
              final p = (t - phase1End) / (1.0 - phase1End);
              final curved = Curves.easeInExpo.transform(p);
              dx = widget.animation.start.dx +
                  ((widget.animation.end.dx - widget.animation.start.dx) *
                      (0.12 + 0.88 * curved));
              dy = widget.animation.start.dy -
                  math.sin((1.0 - p) * math.pi) * 18 +
                  ((widget.animation.end.dy - widget.animation.start.dy) *
                      curved);
              scale = 1.3 - (1.3 - 0.2) * curved;
              opacity = 1.0 - curved * 0.95;
            }
        }

        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Text(
          widget.animation.emoji,
          style: const TextStyle(fontSize: 42),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coordinator — façade publique pour déclencher les animations
// ─────────────────────────────────────────────────────────────────────────────

/// Émojis nourriture variés pour l'animation raton laveur.
const List<String> _foodEmojis = ['🍎', '🥕', '🍗', '🧀', '🍞'];

class GameplayOverlayCoordinator {
  GameplayOverlayCoordinator(this.animationsNotifier);

  /// Le notifier partagé avec [GameplayOverlayAnimationManager].
  /// Les modifications ici ne déclenchent pas de rebuild du GameScreen.
  final ValueNotifier<List<GameplayOverlayAnimation>> animationsNotifier;

  int _counter = 0;
  final _rng = math.Random();

  // ── Animations existantes ─────────────────────────────────────────────────

  void playFoodGain({
    required Offset start,
    required Offset end,
  }) {
    _add(
      emoji: '🍎',
      start: start,
      end: end,
    );
  }

  void playFridgeDeposit({
    required Offset start,
    required Offset end,
  }) {
    _add(
      emoji: '🧊',
      start: start,
      end: end,
    );
  }

  /// Animation Bandit : une pomme vole de la cible vers le joueur actif.
  void playFoodSteal({
    required Offset fromTarget,
    required Offset toThief,
  }) {
    _add(
      emoji: '🍎',
      start: fromTarget,
      end: toThief,
      duration: const Duration(milliseconds: 750),
      beginScale: 1.6,
      endScale: 1.0,
    );
  }

  // ── Animation Raton laveur ────────────────────────────────────────────────

  /// Aspire [foodCount] particules nourriture depuis [playerCenter]
  /// vers [cardCenter] (la carte révélée), avec décalages aléatoires.
  ///
  /// Purement visuel : la logique de suppression est déjà appliquée.
  /// [foodCount] est cappé à 8 pour les performances mobiles.
  void playRaccoonDevour({
    required Offset playerCenter,
    required Offset cardCenter,
    required int foodCount,
  }) {
    final count = foodCount.clamp(1, 8);

    for (int i = 0; i < count; i++) {
      final offsetX = (_rng.nextDouble() - 0.5) * 80;
      final offsetY = (_rng.nextDouble() - 0.5) * 80;
      final particleStart = Offset(
        playerCenter.dx + offsetX,
        playerCenter.dy + offsetY,
      );

      final emoji = _foodEmojis[i % _foodEmojis.length];
      final delay = Duration(milliseconds: i * 65);

      _addRaw(GameplayOverlayAnimation(
        id: _counter++,
        emoji: emoji,
        start: particleStart,
        end: cardCenter,
        duration: const Duration(milliseconds: 950),
        beginScale: 1.8,
        endScale: 0.2,
        type: OverlayAnimationType.raccoonDevour,
        delay: delay,
      ));
    }
  }

  // ── Slot futur : effets spéciaux rares ───────────────────────────────────

  /// Réservé pour : récompenses, déblocages, cartes rares, pub récompensée.
  /// Signature stable — implémenter le corps quand nécessaire.
  // ignore: unused_element
  void _playSpecialEffect({
    required String emoji,
    required Offset origin,
    required Offset target,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    _add(
      emoji: emoji,
      start: origin,
      end: target,
      duration: duration,
      beginScale: 3.0,
      endScale: 0.5,
    );
  }

  // ── Interne ───────────────────────────────────────────────────────────────

  void _add({
    required String emoji,
    required Offset start,
    required Offset end,
    Duration duration = const Duration(milliseconds: 650),
    double beginScale = 2.2,
    double endScale = 0.7,
    OverlayAnimationType type = OverlayAnimationType.travelTo,
    Duration delay = Duration.zero,
  }) {
    _addRaw(GameplayOverlayAnimation(
      id: _counter++,
      emoji: emoji,
      start: start,
      end: end,
      duration: duration,
      beginScale: beginScale,
      endScale: endScale,
      type: type,
      delay: delay,
    ));
  }

  /// Ajoute une animation dans le notifier et planifie sa suppression.
  /// Aucun setState du GameScreen n'est déclenché.
  void _addRaw(GameplayOverlayAnimation animation) {
    final current = List<GameplayOverlayAnimation>.from(animationsNotifier.value);
    current.add(animation);
    animationsNotifier.value = current;

    Future<void>.delayed(animation.duration + animation.delay, () {
      final updated = List<GameplayOverlayAnimation>.from(animationsNotifier.value);
      updated.removeWhere((item) => item.id == animation.id);
      animationsNotifier.value = updated;
    });
  }
}

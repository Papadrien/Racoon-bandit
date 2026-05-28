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

  /// Impact frigo : explosion de particules depuis [start] (pas de [end]).
  /// Utilisé quand un frigo bloque un raton.
  fridgeImpact,
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

  /// Angle de direction en radians (utilisé pour fridgeImpact burst).
  final double angle;

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
    this.angle = 0.0,
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
    // RepaintBoundary global : les particules ne déclenchent JAMAIS
    // un repaint du reste du jeu (fond, joueurs, pioche).
    return RepaintBoundary(
      child: IgnorePointer(
        child: ValueListenableBuilder<List<GameplayOverlayAnimation>>(
          valueListenable: animationsNotifier,
          builder: (context, animations, _) {
            return SizedBox.expand(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: animations
                    .map(
                      (animation) => _AnimatedOverlayItem(
                        key: ValueKey(animation.id),
                        animation: animation,
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item animé — isolé dans son propre RepaintBoundary
// IMPORTANT : aucun setState utilisé — le délai est géré via CurvedAnimation
// avec un Interval, ce qui évite tout rebuild de l'arbre parent.
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

  /// Durée totale incluant le délai initial.
  late final Duration _totalDuration;

  /// Fraction [0..1] représentant la fin du délai dans la durée totale.
  late final double _delayFraction;

  @override
  void initState() {
    super.initState();

    final delay = widget.animation.delay;
    final anim = widget.animation.duration;
    _totalDuration = delay + anim;

    _delayFraction = _totalDuration.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / _totalDuration.inMicroseconds;

    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    // Démarrage immédiat — pas de setState, pas de Future.delayed.
    // Le délai est absorbé dans l'Interval ci-dessous.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildParticleChild(String emoji) {
    if (emoji == '__food__' || emoji == '__trash__') {
      final asset = emoji == '__food__'
          ? 'assets/images/icon_food.png'
          : 'assets/images/icon_trash.png';
      return Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: Image.asset(asset, fit: BoxFit.contain),
      );
    }
    return Text(emoji, style: const TextStyle(fontSize: 42));
  }

  @override
  Widget build(BuildContext context) {
    // Intervalle actif : [_delayFraction .. 1.0]
    // Pendant la phase délai, t=0 → opacity=0, widget invisible mais MONTÉ.
    // Aucun setState, aucun rebuild externe.
    final activeInterval = CurvedAnimation(
      parent: _controller,
      curve: Interval(_delayFraction, 1.0, curve: Curves.linear),
    );

    // RepaintBoundary par particule : chaque particule repeint indépendamment.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: activeInterval,
        builder: (context, child) {
          final t = activeInterval.value; // [0..1] pendant la phase active

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
              // Invisible pendant la phase délai (t == 0 avant interval actif)
              opacity = t == 0.0 ? 0.0 : (1.0 - (t * 0.15));

            case OverlayAnimationType.raccoonDevour:
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
                opacity = t == 0.0 ? 0.0 : 1.0;
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

            case OverlayAnimationType.fridgeImpact:
              // Burst radial depuis [start] dans la direction [angle].
              // Phase 1 (0→0.4) : jaillissement rapide vers l'extérieur.
              // Phase 2 (0.4→1) : ralentissement + fondu.
              const double burstRadius = 55.0;
              final curved = Curves.easeOut.transform(t);
              final dist = curved * burstRadius;
              dx = widget.animation.start.dx +
                  math.cos(widget.animation.angle) * dist;
              dy = widget.animation.start.dy +
                  math.sin(widget.animation.angle) * dist;
              scale = widget.animation.beginScale *
                  (1.0 - Curves.easeIn.transform(t) * 0.6);
              opacity = t == 0.0
                  ? 0.0
                  : (t < 0.35 ? 1.0 : (1.0 - (t - 0.35) / 0.65))
                      .clamp(0.0, 1.0);
          }

          return Positioned.fill(
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(dx - 36, dy - 36),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(child: _buildParticleChild(widget.animation.emoji)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coordinator — façade publique pour déclencher les animations
// ─────────────────────────────────────────────────────────────────────────────

/// Token nourriture pour l'animation raton laveur (utilise icon_food.png).
const List<String> _foodEmojis = ['__food__', '__food__', '__food__', '__food__', '__food__'];

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
      emoji: '__food__',
      start: start,
      end: end,
    );
  }

  void playFridgeDeposit({
    required Offset start,
    required Offset end,
  }) {
    _add(
      emoji: '__trash__',
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
      emoji: '__food__',
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

  // ── Animation Frigo bloque Raton ─────────────────────────────────────────

  /// Burst de particules ❄️ autour du frigo : 6 particules radiales rapides
  /// (200–400 ms), sans bloquer l'UI.
  void playFridgeImpact({required Offset center}) {
    const int count = 6;
    const List<String> emojis = ['💥', '✨', '💥', '✨', '💥', '✨'];
    for (int i = 0; i < count; i++) {
      final angle = (2 * math.pi / count) * i;
      _addRaw(GameplayOverlayAnimation(
        id: _counter++,
        emoji: emojis[i % emojis.length],
        start: center,
        end: center, // non utilisé pour fridgeImpact
        duration: const Duration(milliseconds: 420),
        beginScale: 1.6,
        endScale: 0.3,
        type: OverlayAnimationType.fridgeImpact,
        delay: Duration(milliseconds: i * 18),
        angle: angle,
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
  ///
  /// Les deux opérations (ajout + suppression différée) sont protégées par
  /// un try/catch : si le notifier est disposé avant la fin du délai
  /// (widget détruit pendant une animation), l'erreur est silencieusement ignorée.
  void _addRaw(GameplayOverlayAnimation animation) {
    try {
      final current = List<GameplayOverlayAnimation>.from(animationsNotifier.value);
      current.add(animation);
      animationsNotifier.value = current;
    } catch (_) {
      // notifier déjà disposé — abandon silencieux
      return;
    }

    // Suppression après durée totale (délai déjà intégré dans _totalDuration)
    final totalDuration = animation.duration + animation.delay;
    Future<void>.delayed(totalDuration, () {
      try {
        final updated = List<GameplayOverlayAnimation>.from(animationsNotifier.value);
        updated.removeWhere((item) => item.id == animation.id);
        animationsNotifier.value = updated;
      } catch (_) {
        // notifier disposé entre temps — ignoré
      }
    });
  }
}

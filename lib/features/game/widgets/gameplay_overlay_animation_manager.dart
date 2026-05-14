import 'package:flutter/material.dart';

class GameplayOverlayAnimation {
  final int id;
  final String emoji;
  final Offset start;
  final Offset end;
  final Duration duration;
  final double beginScale;
  final double endScale;

  const GameplayOverlayAnimation({
    required this.id,
    required this.emoji,
    required this.start,
    required this.end,
    required this.duration,
    this.beginScale = 2.2,
    this.endScale = 0.7,
  });
}

class GameplayOverlayAnimationManager extends StatefulWidget {
  const GameplayOverlayAnimationManager({
    super.key,
    required this.animations,
  });

  final List<GameplayOverlayAnimation> animations;

  @override
  State<GameplayOverlayAnimationManager> createState() =>
      _GameplayOverlayAnimationManagerState();
}

class _GameplayOverlayAnimationManagerState
    extends State<GameplayOverlayAnimationManager> {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: widget.animations
            .map(
              (animation) => _AnimatedOverlayItem(
                key: ValueKey(animation.id),
                animation: animation,
              ),
            )
            .toList(),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animation.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curved = Curves.easeOutCubic.transform(_controller.value);
        final dx = widget.animation.start.dx +
            ((widget.animation.end.dx - widget.animation.start.dx) * curved);
        final dy = widget.animation.start.dy +
            ((widget.animation.end.dy - widget.animation.start.dy) * curved);

        final scale = widget.animation.beginScale +
            ((widget.animation.endScale - widget.animation.beginScale) *
                curved);

        final opacity = 1 - (_controller.value * 0.15);

        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: opacity,
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

class GameplayOverlayCoordinator {
  GameplayOverlayCoordinator(this.onAnimationAdded);

  final void Function(GameplayOverlayAnimation animation)
      onAnimationAdded;

  int _counter = 0;

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

  void _add({
    required String emoji,
    required Offset start,
    required Offset end,
    Duration duration = const Duration(milliseconds: 650),
    double beginScale = 2.2,
    double endScale = 0.7,
  }) {
    onAnimationAdded(
      GameplayOverlayAnimation(
        id: _counter++,
        emoji: emoji,
        start: start,
        end: end,
        duration: duration,
        beginScale: beginScale,
        endScale: endScale,
      ),
    );
  }
}

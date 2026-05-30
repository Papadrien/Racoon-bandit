import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/ui/app_spacing.dart';
import '../features/onboarding/onboarding_slide.dart';
import 'primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TutorialDotsIndicator
// ─────────────────────────────────────────────────────────────────────────────

/// Indicateur de pagination — points animés style onboarding.
class TutorialDotsIndicator extends StatelessWidget {
  const TutorialDotsIndicator({
    super.key,
    required this.count,
    required this.current,
    this.activeColor = const Color(0xFF6C2BFF),
    this.inactiveColor = const Color(0xFFE7CDB8),
  });

  final int count;
  final int current;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = current == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 30 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TutorialNextButton — alias vers OrangeButton (style unifié).
// ─────────────────────────────────────────────────────────────────────────────

/// Bouton de navigation tutoriel — délègue à [OrangeButton].
class TutorialNextButton extends StatelessWidget {
  const TutorialNextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = AppSpacing.buttonHeight,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return OrangeButton(
      label: label,
      onPressed: onPressed,
      height: height,
      fontSize: 20,
      letterSpacing: 1.5,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TutorialSlideCard
// ─────────────────────────────────────────────────────────────────────────────

/// Card de slide partagée — image + texte, style onboarding (fond crème).
///
/// Si [slide.cardImageAsset] est non-null, affiche l'image ; sinon l'emoji.
class TutorialSlideCard extends StatelessWidget {
  const TutorialSlideCard({
    super.key,
    required this.slide,
    required this.index,
  });

  final OnboardingSlide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 760;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: (index.isEven ? -1 : 1) * 0.03,
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: slide.accentColor.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: slide.iconWidget != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: compact ? 180 : 220,
                        height: compact ? 180 : 220,
                        child: Center(child: slide.iconWidget),
                      ),
                    )
                  : slide.cardImageAsset != null
                      ? Container(
                          width: compact ? 180 : 220,
                          height: compact ? 180 : 220,
                          decoration: BoxDecoration(
                            color: slide.cardFrontColor ?? const Color(0xFF78909C),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                slide.cardImageAsset!,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        )
                      : _EmojiDisplay(
                          emoji: slide.emoji,
                          compact: compact,
                          accentColor: slide.accentColor,
                        ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF8),
              borderRadius: BorderRadius.circular(38),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slide.title(context),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 22 : 26,
                    fontWeight: FontWeight.w900,
                    color: slide.accentColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A00),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.description(context),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                    color: const Color(0xFF2B2B2B),
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

/// Affichage emoji dans un cercle coloré pour slides sans image.
class _EmojiDisplay extends StatelessWidget {
  const _EmojiDisplay({
    required this.emoji,
    required this.compact,
    required this.accentColor,
  });

  final String emoji;
  final bool compact;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final emojiSize = compact ? 48.0 : 60.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: compact ? 180.0 : 220.0,
        height: compact ? 180.0 : 220.0,
        color: accentColor.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TutorialBackgroundDecorations
// ─────────────────────────────────────────────────────────────────────────────

/// Stickers décoratifs de fond — identiques dans onboarding et tutoriel chaos.
class TutorialBackgroundDecorations extends StatelessWidget {
  const TutorialBackgroundDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          _sticker('assets/images/sticker_pine_tree.png', 30, 140, 90),
          _sticker('assets/images/sticker_pine_cone.png', null, 300, 56,
              right: 40),
          _sticker('assets/images/sticker_cabin.png', 22, null, 92,
              bottom: 160),
          _sticker('assets/images/sticker_pine_tree.png', null, null, 100,
              right: 12, bottom: 210),
          Positioned(
            top: 100,
            left: -40,
            child: Transform.rotate(
              angle: -math.pi / 8,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFCFA8).withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sticker(
    String asset,
    double? left,
    double? top,
    double size, {
    double? right,
    double? bottom,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Image.asset(asset, width: size),
    );
  }
}

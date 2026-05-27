import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/ui/app_spacing.dart';
import 'onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  final List<OnboardingSlide> _slides = OnboardingSlides.all;

  int _currentIndex = 0;

  bool get _isLast => _currentIndex == _slides.length - 1;

  Future<void> _complete() async {
    HapticService.trigger(HapticType.selection);
    AudioService.instance.playSfx(SoundEffect.button);
    await OnboardingService.markCompleted();
    widget.onDone();
  }

  void _nextPage() {
    HapticService.trigger(HapticType.selection);
    AudioService.instance.playSfx(SoundEffect.button);

    if (_isLast) {
      _complete();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4D9C1),
      body: SafeArea(
        child: Stack(
          children: [
            const _BackgroundDecorations(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'ASTUCE ${_currentIndex + 1}/${_slides.length}',
                          style: const TextStyle(
                            color: Color(0xFF6C2BFF),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _complete,
                        child: Text(
                          AppLocalizations.of(context)!.onboardingSkip,
                          style: const TextStyle(
                            color: Color(0xFF2B2B2B),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (value) {
                      setState(() => _currentIndex = value);
                    },
                    itemBuilder: (_, index) {
                      return _TutorialPage(
                        slide: _slides[index],
                        index: index,
                      );
                    },
                  ),
                ),
                _DotsIndicator(
                  count: _slides.length,
                  current: _currentIndex,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF962E), Color(0xFFFF6B00)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x44FF6B00),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _isLast ? 'COMMENCER' : 'SUIVANT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.slide, required this.index});

  final OnboardingSlide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.height < 760;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  slide.cardImageAsset ?? '',
                  height: compact ? 260 : 320,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
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
              children: [
                Text(
                  slide.title(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 42 : 48,
                    fontWeight: FontWeight.w900,
                    color: slide.accentColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 74,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A00),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  slide.description(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2B2B2B),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

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

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});

  final int count;
  final int current;

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
            color: active
                ? const Color(0xFF6C2BFF)
                : const Color(0xFFE7CDB8),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
        );
      }),
    );
  }
}

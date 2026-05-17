import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_slide.dart';

/// Écran d'onboarding — affiché uniquement au premier lancement.
///
/// Navigation : Suivant / Passer / Terminer.
/// Skippable à tout moment.
/// Responsive petits et grands écrans Android.
class OnboardingScreen extends StatefulWidget {
  /// Callback appelé quand l'onboarding est terminé ou skippé.
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlide> _slides = OnboardingSlides.all;

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
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // ── Bouton Passer ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: AnimatedOpacity(
                  opacity: _isLast ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _isLast ? null : _complete,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Slides ─────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) =>
                    _SlideCard(slide: _slides[index]),
              ),
            ),

            // ── Indicateurs de progression ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _DotsIndicator(
                count: _slides.length,
                current: _currentIndex,
                activeColor: AppTheme.primary,
              ),
            ),

            // ── Boutons de navigation ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _NavigationButtons(
                isLast: _isLast,
                onNext: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SlideCard
// ─────────────────────────────────────────────────────────────────────────────

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Adaptation responsive : emoji plus petit sur petits écrans
    final emojiSize = screenHeight < 650 ? 72.0 : 96.0;
    final titleSize = screenHeight < 650 ? 22.0 : 26.0;
    final descSize  = screenHeight < 650 ? 14.0 : 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: slide.cardColor.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: slide.accentColor.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: slide.accentColor.withOpacity(0.15),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji
              Text(
                slide.emoji,
                style: TextStyle(fontSize: emojiSize),
              ),
              const SizedBox(height: 28),
              // Titre
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: slide.accentColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: descSize,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DotsIndicator
// ─────────────────────────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.activeColor,
  });

  final int count;
  final int current;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NavigationButtons
// ─────────────────────────────────────────────────────────────────────────────

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({
    required this.isLast,
    required this.onNext,
  });

  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: AppTheme.primary.withOpacity(0.4),
        ),
        child: Text(
          isLast ? 'C\'est parti ! 🎮' : 'Suivant',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

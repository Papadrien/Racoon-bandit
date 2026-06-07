import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../widgets/tutorial_widgets.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4D9C1),
      body: SafeArea(
        child: Stack(
          children: [
            const TutorialBackgroundDecorations(),
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
                          l10n.onboardingSkip,
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
                      return TutorialSlideCard(
                        slide: _slides[index],
                        index: index,
                      );
                    },
                  ),
                ),
                TutorialDotsIndicator(
                  count: _slides.length,
                  current: _currentIndex,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                  child: TutorialNextButton(
                    label: _isLast ? 'COMMENCER' : 'SUIVANT',
                    onPressed: _nextPage,
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

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_decorations.dart';
import '../../core/ui/app_shadows.dart';
import '../../core/ui/app_spacing.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';
import 'onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
        curve: Curves.easeOutCubic,
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
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 360
        ? AppSpacing.hPadNarrow
        : AppSpacing.hPadNormal;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withValues(alpha: 0.16),
              const Color(0xFF121212),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.lg,
                  horizontalPadding,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: AppDecorations.floatingButton(),
                        child: Text(
                          AppLocalizations.of(context)!.onboardingSkip,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AnimatedOpacity(
                      opacity: _isLast ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: _isLast ? null : _complete,
                        child: Text(
                          AppLocalizations.of(context)!.onboardingSkip,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
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
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (_, index) => _SlideCard(
                    slide: _slides[index],
                    index: index,
                    total: _slides.length,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: _DotsIndicator(
                  count: _slides.length,
                  current: _currentIndex,
                  activeColor: AppTheme.primary,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  AppSpacing.xl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeightSecondary,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                      ),
                    ).copyWith(
                      shadowColor: WidgetStatePropertyAll(
                        AppTheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _isLast ? 'GO !' : 'SUIVANT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({
    required this.slide,
    required this.index,
    required this.total,
  });

  final OnboardingSlide slide;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  slide.cardColor,
                  slide.cardColor.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                ...AppShadows.sticker,
                ...AppShadows.subtleGlow(slide.accentColor),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                      ),
                      child: Text(
                        'ASTUCE ${index + 1}/$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 18 : 26),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: AppShadows.floating,
                    ),
                    child: slide.cardImageAsset != null
                        ? Image.asset(
                            slide.cardImageAsset!,
                            height: isCompact ? 130 : 160,
                            fit: BoxFit.contain,
                          )
                        : Text(
                            slide.emoji,
                            style: TextStyle(
                              fontSize: isCompact ? 70 : 92,
                            ),
                          ),
                  ),
                  SizedBox(height: isCompact ? 18 : 26),
                  Text(
                    slide.title(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 24 : 28,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 72,
                    height: 6,
                    decoration: BoxDecoration(
                      color: slide.accentColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 22),
                  Text(
                    slide.description(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: isCompact ? 15 : 17,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        final active = current == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.white24,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

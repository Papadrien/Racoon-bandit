import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/ui/app_spacing.dart';
import '../../widgets/tutorial_widgets.dart';
import '../onboarding/onboarding_slide.dart';

/// Slides du tutoriel Mode Pagaille.
class ChaosTutorialSlides {
  ChaosTutorialSlides._();

  static List<OnboardingSlide> build(AppLocalizations l10n) => [
        OnboardingSlide(
          emoji: '🌀',
          title: (_) => l10n.chaosSlide1Title,
          description: (_) => l10n.chaosSlide1Desc,
          cardColor: const Color(0xFF2A1F3D),
          accentColor: const Color(0xFFCE93D8),
        ),
        OnboardingSlide(
          emoji: '🍎',
          title: (_) => l10n.chaosSlide2Title,
          description: (_) => l10n.chaosSlide2Desc,
          cardColor: const Color(0xFF1B3A1B),
          accentColor: const Color(0xFF81C784),
        ),
        OnboardingSlide(
          emoji: '🦝',
          title: (_) => l10n.chaosSlide3Title,
          description: (_) => l10n.chaosSlide3Desc,
          cardColor: const Color(0xFF37474F),
          accentColor: const Color(0xFF90A4AE),
        ),
        OnboardingSlide(
          emoji: '🌀',
          title: (_) => l10n.chaosSlide4Title,
          description: (_) => l10n.chaosSlide4Desc,
          cardColor: const Color(0xFF1A0D2E),
          accentColor: const Color(0xFF7C4DFF),
        ),
        OnboardingSlide(
          emoji: '🎲',
          title: (_) => l10n.chaosSlide5Title,
          description: (_) => l10n.chaosSlide5Desc,
          cardColor: const Color(0xFF1A1A2E),
          accentColor: const Color(0xFFFF9800),
        ),
      ];
}

/// Tutoriel Mode Pagaille — même UX que l'onboarding principal.
///
/// Peut s'ouvrir via [ChaosTutorial.show].
class ChaosTutorial extends StatefulWidget {
  const ChaosTutorial({super.key});

  /// Ouvre le tutoriel dans une bottom sheet plein écran.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (_) => const ChaosTutorial(),
    );
  }

  @override
  State<ChaosTutorial> createState() => _ChaosTutorialState();
}

class _ChaosTutorialState extends State<ChaosTutorial> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late List<OnboardingSlide> _slides;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slides = ChaosTutorialSlides.build(AppLocalizations.of(context)!);
  }

  bool get _isLast => _currentIndex == _slides.length - 1;

  void _nextPage() {
    HapticService.trigger(HapticType.selection);
    AudioService.instance.playSfx(SoundEffect.button);
    if (_isLast) {
      Navigator.of(context).pop();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
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
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFFF4D9C1),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            // ── Stickers décoratifs ───────────────────────────────────────
            const ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXLarge),
              ),
              child: TutorialBackgroundDecorations(),
            ),

            // ── Contenu ───────────────────────────────────────────────────
            Column(
              children: [
                // ── Handle + bouton fermer ────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.only(top: 12, left: 16, right: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B2B2B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedOpacity(
                          opacity: _isLast ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: _isLast
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              l10n.chaosTutorialClose,
                              style: const TextStyle(
                                color: Color(0xFF2B2B2B),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Titre + compteur ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        '${l10n.chaosTutorialSheetTitle}  ${_currentIndex + 1}/${_slides.length}',
                        style: const TextStyle(
                          color: Color(0xFF6C2BFF),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Slides ────────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) => TutorialSlideCard(
                      slide: _slides[index],
                      index: index,
                    ),
                  ),
                ),

                // ── Indicateurs ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TutorialDotsIndicator(
                    count: _slides.length,
                    current: _currentIndex,
                  ),
                ),

                // ── Bouton navigation ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: TutorialNextButton(
                    label: _isLast
                        ? l10n.chaosTutorialDone.toUpperCase()
                        : l10n.chaosTutorialNext.toUpperCase(),
                    onPressed: _nextPage,
                    height: 62,
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

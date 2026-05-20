import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/onboarding_slide.dart';

/// Slides du tutoriel Mode Pagaille.
///
/// Même structure que [OnboardingSlides] — facile à étendre.
class ChaosTutorialSlides {
  ChaosTutorialSlides._();

  static const List<OnboardingSlide> all = [
    OnboardingSlide(
      emoji: '🌀',
      title: 'Mode Pagaille',
      description:
          'Des cartes spéciales s\'ajoutent au paquet.\nPlus de surprises, plus de chaos !',
      cardColor: Color(0xFF2A1F3D),
      accentColor: Color(0xFFCE93D8),
    ),
    OnboardingSlide(
      emoji: '🍎',
      title: 'Banquet',
      description:
          'Tu pioches cette carte ? Tu gagnes 2 nourritures d\'un coup.\nBonne pioche !',
      cardColor: Color(0xFF1B3A1B),
      accentColor: Color(0xFF81C784),
    ),
    OnboardingSlide(
      emoji: '🦝',
      title: 'Bébé Raton',
      description:
          'Un petit raton affamé te vole 2 nourritures.\nMoins dangereux que son grand frère, mais ça fait mal.',
      cardColor: Color(0xFF37474F),
      accentColor: Color(0xFF90A4AE),
    ),
    OnboardingSlide(
      emoji: '🌀',
      title: 'Aspirateur',
      description:
          'Cette carte vole 1 nourriture à CHAQUE joueur.\nLe chaos absolu !',
      cardColor: Color(0xFF1A0D2E),
      accentColor: Color(0xFF7C4DFF),
    ),
    OnboardingSlide(
      emoji: '🎲',
      title: 'Prêt pour le chaos ?',
      description:
          'Ce mode est plus imprévisible.\nRigolo en famille, surprenant à chaque partie !',
      cardColor: Color(0xFF1A1A2E),
      accentColor: Color(0xFFFF9800),
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

  final List<OnboardingSlide> _slides = ChaosTutorialSlides.all;

  bool get _isLast => _currentIndex == _slides.length - 1;

  void _nextPage() {
    HapticService.trigger(HapticType.selection);
    AudioService.instance.playSfx(SoundEffect.button);
    if (_isLast) {
      Navigator.of(context).pop();
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // ── Handle + bouton fermer ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      opacity: _isLast ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: _isLast ? null : () => Navigator.of(context).pop(),
                        child: Text(
                          'Fermer',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Titre de la bottom sheet ───────────────────────────────────
            Text(
              'TUTORIEL MODE PAGAILLE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),

            const SizedBox(height: 8),

            // ── Slides ─────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) =>
                    _ChaosTutorialSlideCard(slide: _slides[index]),
              ),
            ),

            // ── Indicateurs ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _DotsIndicator(
                count: _slides.length,
                current: _currentIndex,
                activeColor: AppTheme.primary,
              ),
            ),

            // ── Bouton navigation ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    _isLast ? 'C\'est parti !' : 'Suivant',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChaosTutorialSlideCard
// ─────────────────────────────────────────────────────────────────────────────

class _ChaosTutorialSlideCard extends StatelessWidget {
  const _ChaosTutorialSlideCard({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final emojiSize = screenHeight < 650 ? 64.0 : 80.0;
    final titleSize = screenHeight < 650 ? 20.0 : 24.0;
    final descSize = screenHeight < 650 ? 13.0 : 15.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: slide.cardColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: slide.accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: slide.accentColor.withValues(alpha: 0.18),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slide.emoji,
                style: TextStyle(fontSize: emojiSize),
              ),
              SizedBox(height: screenHeight < 650 ? 16 : 24),
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
              const SizedBox(height: 12),
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: descSize,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.55,
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
// _DotsIndicator (local copy — même logique que l'onboarding)
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

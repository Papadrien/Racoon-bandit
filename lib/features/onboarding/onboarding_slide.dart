import 'package:raccoon_bandit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/ui/app_colors.dart';

/// Modèle d'une slide d'onboarding.
///
/// Architecture modulaire : il suffit d'ajouter une entrée dans
/// [OnboardingSlides.all] pour ajouter une nouvelle slide (nouvelle carte,
/// nouvelle mécanique, futur tutoriel).
class OnboardingSlide {
  const OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
    required this.cardColor,
    this.accentColor = const Color(0xFF7C4DFF),
    this.cardImageAsset,
    this.iconWidget,
  });

  /// Emoji illustrant la slide (fallback si pas d'image).
  final String emoji;

  /// Chemin asset de l'image de la face avant de la carte (optionnel).
  /// Si renseigné, remplace l'emoji dans l'affichage onboarding.
  final String? cardImageAsset;

  /// Widget personnalisé à afficher dans la card (priorité sur image et emoji).
  final Widget? iconWidget;

  /// Titre court de la slide.
  final String Function(BuildContext context) title;

  /// Description courte — max 2 lignes.
  final String Function(BuildContext context) description;

  /// Couleur de fond de la card.
  final Color cardColor;

  /// Couleur accent pour le titre et les décorations.
  final Color accentColor;
}

/// Catalogue des slides d'onboarding.
///
/// Ajouter ici pour de futurs tutoriels sans modifier [OnboardingScreen].
class OnboardingSlides {
  OnboardingSlides._();

  static final List<OnboardingSlide> all = [
    OnboardingSlide(
      emoji: '🍎',
      cardImageAsset: 'assets/images/card_front_food.png',
      title: (context) => AppLocalizations.of(context)!.onboardingFoodTitle,
      description: (context) => AppLocalizations.of(context)!.onboardingFoodDesc,
      cardColor: const Color(0xFF1B5E20),
      accentColor: const Color(0xFF66BB6A),
    ),
    OnboardingSlide(
      emoji: '🥷',
      cardImageAsset: 'assets/images/card_front_pince.png',
      title: (context) => AppLocalizations.of(context)!.onboardingPinceTitle,
      description: (context) => AppLocalizations.of(context)!.onboardingPinceDesc,
      cardColor: const Color(0xFF1A237E),
      accentColor: const Color(0xFF7C4DFF),
    ),
    OnboardingSlide(
      emoji: '🦝',
      cardImageAsset: 'assets/images/card_front_raccoon.png',
      title: (context) => AppLocalizations.of(context)!.onboardingRaccoonTitle,
      description: (context) => AppLocalizations.of(context)!.onboardingRaccoonDesc,
      cardColor: const Color(0xFF37474F),
      accentColor: const Color(0xFF90A4AE),
    ),
    OnboardingSlide(
      emoji: '🧊',
      cardImageAsset: 'assets/images/card_front_trash.png',
      title: (context) => AppLocalizations.of(context)!.onboardingTrashTitle,
      description: (context) => AppLocalizations.of(context)!.onboardingTrashDesc,
      cardColor: const Color(0xFF0D47A1),
      accentColor: const Color(0xFF42A5F5),
    ),
    OnboardingSlide(
      emoji: '🏆',
      title: (_) => 'Victoire',
      description: (_) => 'Celui qui a le plus de nourriture à la fin de la pioche a gagné !',
      cardColor: const Color(0xFF7B5800),
      accentColor: const Color(0xFFFFB300),
      iconWidget: const _TrophyCardIcon(),
    ),
  ];
}

/// Icône trophée pour la slide victoire — reprend le style du résultat screen.
class _TrophyCardIcon extends StatelessWidget {
  const _TrophyCardIcon();

  @override
  Widget build(BuildContext context) {
    const size = 80.0;
    return Container(
      width: size * 1.3,
      height: size * 1.3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.22),
            AppColors.orange.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: const Center(
        child: Text('🏆', style: TextStyle(fontSize: size)),
      ),
    );
  }
}

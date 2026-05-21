import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
  });

  /// Emoji illustrant la slide (grand, visible d'un coup d'œil).
  final String emoji;

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
      title: (context) => AppLocalizations.of(context)!.onboardingFoodTitle,
      description: (context) => AppLocalizations.of(context)!.onboardingFoodDesc,
      cardColor: Color(0xFF1B5E20),
      accentColor: Color(0xFF66BB6A),
    ),
    OnboardingSlide(
      emoji: '🥷',
      title: (context) => AppLocalizations.of(context)!.onboardingBanditTitle,
      description: (context) => AppLocalizations.of(context)!.onboardingBanditDesc,
      cardColor: Color(0xFF1A237E),
      accentColor: Color(0xFF7C4DFF),
    ),
    OnboardingSlide(
      emoji: '🦝',
      title: (context) => AppLocalizations.of(context)!.onboardingRaccoonTitle,
      description: (context) => AppLocalizations.of(context)!.onboardingRaccoonDesc,
      cardColor: Color(0xFF37474F),
      accentColor: Color(0xFF90A4AE),
    ),
    OnboardingSlide(
      emoji: '🧊',
      title: (context) => AppLocalizations.of(context)!.onboardingTrashTitle,
      description: (context) => AppLocalizations.of(context)!.onboardingTrashDesc,
      cardColor: Color(0xFF0D47A1),
      accentColor: Color(0xFF42A5F5),
    ),
  ];
}

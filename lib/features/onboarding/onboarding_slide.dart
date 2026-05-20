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
  final String title;

  /// Description courte — max 2 lignes.
  final String description;

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

  static const List<OnboardingSlide> all = [
    OnboardingSlide(
      emoji: '🍎',
      title: 'Nourriture',
      description:
          'Ramasse le maximum de nourriture sans te les faire voler.',
      cardColor: Color(0xFF1B5E20),
      accentColor: Color(0xFF66BB6A),
    ),
    OnboardingSlide(
      emoji: '🥷',
      title: 'Bandit',
      description:
          'Le bandit te permet de voler une nourriture à un autre joueur.',
      cardColor: Color(0xFF1A237E),
      accentColor: Color(0xFF7C4DFF),
    ),
    OnboardingSlide(
      emoji: '🦝',
      title: 'Raton laveur',
      description:
          'Le raton laveur vole toute ta nourriture. Fais attention.',
      cardColor: Color(0xFF37474F),
      accentColor: Color(0xFF90A4AE),
    ),
    OnboardingSlide(
      emoji: '🧊',
      title: 'Poubelle sécurisée',
      description:
          'La poubelle sécurisée te protège contre un passage du raton laveur.',
      cardColor: Color(0xFF0D47A1),
      accentColor: Color(0xFF42A5F5),
    ),
  ];
}

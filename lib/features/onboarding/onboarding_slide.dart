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
      title: 'Collecte la nourriture',
      description:
          'Pioche des cartes Nourriture pour remplir ton stock.\nLe premier joueur à 10 aliments gagne la partie !',
      cardColor: Color(0xFF1B5E20),
      accentColor: Color(0xFF66BB6A),
    ),
    OnboardingSlide(
      emoji: '🦹',
      title: 'Le Bandit vole !',
      description:
          'La carte Bandit te permet de voler de la nourriture\nà un autre joueur de ton choix.',
      cardColor: Color(0xFF1A237E),
      accentColor: Color(0xFF7C4DFF),
    ),
    OnboardingSlide(
      emoji: '🦝',
      title: 'Le Raton retire',
      description:
          'La carte Raton Laveur retire de la nourriture\nde ton propre stock. Aïe !',
      cardColor: Color(0xFF37474F),
      accentColor: Color(0xFF90A4AE),
    ),
    OnboardingSlide(
      emoji: '🧊',
      title: 'Le Frigo protège',
      description:
          'La carte Frigo te protège du Raton Laveur.\nTon stock est en sécurité pour ce tour !',
      cardColor: Color(0xFF0D47A1),
      accentColor: Color(0xFF42A5F5),
    ),
  ];
}

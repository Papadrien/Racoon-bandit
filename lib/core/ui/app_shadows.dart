import 'package:flutter/material.dart';

/// Ombres partagées — style sticker casual premium.
///
/// Toutes les ombres sont douces, diffuses, peu agressives.
/// Éviter les ombres noires dures ou les blur excessifs.
abstract class AppShadows {
  AppShadows._();

  // ── Sticker ───────────────────────────────────────────────────────────────

  /// Ombre sticker — composants principaux style autocollant.
  /// Utilisée pour les cartes, panneaux, éléments visuels forts.
  static const List<BoxShadow> sticker = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(3, 6),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 4,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  // ── Flottant ──────────────────────────────────────────────────────────────

  /// Ombre flottante — boutons blancs, vies, badges.
  /// Légère profondeur, sensation de "décollé" du fond.
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  // ── Douce ─────────────────────────────────────────────────────────────────

  /// Ombre douce — composants secondaires, séparation légère du fond.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 3),
    ),
  ];

  // ── Bouton ────────────────────────────────────────────────────────────────

  /// Ombre bouton — éléments interactifs principaux.
  /// Décalée vers bas-droite pour effet 3D sticker.
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 14,
      spreadRadius: 0,
      offset: Offset(4, 6),
    ),
  ];

  // ── Glow subtil ───────────────────────────────────────────────────────────

  /// Glow très atténué — halo doux autour d'un composant accentué.
  /// NON néon. Uniquement pour guider le regard, pas pour décorer.
  static List<BoxShadow> subtleGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 18,
          spreadRadius: 2,
          offset: Offset.zero,
        ),
      ];

  /// Glow accent + ombre neutre — panneaux héros, cartes gagnant.
  static List<BoxShadow> accentGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.18),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 12,
          spreadRadius: 0,
          offset: Offset(0, 3),
        ),
      ];

  /// Glow accent fort — carte dos dans dialog récompense.
  static List<BoxShadow> accentGlowStrong(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 28,
          spreadRadius: 4,
          offset: const Offset(0, 6),
        ),
        const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  /// Ombre dialog modal (reward, tutoriel).
  static List<BoxShadow> dialog(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.22),
          blurRadius: 32,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        const BoxShadow(
          color: Color(0x40000000),
          blurRadius: 20,
          spreadRadius: 0,
          offset: Offset(0, 6),
        ),
      ];
}

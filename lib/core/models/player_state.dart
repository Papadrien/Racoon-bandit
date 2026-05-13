import 'package:flutter/material.dart';

/// État d'un joueur pendant la partie.
///
/// Lié à un [PlayerProfile] via [profileId].
/// Porte directement [emoji] et [colorValue] pour affichage
/// sans avoir à relire le service de profils depuis le gameplay.
///
/// Architecture préparée pour : statistiques, parties jouées, succès,
/// déblocages, placement aux coins d'écran.
class PlayerState {
  final int id;
  final String name;

  /// ID du profil joueur associé.
  final String? profileId;

  /// Emoji avatar issu du profil (ou fallback par index).
  final String emoji;

  /// Couleur avatar issue du profil (ou fallback par index).
  final int colorValue;

  int foodCount;
  int trashCount;

  // ── Fallbacks par défaut (cohérents avec les profils par défaut) ──────────
  static const _fallbackEmojis = ['🦝', '🐼', '🦊', '🐸'];
  static const _fallbackColors = [
    0xFF7C4DFF, // violet
    0xFFFF6D00, // orange
    0xFF00BCD4, // cyan
    0xFF4CAF50, // vert
  ];

  PlayerState({
    required this.id,
    required this.name,
    this.profileId,
    String? emoji,
    int? colorValue,
    this.foodCount = 0,
    this.trashCount = 0,
  })  : emoji =
            emoji ?? _fallbackEmojis[(id - 1) % _fallbackEmojis.length],
        colorValue =
            colorValue ?? _fallbackColors[(id - 1) % _fallbackColors.length];

  // ── Accesseurs couleur ────────────────────────────────────────────────────

  /// Couleur du profil (ou fallback).
  Color get profileColor => Color(colorValue);

  // ── Logique jeu ───────────────────────────────────────────────────────────

  /// True si le joueur possède au moins une frigo.
  bool get hasTrash => trashCount > 0;
}

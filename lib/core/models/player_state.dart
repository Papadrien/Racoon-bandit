import 'package:flutter/material.dart';

class PlayerState {
  final int id;
  final String name;

  /// ID du profil joueur associé.
  /// Prêt pour l'injection future dans le gameplay et le classement.
  final String? profileId;

  int foodCount;
  int trashCount;

  PlayerState({
    required this.id,
    required this.name,
    this.profileId,
    this.foodCount = 0,
    this.trashCount = 0,
  });

  /// True si le joueur possède au moins une poubelle.
  bool get hasTrash => trashCount > 0;

  Color get avatarColor {
    const colors = [
      Color(0xFF7C4DFF),
      Color(0xFFFF6D00),
      Color(0xFF00BCD4),
      Color(0xFF4CAF50),
    ];
    return colors[(id - 1) % colors.length];
  }

  IconData get avatarIcon {
    const icons = [
      Icons.person,
      Icons.face,
      Icons.sentiment_satisfied_alt,
      Icons.tag_faces,
    ];
    return icons[(id - 1) % icons.length];
  }
}

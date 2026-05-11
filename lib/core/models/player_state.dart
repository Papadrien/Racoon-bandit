import 'package:flutter/material.dart';

class PlayerState {
  final int id;
  final String name;
  int foodCount;
  bool hasTrash;

  PlayerState({
    required this.id,
    required this.name,
    this.foodCount = 0,
    this.hasTrash = false,
  });

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

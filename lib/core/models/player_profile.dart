import 'dart:convert';

/// Profil persistant d'un joueur.
///
/// Prépare l'architecture pour : avatars image, avatars débloquables,
/// synchronisation gameplay, localisation FR/EN.
class PlayerProfile {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final DateTime createdAt;

  const PlayerProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.createdAt,
  });

  PlayerProfile copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
    DateTime? createdAt,
  }) =>
      PlayerProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        colorValue: json['colorValue'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory PlayerProfile.fromJsonString(String s) =>
      PlayerProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

import 'dart:convert';

/// Modèle de sauvegarde d'une partie en cours.
///
/// Conçu pour :
/// - sérialisation JSON légère via SharedPreferences
/// - robustesse aux évolutions (version de schéma)
/// - futur : statistiques, succès, dos de cartes personnalisé
///
/// La sauvegarde ne persiste QUE pour les fermetures involontaires.
/// Un quit volontaire la supprime immédiatement.
class SavedGame {
  /// Version du schéma — permet migrations futures.
  static const int schemaVersion = 1;

  final int version;
  final DateTime savedAt;

  // ── Joueurs ──────────────────────────────────────────────────────────────
  final List<SavedPlayerState> players;
  final int currentPlayerIndex;

  // ── Deck ─────────────────────────────────────────────────────────────────
  /// Types des cartes restantes dans le deck, dans l'ordre (last = prochain).
  final List<String> remainingDeckTypes;
  final bool chaosMode;

  // ── Métadonnées futures ──────────────────────────────────────────────────
  // Prévu pour : statistiques, succès, dos de cartes, mode de jeu

  const SavedGame({
    required this.version,
    required this.savedAt,
    required this.players,
    required this.currentPlayerIndex,
    required this.remainingDeckTypes,
    required this.chaosMode,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'savedAt': savedAt.toIso8601String(),
        'players': players.map((p) => p.toJson()).toList(),
        'currentPlayerIndex': currentPlayerIndex,
        'remainingDeckTypes': remainingDeckTypes,
        'chaosMode': chaosMode,
      };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
        version: json['version'] as int? ?? 1,
        savedAt: DateTime.parse(json['savedAt'] as String),
        players: (json['players'] as List)
            .map((e) => SavedPlayerState.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPlayerIndex: json['currentPlayerIndex'] as int,
        remainingDeckTypes:
            List<String>.from(json['remainingDeckTypes'] as List),
        chaosMode: json['chaosMode'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());

  factory SavedGame.fromJsonString(String s) =>
      SavedGame.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// Snapshot d'un [PlayerState] pour la sauvegarde.
class SavedPlayerState {
  final int id;
  final String name;
  final String? profileId;
  final String emoji;
  final int colorValue;
  final int foodCount;
  final int trashCount;

  const SavedPlayerState({
    required this.id,
    required this.name,
    this.profileId,
    required this.emoji,
    required this.colorValue,
    required this.foodCount,
    required this.trashCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profileId': profileId,
        'emoji': emoji,
        'colorValue': colorValue,
        'foodCount': foodCount,
        'trashCount': trashCount,
      };

  factory SavedPlayerState.fromJson(Map<String, dynamic> json) =>
      SavedPlayerState(
        id: json['id'] as int,
        name: json['name'] as String,
        profileId: json['profileId'] as String?,
        emoji: json['emoji'] as String,
        colorValue: json['colorValue'] as int,
        foodCount: json['foodCount'] as int,
        trashCount: json['trashCount'] as int,
      );
}

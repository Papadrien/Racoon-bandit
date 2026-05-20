import 'dart:convert';

/// Composition de joueurs sauvegardée pour le lobby.
///
/// Permet de restaurer la dernière sélection au prochain lancement
/// et de préparer la future reprise de partie.
class LobbyComposition {
  final int playerCount;

  /// IDs des profils sélectionnés, ordonnés par slot (longueur == playerCount).
  final List<String> profileIds;

  const LobbyComposition({
    required this.playerCount,
    required this.profileIds,
  });

  Map<String, dynamic> toJson() => {
        'playerCount': playerCount,
        'profileIds': profileIds,
      };

  factory LobbyComposition.fromJson(Map<String, dynamic> json) =>
      LobbyComposition(
        playerCount: json['playerCount'] as int,
        profileIds: List<String>.from(json['profileIds'] as List),
      );

  String toJsonString() => jsonEncode(toJson());

  factory LobbyComposition.fromJsonString(String s) =>
      LobbyComposition.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

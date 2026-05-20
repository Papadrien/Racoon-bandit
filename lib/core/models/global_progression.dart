import 'dart:convert';

class GlobalProgression {
  const GlobalProgression({
    required this.totalGamesPlayed,
    required this.unlockedCardBackIds,
    required this.selectedCardBackId,
  });

  factory GlobalProgression.initial() {
    return const GlobalProgression(
      totalGamesPlayed: 0,
      unlockedCardBackIds: {'purple'},
      selectedCardBackId: 'purple',
    );
  }

  factory GlobalProgression.fromMap(Map<String, dynamic> map) {
    var unlocked = (map['unlockedCardBackIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        {'purple'};

    // Migration : remplacer l'ancien id 'classic' par 'purple'
    if (unlocked.contains('classic')) {
      unlocked = {...unlocked.where((id) => id != 'classic'), 'purple'};
    }

    var selected = map['selectedCardBackId'] as String? ?? 'purple';
    if (selected == 'classic') selected = 'purple';

    return GlobalProgression(
      totalGamesPlayed: map['totalGamesPlayed'] as int? ?? 0,
      unlockedCardBackIds: unlocked,
      selectedCardBackId: selected,
    );
  }

  final int totalGamesPlayed;
  final Set<String> unlockedCardBackIds;
  final String selectedCardBackId;

  Map<String, dynamic> toMap() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'unlockedCardBackIds': unlockedCardBackIds.toList(),
      'selectedCardBackId': selectedCardBackId,
    };
  }

  String toJsonString() => jsonEncode(toMap());

  factory GlobalProgression.fromJsonString(String source) {
    return GlobalProgression.fromMap(
        jsonDecode(source) as Map<String, dynamic>);
  }

  GlobalProgression copyWith({
    int? totalGamesPlayed,
    Set<String>? unlockedCardBackIds,
    String? selectedCardBackId,
  }) {
    return GlobalProgression(
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      unlockedCardBackIds: unlockedCardBackIds ?? this.unlockedCardBackIds,
      selectedCardBackId: selectedCardBackId ?? this.selectedCardBackId,
    );
  }
}

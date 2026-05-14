import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_assets.dart';
import '../models/card_back_config.dart';
import '../models/global_progression.dart';
import '../models/reward_unlock.dart';

class ProgressionService {
  ProgressionService._();

  static const _storageKey = 'global_progression_v1';

  static const List<CardBackConfig> cardBacks = [
    CardBackConfig(
      id: 'classic',
      name: 'Classic',
      requiredGames: 0,
      unlockedByDefault: true,
    ),
    CardBackConfig(
      id: 'blue',
      name: 'Blue',
      requiredGames: 5,
      unlockedByDefault: false,
    ),
    CardBackConfig(
      id: 'green',
      name: 'Green',
      requiredGames: 10,
      unlockedByDefault: false,
    ),
    CardBackConfig(
      id: 'gold',
      name: 'Gold',
      requiredGames: 20,
      unlockedByDefault: false,
    ),
    CardBackConfig(
      id: 'purple',
      name: 'Purple',
      requiredGames: 50,
      unlockedByDefault: false,
    ),
  ];

  static GlobalProgression _progression = GlobalProgression.initial();

  static GlobalProgression get progression => _progression;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null) {
        _progression = GlobalProgression.initial();
        await save();
        return;
      }

      _progression = GlobalProgression.fromJsonString(raw);
      _ensureDefaults();
    } catch (_) {
      _progression = GlobalProgression.initial();
    }
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _progression.toJsonString());
  }

  static Future<List<RewardUnlock>> registerCompletedGame() async {
    final updatedGames = _progression.totalGamesPlayed + 1;

    _progression = _progression.copyWith(
      totalGamesPlayed: updatedGames,
    );

    final unlocked = _checkUnlocks();
    await save();

    return unlocked;
  }

  /// Équipe immédiatement un dos de carte débloqué.
  static Future<void> equipCardBack(String cardBackId) =>
      selectCardBack(cardBackId);

  static Future<void> selectCardBack(String cardBackId) async {
    if (!_progression.unlockedCardBackIds.contains(cardBackId)) {
      return;
    }

    _progression = _progression.copyWith(
      selectedCardBackId: cardBackId,
    );

    await save();
  }

  static List<RewardUnlock> _checkUnlocks() {
    final newUnlocks = <RewardUnlock>[];
    final unlockedIds = {..._progression.unlockedCardBackIds};

    for (final cardBack in cardBacks) {
      final shouldUnlock = cardBack.unlockedByDefault ||
          _progression.totalGamesPlayed >= cardBack.requiredGames;

      if (shouldUnlock && !unlockedIds.contains(cardBack.id)) {
        unlockedIds.add(cardBack.id);
        newUnlocks.add(RewardUnlock(
          id: cardBack.id,
          name: cardBack.name,
          type: RewardType.cardBack,
          assetPath: AppAssets.cardBackAsset(cardBack.id),
        ));
      }
    }

    _progression = _progression.copyWith(
      unlockedCardBackIds: unlockedIds,
    );

    return newUnlocks;
  }

  static void _ensureDefaults() {
    final unlockedIds = {..._progression.unlockedCardBackIds, 'classic'};

    final selected = unlockedIds.contains(_progression.selectedCardBackId)
        ? _progression.selectedCardBackId
        : 'classic';

    _progression = _progression.copyWith(
      unlockedCardBackIds: unlockedIds,
      selectedCardBackId: selected,
    );
  }
}

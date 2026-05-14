import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_assets.dart';
import '../models/card_back_config.dart';
import '../models/global_progression.dart';
import '../models/reward_unlock.dart';

/// Service central de progression : déblocages de dos de cartes.
///
/// Unique condition de déblocage : nombre de parties jouées ([requiredGames]).
/// Les dos avec [unlockedByDefault] sont toujours disponibles.
///
/// Anti-doublon garanti : un dos déjà dans [unlockedCardBackIds] ne
/// génère plus jamais de [RewardUnlock].
class ProgressionService {
  ProgressionService._();

  static const _storageKey = 'global_progression_v1';

  // ── Catalogue des dos de cartes ──────────────────────────────────────────

  static const List<CardBackConfig> cardBacks = [
    CardBackConfig(
      id: 'classic',
      name: 'Classic',
      requiredGames: 0,
      unlockedByDefault: true,
    ),
    CardBackConfig(
      id: 'purple',
      name: 'Purple',
      requiredGames: 0,
      unlockedByDefault: true,
    ),
    CardBackConfig(
      id: 'bandit',
      name: 'Bandit',
      requiredGames: 5,
    ),
    CardBackConfig(
      id: 'gold',
      name: 'Or',
      requiredGames: 10,
    ),
    CardBackConfig(
      id: 'champion',
      name: 'Champion',
      requiredGames: 20,
    ),
  ];

  // ── État interne ─────────────────────────────────────────────────────────

  static GlobalProgression _progression = GlobalProgression.initial();

  static GlobalProgression get progression => _progression;

  // ── Chargement / sauvegarde ──────────────────────────────────────────────

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

  // ── Enregistrement d'une partie ─────────────────────────────────────────

  /// Enregistre une partie terminée et retourne les [RewardUnlock] débloqués.
  static Future<List<RewardUnlock>> registerCompletedGame() async {
    _progression = _progression.copyWith(
      totalGamesPlayed: _progression.totalGamesPlayed + 1,
    );

    final unlocked = _checkUnlocks();
    await save();
    return unlocked;
  }

  // ── Sélection / équipement ───────────────────────────────────────────────

  /// Équipe immédiatement un dos de carte débloqué.
  static Future<void> equipCardBack(String cardBackId) =>
      selectCardBack(cardBackId);

  static Future<void> selectCardBack(String cardBackId) async {
    if (!_progression.unlockedCardBackIds.contains(cardBackId)) return;
    _progression = _progression.copyWith(selectedCardBackId: cardBackId);
    await save();
  }

  // ── Logique de déblocage ─────────────────────────────────────────────────

  /// Vérifie tous les dos et retourne ceux nouvellement débloqués.
  static List<RewardUnlock> _checkUnlocks() {
    final newUnlocks = <RewardUnlock>[];
    final unlockedIds = {..._progression.unlockedCardBackIds};

    for (final cardBack in cardBacks) {
      if (unlockedIds.contains(cardBack.id)) continue;

      final shouldUnlock = cardBack.unlockedByDefault ||
          _progression.totalGamesPlayed >= cardBack.requiredGames;

      if (!shouldUnlock) continue;

      unlockedIds.add(cardBack.id);
      newUnlocks.add(RewardUnlock(
        id: cardBack.id,
        name: cardBack.name,
        type: RewardType.cardBack,
        assetPath: AppAssets.cardBackAsset(cardBack.id),
        unlockHint: 'Débloqué après ${cardBack.requiredGames} '
            'partie${cardBack.requiredGames > 1 ? 's' : ''} jouée'
            '${cardBack.requiredGames > 1 ? 's' : ''} !',
      ));
    }

    _progression = _progression.copyWith(unlockedCardBackIds: unlockedIds);
    return newUnlocks;
  }

  // ── Cohérence des données ────────────────────────────────────────────────

  static void _ensureDefaults() {
    final defaults = cardBacks
        .where((cb) => cb.unlockedByDefault)
        .map((cb) => cb.id)
        .toSet();

    final unlockedIds = {
      ..._progression.unlockedCardBackIds,
      ...defaults,
    };

    final selected = unlockedIds.contains(_progression.selectedCardBackId)
        ? _progression.selectedCardBackId
        : 'classic';

    _progression = _progression.copyWith(
      unlockedCardBackIds: unlockedIds,
      selectedCardBackId: selected,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_assets.dart';
import '../models/card_back_config.dart';
import '../models/global_progression.dart';
import '../models/reward_unlock.dart';
import '../theme/app_theme_provider.dart';

/// Service central de progression : déblocages de dos de cartes.
///
/// Ordre MVP :
/// 1. Violet  — débloqué par défaut
/// 2. Bleu    — 5 parties
/// 3. Vert    — 10 parties
/// 4. Rose    — 20 parties
/// 5. Jaune   — 30 parties
///
/// Anti-doublon garanti : un dos déjà dans [unlockedCardBackIds] ne
/// génère plus jamais de [RewardUnlock].
class ProgressionService {
  ProgressionService._();

  static const _storageKey = 'global_progression_v1';

  // ── Catalogue des dos de cartes ──────────────────────────────────────────

  static const List<CardBackConfig> cardBacks = [
    CardBackConfig(
      id: 'purple',
      name: 'Violet',
      assetPath: AppAssets.cardBackPurple,
      themeColor: Color(0xFFFF6D00),
      requiredGames: 0,
      unlockedByDefault: true,
    ),
    CardBackConfig(
      id: 'blue',
      name: 'Bleu',
      assetPath: AppAssets.cardBackBlue,
      themeColor: Color(0xFF2196F3),
      requiredGames: 5,
    ),
    CardBackConfig(
      id: 'green',
      name: 'Vert',
      assetPath: AppAssets.cardBackGreen,
      themeColor: Color(0xFF4CAF50),
      requiredGames: 10,
    ),
    CardBackConfig(
      id: 'pink',
      name: 'Rose',
      assetPath: AppAssets.cardBackPink,
      themeColor: Color(0xFFE91E8C),
      requiredGames: 20,
    ),
    CardBackConfig(
      id: 'yellow',
      name: 'Jaune',
      assetPath: AppAssets.cardBackYellow,
      themeColor: Color(0xFFFFC107),
      requiredGames: 30,
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
      } else {
        _progression = GlobalProgression.fromJsonString(raw);
        _ensureDefaults();
      }
    } catch (_) {
      _progression = GlobalProgression.initial();
    }

    // Initialise le thème sans notifier (premier chargement)
    AppThemeProvider.instance.initFromCardBack(
      _progression.selectedCardBackId,
    );
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

  /// Équipe immédiatement un dos de carte débloqué et met à jour le thème.
  static Future<void> equipCardBack(String cardBackId) =>
      selectCardBack(cardBackId);

  static Future<void> selectCardBack(String cardBackId) async {
    if (!_progression.unlockedCardBackIds.contains(cardBackId)) return;
    _progression = _progression.copyWith(selectedCardBackId: cardBackId);
    await save();
    // Met à jour le thème dynamiquement (notifie les listeners)
    AppThemeProvider.instance.updateFromCardBack(cardBackId);
  }

  // ── Debug : tout débloquer ───────────────────────────────────────────────

  /// Débloque immédiatement tous les dos (debug mode uniquement).
  static Future<void> debugUnlockAll() async {
    assert(kDebugMode, 'debugUnlockAll ne doit être appelé qu\'en debug mode');
    final allIds = cardBacks.map((cb) => cb.id).toSet();
    _progression = _progression.copyWith(unlockedCardBackIds: allIds);
    await save();
  }

  // ── Logique de déblocage ─────────────────────────────────────────────────

  /// Vérifie tous les dos et retourne ceux nouvellement débloqués.
  static List<RewardUnlock> _checkUnlocks() {
    final newUnlocks = <RewardUnlock>[];
    final unlockedIds = {..._progression.unlockedCardBackIds};

    // En debug, seuils accélérés pour faciliter les tests.
    // En release, progression normale (requiredGames inchangé).
    final debugThresholds = kDebugMode
        ? <String, int>{
            'blue': 1,   // 1ère partie → déblocage bleu
            'green': 3,  // 3ème partie → déblocage vert
          }
        : <String, int>{};

    for (final cardBack in cardBacks) {
      if (unlockedIds.contains(cardBack.id)) continue;

      final threshold = debugThresholds[cardBack.id] ?? cardBack.requiredGames;
      final shouldUnlock = cardBack.unlockedByDefault ||
          _progression.totalGamesPlayed >= threshold;

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

    // Migration : si l'ancien id 'classic' est sélectionné, on bascule sur 'purple'
    var selected = _progression.selectedCardBackId;
    if (selected == 'classic') selected = 'purple';
    if (!unlockedIds.contains(selected)) selected = 'purple';

    _progression = _progression.copyWith(
      unlockedCardBackIds: unlockedIds,
      selectedCardBackId: selected,
    );
  }
}

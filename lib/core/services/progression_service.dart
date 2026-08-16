import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_assets.dart';
import '../models/card_back_config.dart';
import '../models/global_progression.dart';
import '../models/reward_unlock.dart';
import 'purchase_service.dart';

/// Service central de progression : déblocages de dos de cartes.
///
/// Ordre MVP :
/// 1.  Violet   — débloqué par défaut
/// 2.  Bleu     — 5 parties
/// 3.  Vert     — 10 parties
/// 4.  Marron   — 15 parties
/// 5.  Rose     — 20 parties
/// 6.  Nuage    — 25 parties
/// 7.  Orange   — 30 parties
/// 8.  Feu      — 35 parties
/// 9.  Pizza    — 40 parties
/// 10. Jaune    — 45 parties
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
      id: 'pinecone',
      name: 'Marron',
      assetPath: AppAssets.cardBackPinecone,
      themeColor: Color(0xFF8D6E63),
      requiredGames: 15,
    ),
    CardBackConfig(
      id: 'pink',
      name: 'Rose',
      assetPath: AppAssets.cardBackPink,
      themeColor: Color(0xFFE91E8C),
      requiredGames: 20,
    ),
    CardBackConfig(
      id: 'cloud',
      name: 'Nuage',
      assetPath: AppAssets.cardBackCloud,
      themeColor: Color(0xFFB0BEC5),
      requiredGames: 25,
    ),
    CardBackConfig(
      id: 'crystal',
      name: 'Orange',
      assetPath: AppAssets.cardBackCrystal,
      themeColor: Color(0xFFFF9800),
      requiredGames: 30,
    ),
    CardBackConfig(
      id: 'campfire',
      name: 'Feu',
      assetPath: AppAssets.cardBackCampfire,
      themeColor: Color(0xFFE53935),
      requiredGames: 35,
    ),
    CardBackConfig(
      id: 'pizza',
      name: 'Pizza',
      assetPath: AppAssets.cardBackPizza,
      themeColor: Color(0xFF2E7D32),
      requiredGames: 40,
    ),
    CardBackConfig(
      id: 'yellow',
      name: 'Jaune',
      assetPath: AppAssets.cardBackYellow,
      themeColor: Color(0xFFFFC107),
      requiredGames: 45,
    ),
  ];

  // ── État interne ─────────────────────────────────────────────────────────

  static GlobalProgression _progression = GlobalProgression.initial();

  static GlobalProgression get progression => _progression;

  /// Dos de cartes réellement débloqués pour l'affichage/sélection.
  /// Le pack Premium débloque instantanément tous les dos, sans toucher à
  /// la progression persistée (utile si l'achat est un jour remboursé).
  static Set<String> get unlockedCardBackIds {
    if (PurchaseService.instance.isPremium) {
      return cardBacks.map((cb) => cb.id).toSet();
    }
    return _progression.unlockedCardBackIds;
  }

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

  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _progression.toJsonString());
  }

  /// Fusionne une progression reçue du cloud avec la progression locale,
  /// sans jamais rien perdre : union des dos de cartes débloqués, et le
  /// plus grand des deux compteurs de parties. Le dos actuellement équipé
  /// localement est conservé tel quel.
  static Future<void> mergeFromCloud(GlobalProgression cloud) async {
    final mergedUnlocked = <String>{
      ..._progression.unlockedCardBackIds,
      ...cloud.unlockedCardBackIds,
    };
    final mergedGames = _progression.totalGamesPlayed > cloud.totalGamesPlayed
        ? _progression.totalGamesPlayed
        : cloud.totalGamesPlayed;

    _progression = _progression.copyWith(
      totalGamesPlayed: mergedGames,
      unlockedCardBackIds: mergedUnlocked,
    );
    await save();
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
    if (!unlockedCardBackIds.contains(cardBackId)) return;
    _progression = _progression.copyWith(selectedCardBackId: cardBackId);
    await save();
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

      // Le pack Premium donne déjà accès à tous les dos : ce déblocage
      // "naturel" est enregistré (utile si l'achat est un jour remboursé),
      // mais on n'affiche pas la pop-up puisque rien de nouveau n'est
      // réellement débloqué pour le joueur.
      if (!PurchaseService.instance.isPremium) {
        newUnlocks.add(RewardUnlock(
          id: cardBack.id,
          name: cardBack.name,
          type: RewardType.cardBack,
          assetPath: AppAssets.cardBackAsset(cardBack.id),
          requiredGames: cardBack.requiredGames,
        ));
      }
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

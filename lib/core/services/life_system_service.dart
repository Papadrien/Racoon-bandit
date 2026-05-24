import 'dart:convert';

import 'analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LifeSystemService {
  static const int maxLives = 3;
  static const Duration rechargeDuration = Duration(minutes: 15);

  // Clé unique JSON — sauvegarde atomique lives + timestamp
  static const _stateKey = 'life_system_state_v2';
  // Anciennes clés (migration)
  static const _legacyLivesKey = 'current_lives';
  static const _legacyTimestampKey = 'last_life_recharge_timestamp';

  int currentLives = maxLives;
  DateTime? lastLifeRechargeTimestamp;

  bool _isUpdating = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final stateJson = prefs.getString(_stateKey);
    if (stateJson != null) {
      try {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        currentLives = (state['lives'] as int? ?? maxLives).clamp(0, maxLives);
        final ts = state['timestamp'] as int?;
        lastLifeRechargeTimestamp =
            ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
      } catch (e) {
        if (kDebugMode) debugPrint('[LifeSystem] Erreur parsing état: $e');
        currentLives = maxLives;
        lastLifeRechargeTimestamp = null;
      }
    } else {
      // Migration depuis les anciennes clés séparées
      currentLives =
          (prefs.getInt(_legacyLivesKey) ?? maxLives).clamp(0, maxLives);
      final ts = prefs.getInt(_legacyTimestampKey);
      lastLifeRechargeTimestamp =
          ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
    }

    // Timestamp dans le futur (changement d'horloge) → réinitialiser à maintenant
    final now = DateTime.now();
    if (lastLifeRechargeTimestamp != null &&
        lastLifeRechargeTimestamp!.isAfter(now)) {
      if (kDebugMode) {
        debugPrint('[LifeSystem] Timestamp dans le futur détecté, réinitialisation');
      }
      lastLifeRechargeTimestamp = now;
    }

    await updateLivesFromTime();
  }

  Future<void> consumeLife() async {
    await updateLivesFromTime();

    if (currentLives <= 0) return;

    currentLives--;
    lastLifeRechargeTimestamp ??= DateTime.now();

    await _save();
  }

  Future<void> restoreLife() async {
    if (currentLives >= maxLives) return;

    currentLives++;

    if (currentLives >= maxLives) {
      lastLifeRechargeTimestamp = null;
    }

    AnalyticsService.instance.logLifeRestored(
      livesAfter: currentLives,
      source: 'timer',
    );

    await _save();
  }

  Future<void> updateLivesFromTime() async {
    if (_isUpdating) return;
    if (currentLives >= maxLives || lastLifeRechargeTimestamp == null) return;

    _isUpdating = true;
    try {
      final now = DateTime.now();
      final elapsed = now.difference(lastLifeRechargeTimestamp!);

      // Elapsed négatif = horloge modifiée, on reset le timestamp
      if (elapsed.isNegative) {
        lastLifeRechargeTimestamp = now;
        await _save();
        return;
      }

      final restoredLives =
          elapsed.inSeconds ~/ rechargeDuration.inSeconds;

      if (restoredLives <= 0) return;

      currentLives = (currentLives + restoredLives).clamp(0, maxLives);

      if (currentLives >= maxLives) {
        lastLifeRechargeTimestamp = null;
      } else {
        lastLifeRechargeTimestamp = lastLifeRechargeTimestamp!.add(
          Duration(seconds: restoredLives * rechargeDuration.inSeconds),
        );
      }

      await _save();
    } finally {
      _isUpdating = false;
    }
  }

  Duration getRemainingRechargeDuration() {
    if (currentLives >= maxLives || lastLifeRechargeTimestamp == null) {
      return Duration.zero;
    }

    final nextRecharge = lastLifeRechargeTimestamp!.add(rechargeDuration);
    final remaining = nextRecharge.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = jsonEncode({
        'lives': currentLives,
        'timestamp': lastLifeRechargeTimestamp?.millisecondsSinceEpoch,
      });
      await prefs.setString(_stateKey, state);
    } catch (e) {
      if (kDebugMode) debugPrint('[LifeSystem] Erreur sauvegarde: $e');
    }
  }
}

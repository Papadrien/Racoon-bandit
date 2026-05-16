import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class LifeSystemService {
  static const int maxLives = 3;
  static const Duration rechargeDuration = Duration(minutes: 15);

  static const _livesKey = 'current_lives';
  static const _timestampKey = 'last_life_recharge_timestamp';

  int currentLives = maxLives;
  DateTime? lastLifeRechargeTimestamp;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    currentLives = prefs.getInt(_livesKey) ?? maxLives;

    final timestamp = prefs.getInt(_timestampKey);

    if (timestamp != null) {
      lastLifeRechargeTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    await updateLivesFromTime();
  }

  Future<void> consumeLife() async {
    await updateLivesFromTime();

    if (currentLives <= 0) {
      return;
    }

    currentLives--;

    lastLifeRechargeTimestamp ??= DateTime.now();

    await _save();
  }

  Future<void> restoreLife() async {
    if (currentLives >= maxLives) {
      return;
    }

    currentLives++;

    if (currentLives >= maxLives) {
      lastLifeRechargeTimestamp = null;
    }

    await _save();
  }

  Future<void> updateLivesFromTime() async {
    if (currentLives >= maxLives || lastLifeRechargeTimestamp == null) {
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(lastLifeRechargeTimestamp!);

    final restoredLives = elapsed.inSeconds ~/ rechargeDuration.inSeconds;

    if (restoredLives <= 0) {
      return;
    }

    currentLives = (currentLives + restoredLives).clamp(0, maxLives);

    if (currentLives >= maxLives) {
      lastLifeRechargeTimestamp = null;
    } else {
      lastLifeRechargeTimestamp = lastLifeRechargeTimestamp!.add(
        Duration(seconds: restoredLives * rechargeDuration.inSeconds),
      );
    }

    await _save();
  }

  Duration getRemainingRechargeDuration() {
    if (currentLives >= maxLives || lastLifeRechargeTimestamp == null) {
      return Duration.zero;
    }

    final nextRecharge =
        lastLifeRechargeTimestamp!.add(rechargeDuration);

    final remaining = nextRecharge.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_livesKey, currentLives);

    if (lastLifeRechargeTimestamp != null) {
      await prefs.setInt(
        _timestampKey,
        lastLifeRechargeTimestamp!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_timestampKey);
    }
  }
}

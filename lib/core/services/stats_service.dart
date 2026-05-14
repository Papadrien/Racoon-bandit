import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_state.dart';
import '../models/global_stats.dart';

class StatsService {
  StatsService._();

  static const _key = 'global_stats_v1';
  static GlobalStats current = GlobalStats();

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) current = GlobalStats.fromJsonString(raw);
    } catch (_) {}
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, current.toJsonString());
  }

  static Future<void> registerGame(GameState state) async {
    current.gamesPlayed++;
    current.totalCardsPlayed += state.sessionStats.cardsPlayed;
    current.totalFoodGained += state.sessionStats.foodGained;
    current.totalFoodStolen += state.sessionStats.foodStolen;
    current.totalBanditCardsPlayed += state.sessionStats.banditCardsPlayed;
    current.totalRaccoonCardsPlayed += state.sessionStats.raccoonCardsPlayed;
    await save();
  }

  static Future<void> reset() async {
    current = GlobalStats();
    await save();
  }
}

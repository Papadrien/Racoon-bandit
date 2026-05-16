import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/audio_service.dart';
import 'core/services/game_save_service.dart';
import 'core/services/lobby_service.dart';
import 'core/services/player_profiles_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/rewarded_ad_service.dart';
import 'core/services/progression_service.dart';
import 'core/services/stats_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.load();
  await PlayerProfilesService.load();
  await LobbyService.load();
  await GameSaveService.load();
  await ProgressionService.load();
  await StatsService.load();
  await RewardedAdService.initialize();

  // Préchargement des SFX fréquents — évite le délai au premier son
  await AudioService.instance.preloadAll();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const RaccoonBanditApp());
}

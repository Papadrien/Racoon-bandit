import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/game_save_service.dart';
import 'core/services/lobby_service.dart';
import 'core/services/player_profiles_service.dart';
import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.load();
  await PlayerProfilesService.load();
  await LobbyService.load();
  await GameSaveService.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const RaccoonBanditApp());
}

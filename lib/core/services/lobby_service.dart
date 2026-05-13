import 'package:shared_preferences/shared_preferences.dart';

import '../models/lobby_composition.dart';

/// Sauvegarde et restaure la dernière composition de joueurs du lobby.
///
/// Utilisé pour :
/// - préremplir le lobby au prochain lancement
/// - (futur) reprise de partie en cours
class LobbyService {
  LobbyService._();

  static const _keyComposition = 'lobby_composition_v1';

  static LobbyComposition? _lastComposition;

  /// Dernière composition sauvegardée (null si jamais jouée).
  static LobbyComposition? get lastComposition => _lastComposition;

  /// À appeler dans main(), avant runApp, après PlayerProfilesService.load().
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyComposition);
      if (raw != null) {
        _lastComposition = LobbyComposition.fromJsonString(raw);
      }
    } catch (_) {
      _lastComposition = null;
    }
  }

  /// Sauvegarde la composition avant de lancer une partie.
  static Future<void> saveComposition(LobbyComposition composition) async {
    _lastComposition = composition;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyComposition, composition.toJsonString());
    } catch (_) {}
  }
}

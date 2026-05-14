import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_game.dart';

/// Service de sauvegarde/restauration de partie en cours.
///
/// Utilise SharedPreferences (cohérent avec SettingsService, LobbyService).
///
/// Stratégie :
/// - Sauvegarde automatique après chaque action importante.
/// - Suppression explicite lors d'un quit volontaire.
/// - Si sauvegarde corrompue → suppression silencieuse, retour accueil normal.
///
/// Prévu pour : statistiques, succès, modes de jeu futurs.
class GameSaveService {
  GameSaveService._();

  static const _keySave = 'game_save_v1';

  static SavedGame? _current;

  /// Sauvegarde chargée en mémoire (null = aucune partie à reprendre).
  static SavedGame? get current => _current;

  /// Vrai si une partie interrompue est disponible.
  static bool get hasSavedGame => _current != null;

  // ── Init ─────────────────────────────────────────────────────────────────

  /// À appeler dans main(), avant runApp.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keySave);
      if (raw == null) {
        _current = null;
        return;
      }
      _current = SavedGame.fromJsonString(raw);
    } catch (_) {
      // Sauvegarde corrompue → suppression silencieuse
      _current = null;
      await _erase();
    }
  }

  // ── Sauvegarde ───────────────────────────────────────────────────────────

  /// Sauvegarde l'état courant de la partie.
  /// Appelé après chaque action importante depuis [GameScreen].
  static Future<void> save(SavedGame snapshot) async {
    _current = snapshot;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySave, snapshot.toJsonString());
    } catch (_) {}
  }

  // ── Suppression ──────────────────────────────────────────────────────────

  /// Supprime la sauvegarde (quit volontaire ou fin de partie normale).
  static Future<void> clear() async {
    _current = null;
    await _erase();
  }

  static Future<void> _erase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySave);
    } catch (_) {}
  }
}

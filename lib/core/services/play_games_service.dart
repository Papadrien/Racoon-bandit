import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

/// Service Google Play Games Services (Android).
///
/// – Connexion silencieuse tentée une fois au démarrage ([signInSilently]),
///   jamais bloquante et sans popup imposée : si l'utilisateur n'est pas
///   connecté à son compte Google ou refuse, l'app continue normalement,
///   simplement sans succès synchronisés (important pour un jeu destiné
///   aux enfants — pas de flux de connexion forcé).
/// – Synchronisation ([syncAfterGame]) à appeler à la fin de chaque partie :
///   pousse les succès déjà réellement trackés côté app (dos de cartes
///   débloqués). N'invente aucune donnée qui n'existe pas déjà.
///
/// Pas de classements (leaderboards) dans cette app par choix produit.
class PlayGamesService {
  PlayGamesService._();

  static bool _signedIn = false;
  static bool get isSignedIn => _signedIn;

  static String? _playerId;
  static String? get playerId => _playerId;

  // ── IDs Play Console ─────────────────────────────────────────────────────
  // TODO(Adrien) : remplacer ces placeholders par les vrais IDs créés dans
  // Play Console > Play Games Services > Succès pour
  // fr.junade.raccoonbandit. Tant qu'ils ne sont pas remplacés, les appels
  // échouent silencieusement (voir _safeCall) sans jamais crasher l'app.

  /// Un succès Play Games par dos de carte débloquable (hors "purple", qui
  /// est débloqué par défaut et n'a donc pas besoin d'être un succès).
  static const Map<String, String> cardBackAchievementIds = {
    'blue': 'CHANGE_ME_achievement_card_back_blue',
    'green': 'CHANGE_ME_achievement_card_back_green',
    'pink': 'CHANGE_ME_achievement_card_back_pink',
    'yellow': 'CHANGE_ME_achievement_card_back_yellow',
  };

  // ── Connexion ─────────────────────────────────────────────────────────────

  /// À appeler une fois au splash screen. Ne bloque jamais le démarrage :
  /// en cas d'échec (pas connecté, pas de réseau, IDs non configurés...),
  /// on continue simplement sans Play Games.
  static Future<void> signInSilently() async {
    try {
      await GamesServices.signIn();
      _signedIn = await GamesServices.isSignedIn;
      if (_signedIn) {
        try {
          _playerId = await GamesServices.getPlayerID();
        } catch (e) {
          // Certaines versions du plugin/anciens comptes peuvent échouer
          // ici sans que la connexion elle-même soit invalide. Le sync
          // cloud sera simplement désactivé si playerId reste null.
          _playerId = null;
          if (kDebugMode) {
            debugPrint('[PlayGamesService] getPlayerID échoué : $e');
          }
        }
      } else {
        _playerId = null;
      }
      if (kDebugMode) {
        debugPrint(
          '[PlayGamesService] connecté = $_signedIn, playerId = $_playerId',
        );
      }
    } catch (e) {
      _signedIn = false;
      _playerId = null;
      if (kDebugMode) debugPrint('[PlayGamesService] connexion échouée : $e');
    }
  }

  // ── Synchronisation fin de partie ───────────────────────────────────────

  /// À appeler juste après [StatsService.registerGame] et
  /// [ProgressionService.registerCompletedGame], à la fin de chaque partie.
  ///
  /// [unlockedCardBackIds] = ProgressionService.progression.unlockedCardBackIds.
  static Future<void> syncAfterGame({
    required Set<String> unlockedCardBackIds,
  }) async {
    if (!_signedIn) return;

    for (final entry in cardBackAchievementIds.entries) {
      if (!unlockedCardBackIds.contains(entry.key)) continue;
      await _safeCall(
        'unlock(${entry.key})',
        () => GamesServices.unlock(
          achievement: Achievement(androidID: entry.value),
        ),
      );
    }
  }

  static Future<void> _safeCall(String label, Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      if (kDebugMode) debugPrint('[PlayGamesService] $label échoué : $e');
      // Échec silencieux (réseau, IDs non configurés, etc.) — ne doit
      // jamais impacter l'expérience de jeu.
    }
  }
}

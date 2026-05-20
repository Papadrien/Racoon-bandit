import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service centralisé Analytics — toutes les interactions Firebase Analytics
/// passent ici. Aucun écran/widget ne doit appeler FirebaseAnalytics directement.
///
/// Noms d'événements : snake_case, max 40 chars, max 25 params chacun.
/// Paramètres : snake_case, valeurs courtes, pas de données personnelles.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Appelé une seule fois depuis main(), après Firebase.initializeApp().
  /// Silencieux en cas d'échec pour ne pas bloquer le démarrage.
  void init(FirebaseAnalytics analytics) {
    _analytics = analytics;
    _initialized = true;
    _log('AnalyticsService initialisé');
  }

  // ── App ───────────────────────────────────────────────────────────────────

  /// Déclenché automatiquement par Firebase au lancement.
  /// Peut être appelé manuellement pour forcer un event app_open.
  Future<void> logAppOpen() async {
    await _send('app_open', {});
  }

  // ── Navigation / Écrans ──────────────────────────────────────────────────

  Future<void> logScreenView({required String screenName}) async {
    if (!_initialized) return;
    try {
      await _analytics!.logScreenView(screenName: screenName);
      _log('screen_view: $screenName');
    } catch (e) {
      _logError('screen_view', e);
    }
  }

  // ── Gameplay ─────────────────────────────────────────────────────────────

  Future<void> logGameStarted({
    required int nombreJoueurs,
    required bool modePagailleActif,
  }) async {
    await _send('game_started', {
      'nombre_joueurs': nombreJoueurs,
      'mode_pagaille': modePagailleActif ? 1 : 0,
    });
  }

  Future<void> logGameFinished({
    required int nombreJoueurs,
    required bool modePagailleActif,
    required String vainqueur,
    required int dureePartieEstimee,
  }) async {
    await _send('game_finished', {
      'nombre_joueurs': nombreJoueurs,
      'mode_pagaille': modePagailleActif ? 1 : 0,
      'vainqueur': vainqueur.length > 36 ? vainqueur.substring(0, 36) : vainqueur,
      'duree_estimee_s': dureePartieEstimee,
    });
  }

  // ── Vies ─────────────────────────────────────────────────────────────────

  Future<void> logLifeConsumed({required int livesRemaining}) async {
    await _send('life_consumed', {
      'vies_restantes': livesRemaining,
    });
  }

  Future<void> logLifeRestored({
    required int livesAfter,
    required String source, // 'ad' | 'timer'
  }) async {
    await _send('life_restored', {
      'vies_apres': livesAfter,
      'source': source,
    });
  }

  // ── Publicités ───────────────────────────────────────────────────────────

  Future<void> logRewardedAdLoaded() async {
    await _send('rewarded_ad_loaded', {});
  }

  Future<void> logRewardedAdShown() async {
    await _send('rewarded_ad_shown', {});
  }

  Future<void> logRewardedAdFailed({required String reason}) async {
    await _send('rewarded_ad_failed', {
      'raison': reason.length > 36 ? reason.substring(0, 36) : reason,
    });
  }

  Future<void> logRewardedAdRewarded() async {
    await _send('rewarded_ad_rewarded', {});
  }

  // ── Interne ───────────────────────────────────────────────────────────────

  Future<void> _send(String name, Map<String, Object> params) async {
    if (!_initialized || _analytics == null) {
      _log('(non initialisé) $name ignoré');
      return;
    }
    try {
      await _analytics!.logEvent(name: name, parameters: params.isEmpty ? null : params);
      _log('event: $name ${params.isNotEmpty ? params : ""}');
    } catch (e) {
      _logError(name, e);
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Analytics] $msg');
  }

  void _logError(String event, Object e) {
    if (kDebugMode) debugPrint('[Analytics] ⚠️ erreur event "$event": $e');
  }
}

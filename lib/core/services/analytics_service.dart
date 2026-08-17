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
    if (kDebugMode) {
      _log('(debug) screen_view: $screenName ignoré');
      return;
    }
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

  // ── Personnalisation ────────────────────────────────────────────────────

  /// Sélection (équipement) d'un dos de carte, depuis la bottom sheet
  /// de personnalisation ou depuis le lobby.
  Future<void> logCardBackSelected({required String cardBackId}) async {
    await _send('card_back_selected', {
      'dos_carte': cardBackId,
    });
  }

  // ── Mode Pagaille ────────────────────────────────────────────────────────

  /// Ouverture du tutoriel du mode Pagaille (icône aide dans le lobby).
  Future<void> logChaosTutorialOpened() async {
    await _send('chaos_tutorial_opened', {});
  }

  /// Activation du mode Pagaille (via le tutoriel ou le switch direct).
  Future<void> logChaosModeActivated() async {
    await _send('chaos_mode_activated', {});
  }

  // ── Lobby ────────────────────────────────────────────────────────────────

  /// Sélection du nombre de joueurs dans le lobby — un nom d'événement
  /// distinct par valeur (2, 3 ou 4 joueurs) pour un suivi simple côté
  /// Firebase, sans avoir à filtrer sur un paramètre.
  Future<void> logPlayerCountSelected(int count) async {
    final eventName = switch (count) {
      2 => 'player_count_2_selected',
      3 => 'player_count_3_selected',
      4 => 'player_count_4_selected',
      _ => 'player_count_selected',
    };
    await _send(eventName, {});
  }

  // ── Profils ──────────────────────────────────────────────────────────────

  /// Clic sur le bouton "Profils" dans les paramètres.
  Future<void> logProfilesButtonClicked() async {
    await _send('profiles_button_clicked', {});
  }

  // ── Avis (In-App Review) ────────────────────────────────────────────────

  /// [attempt] = 1 (fin de partie 2) ou 2 (fin de partie 6).
  Future<void> logReviewPromptShown({required int attempt}) async {
    await _send('review_prompt_shown', {'attempt': attempt});
  }

  // ── Interne ───────────────────────────────────────────────────────────────

  Future<void> _send(String name, Map<String, Object> params) async {
    if (!_initialized || _analytics == null) {
      _log('(non initialisé) $name ignoré');
      return;
    }
    // Analytics désactivé en debug via setAnalyticsCollectionEnabled(false),
    // mais on court-circuite aussi ici pour éviter tout appel réseau.
    if (kDebugMode) {
      _log('(debug) $name ignoré');
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

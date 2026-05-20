import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/analytics_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/game_save_service.dart';
import 'core/services/lobby_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/player_profiles_service.dart';
import 'core/services/progression_service.dart';
import 'core/services/rewarded_ad_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/stats_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  // Initialisation avec fallback silencieux : un échec Firebase ne doit
  // jamais empêcher le démarrage du jeu.
  await _initFirebase();

  // ── Services métier ───────────────────────────────────────────────────────
  await SettingsService.load();
  await PlayerProfilesService.load();
  await LobbyService.load();
  await GameSaveService.load();
  await ProgressionService.load();
  await StatsService.load();
  await OnboardingService.load();
  await RewardedAdService.initialize();

  // Préchargement des SFX fréquents — évite le délai au premier son
  await AudioService.instance.preloadAll();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const RaccoonBanditApp());
}

/// Initialise Firebase Core + Analytics.
/// En cas d'échec (pas de google-services.json, émulateur sans Play Services…),
/// l'erreur est loguée mais l'app démarre quand même.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final analytics = FirebaseAnalytics.instance;

    // En debug, activer DebugView Firebase (visible dans la console Firebase)
    if (kDebugMode) {
      await analytics.setAnalyticsCollectionEnabled(true);
    }

    AnalyticsService.instance.init(analytics);

    // Événement d'ouverture de l'app
    await AnalyticsService.instance.logAppOpen();

    if (kDebugMode) {
      debugPrint('[Firebase] Initialisé avec succès');
    }
  } catch (e, stack) {
    // Fallback silencieux — le jeu fonctionne sans analytics
    if (kDebugMode) {
      debugPrint('[Firebase] ⚠️ Échec initialisation — analytics désactivé');
      debugPrint('[Firebase] Erreur: $e');
      debugPrint('[Firebase] Stack: $stack');
    }
    // AnalyticsService reste non initialisé → tous les appels _send() sont no-op
  }
}

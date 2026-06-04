import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/app_router.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/consent_service.dart';
import '../../core/services/lobby_service.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/services/player_profiles_service.dart';
import '../../core/services/progression_service.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/stats_service.dart';
import '../../firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final navigator = Navigator.of(context);

    await _initFirebase();

    // Logs de démarrage Crashlytics — visibles dans le rapport de crash
    // uniquement si un crash survient ensuite (breadcrumbs non-fatals).
    FirebaseCrashlytics.instance.log('Services: début du chargement');

    await SettingsService.load();
    await PlayerProfilesService.load();
    await LobbyService.load();
    await ProgressionService.load();
    await StatsService.load();
    await OnboardingService.load();

    FirebaseCrashlytics.instance.log('Services: chargement terminé');

    // ── Consentement UMP ────────────────────────────────────────────────────
    // Le formulaire UMP doit être traité AVANT d'initialiser AdMob,
    // conformément aux exigences Google et aux règles de la politique de
    // consentement pour l'EEE/UK (RGPD / PECR).
    if (mounted) {
      await ConsentService.instance.requestAndShow(context);
    }

    // ── Initialisation AdMob ────────────────────────────────────────────────
    // MobileAds.initialize() est appelé dans tous les cas (y compris si le
    // consentement n'est pas requis dans la région de l'utilisateur), car
    // l'initialisation ne déclenche pas de chargement personnalisé par elle-même.
    await RewardedAdService.initialize();

    // Pré-chargement de la publicité récompensée uniquement si autorisé
    if (ConsentService.instance.canRequestAds) {
      await RewardedAdService.instance.preloadAd();
    }

    await AudioService.instance.preloadAll();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    FirebaseCrashlytics.instance.log('Démarrage terminé — navigation vers home');

    if (!mounted) return;
    navigator.pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ── Crashlytics ──────────────────────────────────────────────────────
      // Désactivé en debug pour ne pas polluer le tableau de bord Firebase.
      // En release, la collection est activée automatiquement.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      FirebaseCrashlytics.instance.log('Application démarrée');

      // ── Analytics ────────────────────────────────────────────────────────
      final analytics = FirebaseAnalytics.instance;
      if (kDebugMode) {
        await analytics.setAnalyticsCollectionEnabled(true);
      }
      AnalyticsService.instance.init(analytics);
      await AnalyticsService.instance.logAppOpen();

      if (kDebugMode) debugPrint('[Firebase] Initialisé avec succès');
    } catch (e) {
      if (kDebugMode) debugPrint('[Firebase] ⚠️ Échec initialisation: $e');
      // Si Firebase lui-même échoue à s'initialiser, on ne peut pas utiliser
      // Crashlytics — on laisse passer silencieusement pour ne pas bloquer l'app.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo.png',
          width: MediaQuery.sizeOf(context).width * 0.8,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}

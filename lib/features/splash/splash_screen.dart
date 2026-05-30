import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/app_router.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/audio_service.dart';
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
    await _initFirebase();
    await SettingsService.load();
    await PlayerProfilesService.load();
    await LobbyService.load();
    await ProgressionService.load();
    await StatsService.load();
    await OnboardingService.load();
    await RewardedAdService.initialize();
    await AudioService.instance.preloadAll();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final analytics = FirebaseAnalytics.instance;
      if (kDebugMode) {
        await analytics.setAnalyticsCollectionEnabled(true);
      }
      AnalyticsService.instance.init(analytics);
      await AnalyticsService.instance.logAppOpen();
      if (kDebugMode) debugPrint('[Firebase] Initialisé avec succès');
    } catch (e) {
      if (kDebugMode) debugPrint('[Firebase] ⚠️ Échec initialisation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo.png',
          width: MediaQuery.sizeOf(context).width,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}

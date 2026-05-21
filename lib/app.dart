import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_router.dart';
import 'core/services/analytics_service.dart';
import 'core/services/audio_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';
import 'l10n/app_localizations.dart';

/// Widget racine de l'application.
///
/// Observe le cycle de vie pour suspendre/reprendre l'audio
/// proprement (mise en arrière-plan, fermeture).
class RaccoonBanditApp extends StatefulWidget {
  const RaccoonBanditApp({super.key});

  @override
  State<RaccoonBanditApp> createState() => _RaccoonBanditAppState();
}

class _RaccoonBanditAppState extends State<RaccoonBanditApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Libère les ressources audio à la fermeture de l'app
    AudioService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stoppe tous les sons si l'app passe en arrière-plan
    // (évite sons bloqués ou erreurs audio système)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AudioService.instance.stopAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reconstruit MaterialApp quand l'accent change (changement de dos de carte)
    return ListenableBuilder(
      listenable: AppThemeProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Raccoon Bandit',
          debugShowCheckedModeBanner: false,
          // ── Localisation FR/EN ─────────────────────────────────────────
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
          ],
          // FR par défaut, EN si langue système anglaise, FR sinon
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return const Locale('fr');
            for (final supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode) {
                return supported;
              }
            }
            return const Locale('fr');
          },
          // ───────────────────────────────────────────────────────────────
          theme: AppTheme.dark.copyWith(
            colorScheme: AppTheme.dark.colorScheme.copyWith(
              secondary: AppThemeProvider.instance.accent,
            ),
          ),
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRouter.generateRoute,
          // Observateur Analytics pour le suivi automatique des routes
          navigatorObservers: [
            _AnalyticsNavigatorObserver(),
          ],
        );
      },
    );
  }
}

/// Observateur de navigation qui logue screen_view à chaque changement de route.
/// Évite de dupliquer l'appel logScreenView() dans chaque écran.
class _AnalyticsNavigatorObserver extends NavigatorObserver {
  static const _routeToScreen = {
    AppRoutes.home: 'home',
    AppRoutes.lobby: 'lobby',
    AppRoutes.game: 'game',
    AppRoutes.result: 'result',
    AppRoutes.profiles: 'profiles',
    AppRoutes.settings: 'settings',
    AppRoutes.premium: 'premium',
    AppRoutes.privacyPolicy: 'privacy_policy',
  };

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _trackRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _trackRoute(newRoute);
  }

  void _trackRoute(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName == null) return;
    final screenName = _routeToScreen[routeName] ?? routeName;
    AnalyticsService.instance.logScreenView(screenName: screenName);
  }
}

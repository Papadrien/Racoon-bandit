import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_router.dart';
import 'core/services/analytics_service.dart';
import 'core/services/audio_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

/// Notifier pour forcer une locale en mode debug.
/// Null = comportement par défaut (résolution système).
final ValueNotifier<Locale?> debugLocaleOverride = ValueNotifier<Locale?>(null);

/// Widget racine de l'application.
class RaccoonBanditApp extends StatefulWidget {
  const RaccoonBanditApp({super.key});

  @override
  State<RaccoonBanditApp> createState() => _RaccoonBanditAppState();
}

class _RaccoonBanditAppState extends State<RaccoonBanditApp> {
  @override
  void dispose() {
    // Libère les ressources audio à la fermeture de l'app
    AudioService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: debugLocaleOverride,
      builder: (context, overrideLocale, _) {
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
          locale: overrideLocale,
          // FR par défaut, EN si langue système anglaise, FR sinon
          localeResolutionCallback: (locale, supportedLocales) {
            if (overrideLocale != null) return overrideLocale;
            if (locale == null) return const Locale('fr');
            for (final supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode) {
                return supported;
              }
            }
            return const Locale('fr');
          },
          // ───────────────────────────────────────────────────────────────
          theme: AppTheme.dark,
          initialRoute: AppRoutes.splash,
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

import 'package:flutter/material.dart';

import '../../features/game/game_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/lobby/lobby_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/profiles/profiles_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String lobby = '/lobby';
  static const String game = '/game';
  static const String result = '/result';
  static const String settings = '/settings';
  static const String premium = '/premium';
  static const String profiles = '/profiles';
  // Onboarding — utilisé pour futurs tutoriels standalone
  static const String onboarding = '/onboarding';
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case AppRoutes.home:
        return _fade(const HomeScreen(), routeSettings);
      case AppRoutes.lobby:
        return _fade(const LobbyScreen(), routeSettings);
      case AppRoutes.game:
        return _fade(const GameScreen(), routeSettings);
      case AppRoutes.result:
        return _fade(const ResultScreen(), routeSettings);
      case AppRoutes.settings:
        return _slide(const SettingsScreen(), routeSettings);
      case AppRoutes.premium:
        return _slide(const PremiumScreen(), routeSettings);
      case AppRoutes.profiles:
        return _slide(const ProfilesScreen(), routeSettings);
      case AppRoutes.onboarding:
        return _fade(
          Builder(
            builder: (context) => OnboardingScreen(
              onDone: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ),
          routeSettings,
        );
      default:
        return _fade(const HomeScreen(), routeSettings);
    }
  }

  static PageRouteBuilder<void> _fade(Widget page, RouteSettings s) =>
      PageRouteBuilder<void>(
        settings: s,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      );

  static PageRouteBuilder<void> _slide(Widget page, RouteSettings s) =>
      PageRouteBuilder<void>(
        settings: s,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, anim, secondaryAnimation, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      );
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utilitaire centralisé pour la navigation sécurisée.
///
/// Fournit :
/// - Protection contre le double-pop (navigationInProgress)
/// - Nettoyage des overlays avant navigation
/// - Logs debug en mode debug uniquement
class NavigationGuard {
  NavigationGuard._();

  // ── Debug logging ──────────────────────────────────────────────────────────

  static void log(String tag, String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[$tag] $message');
    }
  }

  // ── Safe pop ───────────────────────────────────────────────────────────────

  /// Pop sécurisé : vérifie [mounted], [canPop] et [navigationInProgress]
  /// avant d'exécuter. Appelle [beforePop] pour nettoyer overlays/dialogs.
  ///
  /// Retourne true si la navigation a eu lieu.
  static bool safePop(
    BuildContext context, {
    required bool mounted,
    required bool navigationInProgress,
    VoidCallback? beforePop,
    Object? result,
    String debugTag = 'Nav',
  }) {
    if (!mounted) {
      log(debugTag, 'safePop — ignored: not mounted');
      return false;
    }
    if (navigationInProgress) {
      log(debugTag, 'safePop — ignored: navigation already in progress');
      return false;
    }

    final navigator = Navigator.of(context, rootNavigator: false);
    if (!navigator.canPop()) {
      log(debugTag, 'safePop — ignored: cannot pop');
      return false;
    }

    beforePop?.call();
    log(debugTag, 'safePop — popping');
    navigator.pop(result);
    return true;
  }

  /// Push nommé sécurisé : vérifie [mounted] et [navigationInProgress].
  static void safePushNamed(
    BuildContext context,
    String routeName, {
    required bool mounted,
    required bool navigationInProgress,
    Object? arguments,
    String debugTag = 'Nav',
  }) {
    if (!mounted || navigationInProgress) {
      log(debugTag, 'safePushNamed($routeName) — ignored');
      return;
    }
    log(debugTag, 'safePushNamed → $routeName');
    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  /// pushNamedAndRemoveUntil sécurisé.
  static void safePushAndClear(
    BuildContext context,
    String routeName, {
    required bool mounted,
    required bool navigationInProgress,
    RoutePredicate? predicate,
    Object? arguments,
    String debugTag = 'Nav',
  }) {
    if (!mounted || navigationInProgress) {
      log(debugTag, 'safePushAndClear($routeName) — ignored');
      return;
    }
    log(debugTag, 'safePushAndClear → $routeName');
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }
}

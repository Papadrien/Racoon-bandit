import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() async {
  // runZonedGuarded capture toutes les exceptions Dart non gérées
  // (asynchrones incluses) et les transmet à Crashlytics.
  await runZonedGuarded<Future<void>>(
    _bootstrap,
    (Object error, StackTrace stack) {
      // Exceptions asynchrones non capturées (Future, Stream, isolates...)
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        debugPrint('[Zone] Exception non gérée : $error\n$stack');
      }
    },
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Erreurs Flutter (widgets, rendering, framework) ─────────────────────
  // Remplace le handler par défaut qui affiche l'écran rouge en debug.
  // En release, Flutter ne remonte ces erreurs nulle part sans ce hook.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // Comportement standard en debug : afficher dans la console
      FlutterError.dumpErrorToConsole(details);
    } else {
      // En production : envoyer à Crashlytics comme erreur fatale
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // ── Erreurs moteur / plateforme ──────────────────────────────────────────
  // Capture les erreurs provenant du moteur Flutter ou du canal plateforme
  // qui ne passent pas par FlutterError.onError.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      debugPrint('[PlatformDispatcher] Erreur : $error\n$stack');
    }
    return true; // true = erreur consommée, ne pas propager
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  imageCache.maximumSize = 200;
  imageCache.maximumSizeBytes = 150 << 20;

  runApp(const RaccoonBanditApp());
}

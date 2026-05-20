// fichier généré par FlutterFire CLI.
// À regénérer via : flutterfire configure
// Documentation : https://firebase.flutter.dev/docs/cli/

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options Firebase par plateforme.
///
/// ⚠️  Ce fichier contient des clés de projet Firebase.
///     Remplacer les valeurs REPLACE_* par celles de votre projet Firebase
///     (Console Firebase → Paramètres du projet → Vos applications).
///
/// Pour regénérer automatiquement :
///   1. Installer FlutterFire CLI : dart pub global activate flutterfire_cli
///   2. Lancer : flutterfire configure
///   3. Ce fichier sera écrasé avec les vraies valeurs.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Raccoon Bandit ne supporte pas le Web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Plateforme non supportée : $defaultTargetPlatform',
        );
    }
  }

  /// ── Android ─────────────────────────────────────────────────────────────
  /// Valeurs à remplacer par celles du vrai projet Firebase.
  /// Source : google-services.json → client[0]
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ANDROID_API_KEY',
    appId: 'REPLACE_ANDROID_APP_ID',           // mobilesdk_app_id
    messagingSenderId: 'REPLACE_PROJECT_NUMBER',
    projectId: 'REPLACE_PROJECT_ID',
    storageBucket: 'REPLACE_PROJECT_ID.appspot.com',
  );

  /// ── iOS ─────────────────────────────────────────────────────────────────
  /// Valeurs à remplacer par celles du vrai projet Firebase.
  /// Source : GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_IOS_API_KEY',
    appId: 'REPLACE_IOS_APP_ID',
    messagingSenderId: 'REPLACE_PROJECT_NUMBER',
    projectId: 'REPLACE_PROJECT_ID',
    storageBucket: 'REPLACE_PROJECT_ID.appspot.com',
    iosClientId: 'REPLACE_IOS_CLIENT_ID',
    iosBundleId: 'fr.junade.raccoonBandit',
  );
}

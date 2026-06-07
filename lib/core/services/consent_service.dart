import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service singleton gérant le consentement publicitaire via Google UMP.
///
/// Flux recommandé par Google :
///   1. [requestAndShow] au démarrage (avant MobileAds.initialize)
///   2. [canRequestAds] indique si les pubs peuvent être chargées
///   3. [showPrivacyOptionsForm] depuis les Paramètres si [privacyOptionsRequired]
///
/// Ref : https://developers.google.com/admob/flutter/privacy
class ConsentService {
  ConsentService._();

  static final ConsentService instance = ConsentService._();

  // ── API publique ───────────────────────────────────────────────────────────

  /// Vrai si AdMob est autorisé à charger des publicités.
  /// En cas d'erreur SDK, retourne true par bénéfice du doute pour ne pas
  /// bloquer silencieusement les publicités en mode release.
  Future<bool> canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      if (kDebugMode) debugPrint('[Consent] canRequestAds erreur : $e');
      return true; // Bénéfice du doute si le SDK échoue (ex. hors EEE)
    }
  }

  /// Vrai si le bouton "Gérer mes préférences publicitaires" doit être affiché.
  Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      if (kDebugMode) debugPrint('[Consent] privacyOptionsRequired erreur : $e');
      return false;
    }
  }

  /// Demande une mise à jour du statut UMP, puis affiche le formulaire si
  /// nécessaire. À appeler au démarrage avant MobileAds.initialize().
  /// Les erreurs sont absorbées pour ne pas bloquer le démarrage.
  Future<void> requestAndShow() async {
    try {
      await _requestUpdate();
      await _showFormIfRequired();
    } catch (e) {
      if (kDebugMode) debugPrint('[Consent] Erreur UMP : $e');
    }
  }

  /// Ouvre le formulaire de gestion des préférences publicitaires.
  /// À appeler depuis l'écran Paramètres.
  Future<void> showPrivacyOptionsForm() async {
    try {
      final completer = Completer<void>();
      ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (error != null && kDebugMode) {
          debugPrint('[Consent] Formulaire vie privée : ${error.message}');
        }
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    } catch (e) {
      if (kDebugMode) debugPrint('[Consent] showPrivacyOptionsForm : $e');
    }
  }

  // ── Privé ──────────────────────────────────────────────────────────────────

  Future<void> _requestUpdate() async {
    final completer = Completer<void>();

    // Pour tester le formulaire UMP en debug sur un appareil hors-EEE,
    // décommentez le bloc consentDebugSettings ci-dessous et remplacez
    // YOUR_TEST_DEVICE_ID par l'identifiant de l'appareil de test.
    final params = ConsentRequestParameters(
      // consentDebugSettings: kDebugMode
      //     ? ConsentDebugSettings(
      //         debugGeography: DebugGeography.debugGeographyEea,
      //         testIdentifiers: ['YOUR_TEST_DEVICE_ID'],
      //       )
      //     : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (FormError error) {
        if (kDebugMode) {
          debugPrint('[Consent] requestConsentInfoUpdate : ${error.message}');
        }
        if (!completer.isCompleted) completer.complete(); // ne pas bloquer
      },
    );

    // Timeout de sécurité en cas d'absence réseau ou de bug SDK.
    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        if (kDebugMode) debugPrint('[Consent] requestConsentInfoUpdate timeout');
      },
    );
  }

  Future<void> _showFormIfRequired() async {
    final completer = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null && kDebugMode) {
        debugPrint('[Consent] loadAndShowConsentFormIfRequired : ${error.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });

    // Timeout de sécurité : si le callback UMP ne se déclenche jamais
    // (bug SDK, réseau absent), on ne bloque pas indéfiniment le démarrage.
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) debugPrint('[Consent] showFormIfRequired timeout — poursuite du démarrage');
      },
    );
  }
}

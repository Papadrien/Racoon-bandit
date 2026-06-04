import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  /// Couvre : consentement obtenu, zone non-EEE/UK, formulaire non requis.
  bool get canRequestAds {
    final consent = ConsentInformation.instance.consentStatus;
    return consent == ConsentStatus.obtained ||
        consent == ConsentStatus.notRequired;
  }

  /// Vrai si le bouton "Gérer mes préférences publicitaires" doit être affiché
  /// dans les paramètres.
  bool get privacyOptionsRequired =>
      ConsentInformation.instance.privacyOptionsRequirementStatus ==
      PrivacyOptionsRequirementStatus.required;

  /// Demande une mise à jour du statut UMP, puis affiche le formulaire si
  /// nécessaire. À appeler au démarrage avant MobileAds.initialize().
  /// Les erreurs sont absorbées pour ne pas bloquer le démarrage.
  Future<void> requestAndShow(BuildContext context) async {
    try {
      await _requestUpdate();
      if (!context.mounted) return;
      await _showFormIfRequired(context);
    } catch (e) {
      if (kDebugMode) debugPrint('[Consent] Erreur UMP : $e');
    }
  }

  /// Ouvre le formulaire de gestion des préférences publicitaires.
  /// À appeler depuis l'écran Paramètres.
  Future<void> showPrivacyOptionsForm(BuildContext context) async {
    try {
      await ConsentForm.showPrivacyOptionsForm(
        context,
        (FormError? error) {
          if (error != null && kDebugMode) {
            debugPrint('[Consent] Formulaire vie privée : ${error.message}');
          }
        },
      );
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

    await completer.future;
  }

  Future<void> _showFormIfRequired(BuildContext context) async {
    await ConsentForm.loadAndShowConsentFormIfRequired(
      context,
      (FormError? error) {
        if (error != null && kDebugMode) {
          debugPrint('[Consent] loadAndShowConsentFormIfRequired : ${error.message}');
        }
      },
    );
  }
}

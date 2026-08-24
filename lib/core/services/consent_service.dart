import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service singleton gérant le consentement publicitaire via Google UMP.
///
/// IMPORTANT — Public cible déclaré dans Play Console : "5 ans et moins",
/// "6-8", "9-12" uniquement (aucune tranche 13+). L'app est donc
/// entièrement dirigée vers des enfants au sens COPPA. Google interdit
/// explicitement de faire passer un formulaire de consentement UMP/RGPD
/// classique à des utilisateurs tagués enfants (un enfant ne peut pas
/// donner un consentement légalement valable) :
/// https://developers.google.com/admob/flutter/privacy/gdpr#child_directed_treatment
///
/// Le formulaire UMP est donc désactivé ici : la non-personnalisation des
/// annonces est déjà garantie côté requête par tagForChildDirectedTreatment
/// / tagForUnderAgeOfConsent (voir RewardedAdService.initialize()).
///
/// Ref : https://developers.google.com/admob/flutter/privacy
class ConsentService {
  ConsentService._();

  static final ConsentService instance = ConsentService._();

  // ── API publique ───────────────────────────────────────────────────────────

  /// Vrai si AdMob est autorisé à charger des publicités.
  /// L'app étant entièrement dirigée vers les enfants, les annonces sont
  /// systématiquement non personnalisées via TFCD/TFUA : pas besoin de
  /// passer par le statut de consentement UMP pour décider si on peut
  /// charger des pubs.
  Future<bool> canRequestAds() async => true;

  /// Vrai si le bouton "Gérer mes préférences publicitaires" doit être
  /// affiché. Non applicable pour un public entièrement enfant (pas de
  /// formulaire de consentement UMP à gérer) — voir note de classe.
  Future<bool> privacyOptionsRequired() async => false;

  /// Ne fait plus rien : le formulaire UMP ne doit pas être présenté à un
  /// public entièrement enfant. Conservé pour compatibilité d'appel avec
  /// le flux de démarrage (splash_screen.dart).
  Future<bool> requestAndShow() async => true;

  /// Ouvre le formulaire de gestion des préférences publicitaires.
  /// Ne devrait plus être atteignable depuis les Paramètres tant que
  /// [privacyOptionsRequired] renvoie false ; conservé par sécurité mais
  /// ne devrait pas être appelé pour ce public.
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
}

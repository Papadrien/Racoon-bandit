import 'dart:async';

import 'analytics_service.dart';
import 'consent_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _rewardedInterstitialAd;
  Completer<bool>? _loadCompleter;

  bool _isLoading = false;
  bool _isShowing = false;
  bool _isShowRequested = false; // garde-fou anti double-clic précoce
  bool _hasRewardBeenGranted = false;

  static const Duration _loadTimeout = Duration(seconds: 8);

  bool get isAdReady => _rewardedInterstitialAd != null;

  static Future<void> initialize() async {
    // Configuration globale AdMob :
    // - L'app est familiale mais n'est PAS inscrite au programme Google Families.
    //   tagForChildDirectedTreatment doit donc rester à "unspecified" (valeur par défaut).
    // - Le consentement UMP gère la personnalisation selon la région de l'utilisateur.
    await MobileAds.instance.initialize();
  }

  Future<void> preloadAd() async {
    if (_rewardedInterstitialAd != null || _isLoading) return;

    // On marque _isLoading=true AVANT le await canRequestAds() pour éviter
    // une race condition : si deux appels arrivent simultanément, le second
    // sort immédiatement sur le check ci-dessus, au lieu de lancer un second
    // chargement concurrent qui disposerait le premier.
    _isLoading = true;
    _loadCompleter = Completer<bool>();

    // Ne pas charger de publicité si le consentement n'a pas été obtenu ou
    // n'est pas requis dans la région de l'utilisateur.
    bool canRequest = true;
    try {
      canRequest = await ConsentService.instance.canRequestAds();
    } catch (_) {}

    debugPrint('[Ads] canRequestAds=$canRequest');
    if (!canRequest) {
      debugPrint('[Ads] canRequestAds=false, forcing ad load');
    }

    unawaited(
      RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedInterstitialAd?.dispose();
            _rewardedInterstitialAd = ad;
            _isLoading = false;
            if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
              _loadCompleter!.complete(true);
            }
            _loadCompleter = null;
            AnalyticsService.instance.logRewardedAdLoaded();
          },
          onAdFailedToLoad: (error) {
            // Log en debug ET en release pour diagnostiquer les échecs prod.
            debugPrint('[Ads] Failed to preload (code=${error.code}): ${error.message}');
            if (!kDebugMode) {
              FirebaseCrashlytics.instance.recordError(
                '[Ads] Failed to load: ${error.code} — ${error.message}',
                null,
                reason: 'rewarded_ad_load_failed',
                fatal: false,
              );
            }
            _rewardedInterstitialAd = null;
            _isLoading = false;
            if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
              _loadCompleter!.complete(false);
            }
            _loadCompleter = null;
            AnalyticsService.instance
                .logRewardedAdFailed(reason: '${error.code}: ${error.message}');
          },
        ),
      ),
    );
  }

  Future<bool> showRewardedLifeAd({
    required VoidCallback onRewardEarned,
    required ValueChanged<String> onError,
  }) async {
    // Garde-fou le plus précoce possible — bloque les doubles clics
    if (_isShowRequested || _isShowing) return false;
    _isShowRequested = true;

    try {
      // Si pas prête et pas en chargement, lancer le chargement maintenant.
      // On capture le completer APRÈS preloadAd() car canRequestAds() peut
      // retourner false et sortir sans créer de completer (dans ce cas,
      // _loadCompleter reste null et _isLoading reste false).
      if (_rewardedInterstitialAd == null && !_isLoading) {
        await preloadAd();
      }

      // Si en chargement (lancé maintenant ou déjà en cours), attendre avec timeout.
      // Note : on relit _loadCompleter ici (pas une capture préalable) car
      // preloadAd() ci-dessus vient peut-être de le créer.
      if (_rewardedInterstitialAd == null && _isLoading) {
        final completer = _loadCompleter;
        if (completer != null) {
          await completer.future.timeout(
            _loadTimeout,
            onTimeout: () {
              if (kDebugMode) print('[Ads] Load timeout after ${_loadTimeout.inSeconds}s');
              // Résoudre le completer bloqué et réinitialiser l'état de chargement
              if (!completer.isCompleted) completer.complete(false);
              _isLoading = false;
              _loadCompleter = null;
              return false;
            },
          );
        } else {
          // _loadCompleter est null mais _isLoading est true : situation anormale
          // (preloadAd() a été interrompu par canRequestAds()=false par exemple).
          // On réinitialise pour éviter un état bloqué.
          if (kDebugMode) print('[Ads] _isLoading=true but no completer — resetting');
          _isLoading = false;
        }
      }

      // Toujours pas prête = vrai échec réseau ou timeout
      if (_rewardedInterstitialAd == null) {
        unawaited(preloadAd());
        onError('Une erreur est survenue, veuillez réessayer.');
        return false;
      }

      _hasRewardBeenGranted = false;
      _isShowing = true;

      try {
        _rewardedInterstitialAd!.fullScreenContentCallback =
            FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _resetState();
            unawaited(preloadAd());
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _resetState();
            unawaited(preloadAd());
            onError('Une erreur est survenue, veuillez réessayer.');
          },
        );

        AnalyticsService.instance.logRewardedAdShown();

        await _rewardedInterstitialAd!.show(
          onUserEarnedReward: (_, reward) {
            if (_hasRewardBeenGranted) return;
            _hasRewardBeenGranted = true;
            AnalyticsService.instance.logRewardedAdRewarded();
            onRewardEarned();
          },
        );

        return true;
      } catch (e) {
        if (kDebugMode) print('[Ads] Unexpected error: $e');
        _resetState();
        unawaited(preloadAd());
        onError('Une erreur est survenue, veuillez réessayer.');
        return false;
      }
    } finally {
      // Toujours libérer le verrou de demande, même en cas d'erreur inattendue
      _isShowRequested = false;
    }
  }

  void _resetState() {
    _rewardedInterstitialAd = null;
    _isLoading = false;
    _isShowing = false;
    _isShowRequested = false;
    _hasRewardBeenGranted = false;
  }

  String get _adUnitId {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ca-app-pub-3940256099942544/5224354917';
      }
      return 'ca-app-pub-3940256099942544/6978759866';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-7203301690798915/2347010041';
    }
    return 'ca-app-pub-7203301690798915/4781601694';
  }
}

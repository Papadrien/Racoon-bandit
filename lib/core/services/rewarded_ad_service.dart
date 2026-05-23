import 'dart:async';

import 'analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  RewardedInterstitialAd? _rewardedInterstitialAd;
  Completer<bool>? _loadCompleter;

  bool _isLoading = false;
  bool _isShowing = false;
  bool _hasRewardBeenGranted = false;

  bool get isAdReady => _rewardedInterstitialAd != null;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  Future<void> preloadAd() async {
    if (_rewardedInterstitialAd != null || _isLoading) return;

    _isLoading = true;
    _loadCompleter = Completer<bool>();

    await RewardedInterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd?.dispose();
          _rewardedInterstitialAd = ad;
          _isLoading = false;
          _loadCompleter?.complete(true);
          _loadCompleter = null;
          AnalyticsService.instance.logRewardedAdLoaded();
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) print('[Ads] Failed to preload: ${error.message}');
          _rewardedInterstitialAd = null;
          _isLoading = false;
          _loadCompleter?.complete(false);
          _loadCompleter = null;
          AnalyticsService.instance.logRewardedAdFailed(reason: error.message);
        },
      ),
    );
  }

  Future<bool> showRewardedLifeAd({
    required VoidCallback onRewardEarned,
    required ValueChanged<String> onError,
  }) async {
    if (_isShowing) return false;

    // Si pas prête et pas en chargement, lancer le chargement maintenant
    if (_rewardedInterstitialAd == null && !_isLoading) {
      await preloadAd();
    }

    // Si en chargement (lancé maintenant ou déjà en cours), attendre la fin
    if (_rewardedInterstitialAd == null && _isLoading) {
      await _loadCompleter?.future;
    }

    // Toujours pas prête = vrai échec réseau
    if (_rewardedInterstitialAd == null) {
      preloadAd();
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
          preloadAd();
          // Pas de message si l'utilisateur ferme sans regarder entièrement
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _resetState();
          preloadAd();
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
      preloadAd();
      onError('Une erreur est survenue, veuillez réessayer.');
      return false;
    }
  }

  void _resetState() {
    _rewardedInterstitialAd = null;
    _isLoading = false;
    _isShowing = false;
    _hasRewardBeenGranted = false;
  }

  String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/5354046379';
    }
    return 'ca-app-pub-3940256099942544/6978759866';
  }
}

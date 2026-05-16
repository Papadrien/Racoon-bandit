import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  RewardedInterstitialAd? _rewardedInterstitialAd;

  bool _isLoading = false;
  bool _isShowing = false;
  bool _hasRewardBeenGranted = false;

  bool get isBusy => _isLoading || _isShowing;
  bool get isAdReady => _rewardedInterstitialAd != null;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  Future<void> preloadAd() async {
    if (_rewardedInterstitialAd != null || _isLoading) {
      return;
    }

    _isLoading = true;

    await RewardedInterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd?.dispose();
          _rewardedInterstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('[Ads] Failed to preload ad: ${error.message}');
          }

          _rewardedInterstitialAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  Future<bool> showRewardedLifeAd({
    required VoidCallback onRewardEarned,
    required ValueChanged<String> onError,
  }) async {
    if (_isShowing) {
      onError('Une publicité est déjà en cours.');
      return false;
    }

    if (_rewardedInterstitialAd == null) {
      preloadAd();
      onError('Préparation de la publicité...');
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

          if (!_hasRewardBeenGranted) {
            onError('La publicité doit être regardée entièrement.');
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _resetState();
          preloadAd();
          onError('Impossible d\'afficher la publicité.');
        },
      );

      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (_, reward) {
          if (_hasRewardBeenGranted) {
            return;
          }

          _hasRewardBeenGranted = true;
          onRewardEarned();
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[Ads] Unexpected error: $e');
      }

      _resetState();
      preloadAd();
      onError('Une erreur est survenue avec la publicité.');
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

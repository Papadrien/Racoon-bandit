import 'dart:developer';

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

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    log('[Ads] Mobile ads initialized');
  }

  Future<bool> showRewardedLifeAd({
    required VoidCallback onRewardEarned,
    required ValueChanged<String> onError,
  }) async {
    if (_isLoading || _isShowing) {
      log('[Ads] Ad already loading/showing');
      onError('Une publicité est déjà en cours.');
      return false;
    }

    _isLoading = true;
    _hasRewardBeenGranted = false;

    try {
      log('[Ads] Loading rewarded interstitial');

      await RewardedInterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback:
            RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            log('[Ads] Rewarded interstitial loaded');
            _rewardedInterstitialAd = ad;
          },
          onAdFailedToLoad: (error) {
            log('[Ads] Failed to load ad: ${error.message}');
            onError('Publicité indisponible pour le moment.');
          },
        ),
      );

      if (_rewardedInterstitialAd == null) {
        _isLoading = false;
        return false;
      }

      _isLoading = false;
      _isShowing = true;

      _rewardedInterstitialAd!.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          log('[Ads] Ad dismissed');
          ad.dispose();
          _resetState();

          if (!_hasRewardBeenGranted) {
            onError('La publicité doit être regardée entièrement.');
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          log('[Ads] Failed to show ad: ${error.message}');
          ad.dispose();
          _resetState();
          onError('Impossible d\'afficher la publicité.');
        },
      );

      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (_, reward) {
          if (_hasRewardBeenGranted) {
            return;
          }

          _hasRewardBeenGranted = true;
          log('[Ads] Reward earned: ${reward.amount} ${reward.type}');
          onRewardEarned();
        },
      );

      return true;
    } catch (e) {
      log('[Ads] Unexpected error: $e');
      _resetState();
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

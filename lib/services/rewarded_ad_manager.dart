import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isShowingAd = false;

  void loadAd(
      {required Function(RewardItem reward) onUserEarnedReward,
      VoidCallback? onAdClosed}) {
    if (_isShowingAd) return;

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _showAd(
              onUserEarnedReward: onUserEarnedReward, onAdClosed: onAdClosed);
        },
        onAdFailedToLoad: (err) {
          debugPrint('RewardedAd failed to load: $err');
          _isShowingAd = false;
        },
      ),
    );
    _isShowingAd = true;
  }

  void _showAd(
      {required Function(RewardItem reward) onUserEarnedReward,
      VoidCallback? onAdClosed}) {
    if (_rewardedAd == null) {
      _isShowingAd = false;
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        if (onAdClosed != null) onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        if (onAdClosed != null) onAdClosed();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onUserEarnedReward(reward);
    });
  }
}

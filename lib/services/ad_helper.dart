import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1262632864876102/2336908044';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1262632864876102/2336908044';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1262632864876102/1439923063';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1262632864876102/1439923063';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1262632864876102/9126841392';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1262632864876102/9126841392';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // インタースティシャル広告の管理
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  static void loadInterstitialAd({VoidCallback? onAdLoaded}) {
    if (_isInterstitialAdLoading) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  static void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_interstitialAd == null) {
      onAdClosed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // 次回のためにプリロード
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onAdClosed?.call();
      },
    );

    _interstitialAd!.show();
  }

  // 広告読み込み中ダイアログ（利便性のため）
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('広告を読み込み中...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 初期化
  static Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    loadInterstitialAd(); // 起動時に1回プリロード
  }
}

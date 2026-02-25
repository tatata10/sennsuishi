import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // テスト用のアドユニットID（本番用はGoogle AdMob管理画面で取得して差し替えてください）
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Android テスト用バナー広告ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // iOS テスト用バナー広告ID
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Android テスト用インタースティシャル広告ID
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      // iOS テスト用インタースティシャル広告ID
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      // Android テスト用リワード広告ID
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      // iOS テスト用リワード広告ID
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // 初期化
  static Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
  }
}

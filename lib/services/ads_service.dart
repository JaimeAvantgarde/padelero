import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// IDs de AdMob (Google Mobile Ads SDK).
/// En debug se usan IDs de prueba; en release el bloque de anuncios de la app.
class AdUnitIds {
  /// Banner: tipo Banner, tamaño estándar 320x50.
  /// Emplazamiento: parte inferior de la pantalla Home (anchura completa, centrado).
  static String get banner {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-5598736675820629/ANDROID_BANNER_ID' // TODO: Reemplazar con ID real de Android
        : 'ca-app-pub-5598736675820629/1355210898';
  }

  /// Interstitial: se muestra al terminar un partido (solo versión gratuita).
  static String get interstitial {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-5598736675820629/ANDROID_INTERSTITIAL_ID' // TODO: Reemplazar con ID real de Android
        : 'ca-app-pub-5598736675820629/IOS_INTERSTITIAL_ID'; // TODO: Reemplazar con ID real de iOS
  }
}

/// Inicialización y carga de anuncios.
class AdsService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdsService: failed to initialize: $e');
    }
  }

  static InterstitialAd? _interstitialAd;
  static bool _isLoadingInterstitial = false;

  static Future<void> loadInterstitial() async {
    if (!_initialized) return;
    if (_interstitialAd != null || _isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial(); // Precargar el siguiente
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdsService: interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdsService: interstitial failed to load: $error');
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  /// Muestra el interstitial si está cargado (ej. al terminar un partido).
  static Future<void> showInterstitialIfLoaded() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
    }
  }

  static void disposeInterstitial() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

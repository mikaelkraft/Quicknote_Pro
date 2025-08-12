import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'premium_service.dart';
import 'consent_service.dart';

/// Service for managing AdMob advertisements
class AdsService extends ChangeNotifier {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  // Ad Unit IDs - Replace with your actual AdMob unit IDs
  static const String _bannerAdUnitId = kDebugMode
      ? (Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/6300978111' // Test banner
          : 'ca-app-pub-3940256099942544/2934735716')
      : (Platform.isAndroid 
          ? 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_ID'
          : 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_ID');

  static const String _interstitialAdUnitId = kDebugMode
      ? (Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/1033173712' // Test interstitial
          : 'ca-app-pub-3940256099942544/4411468910')
      : (Platform.isAndroid 
          ? 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_ID'
          : 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_ID');

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isAdInitialized = false;
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  
  int _interstitialAdCounter = 0;
  static const int _interstitialFrequency = 3; // Show every 3 actions

  // Getters
  BannerAd? get bannerAd => _bannerAd;
  bool get isAdInitialized => _isAdInitialized;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;

  /// Initialize AdMob
  Future<void> initialize() async {
    try {
      // Check if user has premium (no ads for premium users)
      final premiumService = PremiumService();
      if (premiumService.adFree) {
        debugPrint('User has premium - ads disabled');
        return;
      }

      // Check consent status
      final consentService = ConsentService();
      await consentService.initialize();
      
      if (!consentService.canShowAds) {
        debugPrint('No ad consent - ads disabled');
        return;
      }

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      // Set request configuration
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        testDeviceIds: kDebugMode ? ['YOUR_TEST_DEVICE_ID'] : [],
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
      );
      MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      _isAdInitialized = true;
      
      // Load initial ads
      await _loadBannerAd();
      await _loadInterstitialAd();

      notifyListeners();
      debugPrint('AdMob initialized successfully');
      
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
      _isAdInitialized = false;
    }
  }

  /// Load banner ad
  Future<void> _loadBannerAd() async {
    if (!_isAdInitialized || PremiumService().adFree) return;

    try {
      _bannerAd?.dispose();
      
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(
          nonPersonalizedAds: false,
        ),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded');
            _isBannerAdLoaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            _isBannerAdLoaded = false;
            ad.dispose();
            _bannerAd = null;
            notifyListeners();
            
            // Retry after delay
            Future.delayed(const Duration(seconds: 30), () {
              _loadBannerAd();
            });
          },
          onAdOpened: (ad) {
            debugPrint('Banner ad opened');
            _trackAdImpression('banner');
          },
          onAdClosed: (ad) {
            debugPrint('Banner ad closed');
          },
        ),
      );

      await _bannerAd!.load();
      
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      _isBannerAdLoaded = false;
    }
  }

  /// Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (!_isAdInitialized || PremiumService().adFree) return;

    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(
          nonPersonalizedAds: false,
        ),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded');
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            notifyListeners();

            // Set up callbacks
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Interstitial ad showed');
                _trackAdImpression('interstitial');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Interstitial ad dismissed');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdLoaded = false;
                notifyListeners();
                
                // Preload next interstitial
                _loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial ad failed to show: $error');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdLoaded = false;
                notifyListeners();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            _isInterstitialAdLoaded = false;
            notifyListeners();
            
            // Retry after delay
            Future.delayed(const Duration(seconds: 60), () {
              _loadInterstitialAd();
            });
          },
        ),
      );
      
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _isInterstitialAdLoaded = false;
    }
  }

  /// Show interstitial ad if conditions are met
  Future<void> maybeShowInterstitialAd() async {
    if (!_isAdInitialized || 
        PremiumService().adFree || 
        !_isInterstitialAdLoaded ||
        _interstitialAd == null) {
      return;
    }

    _interstitialAdCounter++;
    
    // Show ad every N actions
    if (_interstitialAdCounter >= _interstitialFrequency) {
      _interstitialAdCounter = 0;
      
      try {
        await _interstitialAd!.show();
      } catch (e) {
        debugPrint('Error showing interstitial ad: $e');
      }
    }
  }

  /// Force show interstitial ad (for specific triggers)
  Future<void> showInterstitialAd() async {
    if (!_isAdInitialized || 
        PremiumService().adFree || 
        !_isInterstitialAdLoaded ||
        _interstitialAd == null) {
      return;
    }

    try {
      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
    }
  }

  /// Check if ads should be shown based on premium status and consent
  bool get shouldShowAds {
    return _isAdInitialized && 
           !PremiumService().adFree && 
           ConsentService().canShowAds;
  }

  /// Refresh banner ad
  Future<void> refreshBannerAd() async {
    if (!shouldShowAds) return;
    await _loadBannerAd();
  }

  /// Track ad impression for analytics
  Future<void> _trackAdImpression(String adType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final impressions = prefs.getInt('ad_impressions_$adType') ?? 0;
      await prefs.setInt('ad_impressions_$adType', impressions + 1);
      
      // Track total impressions
      final totalImpressions = prefs.getInt('total_ad_impressions') ?? 0;
      await prefs.setInt('total_ad_impressions', totalImpressions + 1);
      
      debugPrint('Ad impression tracked: $adType');
    } catch (e) {
      debugPrint('Error tracking ad impression: $e');
    }
  }

  /// Get ad performance analytics
  Future<Map<String, int>> getAdAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'banner_impressions': prefs.getInt('ad_impressions_banner') ?? 0,
      'interstitial_impressions': prefs.getInt('ad_impressions_interstitial') ?? 0,
      'total_impressions': prefs.getInt('total_ad_impressions') ?? 0,
    };
  }

  /// Disable ads (when user upgrades to premium)
  void disableAds() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
    
    notifyListeners();
    debugPrint('Ads disabled for premium user');
  }

  /// Re-enable ads (if user downgrades from premium)
  Future<void> enableAds() async {
    if (PremiumService().adFree) return;
    
    await initialize();
    debugPrint('Ads re-enabled');
  }

  /// Dispose of ad resources
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/ads/ad_config.dart';
import 'consent_service.dart';
import '../subscription/subscription_service.dart';

/// Service to manage ad loading, display, and lifecycle.
/// 
/// Handles banner and interstitial ads with respect to subscription status
/// and consent requirements.
class AdsService extends ChangeNotifier {
  static const String _lastInterstitialKey = 'last_interstitial_shown';
  static const String _interstitialCountKey = 'interstitial_count_today';
  static const String _sessionStartKey = 'session_start_time';
  static const String _adImpressionCountKey = 'ad_impression_count';

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isLoadingBanner = false;
  bool _isLoadingInterstitial = false;
  
  final ConsentService _consentService;
  final SubscriptionService _subscriptionService;
  SharedPreferences? _prefs;
  Timer? _bannerRefreshTimer;
  
  int _adImpressionCount = 0;
  int _adClickCount = 0;
  double _totalRevenue = 0.0;

  /// Whether banner ad is loaded and ready to show
  bool get isBannerLoaded => _isBannerLoaded;

  /// Whether interstitial ad is loaded and ready to show
  bool get isInterstitialLoaded => _isInterstitialLoaded;

  /// Current banner ad instance
  BannerAd? get bannerAd => _bannerAd;

  /// Current ad impression count
  int get adImpressionCount => _adImpressionCount;

  /// Current ad click count
  int get adClickCount => _adClickCount;

  /// Total estimated revenue
  double get totalRevenue => _totalRevenue;

  /// Whether ads should be shown (respects premium status and consent)
  bool get shouldShowAds {
    // Never show ads to premium users
    if (_subscriptionService.isPremium) return false;
    
    // Respect consent requirements
    if (!_consentService.canShowAds) return false;
    
    return true;
  }

  AdsService({
    required ConsentService consentService,
    required SubscriptionService subscriptionService,
  }) : _consentService = consentService,
       _subscriptionService = subscriptionService {
    
    // Listen to subscription changes
    _subscriptionService.addListener(_onSubscriptionChanged);
    
    // Listen to consent changes
    _consentService.addListener(_onConsentChanged);
  }

  /// Initialize the ads service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      // Load impression count
      _adImpressionCount = _prefs?.getInt(_adImpressionCountKey) ?? 0;
      
      // Record session start
      await _recordSessionStart();
      
      // Pre-load ads if conditions are met
      if (shouldShowAds) {
        _preloadAds();
      }
      
      // Start banner refresh timer
      _startBannerRefreshTimer();
      
    } catch (e) {
      debugPrint('Error initializing ads service: $e');
    }
  }

  /// Record session start time
  Future<void> _recordSessionStart() async {
    if (_prefs != null) {
      await _prefs!.setInt(_sessionStartKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Check if minimum session time has passed before showing ads
  bool _hasMinSessionTimePassed() {
    if (_prefs == null) return false;
    
    final sessionStart = _prefs!.getInt(_sessionStartKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = Duration(milliseconds: now - sessionStart);
    
    return elapsed >= AdConfig.minSessionTimeBeforeAds;
  }

  /// Pre-load ads for better user experience
  void _preloadAds() {
    if (shouldShowAds && _hasMinSessionTimePassed()) {
      loadBannerAd();
      loadInterstitialAd();
    }
  }

  /// Load banner ad
  Future<void> loadBannerAd() async {
    if (!shouldShowAds || _isLoadingBanner || _isBannerLoaded) return;

    _isLoadingBanner = true;
    
    try {
      _bannerAd = BannerAd(
        adUnitId: AdConfig.bannerAdUnitId,
        size: AdSize.banner,
        request: _buildAdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded');
            _isBannerLoaded = true;
            _isLoadingBanner = false;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            _isBannerLoaded = false;
            _isLoadingBanner = false;
            ad.dispose();
            _bannerAd = null;
            
            // Rotate ad unit and retry
            AdConfig.rotateAdUnit();
            notifyListeners();
          },
          onAdOpened: (ad) {
            debugPrint('Banner ad opened');
            _recordAdClick();
          },
          onAdClosed: (ad) {
            debugPrint('Banner ad closed');
          },
          onAdImpression: (ad) {
            debugPrint('Banner ad impression');
            _recordAdImpression();
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      _isLoadingBanner = false;
      _bannerAd = null;
    }
  }

  /// Load interstitial ad
  Future<void> loadInterstitialAd() async {
    if (!shouldShowAds || _isLoadingInterstitial || _isInterstitialLoaded) return;

    _isLoadingInterstitial = true;

    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId,
        request: _buildAdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded');
            _interstitialAd = ad;
            _isInterstitialLoaded = true;
            _isLoadingInterstitial = false;
            
            _setInterstitialCallbacks();
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            _isInterstitialLoaded = false;
            _isLoadingInterstitial = false;
            _interstitialAd = null;
            
            // Rotate ad unit and retry
            AdConfig.rotateAdUnit();
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _isLoadingInterstitial = false;
      _interstitialAd = null;
    }
  }

  /// Set interstitial ad callbacks
  void _setInterstitialCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Interstitial ad showed');
        _recordAdImpression();
        _recordInterstitialShown();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        
        // Pre-load next interstitial
        Future.delayed(const Duration(seconds: 1), loadInterstitialAd);
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        notifyListeners();
      },
      onAdClicked: (ad) {
        debugPrint('Interstitial ad clicked');
        _recordAdClick();
      },
    );
  }

  /// Show interstitial ad if conditions are met
  Future<bool> showInterstitialAd() async {
    if (!shouldShowAds || !_isInterstitialLoaded || _interstitialAd == null) {
      return false;
    }

    // Check rate limiting
    if (!_canShowInterstitial()) {
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      return false;
    }
  }

  /// Check if interstitial can be shown (rate limiting)
  bool _canShowInterstitial() {
    if (_prefs == null) return false;

    final now = DateTime.now();
    final lastShown = _prefs!.getInt(_lastInterstitialKey) ?? 0;
    final lastShownTime = DateTime.fromMillisecondsSinceEpoch(lastShown);
    
    // Check cooldown period
    if (now.difference(lastShownTime) < AdConfig.interstitialCooldown) {
      return false;
    }

    // Check daily limit
    final today = DateTime(now.year, now.month, now.day);
    final countKey = '${_interstitialCountKey}_${today.millisecondsSinceEpoch ~/ 86400000}';
    final todayCount = _prefs!.getInt(countKey) ?? 0;
    
    return todayCount < AdConfig.maxInterstitialsPerSession;
  }

  /// Record that an interstitial was shown
  Future<void> _recordInterstitialShown() async {
    if (_prefs == null) return;

    final now = DateTime.now();
    await _prefs!.setInt(_lastInterstitialKey, now.millisecondsSinceEpoch);
    
    // Increment daily count
    final today = DateTime(now.year, now.month, now.day);
    final countKey = '${_interstitialCountKey}_${today.millisecondsSinceEpoch ~/ 86400000}';
    final currentCount = _prefs!.getInt(countKey) ?? 0;
    await _prefs!.setInt(countKey, currentCount + 1);
  }

  /// Build ad request with consent consideration
  AdRequest _buildAdRequest() {
    final extras = <String, String>{};
    
    // Add non-personalized ads parameter if consent not obtained
    if (!_consentService.canShowPersonalizedAds) {
      extras['npa'] = '1'; // Non-personalized ads
    }
    
    return AdRequest(extras: extras);
  }

  /// Record ad impression for analytics
  void _recordAdImpression() {
    _adImpressionCount++;
    _prefs?.setInt(_adImpressionCountKey, _adImpressionCount);
    
    // Estimate revenue (very rough estimate)
    _totalRevenue += Platform.isIOS ? 0.005 : 0.003; // $0.005 iOS, $0.003 Android
    
    notifyListeners();
  }

  /// Record ad click for analytics
  void _recordAdClick() {
    _adClickCount++;
    
    // Estimate revenue from click (rough estimate)
    _totalRevenue += Platform.isIOS ? 0.05 : 0.03; // $0.05 iOS, $0.03 Android
    
    notifyListeners();
  }

  /// Start banner refresh timer
  void _startBannerRefreshTimer() {
    _bannerRefreshTimer?.cancel();
    _bannerRefreshTimer = Timer.periodic(AdConfig.bannerRefreshInterval, (timer) {
      if (shouldShowAds) {
        _refreshBannerAd();
      }
    });
  }

  /// Refresh banner ad
  void _refreshBannerAd() {
    if (_isBannerLoaded) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerLoaded = false;
      notifyListeners();
    }
    
    loadBannerAd();
  }

  /// Handle subscription status changes
  void _onSubscriptionChanged() {
    if (_subscriptionService.isPremium) {
      // User upgraded to premium - hide all ads immediately
      _hideAllAds();
    } else {
      // User is now free tier - start loading ads
      _preloadAds();
    }
  }

  /// Handle consent status changes
  void _onConsentChanged() {
    if (_consentService.canShowAds && !_subscriptionService.isPremium) {
      _preloadAds();
    } else {
      _hideAllAds();
    }
  }

  /// Hide all ads
  void _hideAllAds() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
    
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoaded = false;
    
    _bannerRefreshTimer?.cancel();
    
    notifyListeners();
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    final sessionStart = _prefs?.getInt(_sessionStartKey) ?? DateTime.now().millisecondsSinceEpoch;
    final sessionDuration = DateTime.now().millisecondsSinceEpoch - sessionStart;
    final sessionHours = sessionDuration / (1000 * 60 * 60);
    
    return {
      'impressions': _adImpressionCount,
      'clicks': _adClickCount,
      'revenue': _totalRevenue,
      'ctr': _adImpressionCount > 0 ? (_adClickCount / _adImpressionCount) : 0.0,
      'arpdau': sessionHours > 0 ? (_totalRevenue / sessionHours * 24) : 0.0,
      'session_duration_hours': sessionHours,
    };
  }

  @override
  void dispose() {
    _bannerRefreshTimer?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _subscriptionService.removeListener(_onSubscriptionChanged);
    _consentService.removeListener(_onConsentChanged);
    super.dispose();
  }
}
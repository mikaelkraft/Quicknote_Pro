import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing ad placements, formats, and frequency caps.
/// 
/// Provides a centralized system for controlling ad display, tracking
/// frequency, and ensuring non-intrusive user experience.
class AdsService extends ChangeNotifier {
  static const String _adsEnabledKey = 'ads_enabled';
  static const String _frequencyCapKey = 'frequency_cap_';
  static const String _lastAdShownKey = 'last_ad_shown_';
  
  SharedPreferences? _prefs;
  bool _adsEnabled = true;
  bool _isPremiumUser = false;
  final Map<AdPlacement, DateTime?> _lastAdShown = {};
  final Map<AdPlacement, int> _adCounts = {};

  /// Whether ads are enabled for the current user
  bool get adsEnabled => _adsEnabled && !_isPremiumUser;

  /// Current ad counts by placement
  Map<AdPlacement, int> get adCounts => Map.unmodifiable(_adCounts);

  /// Initialize the ads service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAdsSettings();
    await _loadFrequencyData();
  }

  /// Load ads settings from shared preferences
  Future<void> _loadAdsSettings() async {
    if (_prefs == null) return;
    
    _adsEnabled = _prefs!.getBool(_adsEnabledKey) ?? true;
    notifyListeners();
  }

  /// Load frequency tracking data
  Future<void> _loadFrequencyData() async {
    if (_prefs == null) return;

    for (final placement in AdPlacement.values) {
      final lastShownMs = _prefs!.getInt('${_lastAdShownKey}${placement.name}');
      if (lastShownMs != null) {
        _lastAdShown[placement] = DateTime.fromMillisecondsSinceEpoch(lastShownMs);
      }

      _adCounts[placement] = _prefs!.getInt('${_frequencyCapKey}${placement.name}') ?? 0;
    }
  }

  /// Set premium user status (disables ads)
  void setPremiumStatus(bool isPremium) {
    _isPremiumUser = isPremium;
    notifyListeners();
  }

  /// Toggle ads enabled/disabled
  Future<void> setAdsEnabled(bool enabled) async {
    _adsEnabled = enabled;
    await _prefs?.setBool(_adsEnabledKey, enabled);
    notifyListeners();
  }

  /// Check if an ad can be shown at the specified placement
  bool canShowAd(AdPlacement placement) {
    if (!adsEnabled) return false;

    final config = AdConfig.forPlacement(placement);
    final lastShown = _lastAdShown[placement];
    final currentCount = _adCounts[placement] ?? 0;

    // Check frequency cap
    if (currentCount >= config.dailyLimit) {
      return false;
    }

    // Check time interval
    if (lastShown != null) {
      final timeSinceLastAd = DateTime.now().difference(lastShown);
      if (timeSinceLastAd.inSeconds < config.minIntervalSeconds) {
        return false;
      }
    }

    return true;
  }

  /// Request to show an ad at the specified placement
  Future<AdResult> requestAd(AdPlacement placement) async {
    if (!canShowAd(placement)) {
      return AdResult.blocked(placement, 'Frequency cap or interval restriction');
    }

    // Track ad request for analytics
    await _trackAdEvent('ad_requested', placement, null);

    // Simulate ad loading (replace with actual ad SDK integration)
    final config = AdConfig.forPlacement(placement);
    
    try {
      // In real implementation, this would integrate with ad SDK
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Record the ad request and success
      await _recordAdShown(placement);
      await _trackAdEvent('ad_loaded', placement, config.format);
      await _trackAdEvent('ad_shown', placement, config.format);
      
      return AdResult.success(placement, config.format);
    } catch (e) {
      await _trackAdEvent('ad_failed', placement, null, errorMessage: e.toString());
      return AdResult.error(placement, e.toString());
    }
  }

  /// Record that an ad was shown
  Future<void> _recordAdShown(AdPlacement placement) async {
    final now = DateTime.now();
    _lastAdShown[placement] = now;
    _adCounts[placement] = (_adCounts[placement] ?? 0) + 1;

    // Persist to storage
    await _prefs?.setInt('${_lastAdShownKey}${placement.name}', now.millisecondsSinceEpoch);
    await _prefs?.setInt('${_frequencyCapKey}${placement.name}', _adCounts[placement]!);

    notifyListeners();
  }

  /// Record ad interaction events with comprehensive analytics
  Future<void> recordAdInteraction(AdPlacement placement, AdInteraction interaction, {
    Map<String, dynamic>? additionalData,
  }) async {
    if (kDebugMode) {
      print('Ad interaction: ${placement.name} - ${interaction.name}');
    }
    
    // Track interaction with analytics
    switch (interaction) {
      case AdInteraction.clicked:
        await _trackAdEvent('ad_clicked', placement, null, additionalData: additionalData);
        break;
      case AdInteraction.dismissed:
        await _trackAdEvent('ad_dismissed', placement, null, additionalData: additionalData);
        break;
      case AdInteraction.closed:
        await _trackAdEvent('ad_closed', placement, null, additionalData: additionalData);
        break;
      case AdInteraction.shown:
        // Already tracked in requestAd
        break;
    }
    
    notifyListeners();
  }

  /// Track ad revenue for analytics (when available from ad SDK)
  Future<void> trackAdRevenue({
    required AdPlacement placement,
    required double revenue,
    required String currency,
    String? adNetwork,
    String? adUnit,
  }) async {
    await _trackAdEvent('ad_revenue', placement, null, additionalData: {
      'revenue': revenue,
      'currency': currency,
      'ad_network': adNetwork,
      'ad_unit': adUnit,
    });
  }

  /// Enhanced ad event tracking with analytics integration
  Future<void> _trackAdEvent(
    String eventName, 
    AdPlacement placement, 
    AdFormat? format, {
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    // Use analytics service for comprehensive tracking
    final analyticsService = AnalyticsService();
    
    final properties = <String, dynamic>{
      'placement': placement.name,
      'format': format?.name,
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    await analyticsService.logEvent(eventName, properties);
    
    if (kDebugMode) {
      print('Ad Event: $eventName - $properties');
    }
  }

  /// Reset daily frequency counters (call at midnight or app start)
  Future<void> resetDailyCounters() async {
    final now = DateTime.now();
    
    for (final placement in AdPlacement.values) {
      final lastShown = _lastAdShown[placement];
      if (lastShown != null && !_isSameDay(lastShown, now)) {
        _adCounts[placement] = 0;
        await _prefs?.setInt('${_frequencyCapKey}${placement.name}', 0);
      }
    }
    
    notifyListeners();
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Get ad statistics for debugging
  Map<String, dynamic> getAdStatistics() {
    return {
      'ads_enabled': adsEnabled,
      'is_premium': _isPremiumUser,
      'ad_counts': _adCounts.map((key, value) => MapEntry(key.name, value)),
      'last_shown': _lastAdShown.map((key, value) => 
        MapEntry(key.name, value?.toIso8601String())),
    };
  }
}

/// Ad placement locations within the app
enum AdPlacement {
  /// Banner ad at bottom of note list
  noteListBanner,
  
  /// Interstitial ad after creating multiple notes
  noteCreationInterstitial,
  
  /// Banner ad in settings screen
  settingsBanner,
  
  /// Interstitial ad before premium features
  premiumPromptInterstitial,
  
  /// Native ad in feature discovery
  featureDiscoveryNative,
}

/// Ad format types
enum AdFormat {
  banner,
  interstitial,
  native,
  rewarded,
}

/// Ad interaction types
enum AdInteraction {
  shown,
  clicked,
  dismissed,
  closed,
}

/// Configuration for ad placements
class AdConfig {
  final AdFormat format;
  final int minIntervalSeconds;
  final int dailyLimit;
  final bool dismissible;

  const AdConfig({
    required this.format,
    required this.minIntervalSeconds,
    required this.dailyLimit,
    this.dismissible = true,
  });

  /// Get configuration for a specific placement
  static AdConfig forPlacement(AdPlacement placement) {
    switch (placement) {
      case AdPlacement.noteListBanner:
        return const AdConfig(
          format: AdFormat.banner,
          minIntervalSeconds: 300, // 5 minutes
          dailyLimit: 20,
        );
      
      case AdPlacement.noteCreationInterstitial:
        return const AdConfig(
          format: AdFormat.interstitial,
          minIntervalSeconds: 1800, // 30 minutes
          dailyLimit: 3,
        );
      
      case AdPlacement.settingsBanner:
        return const AdConfig(
          format: AdFormat.banner,
          minIntervalSeconds: 600, // 10 minutes
          dailyLimit: 10,
        );
      
      case AdPlacement.premiumPromptInterstitial:
        return const AdConfig(
          format: AdFormat.interstitial,
          minIntervalSeconds: 3600, // 1 hour
          dailyLimit: 2,
        );
      
      case AdPlacement.featureDiscoveryNative:
        return const AdConfig(
          format: AdFormat.native,
          minIntervalSeconds: 900, // 15 minutes
          dailyLimit: 5,
        );
    }
  }
}

/// Result of an ad request
class AdResult {
  final AdPlacement placement;
  final AdResultType type;
  final AdFormat? format;
  final String? message;

  AdResult._(this.placement, this.type, {this.format, this.message});

  factory AdResult.success(AdPlacement placement, AdFormat format) =>
    AdResult._(placement, AdResultType.success, format: format);

  factory AdResult.blocked(AdPlacement placement, String reason) =>
    AdResult._(placement, AdResultType.blocked, message: reason);

  factory AdResult.error(AdPlacement placement, String error) =>
    AdResult._(placement, AdResultType.error, message: error);

  bool get isSuccess => type == AdResultType.success;
  bool get isBlocked => type == AdResultType.blocked;
  bool get isError => type == AdResultType.error;
}

enum AdResultType {
  success,
  blocked,
  error,
}
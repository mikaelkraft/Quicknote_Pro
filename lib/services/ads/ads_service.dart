import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

import '../../constants/ads_config.dart';
import '../../models/ad_placement.dart';
import '../../models/ad_analytics.dart';

/// Central service for managing ads in QuickNote Pro.
/// 
/// This service handles ad loading, display, frequency capping,
/// analytics tracking, and A/B testing for the free tier experience.
class AdsService extends ChangeNotifier {
  static const String _prefsKeyFrequencyCaps = 'ads_frequency_caps';
  static const String _prefsKeyAnalytics = 'ads_analytics';
  static const String _prefsKeyAbTestVariants = 'ads_ab_test_variants';
  static const String _prefsKeySessionData = 'ads_session_data';
  
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _isPremiumUser = false;
  String _currentSessionId = '';
  DateTime _sessionStartTime = DateTime.now();
  
  final Map<String, AdPlacement> _placements = {};
  final Map<String, AdInstance> _loadedAds = {};
  final Map<String, AdFrequencyCap> _frequencyCaps = {};
  final List<AdAnalytics> _pendingAnalytics = [];
  final Map<String, String> _abTestVariants = {};
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPremiumUser => _isPremiumUser;
  String get currentSessionId => _currentSessionId;
  Map<String, AdPlacement> get placements => Map.unmodifiable(_placements);
  Map<String, AdInstance> get loadedAds => Map.unmodifiable(_loadedAds);
  
  /// Initializes the ads service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _currentSessionId = _generateSessionId();
      _sessionStartTime = DateTime.now();
      
      await _loadPersistedData();
      _initializePlacements();
      _initializeAbTestVariants();
      
      _isInitialized = true;
      debugPrint('AdsService: Initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('AdsService: Initialization failed: $e');
    }
  }

  /// Sets the premium user status
  void setPremiumUser(bool isPremium) {
    if (_isPremiumUser != isPremium) {
      _isPremiumUser = isPremium;
      debugPrint('AdsService: Premium status changed to $isPremium');
      
      if (isPremium) {
        _clearAllAds();
      }
      
      notifyListeners();
    }
  }

  /// Checks if ads are enabled and should be shown
  bool get shouldShowAds {
    return AdsConfig.adsEnabled && !_isPremiumUser && _isInitialized;
  }

  /// Loads an ad for a specific placement
  Future<AdInstance?> loadAd(String placementId, {String? preferredFormat}) async {
    if (!shouldShowAds) {
      debugPrint('AdsService: Ads disabled or premium user');
      return null;
    }

    final placement = _placements[placementId];
    if (placement == null) {
      debugPrint('AdsService: Unknown placement: $placementId');
      return null;
    }

    // Check frequency caps
    final format = preferredFormat ?? placement.formatPriority.first;
    if (!_canShowAd(placementId, format)) {
      await _trackAnalyticsEvent(
        AdsConfig.eventAdFrequencyCapped,
        placementId,
        '',
        format,
        {'reason': 'frequency_cap_reached'},
      );
      return null;
    }

    // Simulate ad loading (replace with actual ad SDK integration)
    final adInstance = await _simulateAdLoading(placementId, format);
    
    if (adInstance != null) {
      _loadedAds[adInstance.id] = adInstance;
      await _trackAnalyticsEvent(
        AdsConfig.eventAdImpression,
        placementId,
        adInstance.id,
        format,
        {
          'load_time_ms': DateTime.now().difference(adInstance.loadedAt!).inMilliseconds,
          'ab_test_variant': _abTestVariants[placementId],
        },
      );
      notifyListeners();
    }

    return adInstance;
  }

  /// Shows a loaded ad
  Future<bool> showAd(String adId) async {
    final ad = _loadedAds[adId];
    if (ad == null || !ad.isDisplayable) {
      debugPrint('AdsService: Ad not found or not displayable: $adId');
      return false;
    }

    // Update ad state
    final shownAd = ad.copyWith(
      state: AdState.shown,
      shownAt: DateTime.now(),
    );
    _loadedAds[adId] = shownAd;

    // Update frequency caps
    await _updateFrequencyCap(ad.placementId, ad.format.value);

    await _trackAnalyticsEvent(
      'ad_shown',
      ad.placementId,
      ad.id,
      ad.format.value,
      {
        'display_order': _getDisplayOrder(ad.placementId),
        'time_since_load': DateTime.now().difference(ad.loadedAt!).inSeconds,
      },
    );

    notifyListeners();
    return true;
  }

  /// Handles ad click
  Future<void> onAdClicked(String adId) async {
    final ad = _loadedAds[adId];
    if (ad == null) return;

    final clickedAd = ad.copyWith(
      state: AdState.clicked,
      clickedAt: DateTime.now(),
    );
    _loadedAds[adId] = clickedAd;

    await _trackAnalyticsEvent(
      AdsConfig.eventAdClick,
      ad.placementId,
      ad.id,
      ad.format.value,
      {
        'click_position': 'unknown', // Could be enhanced with position tracking
        'time_on_screen': ad.displayDuration?.inSeconds ?? 0,
      },
    );

    notifyListeners();
  }

  /// Handles ad dismissal
  Future<void> onAdDismissed(String adId, {String reason = 'user_action'}) async {
    final ad = _loadedAds[adId];
    if (ad == null) return;

    final dismissedAd = ad.copyWith(
      state: AdState.dismissed,
      dismissedAt: DateTime.now(),
    );
    _loadedAds[adId] = dismissedAd;

    await _trackAnalyticsEvent(
      AdsConfig.eventAdDismiss,
      ad.placementId,
      ad.id,
      ad.format.value,
      {
        'dismiss_reason': reason,
        'time_on_screen': ad.displayDuration?.inSeconds ?? 0,
      },
    );

    // Remove dismissed ad after a delay
    Future.delayed(const Duration(seconds: 5), () {
      _loadedAds.remove(adId);
      notifyListeners();
    });

    notifyListeners();
  }

  /// Handles ad conversion (e.g., app install, purchase)
  Future<void> onAdConversion(String adId, {Map<String, dynamic>? conversionData}) async {
    final ad = _loadedAds[adId];
    if (ad == null) return;

    await _trackAnalyticsEvent(
      AdsConfig.eventAdConversion,
      ad.placementId,
      ad.id,
      ad.format.value,
      {
        'conversion_type': conversionData?['type'] ?? 'unknown',
        'conversion_value': conversionData?['value'] ?? 0,
        'time_to_conversion': DateTime.now().difference(ad.clickedAt ?? ad.shownAt!).inSeconds,
      },
    );
  }

  /// Gets analytics metrics for a placement
  Future<AdMetrics?> getMetrics(String placementId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final analytics = await _getAnalyticsForPlacement(placementId, startDate, endDate);
    if (analytics.isEmpty) return null;

    int impressions = 0;
    int clicks = 0;
    int dismissals = 0;
    int conversions = 0;
    int failures = 0;
    int blocked = 0;
    double revenue = 0.0;

    for (final event in analytics) {
      switch (event.eventType) {
        case AdsConfig.eventAdImpression:
          impressions++;
          break;
        case AdsConfig.eventAdClick:
          clicks++;
          break;
        case AdsConfig.eventAdDismiss:
          dismissals++;
          break;
        case AdsConfig.eventAdConversion:
          conversions++;
          revenue += (event.properties['conversion_value'] as num?)?.toDouble() ?? 0.0;
          break;
        case AdsConfig.eventAdLoadFailure:
          failures++;
          break;
        case AdsConfig.eventAdBlocked:
          blocked++;
          break;
      }
    }

    return AdMetrics(
      placementId: placementId,
      format: 'all', // Could be filtered by format
      startDate: startDate ?? _sessionStartTime,
      endDate: endDate ?? DateTime.now(),
      impressions: impressions,
      clicks: clicks,
      dismissals: dismissals,
      conversions: conversions,
      failures: failures,
      blocked: blocked,
      revenue: revenue,
      additionalMetrics: {
        'unique_users': 1, // Simplified for single user
        'session_count': 1,
      },
    );
  }

  /// Gets the A/B test variant for a placement
  String? getAbTestVariant(String placementId) {
    return _abTestVariants[placementId];
  }

  /// Preloads ads for better user experience
  Future<void> preloadAds(List<String> placementIds) async {
    if (!shouldShowAds) return;

    for (final placementId in placementIds) {
      try {
        await loadAd(placementId);
        // Small delay between loads to avoid overwhelming the ad network
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('AdsService: Failed to preload ad for $placementId: $e');
      }
    }
  }

  /// Clears all loaded ads (useful for premium upgrade)
  void _clearAllAds() {
    _loadedAds.clear();
    notifyListeners();
  }

  /// Loads persisted data from SharedPreferences
  Future<void> _loadPersistedData() async {
    if (_prefs == null) return;

    try {
      // Load frequency caps
      final frequencyCapsJson = _prefs!.getString(_prefsKeyFrequencyCaps);
      if (frequencyCapsJson != null) {
        final data = jsonDecode(frequencyCapsJson) as Map<String, dynamic>;
        data.forEach((key, value) {
          _frequencyCaps[key] = AdFrequencyCap.fromJson(value);
        });
      }

      // Load A/B test variants
      final abTestJson = _prefs!.getString(_prefsKeyAbTestVariants);
      if (abTestJson != null) {
        final data = jsonDecode(abTestJson) as Map<String, dynamic>;
        _abTestVariants.addAll(data.cast<String, String>());
      }
    } catch (e) {
      debugPrint('AdsService: Failed to load persisted data: $e');
    }
  }

  /// Initializes ad placements from configuration
  void _initializePlacements() {
    for (final placementId in AdsConfig.allPlacements) {
      final config = AdsConfig.placementConfig[placementId]!;
      _placements[placementId] = AdPlacement(
        id: placementId,
        name: _getPlacementDisplayName(placementId),
        screenLocation: placementId,
        supportedFormats: List<String>.from(config['formats']),
        formatPriority: List<String>.from(config['priority']),
        sessionLimit: config['sessionLimit'],
        abTestEnabled: config['abTestEnabled'],
      );
    }
  }

  /// Initializes A/B test variants
  void _initializeAbTestVariants() {
    if (!AdsConfig.abTestingEnabled) return;

    for (final placementId in AdsConfig.allPlacements) {
      final placement = _placements[placementId];
      if (placement?.abTestEnabled ?? false) {
        // Assign A/B test variant if not already assigned
        if (!_abTestVariants.containsKey(placementId)) {
          final variants = AdsConfig.abTestVariants.values.first; // Simplified
          final randomVariant = variants[Random().nextInt(variants.length)];
          _abTestVariants[placementId] = randomVariant;
        }
      }
    }

    _persistAbTestVariants();
  }

  /// Simulates ad loading (replace with actual ad SDK integration)
  Future<AdInstance?> _simulateAdLoading(String placementId, String format) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Simulate occasional failures
      if (Random().nextDouble() < 0.1) {
        await _trackAnalyticsEvent(
          AdsConfig.eventAdLoadFailure,
          placementId,
          '',
          format,
          {'error': 'network_timeout'},
        );
        return null;
      }

      final adId = _generateAdId();
      return AdInstance(
        id: adId,
        placementId: placementId,
        format: AdFormat.fromString(format),
        state: AdState.loaded,
        loadedAt: DateTime.now(),
        metadata: {
          'network': 'demo_network',
          'creative_id': 'creative_${Random().nextInt(1000)}',
          'advertiser': 'Demo Advertiser',
        },
      );
    } catch (e) {
      await _trackAnalyticsEvent(
        AdsConfig.eventAdLoadFailure,
        placementId,
        '',
        format,
        {'error': e.toString()},
      );
      return null;
    }
  }

  /// Checks if an ad can be shown based on frequency caps
  bool _canShowAd(String placementId, String format) {
    final key = '${placementId}_$format';
    final cap = _frequencyCaps[key];
    
    if (cap == null) {
      // Initialize frequency cap
      _frequencyCaps[key] = AdFrequencyCap(
        placementId: placementId,
        format: format,
        maxAdsPerSession: AdsConfig.getSessionLimitForPlacement(placementId),
        maxAdsPerHour: 15,
        maxAdsPerDay: 50,
        currentSessionCount: 0,
        currentHourCount: 0,
        currentDayCount: 0,
        sessionStartedAt: _sessionStartTime,
      );
      return true;
    }

    if (cap.isCapReached) return false;
    
    final frequencyCapMinutes = AdsConfig.getFrequencyCapForFormat(format);
    return cap.canShowAd(frequencyCapMinutes);
  }

  /// Updates frequency cap after showing an ad
  Future<void> _updateFrequencyCap(String placementId, String format) async {
    final key = '${placementId}_$format';
    final cap = _frequencyCaps[key];
    
    if (cap != null) {
      _frequencyCaps[key] = cap.withIncrementedCount();
      await _persistFrequencyCaps();
    }
  }

  /// Tracks analytics events
  Future<void> _trackAnalyticsEvent(
    String eventType,
    String placementId,
    String adId,
    String format,
    Map<String, dynamic> properties,
  ) async {
    if (!AdsConfig.analyticsEnabled) return;

    final event = AdAnalytics(
      eventId: _generateEventId(),
      eventType: eventType,
      placementId: placementId,
      adId: adId,
      format: format,
      timestamp: DateTime.now(),
      properties: properties,
      sessionId: _currentSessionId,
      abTestVariant: _abTestVariants[placementId],
    );

    _pendingAnalytics.add(event);
    
    // Persist analytics periodically
    if (_pendingAnalytics.length >= 10) {
      await _persistAnalytics();
    }
  }

  /// Gets analytics events for a placement
  Future<List<AdAnalytics>> _getAnalyticsForPlacement(
    String placementId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // In a real implementation, this would query a database or analytics service
    return _pendingAnalytics.where((event) {
      if (event.placementId != placementId) return false;
      if (startDate != null && event.timestamp.isBefore(startDate)) return false;
      if (endDate != null && event.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  /// Persists frequency caps to SharedPreferences
  Future<void> _persistFrequencyCaps() async {
    if (_prefs == null) return;

    try {
      final data = <String, dynamic>{};
      _frequencyCaps.forEach((key, cap) {
        data[key] = cap.toJson();
      });
      await _prefs!.setString(_prefsKeyFrequencyCaps, jsonEncode(data));
    } catch (e) {
      debugPrint('AdsService: Failed to persist frequency caps: $e');
    }
  }

  /// Persists analytics events to SharedPreferences
  Future<void> _persistAnalytics() async {
    if (_prefs == null || _pendingAnalytics.isEmpty) return;

    try {
      final existingJson = _prefs!.getString(_prefsKeyAnalytics);
      final existingEvents = existingJson != null
          ? (jsonDecode(existingJson) as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

      existingEvents.addAll(_pendingAnalytics.map((e) => e.toJson()));
      
      // Keep only the last 1000 events to prevent storage bloat
      if (existingEvents.length > 1000) {
        existingEvents.removeRange(0, existingEvents.length - 1000);
      }

      await _prefs!.setString(_prefsKeyAnalytics, jsonEncode(existingEvents));
      _pendingAnalytics.clear();
    } catch (e) {
      debugPrint('AdsService: Failed to persist analytics: $e');
    }
  }

  /// Persists A/B test variants to SharedPreferences
  Future<void> _persistAbTestVariants() async {
    if (_prefs == null) return;

    try {
      await _prefs!.setString(_prefsKeyAbTestVariants, jsonEncode(_abTestVariants));
    } catch (e) {
      debugPrint('AdsService: Failed to persist A/B test variants: $e');
    }
  }

  /// Helper methods
  String _generateSessionId() => 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateAdId() => 'ad_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateEventId() => 'event_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

  String _getPlacementDisplayName(String placementId) {
    switch (placementId) {
      case AdsConfig.placementHome:
        return 'Home Screen';
      case AdsConfig.placementNoteList:
        return 'Note List';
      case AdsConfig.placementNoteDetails:
        return 'Note Details';
      case AdsConfig.placementSettings:
        return 'Settings';
      case AdsConfig.placementSearch:
        return 'Search Results';
      case AdsConfig.placementFolders:
        return 'Folder Organization';
      default:
        return placementId;
    }
  }

  int _getDisplayOrder(String placementId) {
    return _loadedAds.values
        .where((ad) => ad.placementId == placementId && ad.shownAt != null)
        .length + 1;
  }

  @override
  void dispose() {
    _persistAnalytics();
    _persistFrequencyCaps();
    super.dispose();
  }
}
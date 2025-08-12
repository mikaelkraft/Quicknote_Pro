import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to track and analyze ads-related metrics.
/// 
/// Collects data on ad impressions, clicks, revenue, and user engagement
/// to provide insights for optimization and monetization.
class AdsAnalyticsService extends ChangeNotifier {
  static const String _dailyStatsKey = 'daily_ad_stats';
  static const String _lifetimeStatsKey = 'lifetime_ad_stats';
  static const String _userSegmentKey = 'user_segment';

  SharedPreferences? _prefs;
  Map<String, dynamic> _dailyStats = {};
  Map<String, dynamic> _lifetimeStats = {};
  String _userSegment = 'new';

  /// Current daily stats
  Map<String, dynamic> get dailyStats => Map.from(_dailyStats);

  /// Lifetime stats
  Map<String, dynamic> get lifetimeStats => Map.from(_lifetimeStats);

  /// User segment for targeting
  String get userSegment => _userSegment;

  /// Initialize the analytics service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadStats();
      await _determineUserSegment();
    } catch (e) {
      debugPrint('Error initializing ads analytics service: $e');
    }
  }

  /// Load saved statistics
  Future<void> _loadStats() async {
    if (_prefs == null) return;

    // Load daily stats
    final dailyStatsJson = _prefs!.getString(_dailyStatsKey);
    if (dailyStatsJson != null) {
      try {
        final decoded = jsonDecode(dailyStatsJson);
        final today = _getTodayKey();
        _dailyStats = Map<String, dynamic>.from(decoded[today] ?? {});
      } catch (e) {
        debugPrint('Error loading daily stats: $e');
        _dailyStats = {};
      }
    }

    // Load lifetime stats
    final lifetimeStatsJson = _prefs!.getString(_lifetimeStatsKey);
    if (lifetimeStatsJson != null) {
      try {
        _lifetimeStats = Map<String, dynamic>.from(jsonDecode(lifetimeStatsJson));
      } catch (e) {
        debugPrint('Error loading lifetime stats: $e');
        _lifetimeStats = {};
      }
    }

    // Initialize default values
    _initializeDefaultStats();
  }

  /// Initialize default stat values
  void _initializeDefaultStats() {
    final defaults = {
      'impressions': 0,
      'clicks': 0,
      'revenue': 0.0,
      'banner_impressions': 0,
      'interstitial_impressions': 0,
      'banner_clicks': 0,
      'interstitial_clicks': 0,
      'session_count': 0,
      'total_session_time': 0,
    };

    for (final entry in defaults.entries) {
      _dailyStats[entry.key] ??= entry.value;
      _lifetimeStats[entry.key] ??= entry.value;
    }
  }

  /// Determine user segment based on behavior
  Future<void> _determineUserSegment() async {
    if (_prefs == null) return;

    final totalImpressions = _lifetimeStats['impressions'] ?? 0;
    final totalClicks = _lifetimeStats['clicks'] ?? 0;
    final sessionCount = _lifetimeStats['session_count'] ?? 0;

    if (sessionCount == 0) {
      _userSegment = 'new';
    } else if (sessionCount < 5) {
      _userSegment = 'trial';
    } else if (totalClicks > 10 && totalImpressions > 50) {
      _userSegment = 'engaged';
    } else if (sessionCount > 20) {
      _userSegment = 'regular';
    } else {
      _userSegment = 'casual';
    }

    await _prefs!.setString(_userSegmentKey, _userSegment);
  }

  /// Record ad impression
  Future<void> recordAdImpression({
    required String adType, // 'banner' or 'interstitial'
    required String adUnitId,
    double revenue = 0.0,
  }) async {
    _dailyStats['impressions'] = (_dailyStats['impressions'] ?? 0) + 1;
    _dailyStats['${adType}_impressions'] = (_dailyStats['${adType}_impressions'] ?? 0) + 1;
    _dailyStats['revenue'] = (_dailyStats['revenue'] ?? 0.0) + revenue;

    _lifetimeStats['impressions'] = (_lifetimeStats['impressions'] ?? 0) + 1;
    _lifetimeStats['${adType}_impressions'] = (_lifetimeStats['${adType}_impressions'] ?? 0) + 1;
    _lifetimeStats['revenue'] = (_lifetimeStats['revenue'] ?? 0.0) + revenue;

    await _saveStats();
    await _determineUserSegment();
    notifyListeners();

    debugPrint('Recorded $adType impression. Revenue: \$$revenue');
  }

  /// Record ad click
  Future<void> recordAdClick({
    required String adType, // 'banner' or 'interstitial'
    required String adUnitId,
    double revenue = 0.0,
  }) async {
    _dailyStats['clicks'] = (_dailyStats['clicks'] ?? 0) + 1;
    _dailyStats['${adType}_clicks'] = (_dailyStats['${adType}_clicks'] ?? 0) + 1;
    _dailyStats['revenue'] = (_dailyStats['revenue'] ?? 0.0) + revenue;

    _lifetimeStats['clicks'] = (_lifetimeStats['clicks'] ?? 0) + 1;
    _lifetimeStats['${adType}_clicks'] = (_lifetimeStats['${adType}_clicks'] ?? 0) + 1;
    _lifetimeStats['revenue'] = (_lifetimeStats['revenue'] ?? 0.0) + revenue;

    await _saveStats();
    await _determineUserSegment();
    notifyListeners();

    debugPrint('Recorded $adType click. Revenue: \$$revenue');
  }

  /// Record session start
  Future<void> recordSessionStart() async {
    _dailyStats['session_count'] = (_dailyStats['session_count'] ?? 0) + 1;
    _lifetimeStats['session_count'] = (_lifetimeStats['session_count'] ?? 0) + 1;

    await _saveStats();
    notifyListeners();
  }

  /// Record session end
  Future<void> recordSessionEnd(Duration sessionLength) async {
    final sessionMinutes = sessionLength.inMinutes;
    
    _dailyStats['total_session_time'] = (_dailyStats['total_session_time'] ?? 0) + sessionMinutes;
    _lifetimeStats['total_session_time'] = (_lifetimeStats['total_session_time'] ?? 0) + sessionMinutes;

    await _saveStats();
    await _determineUserSegment();
    notifyListeners();
  }

  /// Get click-through rate (CTR)
  double getCTR({bool lifetime = false}) {
    final stats = lifetime ? _lifetimeStats : _dailyStats;
    final impressions = stats['impressions'] ?? 0;
    final clicks = stats['clicks'] ?? 0;
    
    return impressions > 0 ? (clicks / impressions) : 0.0;
  }

  /// Get average revenue per daily active user (ARPDAU)
  double getARPDAU() {
    final dailyRevenue = _dailyStats['revenue'] ?? 0.0;
    final sessionCount = _dailyStats['session_count'] ?? 0;
    
    return sessionCount > 0 ? (dailyRevenue / sessionCount) : 0.0;
  }

  /// Get revenue per impression (RPI)
  double getRPI({bool lifetime = false}) {
    final stats = lifetime ? _lifetimeStats : _dailyStats;
    final revenue = stats['revenue'] ?? 0.0;
    final impressions = stats['impressions'] ?? 0;
    
    return impressions > 0 ? (revenue / impressions) : 0.0;
  }

  /// Get formatted analytics report
  Map<String, dynamic> getAnalyticsReport() {
    final dailyCTR = getCTR(lifetime: false);
    final lifetimeCTR = getCTR(lifetime: true);
    final arpdau = getARPDAU();
    final dailyRPI = getRPI(lifetime: false);
    final lifetimeRPI = getRPI(lifetime: true);

    return {
      'daily_stats': {
        'impressions': _dailyStats['impressions'] ?? 0,
        'clicks': _dailyStats['clicks'] ?? 0,
        'revenue': _dailyStats['revenue'] ?? 0.0,
        'ctr': dailyCTR,
        'rpi': dailyRPI,
        'session_count': _dailyStats['session_count'] ?? 0,
      },
      'lifetime_stats': {
        'impressions': _lifetimeStats['impressions'] ?? 0,
        'clicks': _lifetimeStats['clicks'] ?? 0,
        'revenue': _lifetimeStats['revenue'] ?? 0.0,
        'ctr': lifetimeCTR,
        'rpi': lifetimeRPI,
        'session_count': _lifetimeStats['session_count'] ?? 0,
      },
      'metrics': {
        'arpdau': arpdau,
        'user_segment': _userSegment,
        'banner_performance': {
          'impressions': _dailyStats['banner_impressions'] ?? 0,
          'clicks': _dailyStats['banner_clicks'] ?? 0,
          'ctr': _getBannerCTR(),
        },
        'interstitial_performance': {
          'impressions': _dailyStats['interstitial_impressions'] ?? 0,
          'clicks': _dailyStats['interstitial_clicks'] ?? 0,
          'ctr': _getInterstitialCTR(),
        },
      },
    };
  }

  /// Get banner CTR
  double _getBannerCTR() {
    final impressions = _dailyStats['banner_impressions'] ?? 0;
    final clicks = _dailyStats['banner_clicks'] ?? 0;
    return impressions > 0 ? (clicks / impressions) : 0.0;
  }

  /// Get interstitial CTR
  double _getInterstitialCTR() {
    final impressions = _dailyStats['interstitial_impressions'] ?? 0;
    final clicks = _dailyStats['interstitial_clicks'] ?? 0;
    return impressions > 0 ? (clicks / impressions) : 0.0;
  }

  /// Save statistics to storage
  Future<void> _saveStats() async {
    if (_prefs == null) return;

    try {
      // Save daily stats with date key
      final today = _getTodayKey();
      final existingDaily = _prefs!.getString(_dailyStatsKey);
      Map<String, dynamic> allDailyStats = {};
      
      if (existingDaily != null) {
        allDailyStats = Map<String, dynamic>.from(jsonDecode(existingDaily));
      }
      
      allDailyStats[today] = _dailyStats;
      
      // Keep only last 30 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      allDailyStats.removeWhere((key, value) {
        final date = DateTime.tryParse(key);
        return date != null && date.isBefore(cutoffDate);
      });
      
      await _prefs!.setString(_dailyStatsKey, jsonEncode(allDailyStats));

      // Save lifetime stats
      await _prefs!.setString(_lifetimeStatsKey, jsonEncode(_lifetimeStats));
      
    } catch (e) {
      debugPrint('Error saving stats: $e');
    }
  }

  /// Get today's date key
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Reset daily stats (called at midnight)
  Future<void> resetDailyStats() async {
    _dailyStats.clear();
    _initializeDefaultStats();
    await _saveStats();
    notifyListeners();
  }

  /// Export analytics data for external analysis
  Map<String, dynamic> exportAnalyticsData() {
    return {
      'daily_stats': _dailyStats,
      'lifetime_stats': _lifetimeStats,
      'user_segment': _userSegment,
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if user is performing well with ads (for optimization)
  bool get isHighPerformingUser {
    final ctr = getCTR(lifetime: true);
    final sessionCount = _lifetimeStats['session_count'] ?? 0;
    
    return ctr > 0.02 && sessionCount > 10; // 2% CTR threshold
  }

  /// Get personalized ad frequency recommendation
  Duration getRecommendedAdFrequency() {
    switch (_userSegment) {
      case 'new':
        return const Duration(minutes: 10); // Less frequent for new users
      case 'trial':
        return const Duration(minutes: 8);
      case 'engaged':
        return const Duration(minutes: 5); // More frequent for engaged users
      case 'regular':
        return const Duration(minutes: 6);
      case 'casual':
        return const Duration(minutes: 12); // Less frequent for casual users
      default:
        return const Duration(minutes: 8);
    }
  }
}
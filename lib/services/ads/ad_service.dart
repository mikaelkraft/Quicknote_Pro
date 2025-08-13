import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/ad_models.dart';
import '../analytics/analytics_service.dart';

/// Service for managing ad display with frequency capping and placement optimization
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  SharedPreferences? _prefs;
  final AnalyticsService _analytics = AnalyticsService();
  bool _isInitialized = false;
  bool _isPremiumUser = false;

  /// Initialize the ad service
  Future<void> initialize({bool isPremiumUser = false}) async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _isPremiumUser = isPremiumUser;
    _isInitialized = true;

    // Clean up old impressions daily
    await _cleanupOldImpressions();
  }

  /// Check if an ad can be shown for a given placement
  Future<bool> canShowAd(String placementId) async {
    if (!_isInitialized) await initialize();

    // Premium users don't see ads
    if (_isPremiumUser) return false;

    final placement = AdPlacements.getById(placementId);
    if (placement == null) return false;

    // Check daily impression limit
    final todayImpressions = await _getTodayImpressions(placementId);
    if (todayImpressions >= placement.maxDailyImpressions) {
      return false;
    }

    // Check minimum interval between ads
    final lastImpression = await _getLastImpression(placementId);
    if (lastImpression != null) {
      final timeSinceLastAd = DateTime.now().difference(lastImpression.timestamp);
      if (timeSinceLastAd.inMinutes < placement.minIntervalMinutes) {
        return false;
      }
    }

    return true;
  }

  /// Request to show an ad for a placement
  Future<AdImpression?> requestAd(String placementId) async {
    if (!await canShowAd(placementId)) return null;

    final placement = AdPlacements.getById(placementId);
    if (placement == null) return null;

    // Create impression record
    final impression = AdImpression(
      id: _generateImpressionId(),
      placementId: placementId,
      format: placement.format,
      timestamp: DateTime.now(),
      adProvider: 'test_provider', // In real implementation, this would be the actual provider
    );

    // Store impression
    await _storeImpression(impression);

    // Track analytics
    await _analytics.trackAdEvent(
      'ad_displayed',
      adFormat: placement.format.name,
      adPlacement: placementId,
      adProvider: impression.adProvider,
      impressionId: impression.id,
    );

    return impression;
  }

  /// Mark an ad as clicked
  Future<void> recordAdClick(String impressionId) async {
    final impression = await _getImpression(impressionId);
    if (impression == null) return;

    final updatedImpression = impression.copyWith(wasClicked: true);
    await _storeImpression(updatedImpression);

    // Track analytics
    await _analytics.trackAdEvent(
      'ad_clicked',
      adFormat: impression.format.name,
      adPlacement: impression.placementId,
      adProvider: impression.adProvider,
      impressionId: impressionId,
    );
  }

  /// Mark an ad as dismissed
  Future<void> recordAdDismiss(String impressionId) async {
    final impression = await _getImpression(impressionId);
    if (impression == null) return;

    final updatedImpression = impression.copyWith(wasDismissed: true);
    await _storeImpression(updatedImpression);

    // Track analytics
    await _analytics.trackAdEvent(
      'ad_dismissed',
      adFormat: impression.format.name,
      adPlacement: impression.placementId,
      adProvider: impression.adProvider,
      impressionId: impressionId,
    );
  }

  /// Record ad load failure
  Future<void> recordAdLoadFailure(String placementId, String errorCode) async {
    await _analytics.trackAdEvent(
      'ad_load_failed',
      adPlacement: placementId,
      errorCode: errorCode,
    );
  }

  /// Get ad performance metrics
  Future<Map<String, dynamic>> getAdMetrics() async {
    final impressions = await _getAllImpressions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate metrics
    final todayImpressions = impressions.where((i) => 
      i.timestamp.isAfter(today) || i.timestamp.isAtSameMomentAs(today)
    ).toList();

    final clickedToday = todayImpressions.where((i) => i.wasClicked).length;
    final dismissedToday = todayImpressions.where((i) => i.wasDismissed).length;

    final ctr = todayImpressions.isNotEmpty 
        ? (clickedToday / todayImpressions.length * 100)
        : 0.0;

    final dismissalRate = todayImpressions.isNotEmpty 
        ? (dismissedToday / todayImpressions.length * 100)
        : 0.0;

    // Placement breakdown
    final placementBreakdown = <String, Map<String, int>>{};
    for (final placement in AdPlacements.allPlacements) {
      final placementImpressions = todayImpressions.where((i) => 
        i.placementId == placement.id
      ).toList();
      
      placementBreakdown[placement.id] = {
        'impressions': placementImpressions.length,
        'clicks': placementImpressions.where((i) => i.wasClicked).length,
        'dismissals': placementImpressions.where((i) => i.wasDismissed).length,
      };
    }

    return {
      'total_impressions_today': todayImpressions.length,
      'total_clicks_today': clickedToday,
      'total_dismissals_today': dismissedToday,
      'click_through_rate': ctr,
      'dismissal_rate': dismissalRate,
      'placement_breakdown': placementBreakdown,
    };
  }

  /// Update premium status
  void updatePremiumStatus(bool isPremium) {
    _isPremiumUser = isPremium;
  }

  /// Clear all ad data (for testing or privacy)
  Future<void> clearData() async {
    await _prefs?.remove('ad_impressions');
  }

  // Private helper methods
  String _generateImpressionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'imp_${timestamp}_$random';
  }

  Future<int> _getTodayImpressions(String placementId) async {
    final impressions = await _getAllImpressions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return impressions.where((impression) => 
      impression.placementId == placementId &&
      (impression.timestamp.isAfter(today) || impression.timestamp.isAtSameMomentAs(today))
    ).length;
  }

  Future<AdImpression?> _getLastImpression(String placementId) async {
    final impressions = await _getAllImpressions();
    final placementImpressions = impressions
        .where((impression) => impression.placementId == placementId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return placementImpressions.isNotEmpty ? placementImpressions.first : null;
  }

  Future<AdImpression?> _getImpression(String impressionId) async {
    final impressions = await _getAllImpressions();
    try {
      return impressions.firstWhere((impression) => impression.id == impressionId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeImpression(AdImpression impression) async {
    final impressions = await _getAllImpressions();
    
    // Remove existing impression with same ID if it exists
    impressions.removeWhere((i) => i.id == impression.id);
    
    // Add new/updated impression
    impressions.add(impression);
    
    // Keep only last 500 impressions to manage storage
    if (impressions.length > 500) {
      impressions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      impressions.removeRange(500, impressions.length);
    }
    
    final impressionsJson = impressions.map((i) => i.toJson()).toList();
    await _prefs?.setString('ad_impressions', jsonEncode(impressionsJson));
  }

  Future<List<AdImpression>> _getAllImpressions() async {
    final impressionsData = _prefs?.getString('ad_impressions');
    if (impressionsData == null) return [];

    try {
      final impressionsList = jsonDecode(impressionsData) as List;
      return impressionsList
          .map((impressionJson) => AdImpression.fromJson(impressionJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _cleanupOldImpressions() async {
    final impressions = await _getAllImpressions();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final recentImpressions = impressions
        .where((impression) => impression.timestamp.isAfter(thirtyDaysAgo))
        .toList();
    
    if (recentImpressions.length != impressions.length) {
      final impressionsJson = recentImpressions.map((i) => i.toJson()).toList();
      await _prefs?.setString('ad_impressions', jsonEncode(impressionsJson));
    }
  }
}
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking analytics and A/B testing
class AnalyticsService extends ChangeNotifier {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Map<String, dynamic> _events = {};
  Map<String, dynamic> _abTestVariants = {};
  String? _userId;
  bool _initialized = false;

  // A/B Test configurations
  final Map<String, ABTest> _activeTests = {
    'monthly_price': ABTest(
      testId: 'monthly_price',
      variants: ['0.99', '1.49'],
      weights: [50, 50], // Equal distribution
      description: 'Test monthly subscription pricing',
    ),
    'lifetime_price': ABTest(
      testId: 'lifetime_price',
      variants: ['4.99', '9.99'],
      weights: [50, 50],
      description: 'Test lifetime purchase pricing',
    ),
    'upgrade_button_text': ABTest(
      testId: 'upgrade_button_text',
      variants: ['Upgrade Now', 'Go Premium', 'Unlock Features'],
      weights: [33, 33, 34],
      description: 'Test upgrade button text',
    ),
    'feature_highlight': ABTest(
      testId: 'feature_highlight',
      variants: ['ad_free', 'unlimited_voice', 'cloud_sync'],
      weights: [33, 33, 34],
      description: 'Test which feature to highlight first',
    ),
  };

  // Getters
  bool get initialized => _initialized;
  String? get userId => _userId;
  Map<String, dynamic> get events => _events;

  /// Initialize analytics service
  Future<void> initialize() async {
    await _loadAnalyticsData();
    await _generateUserId();
    await _assignABTestVariants();
    
    _initialized = true;
    notifyListeners();
    
    // Track app session
    await trackEvent('app_session_start', {
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _userId,
    });
    
    debugPrint('Analytics service initialized');
  }

  /// Load analytics data from shared preferences
  Future<void> _loadAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _userId = prefs.getString('analytics_user_id');
    
    final eventsJson = prefs.getString('analytics_events');
    if (eventsJson != null) {
      _events = jsonDecode(eventsJson);
    }
    
    final abTestsJson = prefs.getString('ab_test_variants');
    if (abTestsJson != null) {
      _abTestVariants = jsonDecode(abTestsJson);
    }
  }

  /// Save analytics data to shared preferences
  Future<void> _saveAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_userId != null) {
      await prefs.setString('analytics_user_id', _userId!);
    }
    
    await prefs.setString('analytics_events', jsonEncode(_events));
    await prefs.setString('ab_test_variants', jsonEncode(_abTestVariants));
  }

  /// Generate unique user ID
  Future<void> _generateUserId() async {
    if (_userId != null) return;

    _userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    await _saveAnalyticsData();
  }

  /// Assign A/B test variants to user
  Future<void> _assignABTestVariants() async {
    final random = Random(_userId.hashCode); // Consistent randomization per user
    
    for (final test in _activeTests.values) {
      if (!_abTestVariants.containsKey(test.testId)) {
        final variant = _selectVariant(test, random);
        _abTestVariants[test.testId] = variant;
        
        // Track variant assignment
        await trackEvent('ab_test_assigned', {
          'test_id': test.testId,
          'variant': variant,
          'user_id': _userId,
        });
      }
    }
    
    await _saveAnalyticsData();
  }

  /// Select variant based on weights
  String _selectVariant(ABTest test, Random random) {
    final totalWeight = test.weights.reduce((a, b) => a + b);
    final randomValue = random.nextInt(totalWeight);
    
    int currentWeight = 0;
    for (int i = 0; i < test.variants.length; i++) {
      currentWeight += test.weights[i];
      if (randomValue < currentWeight) {
        return test.variants[i];
      }
    }
    
    return test.variants.first; // Fallback
  }

  /// Get A/B test variant for a specific test
  String? getABTestVariant(String testId) {
    return _abTestVariants[testId];
  }

  /// Track an event
  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    final eventData = {
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _userId,
      'properties': properties,
    };

    // Store event
    if (!_events.containsKey(eventName)) {
      _events[eventName] = [];
    }
    _events[eventName].add(eventData);

    await _saveAnalyticsData();
    
    if (kDebugMode) {
      debugPrint('Analytics event: $eventName - $properties');
    }
    
    // In production, send to analytics backend
    // await _sendToBackend(eventName, eventData);
  }

  /// Track monetization events
  Future<void> trackPurchaseAttempt(String productId, {String? promoCode}) async {
    await trackEvent('purchase_attempt', {
      'product_id': productId,
      'promo_code': promoCode,
      'price_variant': getABTestVariant('${productId}_price'),
    });
  }

  Future<void> trackPurchaseSuccess(String productId, double amount, {String? promoCode}) async {
    await trackEvent('purchase_success', {
      'product_id': productId,
      'amount': amount,
      'promo_code': promoCode,
      'price_variant': getABTestVariant('${productId}_price'),
    });
  }

  Future<void> trackPurchaseFailure(String productId, String error, {String? promoCode}) async {
    await trackEvent('purchase_failure', {
      'product_id': productId,
      'error': error,
      'promo_code': promoCode,
      'price_variant': getABTestVariant('${productId}_price'),
    });
  }

  /// Track ad events
  Future<void> trackAdImpression(String adType, {String? placement}) async {
    await trackEvent('ad_impression', {
      'ad_type': adType,
      'placement': placement ?? 'unknown',
    });
  }

  Future<void> trackAdClick(String adType, {String? placement}) async {
    await trackEvent('ad_click', {
      'ad_type': adType,
      'placement': placement ?? 'unknown',
    });
  }

  /// Track conversion funnel
  Future<void> trackFunnelStep(String funnelName, String step, {Map<String, dynamic>? extra}) async {
    await trackEvent('funnel_step', {
      'funnel': funnelName,
      'step': step,
      'extra': extra ?? {},
    });
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String feature, {Map<String, dynamic>? context}) async {
    await trackEvent('feature_usage', {
      'feature': feature,
      'context': context ?? {},
    });
  }

  /// Track referral events
  Future<void> trackReferralGenerated(String code) async {
    await trackEvent('referral_generated', {
      'referral_code': code,
    });
  }

  Future<void> trackReferralUsed(String code) async {
    await trackEvent('referral_used', {
      'referral_code': code,
    });
  }

  /// Get conversion analytics
  Map<String, dynamic> getConversionAnalytics() {
    final purchaseAttempts = (_events['purchase_attempt'] ?? []).length;
    final purchaseSuccesses = (_events['purchase_success'] ?? []).length;
    final adImpressions = (_events['ad_impression'] ?? []).length;
    final featureUsages = (_events['feature_usage'] ?? []).length;

    final conversionRate = purchaseAttempts > 0 
        ? (purchaseSuccesses / purchaseAttempts * 100).toStringAsFixed(2)
        : '0.00';

    return {
      'total_sessions': (_events['app_session_start'] ?? []).length,
      'purchase_attempts': purchaseAttempts,
      'purchase_successes': purchaseSuccesses,
      'conversion_rate': '$conversionRate%',
      'ad_impressions': adImpressions,
      'feature_usages': featureUsages,
      'ab_tests_active': _activeTests.length,
    };
  }

  /// Get A/B test results
  Map<String, dynamic> getABTestResults(String testId) {
    final test = _activeTests[testId];
    if (test == null) return {};

    final events = _events.values.expand((eventList) => eventList).where(
      (event) => event['properties']['test_id'] == testId,
    );

    final variantResults = <String, Map<String, int>>{};
    
    for (final variant in test.variants) {
      variantResults[variant] = {
        'assignments': 0,
        'conversions': 0,
      };
    }

    // Count assignments and conversions per variant
    for (final event in events) {
      final variant = event['properties']['variant'];
      if (variant != null && variantResults.containsKey(variant)) {
        if (event['properties']['event_name'] == 'ab_test_assigned') {
          variantResults[variant]!['assignments'] = 
              (variantResults[variant]!['assignments'] ?? 0) + 1;
        } else if (event['properties']['event_name'] == 'purchase_success') {
          variantResults[variant]!['conversions'] = 
              (variantResults[variant]!['conversions'] ?? 0) + 1;
        }
      }
    }

    return {
      'test_id': testId,
      'description': test.description,
      'variants': variantResults,
    };
  }

  /// Get LTV (Lifetime Value) analytics
  Future<Map<String, dynamic>> getLTVAnalytics() async {
    final purchaseEvents = _events['purchase_success'] ?? [];
    
    double totalRevenue = 0.0;
    int totalUsers = 0;
    Map<String, double> revenueByProduct = {};

    for (final event in purchaseEvents) {
      final amount = event['properties']['amount'] ?? 0.0;
      final productId = event['properties']['product_id'] ?? 'unknown';
      
      totalRevenue += amount;
      revenueByProduct[productId] = (revenueByProduct[productId] ?? 0.0) + amount;
    }

    // Calculate unique users (simplified)
    final uniqueUsers = purchaseEvents
        .map((e) => e['user_id'])
        .toSet()
        .length;

    final avgLTV = uniqueUsers > 0 ? totalRevenue / uniqueUsers : 0.0;

    return {
      'total_revenue': totalRevenue,
      'unique_paying_users': uniqueUsers,
      'average_ltv': avgLTV,
      'revenue_by_product': revenueByProduct,
    };
  }

  /// Export analytics data
  Map<String, dynamic> exportAnalyticsData() {
    return {
      'user_id': _userId,
      'events': _events,
      'ab_test_variants': _abTestVariants,
      'active_tests': _activeTests.map((k, v) => MapEntry(k, v.toJson())),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset analytics data (for testing)
  Future<void> resetAnalyticsData() async {
    if (kDebugMode) {
      _events.clear();
      _abTestVariants.clear();
      _userId = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('analytics_user_id');
      await prefs.remove('analytics_events');
      await prefs.remove('ab_test_variants');
      
      await initialize();
      debugPrint('Analytics data reset');
    }
  }
}

/// A/B Test configuration model
class ABTest {
  final String testId;
  final List<String> variants;
  final List<int> weights;
  final String description;

  ABTest({
    required this.testId,
    required this.variants,
    required this.weights,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'testId': testId,
    'variants': variants,
    'weights': weights,
    'description': description,
  };
}
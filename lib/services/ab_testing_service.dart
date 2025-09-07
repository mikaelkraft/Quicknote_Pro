import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import '../constants/feature_flags.dart';
import 'analytics/analytics_service.dart';

/// A/B testing service for running experiments and measuring conversion rates.
/// 
/// This service provides infrastructure for running A/B tests on monetization
/// features, UI changes, and pricing strategies.
class ABTestingService extends ChangeNotifier {
  static const String _experimentsKey = 'ab_experiments';
  static const String _userGroupsKey = 'ab_user_groups';
  
  SharedPreferences? _prefs;
  final AnalyticsService _analytics;
  final Random _random = Random();
  
  final Map<String, ABExperiment> _activeExperiments = {};
  final Map<String, String> _userGroups = {};
  bool _initialized = false;

  ABTestingService(this._analytics);

  /// Whether A/B testing is enabled and initialized
  bool get isEnabled => FeatureFlags.abTestingEnabled && _initialized;

  /// Active experiments
  Map<String, ABExperiment> get activeExperiments => Map.unmodifiable(_activeExperiments);

  /// User's assigned groups
  Map<String, String> get userGroups => Map.unmodifiable(_userGroups);

  /// Initialize the A/B testing service
  Future<void> initialize() async {
    if (!FeatureFlags.abTestingEnabled) {
      if (kDebugMode) {
        print('A/B Testing: Disabled via feature flag');
      }
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    await _loadUserGroups();
    _setupDefaultExperiments();
    _initialized = true;

    if (kDebugMode) {
      print('A/B Testing: Initialized with ${_activeExperiments.length} experiments');
    }
  }

  /// Load user's assigned experiment groups
  Future<void> _loadUserGroups() async {
    if (_prefs == null) return;
    
    final userGroupsJson = _prefs!.getString(_userGroupsKey);
    if (userGroupsJson != null) {
      try {
        // In a real implementation, this would parse JSON
        // For now, we'll use a simple string format
        final groups = userGroupsJson.split(',');
        for (final group in groups) {
          final parts = group.split(':');
          if (parts.length == 2) {
            _userGroups[parts[0]] = parts[1];
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('A/B Testing: Failed to load user groups: $e');
        }
      }
    }
  }

  /// Save user groups to storage
  Future<void> _saveUserGroups() async {
    if (_prefs == null) return;
    
    final userGroupsString = _userGroups.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join(',');
    
    await _prefs!.setString(_userGroupsKey, userGroupsString);
  }

  /// Setup default monetization experiments
  void _setupDefaultExperiments() {
    // Paywall headline experiment
    _activeExperiments['paywall_headline'] = ABExperiment(
      id: 'paywall_headline',
      name: 'Paywall Headline Test',
      description: 'Test different headlines for the paywall screen',
      variants: {
        'control': ABVariant(
          id: 'control',
          name: 'Original Headline',
          trafficAllocation: 50,
          parameters: {
            'headline': 'Upgrade to Premium',
            'subtitle': 'Unlock all features and remove ads',
          },
        ),
        'benefit_focused': ABVariant(
          id: 'benefit_focused',
          name: 'Benefit-Focused Headline',
          trafficAllocation: 50,
          parameters: {
            'headline': 'Get Unlimited Notes & Voice Recording',
            'subtitle': 'Plus advanced features and ad-free experience',
          },
        ),
      },
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    // Ad placement timing experiment
    _activeExperiments['ad_timing'] = ABExperiment(
      id: 'ad_timing',
      name: 'Ad Timing Optimization',
      description: 'Test different timing strategies for showing ads',
      variants: {
        'immediate': ABVariant(
          id: 'immediate',
          name: 'Immediate Display',
          trafficAllocation: 33,
          parameters: {
            'min_session_duration': 0,
            'min_actions_before_ad': 1,
          },
        ),
        'delayed': ABVariant(
          id: 'delayed',
          name: 'Delayed Display',
          trafficAllocation: 33,
          parameters: {
            'min_session_duration': 120, // 2 minutes
            'min_actions_before_ad': 3,
          },
        ),
        'engagement_based': ABVariant(
          id: 'engagement_based',
          name: 'Engagement-Based',
          trafficAllocation: 34,
          parameters: {
            'min_session_duration': 60,
            'min_actions_before_ad': 5,
            'engagement_threshold': 0.7,
          },
        ),
      },
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 21)),
    );

    // Trial duration experiment
    _activeExperiments['trial_duration'] = ABExperiment(
      id: 'trial_duration',
      name: 'Trial Duration Test',
      description: 'Test optimal trial duration for conversion',
      variants: {
        'short_trial': ABVariant(
          id: 'short_trial',
          name: '3-Day Trial',
          trafficAllocation: 25,
          parameters: {
            'trial_days': 3,
            'trial_type': 'short_experience',
          },
        ),
        'standard_trial': ABVariant(
          id: 'standard_trial',
          name: '7-Day Trial',
          trafficAllocation: 50,
          parameters: {
            'trial_days': 7,
            'trial_type': 'standard',
          },
        ),
        'extended_trial': ABVariant(
          id: 'extended_trial',
          name: '14-Day Trial',
          trafficAllocation: 25,
          parameters: {
            'trial_days': 14,
            'trial_type': 'extended_experience',
          },
        ),
      },
      isActive: FeatureFlags.trialsEnabled,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 45)),
    );

    // Pricing display experiment
    _activeExperiments['pricing_display'] = ABExperiment(
      id: 'pricing_display',
      name: 'Pricing Display Format',
      description: 'Test different ways to display pricing information',
      variants: {
        'monthly_focus': ABVariant(
          id: 'monthly_focus',
          name: 'Monthly Price Focus',
          trafficAllocation: 50,
          parameters: {
            'primary_display': 'monthly',
            'annual_discount_emphasis': 'low',
          },
        ),
        'annual_savings': ABVariant(
          id: 'annual_savings',
          name: 'Annual Savings Focus',
          trafficAllocation: 50,
          parameters: {
            'primary_display': 'annual',
            'annual_discount_emphasis': 'high',
            'savings_badge': true,
          },
        ),
      },
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 28)),
    );
  }

  /// Get user's variant for an experiment
  String getVariant(String experimentId, {String? userId}) {
    if (!isEnabled) return 'control';
    
    final experiment = _activeExperiments[experimentId];
    if (experiment == null || !experiment.isActive) {
      return 'control';
    }

    // Check if user already has an assigned group
    if (_userGroups.containsKey(experimentId)) {
      return _userGroups[experimentId]!;
    }

    // Assign user to a variant
    final variant = _assignUserToVariant(experiment, userId);
    _userGroups[experimentId] = variant;
    _saveUserGroups();

    // Track experiment exposure
    _analytics.trackExperimentExposure(experimentId, variant);

    return variant;
  }

  /// Assign user to experiment variant based on traffic allocation
  String _assignUserToVariant(ABExperiment experiment, String? userId) {
    // Use userId hash for consistent assignment, or random for anonymous users
    final seed = userId?.hashCode ?? _random.nextInt(100000);
    final randomValue = (seed.abs() % 100) + 1;
    
    int cumulativeTraffic = 0;
    for (final variant in experiment.variants.values) {
      cumulativeTraffic += variant.trafficAllocation;
      if (randomValue <= cumulativeTraffic) {
        return variant.id;
      }
    }
    
    // Fallback to first variant
    return experiment.variants.keys.first;
  }

  /// Get variant parameters for an experiment
  Map<String, dynamic> getVariantParameters(String experimentId, {String? userId}) {
    final variantId = getVariant(experimentId, userId: userId);
    final experiment = _activeExperiments[experimentId];
    
    if (experiment == null) return {};
    
    final variant = experiment.variants[variantId];
    return variant?.parameters ?? {};
  }

  /// Track experiment conversion event
  void trackConversion(String experimentId, String conversionType, {
    Map<String, dynamic>? properties,
    String? userId,
  }) {
    if (!isEnabled) return;
    
    final variantId = getVariant(experimentId, userId: userId);
    
    _analytics.trackEvent(AnalyticsEvent(
      name: 'ab_test_conversion',
      properties: {
        'experiment_id': experimentId,
        'variant_id': variantId,
        'conversion_type': conversionType,
        ...?properties,
      },
    ));

    if (kDebugMode) {
      print('A/B Test Conversion: $experimentId ($variantId) -> $conversionType');
    }
  }

  /// Force user into specific variant (for testing)
  void forceVariant(String experimentId, String variantId) {
    if (!isEnabled) return;
    
    final experiment = _activeExperiments[experimentId];
    if (experiment?.variants.containsKey(variantId) == true) {
      _userGroups[experimentId] = variantId;
      _saveUserGroups();
      
      if (kDebugMode) {
        print('A/B Test: Forced into $experimentId -> $variantId');
      }
    }
  }

  /// Get experiment status for debugging
  Map<String, dynamic> getExperimentStatus() {
    return {
      'enabled': isEnabled,
      'active_experiments': _activeExperiments.length,
      'user_groups': _userGroups,
      'experiments': _activeExperiments.map((key, experiment) => MapEntry(
        key,
        {
          'name': experiment.name,
          'is_active': experiment.isActive,
          'variants': experiment.variants.keys.toList(),
          'user_variant': _userGroups[key],
        },
      )),
    };
  }

  /// Reset all experiment assignments (for testing)
  Future<void> resetExperiments() async {
    _userGroups.clear();
    await _prefs?.remove(_userGroupsKey);
    
    if (kDebugMode) {
      print('A/B Test: Reset all experiment assignments');
    }
  }
}

/// A/B test experiment definition
class ABExperiment {
  final String id;
  final String name;
  final String description;
  final Map<String, ABVariant> variants;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;

  ABExperiment({
    required this.id,
    required this.name,
    required this.description,
    required this.variants,
    required this.isActive,
    required this.startDate,
    required this.endDate,
  });

  bool get isRunning {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
}

/// A/B test variant definition
class ABVariant {
  final String id;
  final String name;
  final int trafficAllocation; // Percentage (0-100)
  final Map<String, dynamic> parameters;

  ABVariant({
    required this.id,
    required this.name,
    required this.trafficAllocation,
    required this.parameters,
  });
}

/// Extension to AnalyticsService for A/B testing events
extension ABTestingAnalytics on AnalyticsService {
  void trackExperimentExposure(String experimentId, String variantId) {
    trackEvent(AnalyticsEvent(
      name: 'ab_test_exposure',
      properties: {
        'experiment_id': experimentId,
        'variant_id': variantId,
      },
    ));
  }
}
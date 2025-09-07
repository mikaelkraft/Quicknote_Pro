import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/feature_flags.dart';
import 'analytics/analytics_service.dart';
import 'monetization/monetization_service.dart';
import 'ads/ads_service.dart';
import 'ab_testing_service.dart';

/// Centralized configuration manager for the monetization system.
/// 
/// This service coordinates all monetization-related services and provides
/// a unified interface for configuration, initialization, and management.
class MonetizationConfigManager extends ChangeNotifier {
  static const String _configVersionKey = 'monetization_config_version';
  static const String _migrationStatusKey = 'monetization_migration_status';
  static const int currentConfigVersion = 1;

  SharedPreferences? _prefs;
  bool _initialized = false;
  
  // Core services
  late final AnalyticsService _analyticsService;
  late final MonetizationService _monetizationService;
  late final AdsService _adsService;
  late final ABTestingService _abTestingService;

  // Configuration state
  final Map<String, dynamic> _runtimeConfig = {};
  final Map<String, bool> _featureOverrides = {};

  /// Whether the system is fully initialized
  bool get isInitialized => _initialized;

  /// Access to analytics service
  AnalyticsService get analytics => _analyticsService;

  /// Access to monetization service  
  MonetizationService get monetization => _monetizationService;

  /// Access to ads service
  AdsService get ads => _adsService;

  /// Access to A/B testing service
  ABTestingService get abTesting => _abTestingService;

  /// Current configuration version
  int get configVersion => _prefs?.getInt(_configVersionKey) ?? 0;

  /// Runtime configuration values
  Map<String, dynamic> get runtimeConfig => Map.unmodifiable(_runtimeConfig);

  /// Initialize the entire monetization system
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Check for kill switch
      if (FeatureFlags.isKillSwitchActive) {
        if (kDebugMode) {
          print('MonetizationConfig: Kill switch active - monetization disabled');
        }
        return;
      }

      // Initialize services in dependency order
      _analyticsService = AnalyticsService();
      await _analyticsService.initialize();

      _abTestingService = ABTestingService(_analyticsService);
      await _abTestingService.initialize();

      _monetizationService = MonetizationService();
      await _monetizationService.initialize();

      _adsService = AdsService();
      await _adsService.initialize();

      // Check for configuration migration
      await _checkAndMigrate();

      // Load runtime configuration
      await _loadRuntimeConfig();

      _initialized = true;

      // Track initialization
      _analyticsService.trackEvent(AnalyticsEvent(
        name: 'monetization_system_initialized',
        properties: {
          'config_version': currentConfigVersion,
          'feature_flags': FeatureFlags.getAllFlags(),
          'services_initialized': [
            'analytics',
            'ab_testing',
            'monetization',
            'ads',
          ],
        },
      ));

      if (kDebugMode) {
        print('MonetizationConfig: System initialized successfully');
      }

    } catch (e) {
      if (kDebugMode) {
        print('MonetizationConfig: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Check for configuration migrations and apply them
  Future<void> _checkAndMigrate() async {
    if (_prefs == null) return;

    final currentVersion = _prefs!.getInt(_configVersionKey) ?? 0;
    
    if (currentVersion < currentConfigVersion) {
      if (kDebugMode) {
        print('MonetizationConfig: Migrating from v$currentVersion to v$currentConfigVersion');
      }

      // Apply migrations
      await _applyMigrations(currentVersion, currentConfigVersion);

      // Update version
      await _prefs!.setInt(_configVersionKey, currentConfigVersion);
      
      // Track migration
      _analyticsService.trackEvent(AnalyticsEvent(
        name: 'monetization_config_migrated',
        properties: {
          'from_version': currentVersion,
          'to_version': currentConfigVersion,
        },
      ));
    }
  }

  /// Apply configuration migrations
  Future<void> _applyMigrations(int fromVersion, int toVersion) async {
    // Migration logic will be added as needed
    // For now, this is a placeholder for future migrations
    
    for (int version = fromVersion; version < toVersion; version++) {
      switch (version) {
        case 0:
          // Initial migration - clean up any legacy data
          await _migrationV1();
          break;
        // Future migrations will be added here
      }
    }
  }

  /// Migration to version 1 - consolidate legacy data
  Future<void> _migrationV1() async {
    if (_prefs == null) return;

    // Clean up any legacy keys that might conflict
    final legacyKeys = [
      'old_monetization_enabled',
      'legacy_trial_data',
      'deprecated_ad_settings',
    ];

    for (final key in legacyKeys) {
      await _prefs!.remove(key);
    }

    // Set migration status
    await _prefs!.setBool(_migrationStatusKey, true);
  }

  /// Load runtime configuration from various sources
  Future<void> _loadRuntimeConfig() async {
    _runtimeConfig.clear();

    // Load from feature flags
    _runtimeConfig.addAll(FeatureFlags.getAllFlags());

    // Add computed values
    _runtimeConfig['is_debug_mode'] = kDebugMode;
    _runtimeConfig['initialization_timestamp'] = DateTime.now().toIso8601String();
    
    // Add service status
    _runtimeConfig['services_status'] = {
      'analytics_enabled': _analyticsService.analyticsEnabled,
      'firebase_initialized': _analyticsService.firebaseInitialized,
      'ab_testing_enabled': _abTestingService.isEnabled,
      'monetization_tier': _monetizationService.currentTier.name,
      'ads_enabled': _adsService.adsEnabled,
    };

    notifyListeners();
  }

  /// Override a feature flag at runtime (for testing/debugging)
  void overrideFeature(String featureName, bool enabled) {
    if (!kDebugMode && !FeatureFlags.debugMonetizationEnabled) {
      throw Exception('Feature overrides only allowed in debug mode');
    }

    _featureOverrides[featureName] = enabled;
    
    // Reload runtime config
    _loadRuntimeConfig();
    
    if (kDebugMode) {
      print('MonetizationConfig: Override $featureName = $enabled');
    }
  }

  /// Check if a feature is enabled (considering overrides)
  bool isFeatureEnabled(String featureName) {
    // Check runtime overrides first
    if (_featureOverrides.containsKey(featureName)) {
      return _featureOverrides[featureName]!;
    }

    // Fall back to feature flags
    return _runtimeConfig[featureName] as bool? ?? false;
  }

  /// Get configuration value with fallback
  T getConfigValue<T>(String key, T defaultValue) {
    return _runtimeConfig[key] as T? ?? defaultValue;
  }

  /// Set runtime configuration value
  void setRuntimeConfig(String key, dynamic value) {
    _runtimeConfig[key] = value;
    notifyListeners();
  }

  /// Get system health status
  Map<String, dynamic> getSystemHealth() {
    return {
      'initialized': _initialized,
      'config_version': configVersion,
      'kill_switch_active': FeatureFlags.isKillSwitchActive,
      'services': {
        'analytics': {
          'enabled': _initialized ? _analyticsService.analyticsEnabled : false,
          'firebase_ready': _initialized ? _analyticsService.firebaseInitialized : false,
        },
        'monetization': {
          'enabled': FeatureFlags.monetizationEnabled,
          'current_tier': _initialized ? _monetizationService.currentTier.name : 'unknown',
          'has_trial': _initialized ? _monetizationService.hasActiveTrial : false,
        },
        'ads': {
          'enabled': _initialized ? _adsService.adsEnabled : false,
          'placement_stats': _initialized ? _adsService.adCounts : {},
        },
        'ab_testing': {
          'enabled': _initialized ? _abTestingService.isEnabled : false,
          'active_experiments': _initialized ? _abTestingService.activeExperiments.length : 0,
        },
      },
      'feature_flags': FeatureFlags.getAllFlags(),
      'runtime_overrides': _featureOverrides,
    };
  }

  /// Emergency reset - clear all monetization data
  Future<void> emergencyReset() async {
    if (!kDebugMode && !FeatureFlags.debugMonetizationEnabled) {
      throw Exception('Emergency reset only allowed in debug mode');
    }

    if (_prefs == null) return;

    // Clear all monetization-related preferences
    final keys = _prefs!.getKeys().where((key) => 
      key.startsWith('monetization_') ||
      key.startsWith('user_tier') ||
      key.startsWith('usage_count_') ||
      key.startsWith('ads_') ||
      key.startsWith('trial_') ||
      key.startsWith('ab_experiments')
    ).toList();

    for (final key in keys) {
      await _prefs!.remove(key);
    }

    // Clear runtime state
    _runtimeConfig.clear();
    _featureOverrides.clear();
    _initialized = false;

    // Track reset
    _analyticsService.trackEvent(AnalyticsEvent(
      name: 'monetization_emergency_reset',
      properties: {'keys_cleared': keys.length},
    ));

    if (kDebugMode) {
      print('MonetizationConfig: Emergency reset completed');
    }

    notifyListeners();
  }

  /// Export configuration for debugging
  Map<String, dynamic> exportConfiguration() {
    return {
      'system_health': getSystemHealth(),
      'runtime_config': _runtimeConfig,
      'feature_overrides': _featureOverrides,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
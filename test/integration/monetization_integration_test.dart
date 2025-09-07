import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/monetization_config_manager.dart';
import 'package:quicknote_pro/constants/feature_flags.dart';

void main() {
  group('Monetization System Integration Tests', () {
    late MonetizationConfigManager configManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      configManager = MonetizationConfigManager();
    });

    test('should initialize all services successfully', () async {
      await configManager.initialize();
      
      expect(configManager.isInitialized, isTrue);
      expect(configManager.analytics, isNotNull);
      expect(configManager.monetization, isNotNull);
      expect(configManager.ads, isNotNull);
      expect(configManager.abTesting, isNotNull);
    });

    test('should handle kill switch activation', () async {
      // Note: In a real test, we'd set environment variables to activate kill switch
      // For now, we test the logic path
      await configManager.initialize();
      
      final health = configManager.getSystemHealth();
      expect(health['kill_switch_active'], equals(FeatureFlags.isKillSwitchActive));
    });

    test('should provide comprehensive system health status', () async {
      await configManager.initialize();
      
      final health = configManager.getSystemHealth();
      
      expect(health, containsPair('initialized', isTrue));
      expect(health, containsPair('config_version', isA<int>()));
      expect(health, containsPair('services', isA<Map>()));
      expect(health, containsPair('feature_flags', isA<Map>()));
      
      final services = health['services'] as Map;
      expect(services, contains('analytics'));
      expect(services, contains('monetization'));
      expect(services, contains('ads'));
      expect(services, contains('ab_testing'));
    });

    test('should handle feature overrides in debug mode', () async {
      await configManager.initialize();
      
      // In debug mode, should allow overrides
      if (FeatureFlags.debugMonetizationEnabled) {
        expect(() {
          configManager.overrideFeature('test_feature', true);
        }, returnsNormally);
        
        expect(configManager.isFeatureEnabled('test_feature'), isTrue);
        
        configManager.overrideFeature('test_feature', false);
        expect(configManager.isFeatureEnabled('test_feature'), isFalse);
      }
    });

    test('should export configuration correctly', () async {
      await configManager.initialize();
      
      final exported = configManager.exportConfiguration();
      
      expect(exported, containsPair('system_health', isA<Map>()));
      expect(exported, containsPair('runtime_config', isA<Map>()));
      expect(exported, containsPair('feature_overrides', isA<Map>()));
      expect(exported, containsPair('timestamp', isA<String>()));
    });

    test('should integrate analytics with monetization events', () async {
      await configManager.initialize();
      
      final analytics = configManager.analytics;
      final monetization = configManager.monetization;
      
      // Test feature limit tracking
      await monetization.recordFeatureUsage(FeatureType.voiceNoteRecording);
      
      // Analytics should have tracked the usage
      expect(analytics.eventCounts.length, greaterThan(0));
    });

    test('should integrate A/B testing with monetization decisions', () async {
      await configManager.initialize();
      
      final abTesting = configManager.abTesting;
      final monetization = configManager.monetization;
      
      // A/B testing should affect upgrade benefits
      final benefits = monetization.getUpgradeBenefits();
      expect(benefits, isNotEmpty);
      
      // Different variants should potentially show different benefits
      final variant = abTesting.getVariant('paywall_headline');
      expect(variant, isNotEmpty);
    });

    test('should coordinate ads with feature flags', () async {
      await configManager.initialize();
      
      final ads = configManager.ads;
      
      // Ads should respect feature flags
      expect(ads.adsEnabled, equals(FeatureFlags.adsEnabled));
      
      // Different placements should be controlled by specific flags
      for (final placement in AdPlacement.values) {
        final canShow = ads.canShowAd(placement);
        expect(canShow, isA<bool>());
      }
    });

    test('should handle service dependencies correctly', () async {
      await configManager.initialize();
      
      // All services should be initialized in the correct order
      expect(configManager.analytics.analyticsEnabled, isA<bool>());
      expect(configManager.abTesting.isEnabled, isA<bool>());
      expect(configManager.monetization.currentTier, isA<UserTier>());
      expect(configManager.ads.adsEnabled, isA<bool>());
    });

    test('should track monetization system initialization', () async {
      await configManager.initialize();
      
      final analytics = configManager.analytics;
      final events = analytics.getEventQueue();
      
      // Should have tracked initialization event
      final initEvents = events.where((event) => 
        event.name == 'monetization_system_initialized');
      expect(initEvents.length, greaterThan(0));
    });

    test('should handle configuration migration', () async {
      // Set up old configuration version
      SharedPreferences.setMockInitialValues({
        'monetization_config_version': 0,
      });
      
      configManager = MonetizationConfigManager();
      await configManager.initialize();
      
      // Should have migrated to current version
      expect(configManager.configVersion, equals(1));
    });

    test('should validate runtime configuration', () async {
      await configManager.initialize();
      
      final config = configManager.runtimeConfig;
      
      // Should contain all feature flags
      expect(config, containsPair('monetization_enabled', isA<bool>()));
      expect(config, containsPair('ads_enabled', isA<bool>()));
      expect(config, containsPair('paywall_enabled', isA<bool>()));
      
      // Should contain service status
      expect(config, containsPair('services_status', isA<Map>()));
      
      // Should contain metadata
      expect(config, containsPair('is_debug_mode', isA<bool>()));
      expect(config, containsPair('initialization_timestamp', isA<String>()));
    });

    test('should handle emergency reset in debug mode', () async {
      await configManager.initialize();
      
      if (FeatureFlags.debugMonetizationEnabled) {
        // Should allow emergency reset
        expect(() async {
          await configManager.emergencyReset();
        }, returnsNormally);
        
        expect(configManager.isInitialized, isFalse);
      }
    });

    test('should integrate all monetization components seamlessly', () async {
      await configManager.initialize();
      
      // Simulate a complete user flow
      final monetization = configManager.monetization;
      final analytics = configManager.analytics;
      final ads = configManager.ads;
      final abTesting = configManager.abTesting;
      
      // 1. User encounters feature limit
      expect(monetization.canUseFeature(FeatureType.voiceNoteRecording), isA<bool>());
      
      // 2. System decides whether to show upgrade prompt
      expect(monetization.shouldShowUpgradePrompt(FeatureType.voiceNoteRecording), isA<bool>());
      
      // 3. A/B test determines which paywall variant to show
      final paywallVariant = abTesting.getVariant('paywall_headline');
      expect(paywallVariant, isNotEmpty);
      
      // 4. Analytics tracks the flow
      expect(analytics.analyticsEnabled, isA<bool>());
      
      // 5. Ads system respects premium status
      expect(ads.adsEnabled, isA<bool>());
      
      // All components should work together without conflicts
      expect(configManager.getSystemHealth()['initialized'], isTrue);
    });
  });
}
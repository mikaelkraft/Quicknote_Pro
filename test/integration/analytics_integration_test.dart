import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quicknote_pro/services/analytics/analytics_service.dart';
import 'package:quicknote_pro/services/analytics/events.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics Integration Tests', () {
    test('Analytics service should work without Firebase configuration', () async {
      final analyticsService = AnalyticsService();
      
      // Initialize service (should work without Firebase)
      await analyticsService.initialize();
      
      // Service should be enabled but Firebase not initialized
      expect(analyticsService.analyticsEnabled, true);
      expect(analyticsService.firebaseInitialized, false);
      
      // All Firebase methods should work as no-ops
      await analyticsService.setUserId('test_user');
      await analyticsService.setUserProperty('test_property', 'test_value');
      await analyticsService.logScreenView('test_screen');
      await analyticsService.logEvent('test_event', {'param': 'value'});
      
      // Legacy event tracking should still work
      analyticsService.trackEvent(AnalyticsEvent.appStarted());
      expect(analyticsService.eventCounts['app_started'], 1);
      
      // Monetization event helpers should work
      final adParams = MonetizationEventHelpers.adEventParams(
        placement: AdPlacements.homeScreen,
        format: 'banner',
      );
      expect(adParams[MonetizationParams.adPlacement], AdPlacements.homeScreen);
      expect(adParams[MonetizationParams.adFormat], 'banner');
      
      print('✅ Analytics service works safely without Firebase configuration');
    });

    test('Events schema should be accessible and well-formed', () {
      // Test that all event constants are accessible
      expect(MonetizationEvents.adRequested, 'ad_requested');
      expect(MonetizationEvents.upgradeCompleted, 'upgrade_completed');
      expect(MonetizationEvents.featureLimitReached, 'feature_limit_reached');
      
      // Test parameter constants
      expect(MonetizationParams.adPlacement, 'ad_placement');
      expect(MonetizationParams.productId, 'product_id');
      expect(MonetizationParams.featureName, 'feature_name');
      
      // Test placement constants
      expect(AdPlacements.homeScreen, 'home_screen');
      expect(AdPlacements.noteEditor, 'note_editor');
      
      // Test feature names
      expect(FeatureNames.voiceNotes, 'voice_notes');
      expect(FeatureNames.cloudSync, 'cloud_sync');
      
      // Test product IDs
      expect(ProductIds.premiumMonthly, 'premium_monthly');
      expect(ProductIds.premiumYearly, 'premium_yearly');
      
      // Test helper functions
      final adParams = MonetizationEventHelpers.adEventParams(
        placement: AdPlacements.homeScreen,
        format: 'banner',
        revenue: 0.05,
        currency: 'USD',
      );
      expect(adParams.length, 4);
      expect(adParams[MonetizationParams.adRevenue], 0.05);
      expect(adParams[MonetizationParams.currency], 'USD');
      
      // Test parameter filtering (null values should be removed)
      final filteredParams = MonetizationEventHelpers.adEventParams(
        placement: AdPlacements.homeScreen,
        format: null,
        revenue: 0.05,
      );
      expect(filteredParams.containsKey(MonetizationParams.adFormat), false);
      expect(filteredParams.containsKey(MonetizationParams.adRevenue), true);
      
      print('✅ Events schema is accessible and functions correctly');
    });
  });
}
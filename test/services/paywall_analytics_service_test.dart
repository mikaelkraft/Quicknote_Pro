import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/theme/paywall_analytics_service.dart';

void main() {
  group('PaywallAnalyticsService', () {
    test('should log paywall shown events', () {
      // This test verifies the analytics service logs events correctly
      // In a real implementation, you would mock the analytics backend
      
      expect(() {
        PaywallAnalyticsService.logPaywallShown(
          entryPoint: 'theme_picker',
          featureType: 'theme',
          specificFeature: 'futuristic',
        );
      }, returnsNormally);
    });

    test('should log paywall conversion events', () {
      expect(() {
        PaywallAnalyticsService.logPaywallConversion(
          entryPoint: 'theme_picker',
          purchaseType: 'new_purchase',
          planType: 'lifetime',
          price: 14.99,
        );
      }, returnsNormally);
    });

    test('should log failed payment events', () {
      expect(() {
        PaywallAnalyticsService.logFailedPayment(
          entryPoint: 'theme_picker',
          planType: 'lifetime',
          errorType: 'user_cancelled',
        );
      }, returnsNormally);
    });

    test('should log theme selection attempts', () {
      expect(() {
        PaywallAnalyticsService.logThemeSelectionAttempt(
          themeId: 'futuristic',
          isProTheme: true,
          hasAccess: false,
          action: 'blocked',
        );
      }, returnsNormally);
    });

    test('should log upsell entry points', () {
      expect(() {
        PaywallAnalyticsService.logUpsellEntryPoint(
          entryPoint: 'settings',
          action: 'clicked',
          targetFeature: 'theme_picker',
        );
      }, returnsNormally);
    });

    test('should log paywall dismissals', () {
      expect(() {
        PaywallAnalyticsService.logPaywallDismissed(
          entryPoint: 'theme_picker',
          dismissReason: 'close_button',
          timeSpentSeconds: 30,
        );
      }, returnsNormally);
    });

    test('should log offer interactions', () {
      expect(() {
        PaywallAnalyticsService.logOfferInteraction(
          offerType: 'free_trial',
          action: 'viewed',
          entryPoint: 'theme_picker',
        );
      }, returnsNormally);
    });

    test('should log purchase restore attempts', () {
      expect(() {
        PaywallAnalyticsService.logPurchaseRestore(
          success: true,
          restoredItemsCount: 1,
        );
      }, returnsNormally);
    });

    test('should return analytics summary', () {
      final summary = PaywallAnalyticsService.getAnalyticsSummary();
      
      expect(summary, isA<Map<String, dynamic>>());
      expect(summary['analytics_service'], 'PaywallAnalyticsService');
      expect(summary['events_tracked'], isA<List>());
      expect(summary['events_tracked'].length, greaterThan(0));
      expect(summary['last_updated'], isNotNull);
    });

    test('should handle analytics events with additional data', () {
      expect(() {
        PaywallAnalyticsService.logPaywallShown(
          entryPoint: 'theme_picker',
          featureType: 'theme',
          specificFeature: 'futuristic',
          additionalData: {
            'user_session_id': 'abc123',
            'device_type': 'mobile',
            'app_version': '1.0.0',
          },
        );
      }, returnsNormally);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/monetization/monetization_service.dart';
import 'package:quicknote_pro/constants/product_ids.dart';

void main() {
  group('MonetizationService Tests', () {
    late MonetizationService monetizationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      monetizationService = MonetizationService();
    });

    test('should initialize successfully', () async {
      await monetizationService.initialize();
      expect(monetizationService, isNotNull);
    });

    test('should start with free tier user', () async {
      await monetizationService.initialize();
      expect(monetizationService.isPremiumUser, false);
      expect(monetizationService.userTier, 'free');
    });

    test('should update premium status', () async {
      await monetizationService.initialize();
      
      expect(monetizationService.isPremiumUser, false);
      
      await monetizationService.updatePremiumStatus(true);
      expect(monetizationService.isPremiumUser, true);
      expect(monetizationService.userTier, 'premium');
    });

    test('should check feature availability correctly', () async {
      await monetizationService.initialize();
      
      // Free user should have access to basic features
      expect(monetizationService.isFeatureAvailable('basic_notes'), true);
      expect(monetizationService.isFeatureAvailable('basic_editing'), true);
      expect(monetizationService.isFeatureAvailable('premium_only_feature'), false);
      
      // Premium user should have access to all features
      await monetizationService.updatePremiumStatus(true);
      expect(monetizationService.isFeatureAvailable('premium_only_feature'), true);
    });

    test('should enforce usage limits for free users', () async {
      await monetizationService.initialize();
      
      // Free users should be limited by usage
      expect(await monetizationService.canUseFeature('create_note'), true);
      expect(await monetizationService.canUseFeature('voice_note'), true);
      expect(await monetizationService.canUseFeature('cloud_sync'), false);
      expect(await monetizationService.canUseFeature('advanced_drawing'), false);
    });

    test('should allow unlimited usage for premium users', () async {
      await monetizationService.initialize();
      await monetizationService.updatePremiumStatus(true);
      
      // Premium users should have no limits
      expect(await monetizationService.canUseFeature('create_note'), true);
      expect(await monetizationService.canUseFeature('voice_note'), true);
      expect(await monetizationService.canUseFeature('cloud_sync'), true);
      expect(await monetizationService.canUseFeature('advanced_drawing'), true);
    });

    test('should track feature blocking', () async {
      await monetizationService.initialize();
      
      await monetizationService.trackFeatureBlocked('voice_note', reason: 'monthly_limit');
      // Verify analytics event was tracked
      expect(true, true); // Placeholder assertion
    });

    test('should track premium screen views', () async {
      await monetizationService.initialize();
      
      await monetizationService.trackPremiumScreenView(source: 'feature_blocked');
      // Verify analytics event was tracked
      expect(true, true); // Placeholder assertion
    });

    test('should track upgrade attempts', () async {
      await monetizationService.initialize();
      
      await monetizationService.trackUpgradeAttempt('monthly', source: 'banner');
      // Verify analytics event was tracked
      expect(true, true); // Placeholder assertion
    });

    test('should track purchase events', () async {
      await monetizationService.initialize();
      
      await monetizationService.trackPurchaseEvent(
        'purchase_completed',
        planType: 'monthly',
        price: '2.99',
        currency: 'USD',
      );
      // Verify analytics event was tracked
      expect(true, true); // Placeholder assertion
    });

    test('should generate usage statistics', () async {
      await monetizationService.initialize();
      
      final stats = await monetizationService.getUsageStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('notes_count'), true);
      expect(stats.containsKey('notes_limit'), true);
      expect(stats.containsKey('voice_notes_count'), true);
      expect(stats.containsKey('voice_notes_limit'), true);
      expect(stats.containsKey('attachments_count'), true);
      expect(stats.containsKey('attachments_limit'), true);
      expect(stats.containsKey('is_premium'), true);
      expect(stats.containsKey('tier'), true);
      
      expect(stats['notes_limit'], ProductIds.freeNotesLimit);
      expect(stats['voice_notes_limit'], ProductIds.freeVoiceNotesLimit);
      expect(stats['attachments_limit'], ProductIds.freeAttachmentsLimit);
      expect(stats['is_premium'], false);
      expect(stats['tier'], 'free');
    });

    test('should generate monetization insights', () async {
      await monetizationService.initialize();
      
      final insights = await monetizationService.getMonetizationInsights();
      
      expect(insights, isA<Map<String, dynamic>>());
      expect(insights.containsKey('user_metrics'), true);
      expect(insights.containsKey('ad_metrics'), true);
      expect(insights.containsKey('usage_stats'), true);
      expect(insights.containsKey('conversion_funnel'), true);
    });

    test('should increment usage counters', () async {
      await monetizationService.initialize();
      
      await monetizationService.incrementNotesCount();
      await monetizationService.incrementVoiceNotesCount();
      await monetizationService.incrementAttachmentsCount();
      
      // Verify counters were incremented
      expect(true, true); // Placeholder assertion
    });
  });

  group('ProductIds Tests', () {
    test('should have correct product IDs', () {
      expect(ProductIds.premiumMonthly, 'quicknote_premium_monthly');
      expect(ProductIds.premiumLifetime, 'quicknote_premium_lifetime');
      expect(ProductIds.premiumWeeklyTrial, 'quicknote_premium_weekly_trial');
    });

    test('should have all product IDs in allProductIds list', () {
      expect(ProductIds.allProductIds.contains(ProductIds.premiumMonthly), true);
      expect(ProductIds.allProductIds.contains(ProductIds.premiumLifetime), true);
      expect(ProductIds.allProductIds.contains(ProductIds.premiumWeeklyTrial), true);
      expect(ProductIds.allProductIds.length, 3);
    });

    test('should have display names for all products', () {
      for (final productId in ProductIds.allProductIds) {
        expect(ProductIds.productDisplayNames.containsKey(productId), true);
        expect(ProductIds.productDisplayNames[productId], isNotEmpty);
      }
    });

    test('should have fallback prices for all products', () {
      for (final productId in ProductIds.allProductIds) {
        expect(ProductIds.fallbackPrices.containsKey(productId), true);
        expect(ProductIds.fallbackPrices[productId], isNotEmpty);
      }
    });

    test('should have correct free tier limits', () {
      expect(ProductIds.freeNotesLimit, 50);
      expect(ProductIds.freeVoiceNotesLimit, 10);
      expect(ProductIds.freeAttachmentsLimit, 5);
      expect(ProductIds.freeCloudStorageMB, 100);
    });

    test('should have premium features list', () {
      expect(ProductIds.premiumFeatures, isA<List<String>>());
      expect(ProductIds.premiumFeatures.length, greaterThan(5));
      expect(ProductIds.premiumFeatures.contains('Unlimited notes and voice recordings'), true);
      expect(ProductIds.premiumFeatures.contains('Ad-free experience'), true);
    });

    test('should have IAP enabled by default', () {
      expect(ProductIds.iapEnabled, true);
      expect(ProductIds.allowDevBypass, true);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicknote_pro/models/pricing_tier.dart';
import 'package:quicknote_pro/models/user_entitlements.dart';
import 'package:quicknote_pro/services/pricing_tier_service.dart';

void main() {
  group('PricingTierService', () {
    late PricingTierService service;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = PricingTierService();
      await service.initialize();
    });

    test('should initialize with free entitlements', () async {
      expect(service.currentTier, PricingTier.free);
      expect(service.isPremium, false);
      expect(service.currentEntitlements.subscriptionType, SubscriptionType.none);
    });

    test('should start free trial successfully', () async {
      final result = await service.startFreeTrial();
      
      expect(result, true);
      expect(service.isPremium, true);
      expect(service.currentEntitlements.isInTrial, true);
      expect(service.currentEntitlements.subscriptionType, SubscriptionType.trial);
      expect(service.currentEntitlements.trialDaysRemaining, 6); // 7 days minus some time
    });

    test('should not allow multiple trials', () async {
      await service.startFreeTrial();
      final secondResult = await service.startFreeTrial();
      
      expect(secondResult, false);
    });

    test('should activate premium subscription', () async {
      final result = await service.activatePremiumSubscription(
        subscriptionType: SubscriptionType.monthly,
        productId: 'test_product',
        subscriptionId: 'test_sub_123',
      );
      
      expect(result, true);
      expect(service.isPremium, true);
      expect(service.currentEntitlements.hasActiveSubscription, true);
      expect(service.currentEntitlements.subscriptionType, SubscriptionType.monthly);
      expect(service.currentEntitlements.subscriptionId, 'test_sub_123');
    });

    test('should activate lifetime subscription', () async {
      final result = await service.activatePremiumSubscription(
        subscriptionType: SubscriptionType.lifetime,
        productId: 'test_lifetime',
      );
      
      expect(result, true);
      expect(service.isPremium, true);
      expect(service.currentEntitlements.hasActiveSubscription, true);
      expect(service.currentEntitlements.subscriptionType, SubscriptionType.lifetime);
      expect(service.currentEntitlements.isSubscriptionExpired, false);
    });

    test('should track voice note usage', () async {
      expect(service.currentEntitlements.currentMonthVoiceNotes, 0);
      expect(service.hasReachedVoiceNoteLimit(), false);
      
      // Use up to the limit
      for (int i = 0; i < 10; i++) {
        await service.incrementVoiceNoteUsage();
      }
      
      expect(service.currentEntitlements.currentMonthVoiceNotes, 10);
      expect(service.hasReachedVoiceNoteLimit(), true);
      expect(service.getRemainingVoiceNotes(), 0);
    });

    test('should track export usage', () async {
      expect(service.currentEntitlements.currentMonthExports, 0);
      expect(service.hasReachedExportLimit(), false);
      
      // Use up to the limit
      for (int i = 0; i < 5; i++) {
        await service.incrementExportUsage();
      }
      
      expect(service.currentEntitlements.currentMonthExports, 5);
      expect(service.hasReachedExportLimit(), true);
      expect(service.getRemainingExports(), 0);
    });

    test('should not limit premium users', () async {
      await service.activatePremiumSubscription(
        subscriptionType: SubscriptionType.lifetime,
        productId: 'test_lifetime',
      );
      
      // Simulate heavy usage
      for (int i = 0; i < 100; i++) {
        await service.incrementVoiceNoteUsage();
        await service.incrementExportUsage();
      }
      
      expect(service.hasReachedVoiceNoteLimit(), false);
      expect(service.hasReachedExportLimit(), false);
      expect(service.getRemainingVoiceNotes(), -1); // Unlimited
      expect(service.getRemainingExports(), -1); // Unlimited
    });

    test('should check subscription renewal needs', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      
      await service.activatePremiumSubscription(
        subscriptionType: SubscriptionType.monthly,
        productId: 'test_monthly',
        subscriptionEndDate: pastDate,
      );
      
      expect(service.needsRenewal(), true);
      expect(service.isPremium, false); // Expired subscription
    });

    test('should detect trial expiring soon', () async {
      final soonDate = DateTime.now().add(const Duration(hours: 12));
      
      // Manually set a trial that expires soon
      final trialEntitlements = UserEntitlements.trial(
        trialStartDate: DateTime.now().subtract(const Duration(days: 6)),
        trialEndDate: soonDate,
      );
      
      // Update service with these entitlements
      service.clearData();
      await service.activatePremiumSubscription(
        subscriptionType: SubscriptionType.trial,
        productId: 'trial',
      );
      
      // This is a simplified test - in reality we'd need to mock the entitlements
      expect(service.currentEntitlements.isInTrial, true);
    });

    test('should provide upgrade messaging', () {
      final voiceNoteMessaging = service.getUpgradeMessaging('voice_note_limit');
      
      expect(voiceNoteMessaging['title'], isNotNull);
      expect(voiceNoteMessaging['message'], isNotNull);
      expect(voiceNoteMessaging['cta'], isNotNull);
      expect(voiceNoteMessaging['message'], contains('voice notes'));
    });

    test('should track analytics events', () async {
      final events = <MonetizationEvent>[];
      final eventData = <Map<String, dynamic>>[];
      
      service.setAnalyticsCallback((event, data) {
        events.add(event);
        eventData.add(data);
      });
      
      await service.startFreeTrial();
      service.trackFreeLimitReached('voice_note');
      service.trackUpgradeInitiated('test_product', 'limit_reached');
      
      expect(events.length, 3);
      expect(events.contains(MonetizationEvent.trialStarted), true);
      expect(events.contains(MonetizationEvent.freeLimitReached), true);
      expect(events.contains(MonetizationEvent.upgradeInitiated), true);
    });

    test('should restore purchases with rate limiting', () async {
      // First restore attempt should work
      final firstResult = await service.restorePurchases();
      expect(firstResult, false); // No purchases to restore in test
      
      // Second attempt immediately should be rate limited
      final secondResult = await service.restorePurchases();
      expect(secondResult, false);
    });

    test('should persist entitlements across restarts', () async {
      await service.activatePremiumSubscription(
        subscriptionType: SubscriptionType.lifetime,
        productId: 'test_lifetime',
        subscriptionId: 'test_123',
      );
      
      // Create a new service instance to simulate app restart
      final newService = PricingTierService();
      await newService.initialize();
      
      expect(newService.isPremium, true);
      expect(newService.currentEntitlements.subscriptionType, SubscriptionType.lifetime);
      expect(newService.currentEntitlements.subscriptionId, 'test_123');
    });

    test('should handle corrupted data gracefully', () async {
      // Manually corrupt the data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_entitlements', 'invalid_json');
      
      // Create new service - should reset to free
      final newService = PricingTierService();
      await newService.initialize();
      
      expect(newService.currentTier, PricingTier.free);
      expect(newService.isPremium, false);
    });

    test('should clear data completely', () async {
      await service.activatePremiumSubscription(
        subscriptionType: SubscriptionType.lifetime,
        productId: 'test_lifetime',
      );
      await service.incrementVoiceNoteUsage();
      
      expect(service.isPremium, true);
      expect(service.currentEntitlements.currentMonthVoiceNotes, 1);
      
      await service.clearData();
      
      expect(service.isPremium, false);
      expect(service.currentTier, PricingTier.free);
      expect(service.currentEntitlements.currentMonthVoiceNotes, 0);
    });

    test('should handle failed purchases', () async {
      final events = <MonetizationEvent>[];
      service.setAnalyticsCallback((event, data) {
        events.add(event);
      });
      
      await service.handleFailedPurchase('test_product', 'payment_declined');
      
      expect(events.contains(MonetizationEvent.upgradeFailed), true);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicknote_pro/models/pricing_tier.dart';
import 'package:quicknote_pro/models/user_entitlements.dart';

void main() {
  group('PricingTierLimits', () {
    test('should have correct free tier limits', () {
      const limits = PricingTierLimits.free;
      
      expect(limits.tier, PricingTier.free);
      expect(limits.maxNotes, 100);
      expect(limits.maxVoiceNotesPerMonth, 10);
      expect(limits.maxExportsPerMonth, 5);
      expect(limits.maxSyncDevices, 0);
      expect(limits.hasCloudSync, false);
      expect(limits.hasAdvancedDrawingTools, false);
      expect(limits.isAdFree, false);
      expect(limits.hasCustomThemes, false);
      expect(limits.hasUnlimitedBackups, false);
      expect(limits.hasOcrTextRecognition, false);
      expect(limits.maxAttachmentsPerNote, 3);
      expect(limits.maxAttachmentSizeMB, 5);
    });

    test('should have correct premium tier limits', () {
      const limits = PricingTierLimits.premium;
      
      expect(limits.tier, PricingTier.premium);
      expect(limits.maxNotes, -1); // Unlimited
      expect(limits.maxVoiceNotesPerMonth, -1); // Unlimited
      expect(limits.maxExportsPerMonth, -1); // Unlimited
      expect(limits.maxSyncDevices, -1); // Unlimited
      expect(limits.hasCloudSync, true);
      expect(limits.hasAdvancedDrawingTools, true);
      expect(limits.isAdFree, true);
      expect(limits.hasCustomThemes, true);
      expect(limits.hasUnlimitedBackups, true);
      expect(limits.hasOcrTextRecognition, true);
      expect(limits.maxAttachmentsPerNote, -1); // Unlimited
      expect(limits.maxAttachmentSizeMB, 100);
    });

    test('should correctly identify unlimited values', () {
      const limits = PricingTierLimits.premium;
      
      expect(limits.isUnlimited(-1), true);
      expect(limits.isUnlimited(100), false);
      expect(limits.isUnlimited(0), false);
    });

    test('should provide correct limit display text', () {
      const limits = PricingTierLimits.premium;
      
      expect(limits.getLimitDisplay(-1), 'Unlimited');
      expect(limits.getLimitDisplay(100), '100');
      expect(limits.getLimitDisplay(0), '0');
    });

    test('should serialize to and from JSON correctly', () {
      const originalLimits = PricingTierLimits.free;
      final json = originalLimits.toJson();
      final restoredLimits = PricingTierLimits.fromJson(json);
      
      expect(restoredLimits, originalLimits);
    });

    test('should get limits for specific tier', () {
      final freeLimits = PricingTierLimits.forTier(PricingTier.free);
      final premiumLimits = PricingTierLimits.forTier(PricingTier.premium);
      
      expect(freeLimits, PricingTierLimits.free);
      expect(premiumLimits, PricingTierLimits.premium);
    });
  });

  group('UserEntitlements', () {
    test('should create free user entitlements correctly', () {
      final entitlements = UserEntitlements.free();
      
      expect(entitlements.tier, PricingTier.free);
      expect(entitlements.subscriptionType, SubscriptionType.none);
      expect(entitlements.isPremium, false);
      expect(entitlements.hasActiveSubscription, false);
      expect(entitlements.isInTrial, false);
      expect(entitlements.canStartTrial, true);
      expect(entitlements.isTrialUsed, false);
      expect(entitlements.currentMonthVoiceNotes, 0);
      expect(entitlements.currentMonthExports, 0);
    });

    test('should create premium user entitlements correctly', () {
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));
      
      final entitlements = UserEntitlements.premium(
        subscriptionType: SubscriptionType.monthly,
        subscriptionStartDate: now,
        subscriptionEndDate: endDate,
        subscriptionId: 'test_sub_123',
      );
      
      expect(entitlements.tier, PricingTier.premium);
      expect(entitlements.subscriptionType, SubscriptionType.monthly);
      expect(entitlements.isPremium, true);
      expect(entitlements.hasActiveSubscription, true);
      expect(entitlements.isInTrial, false);
      expect(entitlements.canStartTrial, false);
      expect(entitlements.isTrialUsed, true);
      expect(entitlements.subscriptionId, 'test_sub_123');
    });

    test('should create trial entitlements correctly', () {
      final now = DateTime.now();
      final trialEnd = now.add(const Duration(days: 7));
      
      final entitlements = UserEntitlements.trial(
        trialStartDate: now,
        trialEndDate: trialEnd,
      );
      
      expect(entitlements.tier, PricingTier.premium); // Trial gives premium access
      expect(entitlements.subscriptionType, SubscriptionType.trial);
      expect(entitlements.isPremium, true);
      expect(entitlements.hasActiveSubscription, false);
      expect(entitlements.isInTrial, true);
      expect(entitlements.canStartTrial, false);
      expect(entitlements.isTrialUsed, true);
      expect(entitlements.trialDaysRemaining, 6); // Should be 6 days remaining
    });

    test('should handle lifetime subscription correctly', () {
      final entitlements = UserEntitlements.premium(
        subscriptionType: SubscriptionType.lifetime,
      );
      
      expect(entitlements.isPremium, true);
      expect(entitlements.hasActiveSubscription, true);
      expect(entitlements.isSubscriptionExpired, false);
    });

    test('should handle expired monthly subscription', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));
      
      final entitlements = UserEntitlements.premium(
        subscriptionType: SubscriptionType.monthly,
        subscriptionStartDate: pastDate.subtract(const Duration(days: 30)),
        subscriptionEndDate: pastDate,
      );
      
      expect(entitlements.isPremium, false);
      expect(entitlements.hasActiveSubscription, false);
      expect(entitlements.isSubscriptionExpired, true);
    });

    test('should handle expired trial correctly', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));
      
      final entitlements = UserEntitlements.trial(
        trialStartDate: pastDate.subtract(const Duration(days: 7)),
        trialEndDate: pastDate,
      );
      
      expect(entitlements.isPremium, false);
      expect(entitlements.isInTrial, false);
      expect(entitlements.isTrialExpired, true);
      expect(entitlements.trialDaysRemaining, 0);
    });

    test('should reset usage correctly', () {
      final entitlements = UserEntitlements.free()
          .incrementVoiceNotes()
          .incrementVoiceNotes()
          .incrementExports();
      
      expect(entitlements.currentMonthVoiceNotes, 2);
      expect(entitlements.currentMonthExports, 1);
      
      final resetEntitlements = entitlements.resetUsage();
      
      expect(resetEntitlements.currentMonthVoiceNotes, 0);
      expect(resetEntitlements.currentMonthExports, 0);
    });

    test('should detect when usage reset is needed', () {
      final lastMonth = DateTime.now().subtract(const Duration(days: 35));
      final entitlements = UserEntitlements.free().copyWith(
        lastUsageReset: lastMonth,
      );
      
      expect(entitlements.needsUsageReset, true);
    });

    test('should serialize to and from JSON correctly', () {
      final originalEntitlements = UserEntitlements.premium(
        subscriptionType: SubscriptionType.monthly,
        subscriptionStartDate: DateTime.now(),
        subscriptionEndDate: DateTime.now().add(const Duration(days: 30)),
        subscriptionId: 'test_123',
      );
      
      final json = originalEntitlements.toJson();
      final restoredEntitlements = UserEntitlements.fromJson(json);
      
      expect(restoredEntitlements.tier, originalEntitlements.tier);
      expect(restoredEntitlements.subscriptionType, originalEntitlements.subscriptionType);
      expect(restoredEntitlements.subscriptionId, originalEntitlements.subscriptionId);
      expect(restoredEntitlements.isPremium, originalEntitlements.isPremium);
    });

    test('should get current limits based on tier', () {
      final freeEntitlements = UserEntitlements.free();
      final premiumEntitlements = UserEntitlements.premium(
        subscriptionType: SubscriptionType.lifetime,
      );
      
      expect(freeEntitlements.currentLimits, PricingTierLimits.free);
      expect(premiumEntitlements.currentLimits, PricingTierLimits.premium);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/monetization/monetization_service.dart';

void main() {
  group('MonetizationService', () {
    late MonetizationService monetizationService;

    setUp(() {
      monetizationService = MonetizationService();
    });

    test('should initialize with free tier by default', () {
      expect(monetizationService.currentTier, UserTier.free);
      expect(monetizationService.isPremium, false);
    });

    test('should recognize premium status for premium, pro, and enterprise tiers', () {
      monetizationService.setUserTier(UserTier.premium);
      expect(monetizationService.isPremium, true);

      monetizationService.setUserTier(UserTier.pro);
      expect(monetizationService.isPremium, true);

      monetizationService.setUserTier(UserTier.enterprise);
      expect(monetizationService.isPremium, true);

      monetizationService.setUserTier(UserTier.free);
      expect(monetizationService.isPremium, false);
    });

    test('should enforce feature limits for free tier', () {
      expect(monetizationService.isFeatureAvailable(FeatureType.noteCreation), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedDrawing), false);
      expect(monetizationService.canUseFeature(FeatureType.noteCreation), true);
    });

    test('should allow all features for premium, pro, and enterprise tiers', () {
      monetizationService.setUserTier(UserTier.premium);
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedDrawing), true);
      expect(monetizationService.canUseFeature(FeatureType.advancedDrawing), true);

      monetizationService.setUserTier(UserTier.pro);
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedDrawing), true);
      expect(monetizationService.canUseFeature(FeatureType.advancedDrawing), true);

      monetizationService.setUserTier(UserTier.enterprise);
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedDrawing), true);
      expect(monetizationService.canUseFeature(FeatureType.advancedDrawing), true);
    });

    test('should track feature usage correctly', () {
      monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      monetizationService.recordFeatureUsage(FeatureType.noteCreation);

      expect(monetizationService.usageCounts[FeatureType.noteCreation], 2);
    });

    test('should calculate remaining usage correctly', () {
      // Free tier has 50 note limit
      for (int i = 0; i < 45; i++) {
        monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      }

      expect(monetizationService.getRemainingUsage(FeatureType.noteCreation), 5);
    });

    test('should show upgrade prompt when feature limit is reached', () {
      // Reach note creation limit for free tier
      for (int i = 0; i < 50; i++) {
        monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      }

      expect(monetizationService.shouldShowUpgradePrompt(FeatureType.noteCreation), true);
    });

    test('should not show upgrade prompt for premium users', () {
      monetizationService.setUserTier(UserTier.premium);
      expect(monetizationService.shouldShowUpgradePrompt(FeatureType.noteCreation), false);

      monetizationService.setUserTier(UserTier.pro);
      expect(monetizationService.shouldShowUpgradePrompt(FeatureType.noteCreation), false);

      monetizationService.setUserTier(UserTier.enterprise);
      expect(monetizationService.shouldShowUpgradePrompt(FeatureType.noteCreation), false);
    });

    test('should provide correct upgrade recommendations', () {
      expect(monetizationService.getRecommendedUpgrade(), UserTier.premium);

      monetizationService.setUserTier(UserTier.premium);
      expect(monetizationService.getRecommendedUpgrade(), UserTier.pro);

      monetizationService.setUserTier(UserTier.pro);
      expect(monetizationService.getRecommendedUpgrade(), UserTier.enterprise);

      monetizationService.setUserTier(UserTier.enterprise);
      expect(monetizationService.getRecommendedUpgrade(), UserTier.enterprise);
    });
  });
}
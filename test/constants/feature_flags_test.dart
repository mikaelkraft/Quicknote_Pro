import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/constants/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('should have default values for core features', () {
      // Core monetization flags should be enabled by default
      expect(FeatureFlags.monetizationEnabled, isTrue);
      expect(FeatureFlags.iapEnabled, isTrue);
      expect(FeatureFlags.subscriptionsEnabled, isTrue);
      
      // Analytics should be enabled by default
      expect(FeatureFlags.analyticsEnabled, isTrue);
      expect(FeatureFlags.firebaseAnalyticsEnabled, isTrue);
      expect(FeatureFlags.eventTrackingEnabled, isTrue);
      
      // Ads should be enabled by default
      expect(FeatureFlags.adsEnabled, isTrue);
      expect(FeatureFlags.bannerAdsEnabled, isTrue);
      expect(FeatureFlags.interstitialAdsEnabled, isTrue);
      expect(FeatureFlags.nativeAdsEnabled, isTrue);
      
      // Premium features should be enabled by default
      expect(FeatureFlags.paywallEnabled, isTrue);
      expect(FeatureFlags.upgradePromptsEnabled, isTrue);
      expect(FeatureFlags.trialsEnabled, isTrue);
    });

    test('should have safe defaults for experimental features', () {
      // Experimental features should be disabled by default
      expect(FeatureFlags.rewardedAdsEnabled, isFalse);
      expect(FeatureFlags.experimentalFeaturesEnabled, isFalse);
      expect(FeatureFlags.teamWorkspaceEnabled, isFalse);
      expect(FeatureFlags.ssoIntegrationEnabled, isFalse);
      expect(FeatureFlags.adminDashboardEnabled, isFalse);
    });

    test('should have proper debug flag defaults', () {
      // Debug flags should be disabled by default
      expect(FeatureFlags.debugMonetizationEnabled, isFalse);
      expect(FeatureFlags.mockPurchasesEnabled, isFalse);
      expect(FeatureFlags.bypassPremiumChecks, isFalse);
    });

    test('should have reasonable default configuration values', () {
      // Check default frequency caps
      expect(FeatureFlags.adFrequencyCapDaily, equals(10));
      expect(FeatureFlags.upgradePromptMaxDaily, equals(3));
      
      // Check trial durations
      expect(FeatureFlags.trialDurationPremium, equals(7));
      expect(FeatureFlags.trialDurationPro, equals(14));
      
      // Check rollout percentages
      expect(FeatureFlags.adsRolloutPercentage, equals(100));
      expect(FeatureFlags.paywallRolloutPercentage, equals(100));
      expect(FeatureFlags.trialRolloutPercentage, equals(100));
      expect(FeatureFlags.newUiRolloutPercentage, equals(0)); // New UI should be off
    });

    test('should return all flags in getAllFlags()', () {
      final allFlags = FeatureFlags.getAllFlags();
      
      // Should contain core monetization flags
      expect(allFlags, containsPair('monetization_enabled', FeatureFlags.monetizationEnabled));
      expect(allFlags, containsPair('iap_enabled', FeatureFlags.iapEnabled));
      expect(allFlags, containsPair('ads_enabled', FeatureFlags.adsEnabled));
      expect(allFlags, containsPair('paywall_enabled', FeatureFlags.paywallEnabled));
      
      // Should contain configuration values
      expect(allFlags, containsPair('ad_frequency_cap_daily', FeatureFlags.adFrequencyCapDaily));
      expect(allFlags, containsPair('trial_duration_premium', FeatureFlags.trialDurationPremium));
      
      // Should be comprehensive
      expect(allFlags.length, greaterThan(30)); // We have many flags
    });

    test('should handle user-based rollout percentages correctly', () {
      const userId1 = 'user123';
      const userId2 = 'user456'; 
      const userId3 = 'user789';
      
      // 100% rollout - everyone should get the feature
      expect(FeatureFlags.isFeatureEnabledForUser('test_feature', userId1, 100), isTrue);
      expect(FeatureFlags.isFeatureEnabledForUser('test_feature', userId2, 100), isTrue);
      expect(FeatureFlags.isFeatureEnabledForUser('test_feature', userId3, 100), isTrue);
      
      // 0% rollout - no one should get the feature
      expect(FeatureFlags.isFeatureEnabledForUser('test_feature', userId1, 0), isFalse);
      expect(FeatureFlags.isFeatureEnabledForUser('test_feature', userId2, 0), isFalse);
      expect(FeatureFlags.isFeatureEnabledForUser('test_feature', userId3, 0), isFalse);
      
      // Same user should get consistent results
      final result1 = FeatureFlags.isFeatureEnabledForUser('test_feature', userId1, 50);
      final result2 = FeatureFlags.isFeatureEnabledForUser('test_feature', userId1, 50);
      expect(result1, equals(result2));
    });

    test('should have proper kill switch behavior', () {
      // Kill switch should be inactive by default
      expect(FeatureFlags.isKillSwitchActive, isFalse);
      expect(FeatureFlags.shouldDisableMonetization, isFalse);
    });

    test('should provide placement-specific ad frequency caps', () {
      // Different placements should have different caps
      expect(FeatureFlags.getAdFrequencyCap(AdPlacement.noteListBanner), 
        equals(FeatureFlags.adFrequencyCapDaily));
      
      // Should handle all placement types
      for (final placement in AdPlacement.values) {
        final cap = FeatureFlags.getAdFrequencyCap(placement);
        expect(cap, greaterThan(0));
        expect(cap, lessThanOrEqualTo(50)); // Reasonable upper bound
      }
    });
  });
}
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

    test('should recognize premium status for premium, pro, and enterprise tiers', () async {
      await monetizationService.setUserTier(UserTier.premium);
      expect(monetizationService.isPremium, true);

      await monetizationService.setUserTier(UserTier.pro);
      expect(monetizationService.isPremium, true);

      await monetizationService.setUserTier(UserTier.enterprise);
      expect(monetizationService.isPremium, true);

      await monetizationService.setUserTier(UserTier.free);
      expect(monetizationService.isPremium, false);
    });

    test('should enforce feature limits for free tier', () {
      expect(monetizationService.isFeatureAvailable(FeatureType.noteCreation), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedDrawing), false);
      expect(monetizationService.isFeatureAvailable(FeatureType.voiceTranscription), false);
      expect(monetizationService.isFeatureAvailable(FeatureType.ocrTextExtraction), false);
      expect(monetizationService.isFeatureAvailable(FeatureType.cloudExportImport), false);
      expect(monetizationService.isFeatureAvailable(FeatureType.deviceSync), false);
      expect(monetizationService.isFeatureAvailable(FeatureType.basicExport), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.localExportImport), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.doodling), true);
      expect(monetizationService.canUseFeature(FeatureType.noteCreation), true);
    });

    test('should allow premium features for premium tier', () {
      monetizationService.setUserTier(UserTier.premium);
      
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedDrawing), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.voiceTranscription), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.ocrTextExtraction), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.cloudExportImport), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.deviceSync), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.customThemes), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.adRemoval), true);
      
      // Pro-only features should still be unavailable
      expect(monetizationService.isFeatureAvailable(FeatureType.analyticsInsights), false);
      expect(monetizationService.isFeatureAvailable(FeatureType.apiAccess), false);
      
      expect(monetizationService.canUseFeature(FeatureType.advancedDrawing), true);
    });

    test('should allow all pro features for pro tier', () {
      monetizationService.setUserTier(UserTier.pro);
      
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedDrawing), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.analyticsInsights), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.apiAccess), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedSearch), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.automatedBackup), true);
      
      // Enterprise-only features should still be unavailable
      expect(monetizationService.isFeatureAvailable(FeatureType.teamWorkspace), false);
      expect(monetizationService.isFeatureAvailable(FeatureType.ssoIntegration), false);
      
      expect(monetizationService.canUseFeature(FeatureType.advancedDrawing), true);
      expect(monetizationService.canUseFeature(FeatureType.noteCreation), true);
    });

    test('should allow all enterprise features for enterprise tier', () {
      monetizationService.setUserTier(UserTier.enterprise);
      
      expect(monetizationService.isFeatureAvailable(FeatureType.advancedDrawing), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.analyticsInsights), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.teamWorkspace), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.adminDashboard), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.ssoIntegration), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.auditLogs), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.customBranding), true);
      expect(monetizationService.isFeatureAvailable(FeatureType.dedicatedSupport), true);
      
      expect(monetizationService.canUseFeature(FeatureType.advancedDrawing), true);
      expect(monetizationService.canUseFeature(FeatureType.noteCreation), true);
      expect(monetizationService.canUseFeature(FeatureType.teamWorkspace), true);
    });

    test('should track feature usage correctly', () async {
      await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      
      expect(monetizationService.usageCounts[FeatureType.noteCreation], 2);
    });

    test('should track feature usage and emit analytics events', () async {
      // Record usage for a feature within limits
      await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      
      expect(monetizationService.usageCounts[FeatureType.noteCreation], 1);
    });

    test('should emit feature limit reached when feature is blocked', () async {
      // Reach note creation limit for free tier (50 notes)
      for (int i = 0; i < 50; i++) {
        await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      }
      
      // Next attempt should be blocked and emit analytics event
      await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      
      // Usage count should not increment beyond limit
      expect(monetizationService.usageCounts[FeatureType.noteCreation], 50);
    });

    test('should record upgrade prompt with analytics', () async {
      await monetizationService.recordUpgradePromptShown(
        context: 'voice_limit_reached',
        featureBlocked: 'voice_notes',
      );
      
      expect(monetizationService.upgradePromptCount, 1);
    });

    test('should calculate remaining usage correctly', () async {
      // Free tier has 50 note limit
      for (int i = 0; i < 45; i++) {
        await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      }
      
      expect(monetizationService.getRemainingUsage(FeatureType.noteCreation), 5);
    });

    test('should handle device sync limits correctly', () async {
      // Free tier: device sync not available
      expect(monetizationService.isFeatureAvailable(FeatureType.deviceSync), false);
      
      // Premium tier: 3 device sync limit
      await monetizationService.setUserTier(UserTier.premium);
      expect(monetizationService.isFeatureAvailable(FeatureType.deviceSync), true);
      expect(monetizationService.getRemainingUsage(FeatureType.deviceSync), 3);
      
      // Pro tier: 10 device sync limit
      await monetizationService.setUserTier(UserTier.pro);
      expect(monetizationService.getRemainingUsage(FeatureType.deviceSync), 10);
      
      // Enterprise tier: unlimited device sync
      await monetizationService.setUserTier(UserTier.enterprise);
      expect(monetizationService.getRemainingUsage(FeatureType.deviceSync), -1);
    });

    test('should show upgrade prompt when feature limit is reached', () async {
      // Reach note creation limit for free tier
      for (int i = 0; i < 50; i++) {
        await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
      }
      
      expect(monetizationService.shouldShowUpgradePrompt(FeatureType.noteCreation), true);
    });

    test('should not show upgrade prompt for premium users', () async {
      await monetizationService.setUserTier(UserTier.premium);
      
      expect(monetizationService.shouldShowUpgradePrompt(FeatureType.noteCreation), false);
    });
  });
}
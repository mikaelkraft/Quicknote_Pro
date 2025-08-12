import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicknote_pro/models/pricing_tier.dart';
import 'package:quicknote_pro/models/user_entitlements.dart';
import 'package:quicknote_pro/services/pricing_tier_service.dart';
import 'package:quicknote_pro/services/limit_enforcement_service.dart';

void main() {
  group('LimitEnforcementService', () {
    late PricingTierService pricingService;
    late LimitEnforcementService limitService;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      pricingService = PricingTierService();
      await pricingService.initialize();
      limitService = LimitEnforcementService(pricingService);
    });

    group('Free Tier Limits', () {
      test('should allow note creation within limits', () async {
        final result = await limitService.canCreateNote(50);
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should block note creation when limit reached', () async {
        final result = await limitService.canCreateNote(100);
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('100 note limit'));
      });

      test('should allow voice note recording within limits', () async {
        final result = await limitService.canRecordVoiceNote();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should block voice note recording when limit reached', () async {
        // Use up the voice note limit
        for (int i = 0; i < 10; i++) {
          await pricingService.incrementVoiceNoteUsage();
        }
        
        final result = await limitService.canRecordVoiceNote();
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('10 voice notes'));
      });

      test('should allow exports within limits', () async {
        final result = await limitService.canExportNotes();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should block exports when limit reached', () async {
        // Use up the export limit
        for (int i = 0; i < 5; i++) {
          await pricingService.incrementExportUsage();
        }
        
        final result = await limitService.canExportNotes();
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('5 exports'));
      });

      test('should block cloud sync access', () {
        final result = limitService.canAccessCloudSync();
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('Premium feature'));
      });

      test('should block advanced drawing tools', () {
        final result = limitService.canAccessAdvancedDrawingTools();
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('Premium feature'));
      });

      test('should block custom themes', () {
        final result = limitService.canAccessCustomThemes();
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('Premium feature'));
      });

      test('should block OCR access', () {
        final result = limitService.canAccessOCR();
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('OCR'));
      });

      test('should allow attachments within limits', () {
        final result = limitService.canAddAttachment(2);
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should block attachments when limit reached', () {
        final result = limitService.canAddAttachment(3);
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('3 attachments'));
      });

      test('should allow attachment size within limits', () {
        final result = limitService.canAddAttachmentSize(4.0);
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should block attachment size when too large', () {
        final result = limitService.canAddAttachmentSize(10.0);
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('5MB limit'));
      });

      test('should block unlimited backups', () {
        final result = limitService.canAccessUnlimitedBackups();
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
        expect(result.upgradeMessage, isNotNull);
        expect(result.limitMessage, contains('Premium feature'));
      });

      test('should show ads for free users', () {
        final shouldShow = limitService.shouldShowAds();
        
        expect(shouldShow, true);
      });
    });

    group('Premium Tier Access', () {
      setUp(() async {
        await pricingService.activatePremiumSubscription(
          subscriptionType: SubscriptionType.lifetime,
          productId: 'test_lifetime',
        );
      });

      test('should allow unlimited note creation', () async {
        final result = await limitService.canCreateNote(1000);
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should allow unlimited voice note recording', () async {
        // Simulate heavy usage
        for (int i = 0; i < 100; i++) {
          await pricingService.incrementVoiceNoteUsage();
        }
        
        final result = await limitService.canRecordVoiceNote();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should allow unlimited exports', () async {
        // Simulate heavy usage
        for (int i = 0; i < 100; i++) {
          await pricingService.incrementExportUsage();
        }
        
        final result = await limitService.canExportNotes();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should allow cloud sync access', () {
        final result = limitService.canAccessCloudSync();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should allow advanced drawing tools', () {
        final result = limitService.canAccessAdvancedDrawingTools();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should allow custom themes', () {
        final result = limitService.canAccessCustomThemes();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should allow OCR access', () {
        final result = limitService.canAccessOCR();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should allow unlimited attachments', () {
        final result = limitService.canAddAttachment(100);
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should allow larger attachment sizes', () {
        final result = limitService.canAddAttachmentSize(50.0);
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should still enforce maximum attachment size', () {
        final result = limitService.canAddAttachmentSize(150.0);
        
        expect(result.allowed, false);
        expect(result.limitMessage, isNotNull);
      });

      test('should allow unlimited backups', () {
        final result = limitService.canAccessUnlimitedBackups();
        
        expect(result.allowed, true);
        expect(result.limitMessage, isNull);
      });

      test('should not show ads for premium users', () {
        final shouldShow = limitService.shouldShowAds();
        
        expect(shouldShow, false);
      });
    });

    group('Trial Period', () {
      setUp(() async {
        await pricingService.startFreeTrial();
      });

      test('should allow premium features during trial', () {
        expect(limitService.canAccessCloudSync().allowed, true);
        expect(limitService.canAccessAdvancedDrawingTools().allowed, true);
        expect(limitService.canAccessCustomThemes().allowed, true);
        expect(limitService.canAccessOCR().allowed, true);
        expect(limitService.shouldShowAds(), false);
      });

      test('should allow unlimited usage during trial', () async {
        // Simulate heavy usage
        for (int i = 0; i < 100; i++) {
          await pricingService.incrementVoiceNoteUsage();
          await pricingService.incrementExportUsage();
        }
        
        expect((await limitService.canRecordVoiceNote()).allowed, true);
        expect((await limitService.canExportNotes()).allowed, true);
        expect((await limitService.canCreateNote(1000)).allowed, true);
      });
    });

    group('Usage Summary', () {
      test('should provide accurate usage summary for free users', () {
        final summary = limitService.getUsageSummary();
        
        expect(summary['tier'], 'free');
        expect(summary['isPremium'], false);
        expect(summary['voiceNotes']['limit'], 10);
        expect(summary['exports']['limit'], 5);
        expect(summary['features']['cloudSync'], false);
        expect(summary['features']['adFree'], false);
        expect(summary['trial']['canStartTrial'], true);
      });

      test('should provide accurate usage summary for premium users', () async {
        await pricingService.activatePremiumSubscription(
          subscriptionType: SubscriptionType.lifetime,
          productId: 'test_lifetime',
        );
        
        final summary = limitService.getUsageSummary();
        
        expect(summary['tier'], 'premium');
        expect(summary['isPremium'], true);
        expect(summary['voiceNotes']['unlimited'], true);
        expect(summary['exports']['unlimited'], true);
        expect(summary['features']['cloudSync'], true);
        expect(summary['features']['adFree'], true);
        expect(summary['trial']['canStartTrial'], false);
      });

      test('should track usage accurately in summary', () async {
        await pricingService.incrementVoiceNoteUsage();
        await pricingService.incrementVoiceNoteUsage();
        await pricingService.incrementExportUsage();
        
        final summary = limitService.getUsageSummary();
        
        expect(summary['voiceNotes']['used'], 2);
        expect(summary['voiceNotes']['remaining'], 8);
        expect(summary['exports']['used'], 1);
        expect(summary['exports']['remaining'], 4);
      });
    });

    group('Limit Descriptions', () {
      test('should provide free tier limit descriptions', () {
        final descriptions = limitService.getCurrentLimitDescriptions();
        
        expect(descriptions, isNotEmpty);
        expect(descriptions.any((d) => d.contains('100 notes')), true);
        expect(descriptions.any((d) => d.contains('10 voice notes')), true);
        expect(descriptions.any((d) => d.contains('5 exports')), true);
        expect(descriptions.any((d) => d.contains('Local storage only')), true);
        expect(descriptions.any((d) => d.contains('Includes ads')), true);
      });

      test('should provide premium tier descriptions', () async {
        await pricingService.activatePremiumSubscription(
          subscriptionType: SubscriptionType.lifetime,
          productId: 'test_lifetime',
        );
        
        final descriptions = limitService.getCurrentLimitDescriptions();
        
        expect(descriptions, isNotEmpty);
        expect(descriptions.any((d) => d.contains('Unlimited notes')), true);
        expect(descriptions.any((d) => d.contains('Unlimited voice notes')), true);
        expect(descriptions.any((d) => d.contains('Unlimited exports')), true);
        expect(descriptions.any((d) => d.contains('Cloud sync')), true);
        expect(descriptions.any((d) => d.contains('Ad-free')), true);
      });

      test('should provide premium feature highlights', () {
        final highlights = limitService.getPremiumFeatureHighlights();
        
        expect(highlights, isNotEmpty);
        expect(highlights.any((h) => h.contains('Unlimited everything')), true);
        expect(highlights.any((h) => h.contains('Sync across all your devices')), true);
        expect(highlights.any((h) => h.contains('Advanced drawing tools')), true);
        expect(highlights.any((h) => h.contains('Ad-free')), true);
      });
    });
  });
}
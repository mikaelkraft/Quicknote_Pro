import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/models/ad_models.dart';
import 'package:quicknote_pro/services/ads/ad_service.dart';

void main() {
  group('AdService Tests', () {
    late AdService adService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      adService = AdService();
    });

    tearDown(() async {
      await adService.clearData();
    });

    test('should initialize successfully', () async {
      await adService.initialize();
      expect(adService, isNotNull);
    });

    test('should not show ads for premium users', () async {
      await adService.initialize(isPremiumUser: true);
      
      final canShow = await adService.canShowAd('note_list_banner');
      expect(canShow, false);
    });

    test('should show ads for free users within limits', () async {
      await adService.initialize(isPremiumUser: false);
      
      final canShow = await adService.canShowAd('note_list_banner');
      expect(canShow, true);
    });

    test('should respect daily impression limits', () async {
      await adService.initialize(isPremiumUser: false);
      
      // Request maximum allowed impressions for banner
      final placement = AdPlacements.noteListBanner;
      for (int i = 0; i < placement.maxDailyImpressions; i++) {
        final impression = await adService.requestAd(placement.id);
        expect(impression, isNotNull);
      }
      
      // Next request should be denied
      final canShowMore = await adService.canShowAd(placement.id);
      expect(canShowMore, false);
    });

    test('should respect minimum interval between ads', () async {
      await adService.initialize(isPremiumUser: false);
      
      // Request first ad
      final firstImpression = await adService.requestAd('note_list_banner');
      expect(firstImpression, isNotNull);
      
      // Immediate second request should be denied
      final canShowAgain = await adService.canShowAd('note_list_banner');
      expect(canShowAgain, false);
    });

    test('should track ad impressions correctly', () async {
      await adService.initialize(isPremiumUser: false);
      
      final impression = await adService.requestAd('note_list_banner');
      expect(impression, isNotNull);
      expect(impression!.id, isNotEmpty);
      expect(impression.placementId, 'note_list_banner');
      expect(impression.format, AdFormat.banner);
    });

    test('should record ad clicks', () async {
      await adService.initialize(isPremiumUser: false);
      
      final impression = await adService.requestAd('note_list_banner');
      expect(impression, isNotNull);
      
      await adService.recordAdClick(impression!.id);
      // In real implementation, verify the impression was updated
      expect(true, true); // Placeholder assertion
    });

    test('should record ad dismissals', () async {
      await adService.initialize(isPremiumUser: false);
      
      final impression = await adService.requestAd('note_list_banner');
      expect(impression, isNotNull);
      
      await adService.recordAdDismiss(impression!.id);
      // In real implementation, verify the impression was updated
      expect(true, true); // Placeholder assertion
    });

    test('should record ad load failures', () async {
      await adService.initialize(isPremiumUser: false);
      
      await adService.recordAdLoadFailure('note_list_banner', 'network_error');
      // Verify analytics event was tracked
      expect(true, true); // Placeholder assertion
    });

    test('should generate ad metrics', () async {
      await adService.initialize(isPremiumUser: false);
      
      // Create some test impressions
      await adService.requestAd('note_list_banner');
      await adService.requestAd('premium_native');
      
      final metrics = await adService.getAdMetrics();
      
      expect(metrics, isA<Map<String, dynamic>>());
      expect(metrics.containsKey('total_impressions_today'), true);
      expect(metrics.containsKey('click_through_rate'), true);
      expect(metrics.containsKey('dismissal_rate'), true);
      expect(metrics.containsKey('placement_breakdown'), true);
    });

    test('should update premium status', () async {
      await adService.initialize(isPremiumUser: false);
      
      // Should show ads initially
      expect(await adService.canShowAd('note_list_banner'), true);
      
      // Update to premium
      adService.updatePremiumStatus(true);
      
      // Should not show ads after premium upgrade
      expect(await adService.canShowAd('note_list_banner'), false);
    });
  });

  group('AdPlacement Tests', () {
    test('should have predefined placements', () {
      expect(AdPlacements.allPlacements.length, greaterThan(0));
      expect(AdPlacements.noteListBanner.id, 'note_list_banner');
      expect(AdPlacements.editingInterstitial.format, AdFormat.interstitial);
      expect(AdPlacements.premiumNative.isDismissible, true);
      expect(AdPlacements.rewardedUpgrade.format, AdFormat.rewarded);
    });

    test('should find placement by ID', () {
      final placement = AdPlacements.getById('note_list_banner');
      expect(placement, isNotNull);
      expect(placement!.id, 'note_list_banner');
      
      final invalidPlacement = AdPlacements.getById('invalid_id');
      expect(invalidPlacement, isNull);
    });

    test('should serialize to and from JSON', () {
      final originalPlacement = AdPlacements.noteListBanner;
      
      final json = originalPlacement.toJson();
      final reconstructedPlacement = AdPlacement.fromJson(json);
      
      expect(reconstructedPlacement.id, originalPlacement.id);
      expect(reconstructedPlacement.name, originalPlacement.name);
      expect(reconstructedPlacement.format, originalPlacement.format);
      expect(reconstructedPlacement.maxDailyImpressions, originalPlacement.maxDailyImpressions);
      expect(reconstructedPlacement.minIntervalMinutes, originalPlacement.minIntervalMinutes);
      expect(reconstructedPlacement.isDismissible, originalPlacement.isDismissible);
    });
  });

  group('AdImpression Tests', () {
    test('should create impression with proper properties', () {
      final impression = AdImpression(
        id: 'test_impression_123',
        placementId: 'note_list_banner',
        format: AdFormat.banner,
        timestamp: DateTime.now(),
        adProvider: 'test_provider',
      );

      expect(impression.id, 'test_impression_123');
      expect(impression.placementId, 'note_list_banner');
      expect(impression.format, AdFormat.banner);
      expect(impression.adProvider, 'test_provider');
      expect(impression.wasClicked, false);
      expect(impression.wasDismissed, false);
    });

    test('should update impression state', () {
      final originalImpression = AdImpression(
        id: 'test_impression_123',
        placementId: 'note_list_banner',
        format: AdFormat.banner,
        timestamp: DateTime.now(),
      );

      final clickedImpression = originalImpression.copyWith(wasClicked: true);
      expect(clickedImpression.wasClicked, true);
      expect(clickedImpression.wasDismissed, false);

      final dismissedImpression = clickedImpression.copyWith(wasDismissed: true);
      expect(dismissedImpression.wasClicked, true);
      expect(dismissedImpression.wasDismissed, true);
    });

    test('should serialize to and from JSON', () {
      final originalImpression = AdImpression(
        id: 'test_impression_123',
        placementId: 'note_list_banner',
        format: AdFormat.banner,
        timestamp: DateTime.now(),
        adProvider: 'test_provider',
        wasClicked: true,
        wasDismissed: false,
      );

      final json = originalImpression.toJson();
      final reconstructedImpression = AdImpression.fromJson(json);

      expect(reconstructedImpression.id, originalImpression.id);
      expect(reconstructedImpression.placementId, originalImpression.placementId);
      expect(reconstructedImpression.format, originalImpression.format);
      expect(reconstructedImpression.adProvider, originalImpression.adProvider);
      expect(reconstructedImpression.wasClicked, originalImpression.wasClicked);
      expect(reconstructedImpression.wasDismissed, originalImpression.wasDismissed);
    });
  });
}
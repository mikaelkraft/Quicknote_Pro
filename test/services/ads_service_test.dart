import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/ads/ads_service.dart';

void main() {
  group('AdsService', () {
    late AdsService adsService;

    setUp(() {
      adsService = AdsService();
    });

    test('should initialize with ads enabled by default', () {
      expect(adsService.adsEnabled, true);
    });

    test('should disable ads for premium users', () {
      adsService.setPremiumStatus(true);
      expect(adsService.adsEnabled, false);
    });

    test('should allow ads when not premium and ads enabled', () {
      adsService.setPremiumStatus(false);
      adsService.setAdsEnabled(true);
      expect(adsService.adsEnabled, true);
    });

    test('should check frequency caps correctly', () {
      expect(adsService.canShowAd(AdPlacement.noteListBanner), true);
    });

    test('should return proper ad configuration for placements', () {
      final config = AdConfig.forPlacement(AdPlacement.noteListBanner);
      expect(config.format, AdFormat.banner);
      expect(config.dailyLimit, 20);
      expect(config.minIntervalSeconds, 300);
    });

    test('should handle different ad placements', () {
      final bannerConfig = AdConfig.forPlacement(AdPlacement.noteListBanner);
      final interstitialConfig = AdConfig.forPlacement(AdPlacement.noteCreationInterstitial);
      
      expect(bannerConfig.format, AdFormat.banner);
      expect(interstitialConfig.format, AdFormat.interstitial);
      expect(interstitialConfig.dailyLimit, 3);
    });

    test('should provide ad statistics', () {
      final stats = adsService.getAdStatistics();
      expect(stats['ads_enabled'], true);
      expect(stats['is_premium'], false);
      expect(stats['ad_counts'], isA<Map>());
    });
  });

  group('AdResult', () {
    test('should create success result correctly', () {
      final result = AdResult.success(AdPlacement.noteListBanner, AdFormat.banner);
      expect(result.isSuccess, true);
      expect(result.isBlocked, false);
      expect(result.isError, false);
      expect(result.format, AdFormat.banner);
    });

    test('should create blocked result correctly', () {
      final result = AdResult.blocked(AdPlacement.noteListBanner, 'Frequency cap');
      expect(result.isBlocked, true);
      expect(result.isSuccess, false);
      expect(result.message, 'Frequency cap');
    });
  });
}
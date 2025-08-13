import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/analytics/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    test('should initialize with analytics enabled by default', () {
      expect(analyticsService.analyticsEnabled, true);
    });

    test('should track events when analytics is enabled', () {
      final event = AnalyticsEvent.appStarted();
      analyticsService.trackEvent(event);
      
      expect(analyticsService.eventCounts['app_started'], 1);
      expect(analyticsService.getEventQueue().length, 1);
    });

    test('should not track events when analytics is disabled', () {
      analyticsService.setAnalyticsEnabled(false);
      
      final event = AnalyticsEvent.appStarted();
      analyticsService.trackEvent(event);
      
      expect(analyticsService.eventCounts['app_started'], null);
      expect(analyticsService.getEventQueue().length, 0);
    });

    test('should track monetization events correctly', () {
      final event = MonetizationEvent.upgradePromptShown(context: 'test');
      analyticsService.trackMonetizationEvent(event);
      
      expect(analyticsService.eventCounts['monetization_upgrade_prompt_shown'], 1);
    });

    test('should track engagement events correctly', () {
      final event = EngagementEvent.noteCreated();
      analyticsService.trackEngagementEvent(event);
      
      expect(analyticsService.eventCounts['engagement_note_created'], 1);
    });

    test('should track feature events correctly', () {
      final event = FeatureEvent.voiceNote('started');
      analyticsService.trackFeatureEvent(event);
      
      expect(analyticsService.eventCounts['feature_voice_note_started'], 1);
    });
  });
}
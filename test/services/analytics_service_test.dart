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

    test('should operate in safe no-op mode without Firebase', () {
      // Should not throw errors even without Firebase configuration
      expect(analyticsService.firebaseInitialized, false);
      expect(() => analyticsService.logEvent('test_event', {}), returnsNormally);
      expect(() => analyticsService.setUserId('test_user'), returnsNormally);
      expect(() => analyticsService.setUserProperty('test_prop', 'value'), returnsNormally);
      expect(() => analyticsService.logScreenView('test_screen'), returnsNormally);
    });

    test('should track events when analytics is enabled', () {
      final event = AnalyticsEvent.appStarted();
      analyticsService.trackEvent(event);
      
      expect(analyticsService.eventCounts['app_started'], 1);
      expect(analyticsService.getEventQueue().length, 1);
    });

    test('should not track events when analytics is disabled', () async {
      await analyticsService.setAnalyticsEnabled(false);
      
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

    test('should handle Firebase method calls safely without initialization', () async {
      // These should not throw errors even without Firebase
      await analyticsService.setUserId('test_user_123');
      await analyticsService.setUserProperty('premium_user', 'true');
      await analyticsService.logScreenView('home_screen', screenClass: 'MainActivity');
      await analyticsService.logEvent('custom_event', {'param1': 'value1'});
      
      // Should complete without errors
      expect(true, true);
    });
  });
}
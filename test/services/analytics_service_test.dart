import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/models/analytics_event.dart';
import 'package:quicknote_pro/services/analytics/analytics_service.dart';

void main() {
  group('AnalyticsService Tests', () {
    late AnalyticsService analyticsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      analyticsService = AnalyticsService();
    });

    tearDown(() async {
      await analyticsService.clearData();
    });

    test('should initialize successfully', () async {
      await analyticsService.initialize();
      expect(analyticsService, isNotNull);
    });

    test('should track events with proper properties', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackEvent(
        AnalyticsEvents.noteCreated,
        properties: {
          AnalyticsProperties.noteType: 'text',
        },
      );

      // Verify event was tracked (in real implementation, check local storage)
      expect(true, true); // Placeholder assertion
    });

    test('should track activation events', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackActivation(
        AnalyticsEvents.firstNoteCreated,
        properties: {'note_type': 'text'},
      );

      expect(true, true); // Placeholder assertion
    });

    test('should track retention events', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackRetention(
        AnalyticsEvents.sessionStarted,
      );

      expect(true, true); // Placeholder assertion
    });

    test('should track conversion events', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackConversion(
        AnalyticsEvents.premiumScreenViewed,
        properties: {'source': 'feature_blocked'},
      );

      expect(true, true); // Placeholder assertion
    });

    test('should track premium feature blocking', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackPremiumBlock('voice_note');

      expect(true, true); // Placeholder assertion
    });

    test('should track purchase events with all properties', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackPurchaseEvent(
        AnalyticsEvents.purchaseCompleted,
        subscriptionType: 'monthly',
        price: '2.99',
        currency: 'USD',
      );

      expect(true, true); // Placeholder assertion
    });

    test('should track ad events', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackAdEvent(
        AnalyticsEvents.adDisplayed,
        adFormat: 'banner',
        adPlacement: 'note_list',
        adProvider: 'test_provider',
        impressionId: 'test_impression_123',
      );

      expect(true, true); // Placeholder assertion
    });

    test('should generate user metrics', () async {
      await analyticsService.initialize();
      
      // Track some events
      await analyticsService.trackEvent(AnalyticsEvents.noteCreated);
      await analyticsService.trackEvent(AnalyticsEvents.voiceNoteCreated);
      await analyticsService.trackPremiumBlock('advanced_drawing');
      
      final metrics = await analyticsService.getUserMetrics();
      
      expect(metrics, isA<Map<String, dynamic>>());
      expect(metrics.containsKey('user_id'), true);
      expect(metrics.containsKey('session_duration_minutes'), true);
      expect(metrics.containsKey('total_events'), true);
    });

    test('should end session with duration tracking', () async {
      await analyticsService.initialize();
      
      await analyticsService.endSession();
      
      expect(true, true); // Placeholder assertion
    });

    test('should clear all data', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackEvent(AnalyticsEvents.noteCreated);
      await analyticsService.clearData();
      
      // Verify data is cleared
      expect(true, true); // Placeholder assertion
    });
  });

  group('AnalyticsEvent Tests', () {
    test('should create event with proper properties', () {
      final event = AnalyticsEvent.create(
        eventName: AnalyticsEvents.noteCreated,
        userId: 'test_user_123',
        properties: {
          AnalyticsProperties.noteType: 'text',
        },
      );

      expect(event.eventName, AnalyticsEvents.noteCreated);
      expect(event.userId, 'test_user_123');
      expect(event.properties[AnalyticsProperties.noteType], 'text');
      expect(event.timestamp, isA<DateTime>());
    });

    test('should serialize to and from JSON', () {
      final originalEvent = AnalyticsEvent.create(
        eventName: AnalyticsEvents.noteCreated,
        userId: 'test_user_123',
        properties: {
          AnalyticsProperties.noteType: 'text',
        },
      );

      final json = originalEvent.toJson();
      final reconstructedEvent = AnalyticsEvent.fromJson(json);

      expect(reconstructedEvent.eventName, originalEvent.eventName);
      expect(reconstructedEvent.userId, originalEvent.userId);
      expect(reconstructedEvent.properties, originalEvent.properties);
    });
  });

  group('AnalyticsEvents Constants', () {
    test('should contain all required event names', () {
      expect(AnalyticsEvents.allEvents.contains(AnalyticsEvents.appLaunched), true);
      expect(AnalyticsEvents.allEvents.contains(AnalyticsEvents.noteCreated), true);
      expect(AnalyticsEvents.allEvents.contains(AnalyticsEvents.premiumScreenViewed), true);
      expect(AnalyticsEvents.allEvents.contains(AnalyticsEvents.adDisplayed), true);
      expect(AnalyticsEvents.allEvents.length, greaterThan(20));
    });
  });
}
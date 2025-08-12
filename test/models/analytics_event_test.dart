import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/analytics_event.dart';
import 'package:quicknote_pro/models/analytics_event_type.dart';

void main() {
  group('AnalyticsEvent', () {
    test('should create event with all required properties', () {
      // Arrange
      final timestamp = DateTime.now();
      const sessionId = 'test_session_123';
      
      // Act
      final event = AnalyticsEvent(
        eventId: 'test_event_123',
        eventType: 'note_created',
        category: 'feature',
        action: 'note_created',
        timestamp: timestamp,
        sessionId: sessionId,
        userConsent: true,
      );
      
      // Assert
      expect(event.eventId, equals('test_event_123'));
      expect(event.eventType, equals('note_created'));
      expect(event.category, equals('feature'));
      expect(event.action, equals('note_created'));
      expect(event.timestamp, equals(timestamp));
      expect(event.sessionId, equals(sessionId));
      expect(event.userConsent, isTrue);
    });

    test('should create event with factory method', () {
      // Act
      final event = AnalyticsEvent.create(
        eventType: 'premium_purchase_started',
        category: 'monetization',
        action: 'premium_purchase_started',
        sessionId: 'test_session',
        userConsent: true,
        entryPoint: 'paywall',
        value: 5.0,
        properties: {'product_id': 'premium_monthly'},
      );
      
      // Assert
      expect(event.eventId.startsWith('event_'), isTrue);
      expect(event.eventType, equals('premium_purchase_started'));
      expect(event.category, equals('monetization'));
      expect(event.entryPoint, equals('paywall'));
      expect(event.value, equals(5.0));
      expect(event.properties['product_id'], equals('premium_monthly'));
      expect(event.shouldTrack, isTrue);
    });

    test('should serialize to and from JSON correctly', () {
      // Arrange
      final originalEvent = AnalyticsEvent.create(
        eventType: 'theme_changed',
        category: 'theme',
        action: 'theme_changed',
        sessionId: 'test_session',
        userConsent: true,
        entryPoint: 'settings',
        method: 'tap',
        properties: {'theme_mode': 'dark'},
      );
      
      // Act
      final json = originalEvent.toJson();
      final deserializedEvent = AnalyticsEvent.fromJson(json);
      
      // Assert
      expect(deserializedEvent.eventId, equals(originalEvent.eventId));
      expect(deserializedEvent.eventType, equals(originalEvent.eventType));
      expect(deserializedEvent.category, equals(originalEvent.category));
      expect(deserializedEvent.entryPoint, equals(originalEvent.entryPoint));
      expect(deserializedEvent.method, equals(originalEvent.method));
      expect(deserializedEvent.properties['theme_mode'], equals('dark'));
    });

    test('should create privacy-safe version', () {
      // Arrange
      final event = AnalyticsEvent.create(
        eventType: 'user_action',
        category: 'usage',
        action: 'user_action',
        sessionId: 'test_session',
        userConsent: true,
        properties: {
          'safe_property': 'value',
          'user_email': 'user@example.com',
          'user_name': 'John Doe',
          'phone_number': '123-456-7890',
          'address': '123 Main St',
          'feature_used': 'notes',
        },
      );
      
      // Act
      final privacySafeEvent = event.privacySafe;
      
      // Assert
      expect(privacySafeEvent.properties.containsKey('safe_property'), isTrue);
      expect(privacySafeEvent.properties.containsKey('feature_used'), isTrue);
      expect(privacySafeEvent.properties.containsKey('user_email'), isFalse);
      expect(privacySafeEvent.properties.containsKey('user_name'), isFalse);
      expect(privacySafeEvent.properties.containsKey('phone_number'), isFalse);
      expect(privacySafeEvent.properties.containsKey('address'), isFalse);
    });

    test('should identify monetization events correctly', () {
      // Arrange
      final monetizationEvent = AnalyticsEvent.create(
        eventType: 'premium_purchase_completed',
        category: 'monetization',
        action: 'premium_purchase_completed',
        sessionId: 'test_session',
        userConsent: true,
      );
      
      final usageEvent = AnalyticsEvent.create(
        eventType: 'note_created',
        category: 'feature',
        action: 'note_created',
        sessionId: 'test_session',
        userConsent: true,
      );
      
      // Assert
      expect(monetizationEvent.isMonetizationEvent, isTrue);
      expect(usageEvent.isMonetizationEvent, isFalse);
      expect(monetizationEvent.priority, equals(3));
      expect(usageEvent.priority, equals(1));
    });

    test('should handle copyWith correctly', () {
      // Arrange
      final originalEvent = AnalyticsEvent.create(
        eventType: 'test_event',
        category: 'test',
        action: 'test_action',
        sessionId: 'test_session',
        userConsent: true,
        value: 10.0,
      );
      
      // Act
      final updatedEvent = originalEvent.copyWith(
        value: 20.0,
        conversion: true,
      );
      
      // Assert
      expect(updatedEvent.eventId, equals(originalEvent.eventId));
      expect(updatedEvent.value, equals(20.0));
      expect(updatedEvent.conversion, isTrue);
      expect(updatedEvent.category, equals(originalEvent.category));
    });

    test('should handle equality correctly', () {
      // Arrange
      final event1 = AnalyticsEvent.create(
        eventType: 'test_event',
        category: 'test',
        action: 'test_action',
        sessionId: 'test_session',
        userConsent: true,
      );
      
      final event2 = event1.copyWith(value: 10.0);
      final event3 = AnalyticsEvent.create(
        eventType: 'test_event',
        category: 'test',
        action: 'test_action',
        sessionId: 'test_session',
        userConsent: true,
      );
      
      // Assert
      expect(event1, equals(event2)); // Same event ID
      expect(event1, isNot(equals(event3))); // Different event ID
      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('should not track events without user consent', () {
      // Arrange
      final event = AnalyticsEvent.create(
        eventType: 'test_event',
        category: 'test',
        action: 'test_action',
        sessionId: 'test_session',
        userConsent: false,
      );
      
      // Assert
      expect(event.shouldTrack, isFalse);
    });

    test('should handle error events with proper priority', () {
      // Arrange
      final errorEvent = AnalyticsEvent.create(
        eventType: 'app_error',
        category: 'error',
        action: 'app_error',
        sessionId: 'test_session',
        userConsent: true,
        errorCode: 'network_error',
      );
      
      // Assert
      expect(errorEvent.priority, equals(2));
      expect(errorEvent.errorCode, equals('network_error'));
    });
  });
}
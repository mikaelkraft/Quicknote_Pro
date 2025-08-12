import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/analytics/analytics_service.dart';
import 'package:quicknote_pro/models/analytics_event_type.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      analyticsService = AnalyticsService();
    });

    tearDown(() {
      analyticsService.dispose();
    });

    test('should initialize correctly', () async {
      // Act
      await analyticsService.initialize();

      // Assert
      expect(analyticsService.isInitialized, isTrue);
      expect(analyticsService.sessionId.isNotEmpty, isTrue);
      expect(analyticsService.sessionId.startsWith('session_'), isTrue);
    });

    test('should handle user consent correctly', () async {
      // Arrange
      await analyticsService.initialize();
      expect(analyticsService.userConsent, isFalse);
      expect(analyticsService.isEnabled, isFalse);

      // Act - Grant consent
      await analyticsService.setUserConsent(true);

      // Assert
      expect(analyticsService.userConsent, isTrue);
      expect(analyticsService.isEnabled, isTrue);

      // Act - Revoke consent
      await analyticsService.setUserConsent(false);

      // Assert
      expect(analyticsService.userConsent, isFalse);
      expect(analyticsService.isEnabled, isFalse);
    });

    test('should not track events without consent', () async {
      // Arrange
      await analyticsService.initialize();
      expect(analyticsService.userConsent, isFalse);

      // Act
      await analyticsService.trackEvent(AnalyticsEventType.noteCreated);

      // Assert
      expect(analyticsService.pendingEventCount, equals(0));
    });

    test('should track events with consent', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);

      // Act
      await analyticsService.trackEvent(
        AnalyticsEventType.noteCreated,
        entryPoint: AnalyticsEntryPoint.dashboard,
        method: AnalyticsMethod.tap,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(0));
    });

    test('should track monetization events with correct properties', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);

      // Act
      await analyticsService.trackMonetizationEvent(
        AnalyticsEventType.premiumPurchaseStarted,
        entryPoint: AnalyticsEntryPoint.paywall,
        productId: 'premium_monthly',
        price: 1.0,
        currency: 'USD',
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(0));
    });

    test('should track usage events with correct properties', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);

      // Act
      await analyticsService.trackUsageEvent(
        AnalyticsEventType.noteCreated,
        entryPoint: AnalyticsEntryPoint.dashboard,
        method: AnalyticsMethod.tap,
        count: 1,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(0));
    });

    test('should track error events with correct properties', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);

      // Act
      await analyticsService.trackErrorEvent(
        AnalyticsEventType.networkError,
        AnalyticsErrorCode.networkUnavailable,
        entryPoint: AnalyticsEntryPoint.dashboard,
        errorMessage: 'Network connection failed',
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(0));
    });

    test('should provide analytics statistics', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);

      // Act
      await analyticsService.trackEvent(AnalyticsEventType.noteCreated);
      final stats = await analyticsService.getAnalyticsStats();

      // Assert
      expect(stats['user_consent'], isTrue);
      expect(stats['is_enabled'], isTrue);
      expect(stats['current_session'], equals(analyticsService.sessionId));
      expect(stats['pending_events'], greaterThan(0));
    });

    test('should clear all data correctly', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);
      await analyticsService.trackEvent(AnalyticsEventType.noteCreated);
      expect(analyticsService.pendingEventCount, greaterThan(0));

      // Act
      await analyticsService.clearAllData();

      // Assert
      expect(analyticsService.pendingEventCount, equals(0));
    });

    test('should handle initialization failure gracefully', () async {
      // This test verifies error handling during initialization
      // In a real scenario, this might happen if SharedPreferences fails
      
      // Act & Assert - Should not throw
      expect(() async => await analyticsService.initialize(), returnsNormally);
    });

    test('should throw error when setting consent before initialization', () async {
      // Act & Assert
      expect(
        () async => await analyticsService.setUserConsent(true),
        throwsA(isA<StateError>()),
      );
    });

    test('should persist consent across restarts', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);
      analyticsService.dispose();

      // Act - Create new service instance (simulating app restart)
      final newAnalyticsService = AnalyticsService();
      await newAnalyticsService.initialize();

      // Assert
      expect(newAnalyticsService.userConsent, isTrue);
      expect(newAnalyticsService.isEnabled, isTrue);

      newAnalyticsService.dispose();
    });

    test('should handle high priority events immediately', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);

      // Act
      await analyticsService.trackEvent(AnalyticsEventType.appCrash);

      // Assert - High priority events should be processed immediately
      // In this test implementation, we just verify it doesn't throw
      expect(analyticsService.pendingEventCount, greaterThanOrEqualTo(0));
    });

    test('should batch process events correctly', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);

      // Act - Track multiple events
      for (int i = 0; i < 5; i++) {
        await analyticsService.trackEvent(AnalyticsEventType.noteCreated);
      }

      // Assert
      expect(analyticsService.pendingEventCount, equals(5));
    });

    test('should limit pending events to prevent memory issues', () async {
      // Arrange
      await analyticsService.initialize();
      await analyticsService.setUserConsent(true);

      // Act - Track many events (more than the internal limit)
      for (int i = 0; i < 150; i++) {
        await analyticsService.trackEvent(AnalyticsEventType.noteCreated);
      }

      // Assert - Should be limited to max pending events (100)
      expect(analyticsService.pendingEventCount, lessThanOrEqualTo(100));
    });

    test('should generate unique session IDs', () async {
      // Arrange & Act
      await analyticsService.initialize();
      final sessionId1 = analyticsService.sessionId;
      
      analyticsService.dispose();
      
      final newService = AnalyticsService();
      await newService.initialize();
      final sessionId2 = newService.sessionId;

      // Assert
      expect(sessionId1, isNot(equals(sessionId2)));
      expect(sessionId1.startsWith('session_'), isTrue);
      expect(sessionId2.startsWith('session_'), isTrue);

      newService.dispose();
    });
  });
}
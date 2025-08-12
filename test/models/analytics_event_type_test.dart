import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/analytics_event_type.dart';

void main() {
  group('AnalyticsEventType', () {
    test('should have correct category for monetization events', () {
      // Arrange & Act
      final monetizationEvents = [
        AnalyticsEventType.premiumPurchaseStarted,
        AnalyticsEventType.premiumPurchaseCompleted,
        AnalyticsEventType.paywallShown,
        AnalyticsEventType.freeLimitReached,
      ];
      
      // Assert
      for (final event in monetizationEvents) {
        expect(event.category, equals('monetization'));
        expect(event.isMonetizationEvent, isTrue);
        expect(event.isUsageEvent, isFalse);
      }
    });

    test('should have correct category for advertising events', () {
      // Arrange & Act
      final adEvents = [
        AnalyticsEventType.adRequested,
        AnalyticsEventType.adLoaded,
        AnalyticsEventType.adShown,
        AnalyticsEventType.adClicked,
      ];
      
      // Assert
      for (final event in adEvents) {
        expect(event.category, equals('advertising'));
      }
    });

    test('should have correct category for theme events', () {
      // Arrange & Act
      final themeEvents = [
        AnalyticsEventType.themeChanged,
        AnalyticsEventType.accentColorChanged,
        AnalyticsEventType.premiumThemeAccessed,
        AnalyticsEventType.themeSettingsViewed,
      ];
      
      // Assert
      for (final event in themeEvents) {
        expect(event.category, equals('theme'));
      }
    });

    test('should have correct category for feature events', () {
      // Arrange & Act
      final featureEvents = [
        AnalyticsEventType.noteCreated,
        AnalyticsEventType.noteEdited,
        AnalyticsEventType.voiceNoteRecorded,
        AnalyticsEventType.ocrUsed,
        AnalyticsEventType.cloudSyncPerformed,
      ];
      
      // Assert
      for (final event in featureEvents) {
        expect(event.category, equals('feature'));
        expect(event.isUsageEvent, isTrue);
      }
    });

    test('should have correct category for navigation events', () {
      // Arrange & Act
      final navigationEvents = [
        AnalyticsEventType.appLaunched,
        AnalyticsEventType.settingsAccessed,
        AnalyticsEventType.onboardingStarted,
        AnalyticsEventType.helpAccessed,
      ];
      
      // Assert
      for (final event in navigationEvents) {
        expect(event.category, equals('navigation'));
        expect(event.isUsageEvent, isTrue);
      }
    });

    test('should have correct category for error events', () {
      // Arrange & Act
      final errorEvents = [
        AnalyticsEventType.appError,
        AnalyticsEventType.networkError,
        AnalyticsEventType.storageError,
        AnalyticsEventType.appCrash,
      ];
      
      // Assert
      for (final event in errorEvents) {
        expect(event.category, equals('error'));
        expect(event.isErrorEvent, isTrue);
      }
    });

    test('should have correct category for engagement events', () {
      // Arrange & Act
      final engagementEvents = [
        AnalyticsEventType.sessionStarted,
        AnalyticsEventType.sessionEnded,
        AnalyticsEventType.dailyActive,
        AnalyticsEventType.userRetention,
      ];
      
      // Assert
      for (final event in engagementEvents) {
        expect(event.category, equals('engagement'));
      }
    });

    test('should identify high priority events correctly', () {
      // Arrange & Act
      final highPriorityEvents = [
        AnalyticsEventType.premiumPurchaseCompleted,
        AnalyticsEventType.appCrash,
        AnalyticsEventType.freeLimitReached,
        AnalyticsEventType.networkError,
      ];
      
      final lowPriorityEvents = [
        AnalyticsEventType.noteCreated,
        AnalyticsEventType.themeChanged,
        AnalyticsEventType.settingsAccessed,
      ];
      
      // Assert
      for (final event in highPriorityEvents) {
        expect(event.isHighPriority, isTrue, reason: '${event.value} should be high priority');
      }
      
      for (final event in lowPriorityEvents) {
        expect(event.isHighPriority, isFalse, reason: '${event.value} should not be high priority');
      }
    });

    test('should return correct string values', () {
      // Assert
      expect(AnalyticsEventType.premiumPurchaseStarted.value, equals('premium_purchase_started'));
      expect(AnalyticsEventType.noteCreated.value, equals('note_created'));
      expect(AnalyticsEventType.themeChanged.value, equals('theme_changed'));
      expect(AnalyticsEventType.appError.value, equals('app_error'));
    });

    test('should provide correct categorized event lists', () {
      // Act
      final monetizationEvents = AnalyticsEventType.monetizationEvents;
      final usageEvents = AnalyticsEventType.usageEvents;
      final errorEvents = AnalyticsEventType.errorEvents;
      final highPriorityEvents = AnalyticsEventType.highPriorityEvents;
      
      // Assert
      expect(monetizationEvents.isNotEmpty, isTrue);
      expect(usageEvents.isNotEmpty, isTrue);
      expect(errorEvents.isNotEmpty, isTrue);
      expect(highPriorityEvents.isNotEmpty, isTrue);
      
      // Verify all monetization events are actually monetization events
      for (final event in monetizationEvents) {
        expect(event.isMonetizationEvent, isTrue);
      }
      
      // Verify all usage events are actually usage events
      for (final event in usageEvents) {
        expect(event.isUsageEvent, isTrue);
      }
      
      // Verify all error events are actually error events
      for (final event in errorEvents) {
        expect(event.isErrorEvent, isTrue);
      }
      
      // Verify all high priority events are actually high priority
      for (final event in highPriorityEvents) {
        expect(event.isHighPriority, isTrue);
      }
    });

    test('should handle toString correctly', () {
      // Assert
      expect(AnalyticsEventType.premiumPurchaseStarted.toString(), equals('premium_purchase_started'));
      expect(AnalyticsEventType.noteCreated.toString(), equals('note_created'));
    });
  });

  group('AnalyticsEntryPoint', () {
    test('should have all common entry points defined', () {
      // Assert
      expect(AnalyticsEntryPoint.mainMenu, equals('main_menu'));
      expect(AnalyticsEntryPoint.dashboard, equals('dashboard'));
      expect(AnalyticsEntryPoint.settings, equals('settings'));
      expect(AnalyticsEntryPoint.noteEditor, equals('note_editor'));
      expect(AnalyticsEntryPoint.themeSettings, equals('theme_settings'));
      expect(AnalyticsEntryPoint.paywall, equals('paywall'));
      expect(AnalyticsEntryPoint.notification, equals('notification'));
      expect(AnalyticsEntryPoint.widget, equals('widget'));
    });
  });

  group('AnalyticsMethod', () {
    test('should have all common methods defined', () {
      // Assert
      expect(AnalyticsMethod.tap, equals('tap'));
      expect(AnalyticsMethod.longPress, equals('long_press'));
      expect(AnalyticsMethod.swipe, equals('swipe'));
      expect(AnalyticsMethod.voice, equals('voice'));
      expect(AnalyticsMethod.keyboard, equals('keyboard'));
      expect(AnalyticsMethod.automatic, equals('automatic'));
      expect(AnalyticsMethod.api, equals('api'));
      expect(AnalyticsMethod.sync, equals('sync'));
    });
  });

  group('AnalyticsErrorCode', () {
    test('should have all common error codes defined', () {
      // Assert
      expect(AnalyticsErrorCode.networkUnavailable, equals('network_unavailable'));
      expect(AnalyticsErrorCode.serverError, equals('server_error'));
      expect(AnalyticsErrorCode.authenticationFailed, equals('authentication_failed'));
      expect(AnalyticsErrorCode.paymentFailed, equals('payment_failed'));
      expect(AnalyticsErrorCode.permissionDenied, equals('permission_denied'));
      expect(AnalyticsErrorCode.timeoutError, equals('timeout_error'));
      expect(AnalyticsErrorCode.userCancelled, equals('user_cancelled'));
      expect(AnalyticsErrorCode.quotaExceeded, equals('quota_exceeded'));
    });
  });
}
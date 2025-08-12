import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/analytics/analytics_service.dart';
import 'package:quicknote_pro/services/analytics/analytics_integration_service.dart';
import 'package:quicknote_pro/services/theme/theme_service.dart';
import 'package:quicknote_pro/models/analytics_event_type.dart';

void main() {
  group('AnalyticsIntegrationService', () {
    late AnalyticsService analyticsService;
    late ThemeService themeService;
    late AnalyticsIntegrationService integrationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      analyticsService = AnalyticsService();
      themeService = ThemeService();
      integrationService = AnalyticsIntegrationService(
        analyticsService: analyticsService,
        themeService: themeService,
      );

      await analyticsService.initialize();
      await themeService.initialize();
      await integrationService.initialize();
      await analyticsService.setUserConsent(true);
    });

    tearDown(() {
      integrationService.dispose();
      analyticsService.dispose();
    });

    test('should initialize correctly', () async {
      // Assert
      expect(integrationService, isNotNull);
      expect(analyticsService.isInitialized, isTrue);
      expect(analyticsService.isEnabled, isTrue);
    });

    test('should track note creation events', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackNoteCreated(
        entryPoint: AnalyticsEntryPoint.dashboard,
        method: AnalyticsMethod.tap,
        hasAttachments: true,
        attachmentCount: 2,
        hasImages: true,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track note editing events', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackNoteEdited(
        entryPoint: AnalyticsEntryPoint.noteEditor,
        method: AnalyticsMethod.keyboard,
        wordCount: 150,
        contentChanged: true,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track premium purchase flow', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act - Purchase started
      await integrationService.trackPremiumPurchaseStarted(
        entryPoint: AnalyticsEntryPoint.paywall,
        productId: 'premium_monthly',
        price: 1.0,
      );

      // Act - Purchase completed
      await integrationService.trackPremiumPurchaseCompleted(
        entryPoint: AnalyticsEntryPoint.paywall,
        productId: 'premium_monthly',
        price: 1.0,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount + 1));
    });

    test('should track premium purchase failure', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackPremiumPurchaseFailed(
        entryPoint: AnalyticsEntryPoint.paywall,
        productId: 'premium_monthly',
        errorCode: AnalyticsErrorCode.paymentFailed,
        price: 1.0,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track paywall interactions', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackPaywallShown(
        entryPoint: AnalyticsEntryPoint.noteEditor,
        trigger: 'free_limit_reached',
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track free limit reached', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackFreeLimitReached(
        feature: 'note_creation',
        entryPoint: AnalyticsEntryPoint.noteEditor,
        currentUsage: 50,
        limit: 50,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track cloud sync events', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act - Successful sync
      await integrationService.trackCloudSync(
        entryPoint: AnalyticsEntryPoint.settings,
        success: true,
        method: AnalyticsMethod.automatic,
        noteCount: 25,
      );

      // Act - Failed sync
      await integrationService.trackCloudSync(
        entryPoint: AnalyticsEntryPoint.settings,
        success: false,
        errorCode: AnalyticsErrorCode.networkUnavailable,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount + 1));
    });

    test('should track backup operations', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act - Successful backup
      await integrationService.trackBackupCreated(
        entryPoint: AnalyticsEntryPoint.settings,
        success: true,
        noteCount: 100,
        fileSize: 1024000,
      );

      // Act - Failed backup
      await integrationService.trackBackupCreated(
        entryPoint: AnalyticsEntryPoint.settings,
        success: false,
        errorCode: AnalyticsErrorCode.storageQuotaExceeded,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount + 1));
    });

    test('should track backup import operations', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackBackupImported(
        entryPoint: AnalyticsEntryPoint.settings,
        success: true,
        importedNotes: 75,
        skippedNotes: 5,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track OCR usage', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackOcrUsed(
        entryPoint: AnalyticsEntryPoint.noteEditor,
        success: true,
        textLength: 250,
        language: 'en',
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track voice note recording', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackVoiceNoteRecorded(
        entryPoint: AnalyticsEntryPoint.noteEditor,
        success: true,
        durationMs: 30000,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track app launch', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackAppLaunched(
        launchMode: 'normal',
        fromWidget: false,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should track feature discovery', () async {
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackFeatureDiscovered(
        feature: 'voice_notes',
        entryPoint: AnalyticsEntryPoint.noteEditor,
        method: AnalyticsMethod.tap,
      );

      // Assert
      expect(analyticsService.pendingEventCount, greaterThan(initialEventCount));
    });

    test('should not track events without analytics consent', () async {
      // Arrange
      await analyticsService.setUserConsent(false);
      final initialEventCount = analyticsService.pendingEventCount;

      // Act
      await integrationService.trackNoteCreated(
        entryPoint: AnalyticsEntryPoint.dashboard,
      );

      // Assert
      expect(analyticsService.pendingEventCount, equals(initialEventCount));
    });

    test('should handle theme changes through service integration', () async {
      // Note: This test demonstrates how theme changes would be tracked
      // automatically through the integration service, but we can't directly
      // test the listener here without more complex mocking.
      
      // Arrange
      final initialEventCount = analyticsService.pendingEventCount;

      // Act - Simulate theme change by calling the integration method directly
      // In real usage, this would be triggered by the theme service listener
      await themeService.setThemeMode(ThemeMode.dark);

      // Assert
      // The actual integration would track this automatically through listeners
      expect(themeService.themeMode, equals(ThemeMode.dark));
    });
  });
}
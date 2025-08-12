import 'package:flutter/material.dart';
import '../theme/theme_service.dart';
import 'analytics_service.dart';
import '../../models/analytics_event_type.dart';

/// Service that integrates analytics tracking with existing app services.
/// 
/// This service provides a bridge between core app functionality and analytics,
/// ensuring proper event tracking without tightly coupling services.
class AnalyticsIntegrationService extends ChangeNotifier {
  final AnalyticsService _analyticsService;
  final ThemeService _themeService;
  
  bool _isInitialized = false;
  
  AnalyticsIntegrationService({
    required AnalyticsService analyticsService,
    required ThemeService themeService,
  }) : _analyticsService = analyticsService,
       _themeService = themeService;

  /// Initialize the integration service and set up listeners
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize analytics service if not already done
    if (!_analyticsService.isInitialized) {
      await _analyticsService.initialize();
    }
    
    // Set up theme service listener
    _themeService.addListener(_onThemeChanged);
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Track theme-related events
  void _onThemeChanged() {
    if (!_analyticsService.isEnabled) return;
    
    _analyticsService.trackUsageEvent(
      AnalyticsEventType.themeChanged,
      entryPoint: AnalyticsEntryPoint.themeSettings,
      method: AnalyticsMethod.tap,
      additionalProperties: {
        'theme_mode': _themeService.themeMode.toString(),
        'has_accent_color': _themeService.accentColor != null,
      },
    );
  }

  /// Track note creation events
  Future<void> trackNoteCreated({
    required String entryPoint,
    String? method,
    bool hasAttachments = false,
    int attachmentCount = 0,
    bool hasVoiceNote = false,
    bool hasImages = false,
  }) async {
    await _analyticsService.trackUsageEvent(
      AnalyticsEventType.noteCreated,
      entryPoint: entryPoint,
      method: method ?? AnalyticsMethod.tap,
      additionalProperties: {
        'has_attachments': hasAttachments,
        'attachment_count': attachmentCount,
        'has_voice_note': hasVoiceNote,
        'has_images': hasImages,
      },
    );
  }

  /// Track note editing events
  Future<void> trackNoteEdited({
    required String entryPoint,
    String? method,
    int? wordCount,
    bool contentChanged = false,
    bool attachmentsChanged = false,
  }) async {
    await _analyticsService.trackUsageEvent(
      AnalyticsEventType.noteEdited,
      entryPoint: entryPoint,
      method: method ?? AnalyticsMethod.keyboard,
      additionalProperties: {
        'word_count': wordCount,
        'content_changed': contentChanged,
        'attachments_changed': attachmentsChanged,
      },
    );
  }

  /// Track premium purchase flow events
  Future<void> trackPremiumPurchaseStarted({
    required String entryPoint,
    required String productId,
    double? price,
  }) async {
    await _analyticsService.trackMonetizationEvent(
      AnalyticsEventType.premiumPurchaseStarted,
      entryPoint: entryPoint,
      productId: productId,
      price: price,
      currency: 'USD', // Default currency
    );
  }

  /// Track premium purchase completion
  Future<void> trackPremiumPurchaseCompleted({
    required String entryPoint,
    required String productId,
    required double price,
    String? currency,
  }) async {
    await _analyticsService.trackMonetizationEvent(
      AnalyticsEventType.premiumPurchaseCompleted,
      entryPoint: entryPoint,
      productId: productId,
      price: price,
      currency: currency ?? 'USD',
      conversion: true,
    );
  }

  /// Track premium purchase failure
  Future<void> trackPremiumPurchaseFailed({
    required String entryPoint,
    required String productId,
    required String errorCode,
    double? price,
  }) async {
    await _analyticsService.trackMonetizationEvent(
      AnalyticsEventType.premiumPurchaseFailed,
      entryPoint: entryPoint,
      productId: productId,
      price: price,
      conversion: false,
      errorCode: errorCode,
    );
  }

  /// Track paywall interactions
  Future<void> trackPaywallShown({
    required String entryPoint,
    String? trigger,
  }) async {
    await _analyticsService.trackMonetizationEvent(
      AnalyticsEventType.paywallShown,
      entryPoint: entryPoint,
      additionalProperties: {
        'trigger': trigger,
      },
    );
  }

  /// Track free limit reached
  Future<void> trackFreeLimitReached({
    required String feature,
    required String entryPoint,
    int? currentUsage,
    int? limit,
  }) async {
    await _analyticsService.trackMonetizationEvent(
      AnalyticsEventType.freeLimitReached,
      entryPoint: entryPoint,
      additionalProperties: {
        'feature': feature,
        'current_usage': currentUsage,
        'limit': limit,
      },
    );
  }

  /// Track cloud sync events
  Future<void> trackCloudSync({
    required String entryPoint,
    required bool success,
    String? method,
    int? noteCount,
    String? errorCode,
  }) async {
    final eventType = success 
        ? AnalyticsEventType.cloudSyncPerformed
        : AnalyticsEventType.networkError;
    
    await _analyticsService.trackUsageEvent(
      eventType,
      entryPoint: entryPoint,
      method: method ?? AnalyticsMethod.automatic,
      additionalProperties: {
        'note_count': noteCount,
        'success': success,
      },
    );
    
    if (!success && errorCode != null) {
      await _analyticsService.trackErrorEvent(
        AnalyticsEventType.networkError,
        errorCode,
        entryPoint: entryPoint,
      );
    }
  }

  /// Track backup operations
  Future<void> trackBackupCreated({
    required String entryPoint,
    required bool success,
    int? noteCount,
    int? fileSize,
    String? errorCode,
  }) async {
    if (success) {
      await _analyticsService.trackUsageEvent(
        AnalyticsEventType.backupCreated,
        entryPoint: entryPoint,
        method: AnalyticsMethod.export,
        additionalProperties: {
          'note_count': noteCount,
          'file_size_bytes': fileSize,
        },
      );
    } else if (errorCode != null) {
      await _analyticsService.trackErrorEvent(
        AnalyticsEventType.storageError,
        errorCode,
        entryPoint: entryPoint,
        additionalProperties: {
          'operation': 'backup_create',
        },
      );
    }
  }

  /// Track backup import operations
  Future<void> trackBackupImported({
    required String entryPoint,
    required bool success,
    int? importedNotes,
    int? skippedNotes,
    String? errorCode,
  }) async {
    if (success) {
      await _analyticsService.trackUsageEvent(
        AnalyticsEventType.backupImported,
        entryPoint: entryPoint,
        method: AnalyticsMethod.import,
        additionalProperties: {
          'imported_notes': importedNotes,
          'skipped_notes': skippedNotes,
        },
      );
    } else if (errorCode != null) {
      await _analyticsService.trackErrorEvent(
        AnalyticsEventType.storageError,
        errorCode,
        entryPoint: entryPoint,
        additionalProperties: {
          'operation': 'backup_import',
        },
      );
    }
  }

  /// Track OCR usage
  Future<void> trackOcrUsed({
    required String entryPoint,
    required bool success,
    int? textLength,
    String? language,
    String? errorCode,
  }) async {
    if (success) {
      await _analyticsService.trackUsageEvent(
        AnalyticsEventType.ocrUsed,
        entryPoint: entryPoint,
        method: AnalyticsMethod.automatic,
        additionalProperties: {
          'text_length': textLength,
          'language': language,
        },
      );
    } else if (errorCode != null) {
      await _analyticsService.trackErrorEvent(
        AnalyticsEventType.appError,
        errorCode,
        entryPoint: entryPoint,
        additionalProperties: {
          'operation': 'ocr_processing',
        },
      );
    }
  }

  /// Track voice note recording
  Future<void> trackVoiceNoteRecorded({
    required String entryPoint,
    required bool success,
    int? durationMs,
    String? errorCode,
  }) async {
    if (success) {
      await _analyticsService.trackUsageEvent(
        AnalyticsEventType.voiceNoteRecorded,
        entryPoint: entryPoint,
        method: AnalyticsMethod.voice,
        additionalProperties: {
          'duration_ms': durationMs,
        },
      );
    } else if (errorCode != null) {
      await _analyticsService.trackErrorEvent(
        AnalyticsEventType.appError,
        errorCode,
        entryPoint: entryPoint,
        additionalProperties: {
          'operation': 'voice_recording',
        },
      );
    }
  }

  /// Track app launch
  Future<void> trackAppLaunched({
    String? launchMode,
    bool? fromWidget,
  }) async {
    await _analyticsService.trackUsageEvent(
      AnalyticsEventType.appLaunched,
      entryPoint: fromWidget == true 
          ? AnalyticsEntryPoint.widget 
          : AnalyticsEntryPoint.mainMenu,
      additionalProperties: {
        'launch_mode': launchMode,
        'from_widget': fromWidget,
      },
    );
  }

  /// Track feature discovery
  Future<void> trackFeatureDiscovered({
    required String feature,
    required String entryPoint,
    String? method,
  }) async {
    await _analyticsService.trackUsageEvent(
      AnalyticsEventType.featureDiscovered,
      entryPoint: entryPoint,
      method: method,
      label: feature,
    );
  }

  /// Dispose of the integration service
  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }
}
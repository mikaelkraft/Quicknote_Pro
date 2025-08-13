import 'dart:convert';

/// Model representing an analytics event for monetization tracking
class AnalyticsEvent {
  final String eventName;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String userId;

  const AnalyticsEvent({
    required this.eventName,
    required this.properties,
    required this.timestamp,
    required this.userId,
  });

  /// Create an analytics event with current timestamp
  factory AnalyticsEvent.create({
    required String eventName,
    required String userId,
    Map<String, dynamic> properties = const {},
  }) {
    return AnalyticsEvent(
      eventName: eventName,
      properties: properties,
      timestamp: DateTime.now(),
      userId: userId,
    );
  }

  /// Convert event to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  /// Create event from JSON
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventName: json['eventName'] as String,
      properties: Map<String, dynamic>.from(json['properties'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String,
    );
  }

  @override
  String toString() {
    return 'AnalyticsEvent{eventName: $eventName, userId: $userId, timestamp: $timestamp}';
  }
}

/// Predefined event names for monetization tracking
class AnalyticsEvents {
  AnalyticsEvents._();

  // Activation events
  static const String appLaunched = 'app_launched';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String firstNoteCreated = 'first_note_created';
  static const String featureDiscovered = 'feature_discovered';

  // Retention events
  static const String sessionStarted = 'session_started';
  static const String sessionEnded = 'session_ended';
  static const String noteCreated = 'note_created';
  static const String noteEdited = 'note_edited';
  static const String noteDeleted = 'note_deleted';
  static const String attachmentAdded = 'attachment_added';
  static const String searchPerformed = 'search_performed';
  static const String folderCreated = 'folder_created';

  // Conversion events
  static const String premiumScreenViewed = 'premium_screen_viewed';
  static const String premiumFeatureBlocked = 'premium_feature_blocked';
  static const String upgradeButtonTapped = 'upgrade_button_tapped';
  static const String purchaseStarted = 'purchase_started';
  static const String purchaseCompleted = 'purchase_completed';
  static const String purchaseFailed = 'purchase_failed';
  static const String trialStarted = 'trial_started';
  static const String subscriptionCancelled = 'subscription_cancelled';

  // Ad events
  static const String adDisplayed = 'ad_displayed';
  static const String adClicked = 'ad_clicked';
  static const String adDismissed = 'ad_dismissed';
  static const String adLoadFailed = 'ad_load_failed';

  // Usage events
  static const String voiceNoteCreated = 'voice_note_created';
  static const String drawingCreated = 'drawing_created';
  static const String ocrUsed = 'ocr_used';
  static const String syncTriggered = 'sync_triggered';
  static const String exportPerformed = 'export_performed';

  /// Get all event names for validation
  static List<String> get allEvents => [
    appLaunched, onboardingCompleted, firstNoteCreated, featureDiscovered,
    sessionStarted, sessionEnded, noteCreated, noteEdited, noteDeleted,
    attachmentAdded, searchPerformed, folderCreated,
    premiumScreenViewed, premiumFeatureBlocked, upgradeButtonTapped,
    purchaseStarted, purchaseCompleted, purchaseFailed, trialStarted,
    subscriptionCancelled, adDisplayed, adClicked, adDismissed, adLoadFailed,
    voiceNoteCreated, drawingCreated, ocrUsed, syncTriggered, exportPerformed,
  ];
}

/// Common properties for analytics events
class AnalyticsProperties {
  AnalyticsProperties._();

  // Common properties
  static const String platform = 'platform';
  static const String appVersion = 'app_version';
  static const String userId = 'user_id';
  static const String sessionId = 'session_id';

  // Feature-specific properties
  static const String featureName = 'feature_name';
  static const String noteType = 'note_type';
  static const String attachmentType = 'attachment_type';
  static const String searchQuery = 'search_query';
  static const String subscriptionType = 'subscription_type';
  static const String purchasePrice = 'purchase_price';
  static const String currency = 'currency';

  // Ad-specific properties
  static const String adFormat = 'ad_format';
  static const String adPlacement = 'ad_placement';
  static const String adProvider = 'ad_provider';
  static const String impressionId = 'impression_id';

  // Error properties
  static const String errorCode = 'error_code';
  static const String errorMessage = 'error_message';
}
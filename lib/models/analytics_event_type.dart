/// Comprehensive taxonomy of analytics events for monetization and usage tracking.
/// 
/// This enum defines all trackable events in the Quicknote Pro application,
/// organized by category and aligned with business insights requirements.
enum AnalyticsEventType {
  // === MONETIZATION EVENTS ===
  
  /// Premium subscription purchase initiated
  premiumPurchaseStarted('premium_purchase_started'),
  
  /// Premium subscription purchase completed successfully
  premiumPurchaseCompleted('premium_purchase_completed'),
  
  /// Premium subscription purchase failed
  premiumPurchaseFailed('premium_purchase_failed'),
  
  /// Premium subscription purchase cancelled by user
  premiumPurchaseCancelled('premium_purchase_cancelled'),
  
  /// Premium subscription renewed
  premiumSubscriptionRenewed('premium_subscription_renewed'),
  
  /// Premium subscription cancelled
  premiumSubscriptionCancelled('premium_subscription_cancelled'),
  
  /// Premium subscription expired
  premiumSubscriptionExpired('premium_subscription_expired'),
  
  /// Paywall displayed to user
  paywallShown('paywall_shown'),
  
  /// User dismissed paywall without action
  paywallDismissed('paywall_dismissed'),
  
  /// User interacted with paywall (clicked upgrade)
  paywallInteracted('paywall_interacted'),
  
  /// Free usage limit reached
  freeLimitReached('free_limit_reached'),
  
  /// Free usage limit warning shown
  freeLimitWarning('free_limit_warning'),
  
  // === AD EVENTS ===
  
  /// Advertisement requested
  adRequested('ad_requested'),
  
  /// Advertisement loaded successfully
  adLoaded('ad_loaded'),
  
  /// Advertisement failed to load
  adFailed('ad_failed'),
  
  /// Advertisement displayed to user
  adShown('ad_shown'),
  
  /// User clicked on advertisement
  adClicked('ad_clicked'),
  
  /// Advertisement dismissed/closed
  adDismissed('ad_dismissed'),
  
  /// Rewarded ad completed (user earned reward)
  rewardedAdCompleted('rewarded_ad_completed'),
  
  // === THEME EVENTS ===
  
  /// User changed theme mode (light/dark/system)
  themeChanged('theme_changed'),
  
  /// User selected custom accent color
  accentColorChanged('accent_color_changed'),
  
  /// Premium theme accessed (requires entitlement check)
  premiumThemeAccessed('premium_theme_accessed'),
  
  /// Theme settings screen viewed
  themeSettingsViewed('theme_settings_viewed'),
  
  // === FEATURE USAGE EVENTS ===
  
  /// Note created by user
  noteCreated('note_created'),
  
  /// Note edited/updated
  noteEdited('note_edited'),
  
  /// Note deleted
  noteDeleted('note_deleted'),
  
  /// Note shared
  noteShared('note_shared'),
  
  /// Note exported
  noteExported('note_exported'),
  
  /// Note searched
  noteSearched('note_searched'),
  
  /// Voice note recorded
  voiceNoteRecorded('voice_note_recorded'),
  
  /// Image attached to note
  imageAttached('image_attached'),
  
  /// OCR text recognition used
  ocrUsed('ocr_used'),
  
  /// Cloud sync performed
  cloudSyncPerformed('cloud_sync_performed'),
  
  /// Backup created
  backupCreated('backup_created'),
  
  /// Backup imported
  backupImported('backup_imported'),
  
  // === NAVIGATION/UX EVENTS ===
  
  /// App launched/opened
  appLaunched('app_launched'),
  
  /// App backgrounded
  appBackgrounded('app_backgrounded'),
  
  /// Settings screen accessed
  settingsAccessed('settings_accessed'),
  
  /// Onboarding flow started
  onboardingStarted('onboarding_started'),
  
  /// Onboarding flow completed
  onboardingCompleted('onboarding_completed'),
  
  /// Tutorial viewed
  tutorialViewed('tutorial_viewed'),
  
  /// Help/support accessed
  helpAccessed('help_accessed'),
  
  // === ERROR/PERFORMANCE EVENTS ===
  
  /// Application error occurred
  appError('app_error'),
  
  /// Network error occurred
  networkError('network_error'),
  
  /// Storage error occurred
  storageError('storage_error'),
  
  /// Performance issue detected
  performanceIssue('performance_issue'),
  
  /// Crash occurred
  appCrash('app_crash'),
  
  // === ENGAGEMENT EVENTS ===
  
  /// User session started
  sessionStarted('session_started'),
  
  /// User session ended
  sessionEnded('session_ended'),
  
  /// Daily active user
  dailyActive('daily_active'),
  
  /// Weekly active user
  weeklyActive('weekly_active'),
  
  /// User retention tracked
  userRetention('user_retention'),
  
  /// Feature discovery
  featureDiscovered('feature_discovered');

  const AnalyticsEventType(this.value);
  
  /// String value of the event type
  final String value;

  @override
  String toString() => value;

  /// Get event category for grouping
  String get category {
    switch (this) {
      case AnalyticsEventType.premiumPurchaseStarted:
      case AnalyticsEventType.premiumPurchaseCompleted:
      case AnalyticsEventType.premiumPurchaseFailed:
      case AnalyticsEventType.premiumPurchaseCancelled:
      case AnalyticsEventType.premiumSubscriptionRenewed:
      case AnalyticsEventType.premiumSubscriptionCancelled:
      case AnalyticsEventType.premiumSubscriptionExpired:
      case AnalyticsEventType.paywallShown:
      case AnalyticsEventType.paywallDismissed:
      case AnalyticsEventType.paywallInteracted:
      case AnalyticsEventType.freeLimitReached:
      case AnalyticsEventType.freeLimitWarning:
        return 'monetization';
        
      case AnalyticsEventType.adRequested:
      case AnalyticsEventType.adLoaded:
      case AnalyticsEventType.adFailed:
      case AnalyticsEventType.adShown:
      case AnalyticsEventType.adClicked:
      case AnalyticsEventType.adDismissed:
      case AnalyticsEventType.rewardedAdCompleted:
        return 'advertising';
        
      case AnalyticsEventType.themeChanged:
      case AnalyticsEventType.accentColorChanged:
      case AnalyticsEventType.premiumThemeAccessed:
      case AnalyticsEventType.themeSettingsViewed:
        return 'theme';
        
      case AnalyticsEventType.noteCreated:
      case AnalyticsEventType.noteEdited:
      case AnalyticsEventType.noteDeleted:
      case AnalyticsEventType.noteShared:
      case AnalyticsEventType.noteExported:
      case AnalyticsEventType.noteSearched:
      case AnalyticsEventType.voiceNoteRecorded:
      case AnalyticsEventType.imageAttached:
      case AnalyticsEventType.ocrUsed:
      case AnalyticsEventType.cloudSyncPerformed:
      case AnalyticsEventType.backupCreated:
      case AnalyticsEventType.backupImported:
        return 'feature';
        
      case AnalyticsEventType.appLaunched:
      case AnalyticsEventType.appBackgrounded:
      case AnalyticsEventType.settingsAccessed:
      case AnalyticsEventType.onboardingStarted:
      case AnalyticsEventType.onboardingCompleted:
      case AnalyticsEventType.tutorialViewed:
      case AnalyticsEventType.helpAccessed:
        return 'navigation';
        
      case AnalyticsEventType.appError:
      case AnalyticsEventType.networkError:
      case AnalyticsEventType.storageError:
      case AnalyticsEventType.performanceIssue:
      case AnalyticsEventType.appCrash:
        return 'error';
        
      case AnalyticsEventType.sessionStarted:
      case AnalyticsEventType.sessionEnded:
      case AnalyticsEventType.dailyActive:
      case AnalyticsEventType.weeklyActive:
      case AnalyticsEventType.userRetention:
      case AnalyticsEventType.featureDiscovered:
        return 'engagement';
    }
  }

  /// Check if this event type is related to monetization
  bool get isMonetizationEvent => category == 'monetization';

  /// Check if this event type is related to usage/features
  bool get isUsageEvent => category == 'feature' || category == 'navigation';

  /// Check if this event type indicates an error
  bool get isErrorEvent => category == 'error';

  /// Check if this event type is high priority for tracking
  bool get isHighPriority => 
      isMonetizationEvent || 
      isErrorEvent || 
      this == AnalyticsEventType.appCrash ||
      this == AnalyticsEventType.freeLimitReached;

  /// Get all monetization-related event types
  static List<AnalyticsEventType> get monetizationEvents => 
      values.where((event) => event.isMonetizationEvent).toList();

  /// Get all usage-related event types
  static List<AnalyticsEventType> get usageEvents => 
      values.where((event) => event.isUsageEvent).toList();

  /// Get all error-related event types
  static List<AnalyticsEventType> get errorEvents => 
      values.where((event) => event.isErrorEvent).toList();

  /// Get all high-priority event types
  static List<AnalyticsEventType> get highPriorityEvents => 
      values.where((event) => event.isHighPriority).toList();
}

/// Common entry points for analytics events
class AnalyticsEntryPoint {
  static const String mainMenu = 'main_menu';
  static const String dashboard = 'dashboard';
  static const String settings = 'settings';
  static const String noteEditor = 'note_editor';
  static const String themeSettings = 'theme_settings';
  static const String paywall = 'paywall';
  static const String onboarding = 'onboarding';
  static const String notification = 'notification';
  static const String searchResults = 'search_results';
  static const String contextMenu = 'context_menu';
  static const String toolbar = 'toolbar';
  static const String systemBack = 'system_back';
  static const String deepLink = 'deep_link';
  static const String widget = 'widget';
  static const String shareExtension = 'share_extension';
}

/// Common methods for completing actions
class AnalyticsMethod {
  static const String tap = 'tap';
  static const String longPress = 'long_press';
  static const String swipe = 'swipe';
  static const String drag = 'drag';
  static const String voice = 'voice';
  static const String keyboard = 'keyboard';
  static const String gesture = 'gesture';
  static const String automatic = 'automatic';
  static const String systemTriggered = 'system_triggered';
  static const String scheduled = 'scheduled';
  static const String api = 'api';
  static const String sync = 'sync';
  static const String import = 'import';
  static const String export = 'export';
}

/// Common error codes for analytics events
class AnalyticsErrorCode {
  static const String networkUnavailable = 'network_unavailable';
  static const String serverError = 'server_error';
  static const String authenticationFailed = 'authentication_failed';
  static const String paymentFailed = 'payment_failed';
  static const String storageQuotaExceeded = 'storage_quota_exceeded';
  static const String permissionDenied = 'permission_denied';
  static const String fileNotFound = 'file_not_found';
  static const String invalidFormat = 'invalid_format';
  static const String timeoutError = 'timeout_error';
  static const String unknownError = 'unknown_error';
  static const String userCancelled = 'user_cancelled';
  static const String featureNotAvailable = 'feature_not_available';
  static const String quotaExceeded = 'quota_exceeded';
  static const String subscriptionInactive = 'subscription_inactive';
}
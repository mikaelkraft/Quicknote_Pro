import 'package:flutter/foundation.dart';

/// Service to track analytics events related to theme interactions
/// 
/// Logs theme-related user actions for insights and conversion tracking.
/// Events are logged to debug console in development mode.
class AnalyticsService {
  static AnalyticsService? _instance;
  
  /// Singleton instance
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  AnalyticsService._();

  /// Track when a theme is viewed in the theme picker
  void trackThemeViewed({
    required String themeName,
    required bool isPremium,
    required bool hasProAccess,
  }) {
    _logEvent('theme_viewed', {
      'theme_name': themeName,
      'is_premium': isPremium,
      'has_pro_access': hasProAccess,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track when user attempts to select a locked theme
  void trackThemeSelectAttemptLocked({
    required String themeName,
    required String userType, // 'free', 'monthly', 'lifetime'
  }) {
    _logEvent('theme_select_attempt_locked', {
      'theme_name': themeName,
      'user_type': userType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track when a theme is successfully selected
  void trackThemeSelected({
    required String themeName,
    required bool isPremium,
    required String userType,
    required String previousTheme,
  }) {
    _logEvent('theme_selected', {
      'theme_name': themeName,
      'is_premium': isPremium,
      'user_type': userType,
      'previous_theme': previousTheme,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track when paywall is shown from theme selection
  void trackPaywallShownFromTheme({
    required String triggerTheme,
    required String paywallType, // 'theme_upgrade'
  }) {
    _logEvent('paywall_shown_from_theme', {
      'trigger_theme': triggerTheme,
      'paywall_type': paywallType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track conversion events (when user purchases Pro after seeing paywall)
  void trackConversion({
    required String conversionType, // 'monthly_pro', 'lifetime_pro'
    required String triggerSource, // 'theme_paywall'
    required String triggerTheme,
    required double amount,
  }) {
    _logEvent('conversion', {
      'conversion_type': conversionType,
      'trigger_source': triggerSource,
      'trigger_theme': triggerTheme,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track when theme automatically falls back due to subscription lapse
  void trackThemeFallback({
    required String fromTheme,
    required String toTheme,
    required String reason, // 'subscription_expired', 'subscription_cancelled'
  }) {
    _logEvent('theme_fallback', {
      'from_theme': fromTheme,
      'to_theme': toTheme,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track theme picker opened
  void trackThemePickerOpened({
    required String currentTheme,
    required bool hasProAccess,
  }) {
    _logEvent('theme_picker_opened', {
      'current_theme': currentTheme,
      'has_pro_access': hasProAccess,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track theme picker closed
  void trackThemePickerClosed({
    required String currentTheme,
    required bool themeChanged,
    required int timeSpentSeconds,
  }) {
    _logEvent('theme_picker_closed', {
      'current_theme': currentTheme,
      'theme_changed': themeChanged,
      'time_spent_seconds': timeSpentSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track subscription status check
  void trackSubscriptionStatusChecked({
    required String status, // 'free', 'monthly_pro', 'lifetime_pro'
    required bool isOfflineCache,
    required bool needsRefresh,
  }) {
    _logEvent('subscription_status_checked', {
      'status': status,
      'is_offline_cache': isOfflineCache,
      'needs_refresh': needsRefresh,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track when user dismisses Pro upsell
  void trackProUpsellDismissed({
    required String triggerTheme,
    required String dismissalMethod, // 'close_button', 'outside_tap', 'back_button'
  }) {
    _logEvent('pro_upsell_dismissed', {
      'trigger_theme': triggerTheme,
      'dismissal_method': dismissalMethod,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track when user taps on Pro badge/label
  void trackProBadgeTapped({
    required String themeName,
    required String location, // 'theme_picker', 'settings_screen'
  }) {
    _logEvent('pro_badge_tapped', {
      'theme_name': themeName,
      'location': location,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Internal method to log events
  /// 
  /// In a production app, this would send events to your analytics service
  /// (Firebase Analytics, Mixpanel, etc.). For now, it logs to debug console.
  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    if (kDebugMode) {
      debugPrint('📊 Analytics Event: $eventName');
      debugPrint('   Parameters: $parameters');
    }
    
    // In production, send to analytics service:
    // FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
    // or
    // Mixpanel.track(eventName, parameters);
  }

  /// Batch log multiple events (useful for offline scenarios)
  void logBatch(List<Map<String, dynamic>> events) {
    for (final event in events) {
      if (event.containsKey('event_name') && event.containsKey('parameters')) {
        _logEvent(event['event_name'], event['parameters']);
      }
    }
  }

  /// Set user properties for analytics
  void setUserProperties({
    required String userId,
    required String subscriptionStatus,
    required String currentTheme,
  }) {
    if (kDebugMode) {
      debugPrint('📊 Analytics User Properties Updated:');
      debugPrint('   User ID: $userId');
      debugPrint('   Subscription: $subscriptionStatus');
      debugPrint('   Theme: $currentTheme');
    }
    
    // In production:
    // FirebaseAnalytics.instance.setUserId(id: userId);
    // FirebaseAnalytics.instance.setUserProperty(name: 'subscription_status', value: subscriptionStatus);
    // FirebaseAnalytics.instance.setUserProperty(name: 'current_theme', value: currentTheme);
  }
}
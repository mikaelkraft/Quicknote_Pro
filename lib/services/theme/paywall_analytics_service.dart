import 'package:flutter/foundation.dart';

/// Service for tracking paywall and monetization analytics
/// 
/// Logs events related to paywall interactions, purchases, and upsell flows
/// for business intelligence and optimization.
class PaywallAnalyticsService {
  static const String _logPrefix = '[PaywallAnalytics]';

  /// Log when paywall is shown to user
  static void logPaywallShown({
    required String entryPoint,
    required String featureType,
    String? specificFeature,
    Map<String, dynamic>? additionalData,
  }) {
    final event = {
      'event': 'paywall_shown',
      'entry_point': entryPoint, // 'theme_picker', 'settings', 'voice_notes', etc.
      'feature_type': featureType, // 'theme', 'voice_notes', 'drawing_tools', etc.
      'specific_feature': specificFeature, // 'futuristic_theme', 'neon_theme', etc.
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    _logEvent('paywall_shown', event);
  }

  /// Log when user converts (makes a purchase)
  static void logPaywallConversion({
    required String entryPoint,
    required String purchaseType,
    required String planType,
    required double price,
    String? currency,
    Map<String, dynamic>? additionalData,
  }) {
    final event = {
      'event': 'paywall_conversion',
      'entry_point': entryPoint,
      'purchase_type': purchaseType, // 'new_purchase', 'restore'
      'plan_type': planType, // 'monthly', 'lifetime'
      'price': price,
      'currency': currency ?? 'USD',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    _logEvent('paywall_conversion', event);
  }

  /// Log upsell entry point usage
  static void logUpsellEntryPoint({
    required String entryPoint,
    required String action,
    String? targetFeature,
    Map<String, dynamic>? additionalData,
  }) {
    final event = {
      'event': 'upsell_entry_point',
      'entry_point': entryPoint,
      'action': action, // 'clicked', 'dismissed', 'viewed'
      'target_feature': targetFeature,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    _logEvent('upsell_entry_point', event);
  }

  /// Log failed payment attempts
  static void logFailedPayment({
    required String entryPoint,
    required String planType,
    required String errorType,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) {
    final event = {
      'event': 'failed_payment',
      'entry_point': entryPoint,
      'plan_type': planType,
      'error_type': errorType, // 'user_cancelled', 'payment_failed', 'network_error', etc.
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    _logEvent('failed_payment', event);
  }

  /// Log theme selection attempts
  static void logThemeSelectionAttempt({
    required String themeId,
    required bool isProTheme,
    required bool hasAccess,
    String? action, // 'selected', 'blocked', 'upgraded'
  }) {
    final event = {
      'event': 'theme_selection_attempt',
      'theme_id': themeId,
      'is_pro_theme': isProTheme,
      'has_access': hasAccess,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logEvent('theme_selection_attempt', event);
  }

  /// Log when user dismisses paywall
  static void logPaywallDismissed({
    required String entryPoint,
    required String dismissReason,
    int? timeSpentSeconds,
    Map<String, dynamic>? additionalData,
  }) {
    final event = {
      'event': 'paywall_dismissed',
      'entry_point': entryPoint,
      'dismiss_reason': dismissReason, // 'close_button', 'back_gesture', 'outside_tap'
      'time_spent_seconds': timeSpentSeconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    _logEvent('paywall_dismissed', event);
  }

  /// Log trial or discount offer interactions
  static void logOfferInteraction({
    required String offerType,
    required String action,
    String? entryPoint,
    Map<String, dynamic>? offerDetails,
  }) {
    final event = {
      'event': 'offer_interaction',
      'offer_type': offerType, // 'free_trial', 'discount', 'limited_time'
      'action': action, // 'viewed', 'accepted', 'declined'
      'entry_point': entryPoint,
      'offer_details': offerDetails,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logEvent('offer_interaction', event);
  }

  /// Log purchase restoration attempts
  static void logPurchaseRestore({
    required bool success,
    String? errorMessage,
    int? restoredItemsCount,
  }) {
    final event = {
      'event': 'purchase_restore',
      'success': success,
      'error_message': errorMessage,
      'restored_items_count': restoredItemsCount,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logEvent('purchase_restore', event);
  }

  /// Internal method to log events
  static void _logEvent(String eventType, Map<String, dynamic> eventData) {
    if (kDebugMode) {
      print('$_logPrefix $eventType: $eventData');
    }

    // In a production app, you would send this to your analytics service
    // Examples: Firebase Analytics, Mixpanel, Amplitude, etc.
    // 
    // FirebaseAnalytics.instance.logEvent(
    //   name: eventType,
    //   parameters: eventData,
    // );
    //
    // Or custom analytics endpoint:
    // await _sendToAnalyticsEndpoint(eventType, eventData);
  }

  /// Get summary of analytics events for debugging
  static Map<String, dynamic> getAnalyticsSummary() {
    // In a real implementation, this would return actual analytics data
    return {
      'analytics_service': 'PaywallAnalyticsService',
      'events_tracked': [
        'paywall_shown',
        'paywall_conversion', 
        'upsell_entry_point',
        'failed_payment',
        'theme_selection_attempt',
        'paywall_dismissed',
        'offer_interaction',
        'purchase_restore',
      ],
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}
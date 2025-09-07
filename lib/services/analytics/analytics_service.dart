import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics service for tracking monetization and usage events.
/// 
/// Provides a centralized system for collecting and managing analytics events
/// related to user behavior, monetization actions, and feature usage.
/// 
/// This service gracefully handles missing Firebase configuration by operating
/// in a safe no-op mode when Firebase is not available.
class AnalyticsService extends ChangeNotifier {
  static const String _analyticsEnabledKey = 'analytics_enabled';
  
  SharedPreferences? _prefs;
  FirebaseAnalytics? _analytics;
  bool _analyticsEnabled = true;
  bool _firebaseInitialized = false;
  final List<AnalyticsEvent> _eventQueue = [];
  final Map<String, int> _eventCounts = {};

  /// Whether analytics tracking is enabled
  bool get analyticsEnabled => _analyticsEnabled;

  /// Whether Firebase is properly initialized
  bool get firebaseInitialized => _firebaseInitialized;

  /// Event counts for debugging and monitoring
  Map<String, int> get eventCounts => Map.unmodifiable(_eventCounts);

  /// Initialize the analytics service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAnalyticsSettings();
    await _initializeFirebase();
  }

  /// Initialize Firebase Analytics with safe fallback
  Future<void> _initializeFirebase() async {
    try {
      // Try to initialize Firebase
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _firebaseInitialized = true;
      
      if (kDebugMode) {
        print('Analytics: Firebase Analytics initialized successfully');
      }
    } catch (e) {
      _firebaseInitialized = false;
      if (kDebugMode) {
        print('Analytics: Firebase Analytics not available (${e.toString()})');
        print('Analytics: Operating in safe no-op mode');
        print('Analytics: Run "flutterfire configure" to enable Firebase Analytics');
      }
    }
  }

  /// Load analytics settings from shared preferences
  Future<void> _loadAnalyticsSettings() async {
    if (_prefs == null) return;
    
    _analyticsEnabled = _prefs!.getBool(_analyticsEnabledKey) ?? true;
    notifyListeners();
  }

  /// Toggle analytics tracking
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _analyticsEnabled = enabled;
    await _prefs?.setBool(_analyticsEnabledKey, enabled);
    
    // Set Firebase Analytics collection enabled state
    if (_firebaseInitialized && _analytics != null) {
      await _analytics!.setAnalyticsCollectionEnabled(enabled);
    }
    
    notifyListeners();
    
    if (enabled) {
      trackEvent(AnalyticsEvent.analyticsEnabled());
    } else {
      trackEvent(AnalyticsEvent.analyticsDisabled());
    }
  }

  /// Set user ID for analytics tracking
  Future<void> setUserId(String? userId) async {
    if (!_analyticsEnabled || !_firebaseInitialized || _analytics == null) {
      if (kDebugMode) {
        print('Analytics: setUserId($userId) - no-op mode');
      }
      return;
    }

    try {
      await _analytics!.setUserId(id: userId);
      if (kDebugMode) {
        print('Analytics: User ID set to $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics: Failed to set user ID: $e');
      }
    }
  }

  /// Set user property for analytics
  Future<void> setUserProperty(String name, String? value) async {
    if (!_analyticsEnabled || !_firebaseInitialized || _analytics == null) {
      if (kDebugMode) {
        print('Analytics: setUserProperty($name, $value) - no-op mode');
      }
      return;
    }

    try {
      await _analytics!.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('Analytics: User property $name set to $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics: Failed to set user property: $e');
      }
    }
  }

  /// Set subscription status user property
  Future<void> setSubscriptionStatus(String status) async {
    await setUserProperty('subscription_status', status);
  }

  /// Log screen view event
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (!_analyticsEnabled) return;

    if (_firebaseInitialized && _analytics != null) {
      try {
        await _analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Analytics: Failed to log screen view: $e');
        }
      }
    }

    // Also track in local queue for debugging
    trackEvent(AnalyticsEvent(
      name: 'screen_view',
      properties: {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
      },
    ));
  }

  /// Log custom event with Firebase Analytics
  Future<void> logEvent(String name, Map<String, Object?>? parameters) async {
    if (!_analyticsEnabled) return;

    // Filter out null values
    final filteredParams = parameters?.entries
        .where((entry) => entry.value != null)
        .fold<Map<String, Object>>(
          {},
          (map, entry) => map..[entry.key] = entry.value!,
        );

    if (_firebaseInitialized && _analytics != null) {
      try {
        await _analytics!.logEvent(
          name: name,
          parameters: filteredParams,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Analytics: Failed to log event $name: $e');
        }
      }
    }

    // Also track in local system for backward compatibility
    trackEvent(AnalyticsEvent(
      name: name,
      properties: filteredParams ?? {},
    ));
  }

  /// Track an analytics event (legacy API)
  void trackEvent(AnalyticsEvent event) {
    if (!_analyticsEnabled) return;
    
    _eventQueue.add(event);
    _eventCounts[event.name] = (_eventCounts[event.name] ?? 0) + 1;
    
    if (kDebugMode) {
      print('Analytics: ${event.name} - ${event.properties}');
    }
    
    // Send to Firebase if available
    if (_firebaseInitialized && _analytics != null) {
      logEvent(event.name, event.properties);
    }
    
    notifyListeners();
  }

  /// Track monetization-specific events
  void trackMonetizationEvent(MonetizationEvent event) {
    trackEvent(AnalyticsEvent.monetization(
      action: event.action,
      properties: event.properties,
    ));
  }

  /// Track user engagement events
  void trackEngagementEvent(EngagementEvent event) {
    trackEvent(AnalyticsEvent.engagement(
      action: event.action,
      properties: event.properties,
    ));
  }

  /// Track feature usage events
  void trackFeatureEvent(FeatureEvent event) {
    trackEvent(AnalyticsEvent.feature(
      featureName: event.featureName,
      action: event.action,
      properties: event.properties,
    ));
  }

  /// Track revenue-specific events for KPI monitoring
  Future<void> trackRevenueEvent({
    required String eventName,
    required double revenue,
    required String currency,
    String? transactionId,
    String? productId,
    String? subscriptionTier,
    Map<String, dynamic>? additionalProperties,
  }) async {
    final properties = {
      'revenue': revenue,
      'currency': currency,
      'transaction_id': transactionId,
      'product_id': productId,
      'subscription_tier': subscriptionTier,
      'timestamp': DateTime.now().toIso8601String(),
      'user_locale': _getUserLocale(),
      ...?additionalProperties,
    };

    await logEvent(eventName, properties);
    
    // Also track as purchase event for Firebase
    if (_firebaseInitialized && _analytics != null) {
      try {
        await _analytics!.logPurchase(
          currency: currency,
          value: revenue,
          transactionId: transactionId,
          items: productId != null ? [
            AnalyticsEventItem(
              itemId: productId,
              itemName: subscriptionTier ?? productId,
              itemCategory: 'subscription',
              price: revenue,
            ),
          ] : null,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Analytics: Failed to log purchase event: $e');
        }
      }
    }
  }

  /// Track conversion funnel events for KPI monitoring
  Future<void> trackConversionFunnel({
    required String stage,
    required String context,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? properties,
  }) async {
    await logEvent('conversion_funnel', {
      'stage': stage,
      'context': context,
      'user_id': userId,
      'session_id': sessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'user_locale': _getUserLocale(),
      ...?properties,
    });
  }

  /// Track user engagement metrics for retention analysis
  Future<void> trackEngagementMetric({
    required String metricName,
    required dynamic value,
    String? context,
    Map<String, dynamic>? properties,
  }) async {
    await logEvent('engagement_metric', {
      'metric_name': metricName,
      'value': value,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'user_locale': _getUserLocale(),
      ...?properties,
    });
  }

  /// Track cohort-specific events for retention analysis
  Future<void> trackCohortEvent({
    required String cohortId,
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    await logEvent('cohort_event', {
      'cohort_id': cohortId,
      'event_name': eventName,
      'timestamp': DateTime.now().toIso8601String(),
      'user_locale': _getUserLocale(),
      ...?properties,
    });
  }

  /// Get event queue for processing
  List<AnalyticsEvent> getEventQueue() {
    return List.unmodifiable(_eventQueue);
  }

  /// Clear processed events
  void clearEventQueue() {
    _eventQueue.clear();
    notifyListeners();
  }
}

/// Base analytics event class
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    required this.properties,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// App lifecycle events
  factory AnalyticsEvent.appStarted() => AnalyticsEvent(
    name: 'app_started',
    properties: {},
  );

  factory AnalyticsEvent.appBackgrounded() => AnalyticsEvent(
    name: 'app_backgrounded',
    properties: {},
  );

  /// Analytics control events
  factory AnalyticsEvent.analyticsEnabled() => AnalyticsEvent(
    name: 'analytics_enabled',
    properties: {},
  );

  factory AnalyticsEvent.analyticsDisabled() => AnalyticsEvent(
    name: 'analytics_disabled',
    properties: {},
  );

  /// Monetization events
  factory AnalyticsEvent.monetization({
    required String action,
    Map<String, dynamic>? properties,
  }) => AnalyticsEvent(
    name: 'monetization_$action',
    properties: properties ?? {},
  );

  /// Engagement events
  factory AnalyticsEvent.engagement({
    required String action,
    Map<String, dynamic>? properties,
  }) => AnalyticsEvent(
    name: 'engagement_$action',
    properties: properties ?? {},
  );

  /// Feature usage events
  factory AnalyticsEvent.feature({
    required String featureName,
    required String action,
    Map<String, dynamic>? properties,
  }) => AnalyticsEvent(
    name: 'feature_${featureName}_$action',
    properties: properties ?? {},
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'properties': properties,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Helper function to get the current user locale
String _getUserLocale() {
  try {
    return WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
  } catch (e) {
    return 'en'; // fallback to English
  }
}

/// Monetization-specific event types
class MonetizationEvent {
  final String action;
  final Map<String, dynamic> properties;

  MonetizationEvent(this.action, [this.properties = const {}]);

  // Ad-related events
  static MonetizationEvent adRequested({String? placement}) => 
    MonetizationEvent('ad_requested', {'placement': placement});
  
  static MonetizationEvent adShown({String? placement, String? format}) => 
    MonetizationEvent('ad_shown', {'placement': placement, 'format': format});
  
  static MonetizationEvent adClicked({String? placement}) => 
    MonetizationEvent('ad_clicked', {'placement': placement});
  
  static MonetizationEvent adDismissed({String? placement}) => 
    MonetizationEvent('ad_dismissed', {'placement': placement});

  // Premium/pricing events
  static MonetizationEvent upgradePromptShown({String? context, String? featureBlocked, String? userTier}) => 
    MonetizationEvent('upgrade_prompt_shown', {
      'context': context,
      'feature_blocked': featureBlocked,
      'user_tier': userTier,
      'user_locale': _getUserLocale(),
    });
  
  static MonetizationEvent upgradeStarted({
    String? tier, 
    String? context, 
    String? pricePoint,
    String? planTerm,
    String? region,
    bool? perUser,
    int? seats,
    double? basePrice,
    double? localizedPrice,
  }) => 
    MonetizationEvent('upgrade_started', {
      'tier': tier,
      'context': context,
      'price_point': pricePoint,
      'plan_term': planTerm,
      'region': region,
      'per_user': perUser,
      'seats': seats,
      'base_price': basePrice,
      'localized_price': localizedPrice,
      'user_locale': _getUserLocale(),
    });
  
  static MonetizationEvent upgradeCompleted({
    String? tier, 
    String? transactionId, 
    String? pricePaid,
    String? planTerm,
    String? region,
    bool? perUser,
    int? seats,
    double? basePrice,
    double? localizedPrice,
  }) => 
    MonetizationEvent('upgrade_completed', {
      'tier': tier,
      'transaction_id': transactionId,
      'price_paid': pricePaid,
      'plan_term': planTerm,
      'region': region,
      'per_user': perUser,
      'seats': seats,
      'base_price': basePrice,
      'localized_price': localizedPrice,
      'user_locale': _getUserLocale(),
    });
  
  static MonetizationEvent upgradeCancelled({String? tier, String? stage, String? reason}) => 
    MonetizationEvent('upgrade_cancelled', {
      'tier': tier,
      'stage': stage,
      'reason': reason,
    });

  static MonetizationEvent restorePurchases({String? source}) => 
    MonetizationEvent('restore_purchases', {'source': source});

  // Feature limit events
  static MonetizationEvent featureLimitReached({String? feature, int? currentUsage, int? limit, String? userTier}) => 
    MonetizationEvent('feature_limit_reached', {
      'feature': feature,
      'current_usage': currentUsage,
      'limit': limit,
      'user_tier': userTier,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent premiumFeatureUsed({String? feature, String? userTier}) => 
    MonetizationEvent('premium_feature_used', {
      'feature': feature,
      'user_tier': userTier,
      'user_locale': _getUserLocale(),
    });

  // Trial-related events
  static MonetizationEvent trialStarted({String? tier, String? trialType, int? durationDays, String? context, String? promoCode}) => 
    MonetizationEvent('trial_started', {
      'tier': tier,
      'trial_type': trialType,
      'duration_days': durationDays,
      'context': context,
      'promo_code': promoCode,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent trialExpired({String? tier, String? trialType, int? durationDays}) => 
    MonetizationEvent('trial_expired', {
      'tier': tier,
      'trial_type': trialType,
      'duration_days': durationDays,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent trialExtended({String? tier, int? additionalDays, String? reason}) => 
    MonetizationEvent('trial_extended', {
      'tier': tier,
      'additional_days': additionalDays,
      'reason': reason,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent trialConverted({String? trialTier, String? subscribedTier, int? trialDurationDays, int? conversionDay, String? paymentMethod, double? amount}) => 
    MonetizationEvent('trial_converted', {
      'trial_tier': trialTier,
      'subscribed_tier': subscribedTier,
      'trial_duration_days': trialDurationDays,
      'conversion_day': conversionDay,
      'payment_method': paymentMethod,
      'amount': amount,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent trialCancelled({String? tier, String? reason, int? daysUsed}) => 
    MonetizationEvent('trial_cancelled', {
      'tier': tier,
      'reason': reason,
      'days_used': daysUsed,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent conversionAttempted({String? tier, String? context, int? attemptNumber, bool? hasActiveTrial}) => 
    MonetizationEvent('conversion_attempted', {
      'tier': tier,
      'context': context,
      'attempt_number': attemptNumber,
      'has_active_trial': hasActiveTrial,
      'user_locale': _getUserLocale(),
    });

  // Referral-related events
  static MonetizationEvent referralCodeGenerated({String? userId, String? referralCode}) => 
    MonetizationEvent('referral_code_generated', {
      'user_id': userId,
      'referral_code': referralCode,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent referralCodeShared({String? code, String? method}) => 
    MonetizationEvent('referral_code_shared', {
      'code': code,
      'method': method,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent referralCodeUsed({String? code, String? newUserId}) => 
    MonetizationEvent('referral_code_used', {
      'code': code,
      'new_user_id': newUserId,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent referralApplied({String? referrerCode, String? refereeId}) => 
    MonetizationEvent('referral_applied', {
      'referrer_code': referrerCode,
      'referee_id': refereeId,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent referralConverted({String? referrerCode, String? refereeId, double? rewardAmount}) => 
    MonetizationEvent('referral_converted', {
      'referrer_code': referrerCode,
      'referee_id': refereeId,
      'reward_amount': rewardAmount,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent referralRewardClaimed({String? rewardType, double? amount, String? currency}) => 
    MonetizationEvent('referral_reward_claimed', {
      'reward_type': rewardType,
      'amount': amount,
      'currency': currency,
      'user_locale': _getUserLocale(),
    });

  // Coupon-related events
  static MonetizationEvent couponApplied({String? couponCode, String? discountType, double? discountAmount, double? originalPrice, String? tier, String? term}) => 
    MonetizationEvent('coupon_applied', {
      'coupon_code': couponCode,
      'discount_type': discountType,
      'discount_amount': discountAmount,
      'original_price': originalPrice,
      'tier': tier,
      'term': term,
      'user_locale': _getUserLocale(),
    });

  static MonetizationEvent couponValidated({String? couponCode, bool? isValid, String? errorReason}) => 
    MonetizationEvent('coupon_validated', {
      'coupon_code': couponCode,
      'is_valid': isValid,
      'error_reason': errorReason,
      'user_locale': _getUserLocale(),
    });
}

/// Engagement event types
class EngagementEvent {
  final String action;
  final Map<String, dynamic> properties;

  EngagementEvent(this.action, [this.properties = const {}]);

  static EngagementEvent noteCreated() => EngagementEvent('note_created');
  static EngagementEvent noteEdited({int? duration}) => 
    EngagementEvent('note_edited', {'duration_seconds': duration});
  static EngagementEvent noteShared() => EngagementEvent('note_shared');
  static EngagementEvent sessionStarted() => EngagementEvent('session_started');
  static EngagementEvent sessionEnded({int? duration}) => 
    EngagementEvent('session_ended', {'duration_seconds': duration});
}

/// Feature usage event types
class FeatureEvent {
  final String featureName;
  final String action;
  final Map<String, dynamic> properties;

  FeatureEvent(this.featureName, this.action, [this.properties = const {}]);

  static FeatureEvent voiceNote(String action, [Map<String, dynamic>? props]) => 
    FeatureEvent('voice_note', action, props ?? {});
  
  static FeatureEvent doodle(String action, [Map<String, dynamic>? props]) => 
    FeatureEvent('doodle', action, props ?? {});
  
  static FeatureEvent sync(String action, [Map<String, dynamic>? props]) => 
    FeatureEvent('sync', action, props ?? {});
  
  static FeatureEvent backup(String action, [Map<String, dynamic>? props]) => 
    FeatureEvent('backup', action, props ?? {});
}
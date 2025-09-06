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
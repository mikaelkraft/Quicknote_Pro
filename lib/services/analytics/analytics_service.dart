import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Analytics service for tracking monetization and usage events.
/// 
/// Provides a centralized system for collecting and managing analytics events
/// related to user behavior, monetization actions, and feature usage.
class AnalyticsService extends ChangeNotifier {
  static const String _analyticsEnabledKey = 'analytics_enabled';
  
  SharedPreferences? _prefs;
  bool _analyticsEnabled = true;
  final List<AnalyticsEvent> _eventQueue = [];
  final Map<String, int> _eventCounts = {};

  /// Whether analytics tracking is enabled
  bool get analyticsEnabled => _analyticsEnabled;

  /// Event counts for debugging and monitoring
  Map<String, int> get eventCounts => Map.unmodifiable(_eventCounts);

  /// Initialize the analytics service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAnalyticsSettings();
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
    notifyListeners();
    
    if (enabled) {
      trackEvent(AnalyticsEvent.analyticsEnabled());
    } else {
      trackEvent(AnalyticsEvent.analyticsDisabled());
    }
  }

  /// Track an analytics event
  void trackEvent(AnalyticsEvent event) {
    if (!_analyticsEnabled) return;
    
    _eventQueue.add(event);
    _eventCounts[event.name] = (_eventCounts[event.name] ?? 0) + 1;
    
    if (kDebugMode) {
      print('Analytics: ${event.name} - ${event.properties}');
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
  static MonetizationEvent upgradePromptShown({String? context}) => 
    MonetizationEvent('upgrade_prompt_shown', {'context': context});
  
  static MonetizationEvent upgradeStarted({String? tier}) => 
    MonetizationEvent('upgrade_started', {'tier': tier});
  
  static MonetizationEvent upgradeCompleted({String? tier}) => 
    MonetizationEvent('upgrade_completed', {'tier': tier});
  
  static MonetizationEvent upgradeCancelled({String? tier}) => 
    MonetizationEvent('upgrade_cancelled', {'tier': tier});

  // Feature limit events
  static MonetizationEvent featureLimitReached({String? feature}) => 
    MonetizationEvent('feature_limit_reached', {'feature': feature});
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
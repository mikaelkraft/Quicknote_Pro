import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/analytics_event.dart';

/// Service for tracking analytics events and user behavior for monetization insights
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  SharedPreferences? _prefs;
  String? _userId;
  String? _sessionId;
  DateTime? _sessionStartTime;
  final List<AnalyticsEvent> _eventQueue = [];
  bool _isInitialized = false;

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _userId = _prefs!.getString('analytics_user_id') ?? _generateUserId();
    _sessionId = _generateSessionId();
    _sessionStartTime = DateTime.now();
    
    await _prefs!.setString('analytics_user_id', _userId!);
    _isInitialized = true;

    // Track session start
    await trackEvent(
      AnalyticsEvents.sessionStarted,
      properties: {
        AnalyticsProperties.platform: _getPlatform(),
        AnalyticsProperties.appVersion: await _getAppVersion(),
      },
    );
  }

  /// Track an analytics event
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic> properties = const {},
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final event = AnalyticsEvent.create(
      eventName: eventName,
      userId: _userId!,
      properties: {
        ...properties,
        AnalyticsProperties.sessionId: _sessionId,
        AnalyticsProperties.platform: _getPlatform(),
        AnalyticsProperties.appVersion: await _getAppVersion(),
      },
    );

    _eventQueue.add(event);
    await _persistEvent(event);
    
    // In a real implementation, you would also send to analytics backend
    // await _sendToBackend(event);
  }

  /// Track activation events
  Future<void> trackActivation(String eventName, {Map<String, dynamic>? properties}) async {
    await trackEvent(eventName, properties: properties ?? {});
  }

  /// Track retention events
  Future<void> trackRetention(String eventName, {Map<String, dynamic>? properties}) async {
    await trackEvent(eventName, properties: properties ?? {});
  }

  /// Track conversion events
  Future<void> trackConversion(String eventName, {Map<String, dynamic>? properties}) async {
    await trackEvent(eventName, properties: properties ?? {});
  }

  /// Track premium feature blocking
  Future<void> trackPremiumBlock(String featureName) async {
    await trackConversion(
      AnalyticsEvents.premiumFeatureBlocked,
      properties: {
        AnalyticsProperties.featureName: featureName,
      },
    );
  }

  /// Track purchase flow events
  Future<void> trackPurchaseEvent(String eventName, {
    String? subscriptionType,
    String? price,
    String? currency,
    String? errorCode,
    String? errorMessage,
  }) async {
    final properties = <String, dynamic>{};
    
    if (subscriptionType != null) {
      properties[AnalyticsProperties.subscriptionType] = subscriptionType;
    }
    if (price != null) {
      properties[AnalyticsProperties.purchasePrice] = price;
    }
    if (currency != null) {
      properties[AnalyticsProperties.currency] = currency;
    }
    if (errorCode != null) {
      properties[AnalyticsProperties.errorCode] = errorCode;
    }
    if (errorMessage != null) {
      properties[AnalyticsProperties.errorMessage] = errorMessage;
    }

    await trackConversion(eventName, properties: properties);
  }

  /// Track ad events
  Future<void> trackAdEvent(String eventName, {
    String? adFormat,
    String? adPlacement,
    String? adProvider,
    String? impressionId,
    String? errorCode,
  }) async {
    final properties = <String, dynamic>{};
    
    if (adFormat != null) {
      properties[AnalyticsProperties.adFormat] = adFormat;
    }
    if (adPlacement != null) {
      properties[AnalyticsProperties.adPlacement] = adPlacement;
    }
    if (adProvider != null) {
      properties[AnalyticsProperties.adProvider] = adProvider;
    }
    if (impressionId != null) {
      properties[AnalyticsProperties.impressionId] = impressionId;
    }
    if (errorCode != null) {
      properties[AnalyticsProperties.errorCode] = errorCode;
    }

    await trackEvent(eventName, properties: properties);
  }

  /// Get user metrics for monetization analysis
  Future<Map<String, dynamic>> getUserMetrics() async {
    final events = await _getStoredEvents();
    final now = DateTime.now();
    final sessionDuration = _sessionStartTime != null
        ? now.difference(_sessionStartTime!).inMinutes
        : 0;

    // Calculate metrics
    final notesCreated = events.where((e) => e.eventName == AnalyticsEvents.noteCreated).length;
    final voiceNotesCreated = events.where((e) => e.eventName == AnalyticsEvents.voiceNoteCreated).length;
    final drawingsCreated = events.where((e) => e.eventName == AnalyticsEvents.drawingCreated).length;
    final premiumBlockedCount = events.where((e) => e.eventName == AnalyticsEvents.premiumFeatureBlocked).length;
    final upgradeAttempts = events.where((e) => e.eventName == AnalyticsEvents.upgradeButtonTapped).length;

    return {
      'user_id': _userId,
      'session_duration_minutes': sessionDuration,
      'notes_created': notesCreated,
      'voice_notes_created': voiceNotesCreated,
      'drawings_created': drawingsCreated,
      'premium_blocks_count': premiumBlockedCount,
      'upgrade_attempts': upgradeAttempts,
      'total_events': events.length,
    };
  }

  /// End current session and track session metrics
  Future<void> endSession() async {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      await trackEvent(
        AnalyticsEvents.sessionEnded,
        properties: {
          'session_duration_seconds': sessionDuration.inSeconds,
          'session_duration_minutes': sessionDuration.inMinutes,
        },
      );
    }
  }

  /// Clear analytics data (for testing or privacy)
  Future<void> clearData() async {
    await _prefs?.remove('analytics_events');
    _eventQueue.clear();
  }

  // Private helper methods
  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'user_$timestamp';
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'session_$timestamp';
  }

  String _getPlatform() {
    // In a real implementation, detect actual platform
    return 'flutter';
  }

  Future<String> _getAppVersion() async {
    // In a real implementation, get from package_info
    return '1.0.0';
  }

  Future<void> _persistEvent(AnalyticsEvent event) async {
    final events = await _getStoredEvents();
    events.add(event);
    
    // Keep only last 1000 events to manage storage
    if (events.length > 1000) {
      events.removeRange(0, events.length - 1000);
    }
    
    final eventsJson = events.map((e) => e.toJson()).toList();
    await _prefs?.setString('analytics_events', jsonEncode(eventsJson));
  }

  Future<List<AnalyticsEvent>> _getStoredEvents() async {
    final eventsData = _prefs?.getString('analytics_events');
    if (eventsData == null) return [];

    try {
      final eventsList = jsonDecode(eventsData) as List;
      return eventsList
          .map((eventJson) => AnalyticsEvent.fromJson(eventJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
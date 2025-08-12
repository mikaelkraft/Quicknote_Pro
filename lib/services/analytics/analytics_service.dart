import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/analytics_event.dart';
import '../../models/analytics_event_type.dart';

/// Service for managing analytics events with privacy controls and error handling.
/// 
/// This service provides centralized analytics tracking for monetization and usage
/// insights while ensuring user privacy and handling failures gracefully.
class AnalyticsService extends ChangeNotifier {
  static const String _consentKey = 'analytics_consent';
  static const String _sessionIdKey = 'analytics_session_id';
  static const String _pendingEventsKey = 'pending_analytics_events';
  static const String _eventCountKey = 'analytics_event_count';
  static const String _lastEventTimeKey = 'last_analytics_event_time';
  
  static const int _maxPendingEvents = 100;
  static const int _batchSize = 10;
  static const Duration _batchDelay = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(minutes: 1);
  static const int _maxRetries = 3;

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _userConsent = false;
  String _currentSessionId = '';
  Timer? _batchTimer;
  Timer? _retryTimer;
  bool _isProcessingBatch = false;
  
  final List<AnalyticsEvent> _pendingEvents = [];
  final Map<String, int> _retryCount = {};
  
  /// Whether analytics tracking is enabled
  bool get isEnabled => _userConsent && _isInitialized;
  
  /// Current user consent status
  bool get userConsent => _userConsent;
  
  /// Current session ID
  String get sessionId => _currentSessionId;
  
  /// Number of pending events
  int get pendingEventCount => _pendingEvents.length;
  
  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadUserConsent();
      await _loadSessionId();
      await _loadPendingEvents();
      
      _isInitialized = true;
      _startBatchTimer();
      
      // Track session start
      if (_userConsent) {
        await trackEvent(AnalyticsEventType.sessionStarted);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Analytics initialization failed: $e');
      _handleError('initialization_failed', e);
    }
  }

  /// Set user consent for analytics tracking
  Future<void> setUserConsent(bool consent) async {
    if (!_isInitialized) {
      throw StateError('Analytics service not initialized');
    }
    
    final previousConsent = _userConsent;
    _userConsent = consent;
    
    try {
      await _prefs!.setBool(_consentKey, consent);
      
      if (!previousConsent && consent) {
        // User just opted in - start tracking
        await trackEvent(AnalyticsEventType.sessionStarted);
      } else if (previousConsent && !consent) {
        // User opted out - clear pending events
        await _clearPendingEvents();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save consent preference: $e');
      _userConsent = previousConsent; // Revert on error
      _handleError('consent_save_failed', e);
    }
  }

  /// Track an analytics event
  Future<void> trackEvent(
    AnalyticsEventType eventType, {
    String? label,
    double? value,
    String? entryPoint,
    String? method,
    bool? conversion,
    String? errorCode,
    Map<String, dynamic> properties = const {},
  }) async {
    if (!_isInitialized) {
      debugPrint('Analytics not initialized, queueing event: ${eventType.value}');
      return;
    }

    if (!_userConsent) {
      debugPrint('User has not consented to analytics');
      return;
    }

    try {
      final event = AnalyticsEvent.create(
        eventType: eventType.value,
        category: eventType.category,
        action: eventType.value,
        label: label,
        value: value,
        entryPoint: entryPoint,
        method: method,
        conversion: conversion,
        errorCode: errorCode,
        properties: properties,
        sessionId: _currentSessionId,
        userConsent: _userConsent,
      );

      await _queueEvent(event);
      await _updateEventStats(event);
      
      // Process high priority events immediately
      if (eventType.isHighPriority) {
        await _processBatch(force: true);
      }
      
    } catch (e) {
      debugPrint('Failed to track event ${eventType.value}: $e');
      _handleError('event_tracking_failed', e);
    }
  }

  /// Track a monetization event with specific properties
  Future<void> trackMonetizationEvent(
    AnalyticsEventType eventType, {
    required String entryPoint,
    String? productId,
    double? price,
    String? currency,
    bool? conversion,
    String? errorCode,
    Map<String, dynamic> additionalProperties = const {},
  }) async {
    final properties = Map<String, dynamic>.from(additionalProperties);
    if (productId != null) properties['product_id'] = productId;
    if (price != null) properties['price'] = price;
    if (currency != null) properties['currency'] = currency;

    await trackEvent(
      eventType,
      entryPoint: entryPoint,
      value: price,
      conversion: conversion,
      errorCode: errorCode,
      properties: properties,
    );
  }

  /// Track a usage event with context
  Future<void> trackUsageEvent(
    AnalyticsEventType eventType, {
    required String entryPoint,
    String? method,
    String? label,
    int? count,
    Map<String, dynamic> additionalProperties = const {},
  }) async {
    final properties = Map<String, dynamic>.from(additionalProperties);
    if (count != null) properties['count'] = count;

    await trackEvent(
      eventType,
      entryPoint: entryPoint,
      method: method,
      label: label,
      value: count?.toDouble(),
      properties: properties,
    );
  }

  /// Track an error event
  Future<void> trackErrorEvent(
    AnalyticsEventType eventType,
    String errorCode, {
    String? entryPoint,
    String? errorMessage,
    Map<String, dynamic> additionalProperties = const {},
  }) async {
    final properties = Map<String, dynamic>.from(additionalProperties);
    if (errorMessage != null) properties['error_message'] = errorMessage;

    await trackEvent(
      eventType,
      entryPoint: entryPoint,
      errorCode: errorCode,
      properties: properties,
    );
  }

  /// Get analytics statistics
  Future<Map<String, dynamic>> getAnalyticsStats() async {
    if (!_isInitialized) return {};

    try {
      final eventCount = _prefs!.getInt(_eventCountKey) ?? 0;
      final lastEventTime = _prefs!.getString(_lastEventTimeKey);
      
      return {
        'total_events': eventCount,
        'pending_events': _pendingEvents.length,
        'last_event_time': lastEventTime,
        'current_session': _currentSessionId,
        'user_consent': _userConsent,
        'is_enabled': isEnabled,
      };
    } catch (e) {
      debugPrint('Failed to get analytics stats: $e');
      return {};
    }
  }

  /// Clear all analytics data (for privacy compliance)
  Future<void> clearAllData() async {
    if (!_isInitialized) return;

    try {
      await _clearPendingEvents();
      await _prefs!.remove(_eventCountKey);
      await _prefs!.remove(_lastEventTimeKey);
      
      _pendingEvents.clear();
      _retryCount.clear();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear analytics data: $e');
      _handleError('data_clear_failed', e);
    }
  }

  /// Dispose of the service and cleanup resources
  @override
  void dispose() {
    _batchTimer?.cancel();
    _retryTimer?.cancel();
    
    // Track session end if consent given
    if (_userConsent && _isInitialized) {
      trackEvent(AnalyticsEventType.sessionEnded);
    }
    
    super.dispose();
  }

  // Private methods

  Future<void> _loadUserConsent() async {
    _userConsent = _prefs!.getBool(_consentKey) ?? false;
  }

  Future<void> _loadSessionId() async {
    _currentSessionId = _prefs!.getString(_sessionIdKey) ?? _generateSessionId();
    await _prefs!.setString(_sessionIdKey, _currentSessionId);
  }

  Future<void> _loadPendingEvents() async {
    try {
      final pendingEventsJson = _prefs!.getStringList(_pendingEventsKey) ?? [];
      _pendingEvents.clear();
      
      for (final eventJson in pendingEventsJson) {
        try {
          final event = AnalyticsEvent.fromJsonString(eventJson);
          _pendingEvents.add(event);
        } catch (e) {
          debugPrint('Failed to parse pending event: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to load pending events: $e');
    }
  }

  Future<void> _queueEvent(AnalyticsEvent event) async {
    _pendingEvents.add(event);
    
    // Limit pending events to prevent memory issues
    if (_pendingEvents.length > _maxPendingEvents) {
      _pendingEvents.removeRange(0, _pendingEvents.length - _maxPendingEvents);
    }
    
    await _savePendingEvents();
  }

  Future<void> _savePendingEvents() async {
    try {
      final eventJsonList = _pendingEvents
          .map((event) => event.toJsonString())
          .toList();
      await _prefs!.setStringList(_pendingEventsKey, eventJsonList);
    } catch (e) {
      debugPrint('Failed to save pending events: $e');
    }
  }

  Future<void> _updateEventStats(AnalyticsEvent event) async {
    try {
      final currentCount = _prefs!.getInt(_eventCountKey) ?? 0;
      await _prefs!.setInt(_eventCountKey, currentCount + 1);
      await _prefs!.setString(_lastEventTimeKey, event.timestamp.toIso8601String());
    } catch (e) {
      debugPrint('Failed to update event stats: $e');
    }
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchDelay, (_) => _processBatch());
  }

  Future<void> _processBatch({bool force = false}) async {
    if (_isProcessingBatch) return;
    if (_pendingEvents.isEmpty) return;
    if (!_userConsent && !force) return;

    _isProcessingBatch = true;

    try {
      final batchSize = force ? _pendingEvents.length : _batchSize;
      final batch = _pendingEvents.take(batchSize).toList();
      
      if (batch.isNotEmpty) {
        await _sendEventBatch(batch);
        _pendingEvents.removeRange(0, batch.length);
        await _savePendingEvents();
      }
    } catch (e) {
      debugPrint('Batch processing failed: $e');
      _handleError('batch_processing_failed', e);
    } finally {
      _isProcessingBatch = false;
    }
  }

  Future<void> _sendEventBatch(List<AnalyticsEvent> events) async {
    // In a real implementation, this would send events to an analytics service
    // For now, we'll just log them (privacy-safe logging)
    
    if (kDebugMode) {
      debugPrint('Analytics batch (${events.length} events):');
      for (final event in events) {
        debugPrint('  ${event.eventType}: ${event.category}/${event.action}');
      }
    }
    
    // Simulate network call with potential failure
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Simulate random failures for testing error handling
    if (kDebugMode && Random().nextDouble() < 0.1) {
      throw Exception('Simulated network error');
    }
  }

  Future<void> _clearPendingEvents() async {
    _pendingEvents.clear();
    await _prefs!.remove(_pendingEventsKey);
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000000);
    return 'session_${timestamp}_$random';
  }

  void _handleError(String errorType, dynamic error) {
    if (kDebugMode) {
      debugPrint('Analytics error [$errorType]: $error');
    }
    
    // Track analytics errors (if consent given and not an infinite loop)
    if (_userConsent && errorType != 'event_tracking_failed') {
      try {
        trackErrorEvent(
          AnalyticsEventType.appError,
          errorType,
          errorMessage: error.toString(),
        );
      } catch (e) {
        debugPrint('Failed to track analytics error: $e');
      }
    }
  }
}
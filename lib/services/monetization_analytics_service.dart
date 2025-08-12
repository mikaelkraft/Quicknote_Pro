import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pricing_tier_service.dart';

/// Analytics service specifically for monetization events
class MonetizationAnalyticsService {
  static const String _analyticsKey = 'monetization_analytics';
  static const String _sessionKey = 'analytics_session_id';
  
  SharedPreferences? _prefs;
  String? _sessionId;
  final List<Map<String, dynamic>> _eventQueue = [];
  Timer? _flushTimer;
  
  /// Initialize the analytics service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionId = _generateSessionId();
    
    // Start periodic flush of events
    _flushTimer = Timer.periodic(const Duration(minutes: 5), (_) => _flushEvents());
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'session_${timestamp}_$random';
  }

  /// Track a monetization event
  void trackEvent(MonetizationEvent event, Map<String, dynamic> data) {
    if (_prefs == null) return;
    
    final eventData = {
      'event_name': event.name,
      'session_id': _sessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'client_timestamp': DateTime.now().millisecondsSinceEpoch,
      'platform': _getPlatform(),
      'app_version': '1.0.0', // This should come from package info
      ...data,
    };
    
    _eventQueue.add(eventData);
    
    // Log in debug mode
    if (kDebugMode) {
      print('📊 Analytics Event: ${event.name}');
      print('   Data: ${jsonEncode(eventData)}');
    }
    
    // Flush immediately for critical events
    if (_isCriticalEvent(event)) {
      _flushEvents();
    }
  }

  /// Check if event should be flushed immediately
  bool _isCriticalEvent(MonetizationEvent event) {
    return [
      MonetizationEvent.upgradeCompleted,
      MonetizationEvent.upgradeFailed,
      MonetizationEvent.trialStarted,
    ].contains(event);
  }

  /// Get current platform string
  String _getPlatform() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.toString().split('.').last;
  }

  /// Flush events to persistent storage
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty || _prefs == null) return;
    
    try {
      // Load existing events
      final existingEventsJson = _prefs!.getString(_analyticsKey) ?? '[]';
      final existingEvents = jsonDecode(existingEventsJson) as List;
      
      // Add new events
      existingEvents.addAll(_eventQueue);
      
      // Keep only last 1000 events to prevent storage bloat
      if (existingEvents.length > 1000) {
        existingEvents.removeRange(0, existingEvents.length - 1000);
      }
      
      // Save back to storage
      await _prefs!.setString(_analyticsKey, jsonEncode(existingEvents));
      
      if (kDebugMode) {
        print('📊 Flushed ${_eventQueue.length} analytics events');
      }
      
      _eventQueue.clear();
    } catch (e) {
      if (kDebugMode) {
        print('📊 Error flushing analytics events: $e');
      }
    }
  }

  /// Get all stored events (for export or debugging)
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    if (_prefs == null) return [];
    
    try {
      final eventsJson = _prefs!.getString(_analyticsKey) ?? '[]';
      final events = jsonDecode(eventsJson) as List;
      return events.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('📊 Error loading analytics events: $e');
      }
      return [];
    }
  }

  /// Get events filtered by date range
  Future<List<Map<String, dynamic>>> getEventsByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allEvents = await getAllEvents();
    
    return allEvents.where((event) {
      final timestampStr = event['timestamp'] as String?;
      if (timestampStr == null) return false;
      
      try {
        final timestamp = DateTime.parse(timestampStr);
        
        if (startDate != null && timestamp.isBefore(startDate)) {
          return false;
        }
        
        if (endDate != null && timestamp.isAfter(endDate)) {
          return false;
        }
        
        return true;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Get analytics summary for the last 30 days
  Future<Map<String, dynamic>> getMonetizationSummary() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final events = await getEventsByDateRange(startDate: thirtyDaysAgo);
    
    final summary = <String, dynamic>{
      'total_events': events.length,
      'period_days': 30,
      'events_by_type': <String, int>{},
      'conversion_funnel': _calculateConversionFunnel(events),
      'limit_reached_events': _getLimitReachedSummary(events),
      'trial_metrics': _getTrialMetrics(events),
      'upgrade_metrics': _getUpgradeMetrics(events),
    };
    
    // Count events by type
    for (final event in events) {
      final eventName = event['event_name'] as String? ?? 'unknown';
      summary['events_by_type'][eventName] = 
          (summary['events_by_type'][eventName] ?? 0) + 1;
    }
    
    return summary;
  }

  /// Calculate conversion funnel metrics
  Map<String, dynamic> _calculateConversionFunnel(List<Map<String, dynamic>> events) {
    final limitReached = events.where((e) => e['event_name'] == 'freeLimitReached').length;
    final upgradeInitiated = events.where((e) => e['event_name'] == 'upgradeInitiated').length;
    final upgradeCompleted = events.where((e) => e['event_name'] == 'upgradeCompleted').length;
    
    return {
      'limit_reached': limitReached,
      'upgrade_initiated': upgradeInitiated,
      'upgrade_completed': upgradeCompleted,
      'limit_to_initiate_rate': limitReached > 0 ? upgradeInitiated / limitReached : 0.0,
      'initiate_to_complete_rate': upgradeInitiated > 0 ? upgradeCompleted / upgradeInitiated : 0.0,
      'overall_conversion_rate': limitReached > 0 ? upgradeCompleted / limitReached : 0.0,
    };
  }

  /// Get summary of limit reached events
  Map<String, dynamic> _getLimitReachedSummary(List<Map<String, dynamic>> events) {
    final limitEvents = events.where((e) => e['event_name'] == 'freeLimitReached');
    final featureCounts = <String, int>{};
    
    for (final event in limitEvents) {
      final feature = event['feature'] as String? ?? 'unknown';
      featureCounts[feature] = (featureCounts[feature] ?? 0) + 1;
    }
    
    return {
      'total_limit_events': limitEvents.length,
      'by_feature': featureCounts,
      'most_limited_feature': featureCounts.isNotEmpty 
          ? featureCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// Get trial-related metrics
  Map<String, dynamic> _getTrialMetrics(List<Map<String, dynamic>> events) {
    final trialStarted = events.where((e) => e['event_name'] == 'trialStarted').length;
    final trialExpired = events.where((e) => e['event_name'] == 'trialExpired').length;
    
    return {
      'trials_started': trialStarted,
      'trials_expired': trialExpired,
      'trial_conversion_rate': trialStarted > 0 
          ? events.where((e) => e['event_name'] == 'upgradeCompleted').length / trialStarted
          : 0.0,
    };
  }

  /// Get upgrade-related metrics
  Map<String, dynamic> _getUpgradeMetrics(List<Map<String, dynamic>> events) {
    final upgradeEvents = events.where((e) => e['event_name'] == 'upgradeCompleted');
    final failedEvents = events.where((e) => e['event_name'] == 'upgradeFailed');
    
    final productCounts = <String, int>{};
    final sourceCounts = <String, int>{};
    
    for (final event in upgradeEvents) {
      final productId = event['product_id'] as String? ?? 'unknown';
      final source = event['source'] as String? ?? 'unknown';
      
      productCounts[productId] = (productCounts[productId] ?? 0) + 1;
      sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
    }
    
    return {
      'successful_upgrades': upgradeEvents.length,
      'failed_upgrades': failedEvents.length,
      'success_rate': (upgradeEvents.length + failedEvents.length) > 0
          ? upgradeEvents.length / (upgradeEvents.length + failedEvents.length)
          : 0.0,
      'by_product': productCounts,
      'by_source': sourceCounts,
    };
  }

  /// Export analytics data for external analysis
  Future<String> exportAnalyticsData({DateTime? startDate, DateTime? endDate}) async {
    final events = await getEventsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    
    final exportData = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'export_range': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
      'event_count': events.length,
      'events': events,
    };
    
    return jsonEncode(exportData);
  }

  /// Clear old analytics data
  Future<void> clearOldData({int keepDays = 90}) async {
    if (_prefs == null) return;
    
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    final events = await getEventsByDateRange(startDate: cutoffDate);
    
    await _prefs!.setString(_analyticsKey, jsonEncode(events));
    
    if (kDebugMode) {
      print('📊 Cleared analytics data older than $keepDays days');
    }
  }

  /// Clear all analytics data
  Future<void> clearAllData() async {
    if (_prefs == null) return;
    
    await _prefs!.remove(_analyticsKey);
    _eventQueue.clear();
    
    if (kDebugMode) {
      print('📊 Cleared all analytics data');
    }
  }

  /// Dispose of the service
  void dispose() {
    _flushTimer?.cancel();
    _flushEvents(); // Final flush
  }
}
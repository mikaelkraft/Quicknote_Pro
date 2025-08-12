import 'dart:convert';

/// Analytics event model that captures user interactions for monetization and usage tracking.
/// 
/// This model is designed to be privacy-compliant and provides structured data
/// for business insights while protecting user privacy.
class AnalyticsEvent {
  /// Unique identifier for the event instance
  final String eventId;
  
  /// Type of event (from AnalyticsEventType enum)
  final String eventType;
  
  /// Category of the event (monetization, usage, feature, etc.)
  final String category;
  
  /// Specific action taken by the user
  final String action;
  
  /// Optional label for additional context
  final String? label;
  
  /// Numerical value associated with the event (price, count, etc.)
  final double? value;
  
  /// Entry point where the user initiated this action
  final String? entryPoint;
  
  /// Method used to complete the action
  final String? method;
  
  /// Whether the action resulted in a conversion
  final bool? conversion;
  
  /// Error code if the action failed
  final String? errorCode;
  
  /// Additional properties for context
  final Map<String, dynamic> properties;
  
  /// Timestamp when the event occurred
  final DateTime timestamp;
  
  /// Session identifier to group related events
  final String sessionId;
  
  /// User consent status for analytics tracking
  final bool userConsent;

  const AnalyticsEvent({
    required this.eventId,
    required this.eventType,
    required this.category,
    required this.action,
    this.label,
    this.value,
    this.entryPoint,
    this.method,
    this.conversion,
    this.errorCode,
    this.properties = const {},
    required this.timestamp,
    required this.sessionId,
    required this.userConsent,
  });

  /// Create a new analytics event with auto-generated ID and timestamp
  factory AnalyticsEvent.create({
    required String eventType,
    required String category,
    required String action,
    String? label,
    double? value,
    String? entryPoint,
    String? method,
    bool? conversion,
    String? errorCode,
    Map<String, dynamic> properties = const {},
    required String sessionId,
    required bool userConsent,
  }) {
    final now = DateTime.now();
    final eventId = 'event_${now.millisecondsSinceEpoch}_${now.microsecond}';
    
    return AnalyticsEvent(
      eventId: eventId,
      eventType: eventType,
      category: category,
      action: action,
      label: label,
      value: value,
      entryPoint: entryPoint,
      method: method,
      conversion: conversion,
      errorCode: errorCode,
      properties: Map.from(properties),
      timestamp: now,
      sessionId: sessionId,
      userConsent: userConsent,
    );
  }

  /// Create a copy of the event with updated fields
  AnalyticsEvent copyWith({
    String? eventId,
    String? eventType,
    String? category,
    String? action,
    String? label,
    double? value,
    String? entryPoint,
    String? method,
    bool? conversion,
    String? errorCode,
    Map<String, dynamic>? properties,
    DateTime? timestamp,
    String? sessionId,
    bool? userConsent,
  }) {
    return AnalyticsEvent(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      category: category ?? this.category,
      action: action ?? this.action,
      label: label ?? this.label,
      value: value ?? this.value,
      entryPoint: entryPoint ?? this.entryPoint,
      method: method ?? this.method,
      conversion: conversion ?? this.conversion,
      errorCode: errorCode ?? this.errorCode,
      properties: properties ?? Map.from(this.properties),
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      userConsent: userConsent ?? this.userConsent,
    );
  }

  /// Convert event to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'category': category,
      'action': action,
      'label': label,
      'value': value,
      'entryPoint': entryPoint,
      'method': method,
      'conversion': conversion,
      'errorCode': errorCode,
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'userConsent': userConsent,
    };
  }

  /// Create event from JSON
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventId: json['eventId'] as String,
      eventType: json['eventType'] as String,
      category: json['category'] as String,
      action: json['action'] as String,
      label: json['label'] as String?,
      value: json['value'] as double?,
      entryPoint: json['entryPoint'] as String?,
      method: json['method'] as String?,
      conversion: json['conversion'] as bool?,
      errorCode: json['errorCode'] as String?,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['sessionId'] as String,
      userConsent: json['userConsent'] as bool,
    );
  }

  /// Convert event to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create event from JSON string
  factory AnalyticsEvent.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AnalyticsEvent.fromJson(json);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId;

  @override
  int get hashCode => eventId.hashCode;

  @override
  String toString() {
    return 'AnalyticsEvent{eventId: $eventId, eventType: $eventType, '
           'category: $category, action: $action, timestamp: $timestamp}';
  }

  /// Check if the event should be tracked based on user consent
  bool get shouldTrack => userConsent;

  /// Get a privacy-safe version of the event (removes PII)
  AnalyticsEvent get privacySafe {
    // Remove any potentially sensitive properties
    final safeProperties = Map<String, dynamic>.from(properties);
    safeProperties.removeWhere((key, value) => 
        key.toLowerCase().contains('email') ||
        key.toLowerCase().contains('name') ||
        key.toLowerCase().contains('phone') ||
        key.toLowerCase().contains('address'));

    return copyWith(properties: safeProperties);
  }

  /// Check if this is a monetization-related event
  bool get isMonetizationEvent => 
      category == 'monetization' || 
      eventType.contains('purchase') ||
      eventType.contains('subscription') ||
      eventType.contains('premium');

  /// Check if this is a usage tracking event
  bool get isUsageEvent => 
      category == 'usage' || 
      category == 'feature';

  /// Get event priority for processing (higher number = higher priority)
  int get priority {
    if (isMonetizationEvent) return 3;
    if (errorCode != null) return 2;
    return 1;
  }
}
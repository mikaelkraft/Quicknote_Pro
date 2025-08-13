/// Represents analytics data for ad interactions.
/// 
/// This model tracks comprehensive metrics for ads to enable
/// A/B testing, performance analysis, and revenue optimization.
class AdAnalytics {
  final String eventId;
  final String eventType;
  final String placementId;
  final String adId;
  final String format;
  final DateTime timestamp;
  final Map<String, dynamic> properties;
  final String? userId;
  final String? sessionId;
  final String? abTestVariant;

  const AdAnalytics({
    required this.eventId,
    required this.eventType,
    required this.placementId,
    required this.adId,
    required this.format,
    required this.timestamp,
    this.properties = const {},
    this.userId,
    this.sessionId,
    this.abTestVariant,
  });

  /// Creates an AdAnalytics event from JSON
  factory AdAnalytics.fromJson(Map<String, dynamic> json) {
    return AdAnalytics(
      eventId: json['eventId'] ?? '',
      eventType: json['eventType'] ?? '',
      placementId: json['placementId'] ?? '',
      adId: json['adId'] ?? '',
      format: json['format'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      userId: json['userId'],
      sessionId: json['sessionId'],
      abTestVariant: json['abTestVariant'],
    );
  }

  /// Converts the AdAnalytics event to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'placementId': placementId,
      'adId': adId,
      'format': format,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties,
      'userId': userId,
      'sessionId': sessionId,
      'abTestVariant': abTestVariant,
    };
  }

  /// Creates a copy of the AdAnalytics with optional parameter overrides
  AdAnalytics copyWith({
    String? eventId,
    String? eventType,
    String? placementId,
    String? adId,
    String? format,
    DateTime? timestamp,
    Map<String, dynamic>? properties,
    String? userId,
    String? sessionId,
    String? abTestVariant,
  }) {
    return AdAnalytics(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      placementId: placementId ?? this.placementId,
      adId: adId ?? this.adId,
      format: format ?? this.format,
      timestamp: timestamp ?? this.timestamp,
      properties: properties ?? this.properties,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      abTestVariant: abTestVariant ?? this.abTestVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdAnalytics && other.eventId == eventId;
  }

  @override
  int get hashCode => eventId.hashCode;

  @override
  String toString() {
    return 'AdAnalytics(eventId: $eventId, type: $eventType, placement: $placementId)';
  }
}

/// Aggregated analytics metrics for ads performance.
class AdMetrics {
  final String placementId;
  final String format;
  final DateTime startDate;
  final DateTime endDate;
  final int impressions;
  final int clicks;
  final int dismissals;
  final int conversions;
  final int failures;
  final int blocked;
  final double revenue;
  final Map<String, dynamic> additionalMetrics;

  const AdMetrics({
    required this.placementId,
    required this.format,
    required this.startDate,
    required this.endDate,
    required this.impressions,
    required this.clicks,
    required this.dismissals,
    required this.conversions,
    required this.failures,
    required this.blocked,
    required this.revenue,
    this.additionalMetrics = const {},
  });

  /// Creates AdMetrics from JSON
  factory AdMetrics.fromJson(Map<String, dynamic> json) {
    return AdMetrics(
      placementId: json['placementId'] ?? '',
      format: json['format'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      dismissals: json['dismissals'] ?? 0,
      conversions: json['conversions'] ?? 0,
      failures: json['failures'] ?? 0,
      blocked: json['blocked'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      additionalMetrics: Map<String, dynamic>.from(json['additionalMetrics'] ?? {}),
    );
  }

  /// Converts AdMetrics to JSON
  Map<String, dynamic> toJson() {
    return {
      'placementId': placementId,
      'format': format,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'impressions': impressions,
      'clicks': clicks,
      'dismissals': dismissals,
      'conversions': conversions,
      'failures': failures,
      'blocked': blocked,
      'revenue': revenue,
      'additionalMetrics': additionalMetrics,
    };
  }

  /// Calculates the click-through rate (CTR)
  double get clickThroughRate {
    if (impressions == 0) return 0.0;
    return clicks / impressions;
  }

  /// Calculates the conversion rate
  double get conversionRate {
    if (clicks == 0) return 0.0;
    return conversions / clicks;
  }

  /// Calculates the dismissal rate
  double get dismissalRate {
    if (impressions == 0) return 0.0;
    return dismissals / impressions;
  }

  /// Calculates the failure rate
  double get failureRate {
    final totalAttempts = impressions + failures;
    if (totalAttempts == 0) return 0.0;
    return failures / totalAttempts;
  }

  /// Calculates the effective cost per mille (eCPM)
  double get eCPM {
    if (impressions == 0) return 0.0;
    return (revenue / impressions) * 1000;
  }

  /// Calculates the revenue per user (RPU)
  double get revenuePerUser {
    final users = additionalMetrics['unique_users'] as int? ?? 1;
    return revenue / users;
  }

  /// Creates a copy of AdMetrics with optional parameter overrides
  AdMetrics copyWith({
    String? placementId,
    String? format,
    DateTime? startDate,
    DateTime? endDate,
    int? impressions,
    int? clicks,
    int? dismissals,
    int? conversions,
    int? failures,
    int? blocked,
    double? revenue,
    Map<String, dynamic>? additionalMetrics,
  }) {
    return AdMetrics(
      placementId: placementId ?? this.placementId,
      format: format ?? this.format,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      dismissals: dismissals ?? this.dismissals,
      conversions: conversions ?? this.conversions,
      failures: failures ?? this.failures,
      blocked: blocked ?? this.blocked,
      revenue: revenue ?? this.revenue,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
    );
  }

  @override
  String toString() {
    return 'AdMetrics(placement: $placementId, format: $format, CTR: ${(clickThroughRate * 100).toStringAsFixed(2)}%)';
  }
}

/// Represents frequency capping data for ads.
class AdFrequencyCap {
  final String placementId;
  final String format;
  final int maxAdsPerSession;
  final int maxAdsPerHour;
  final int maxAdsPerDay;
  final int currentSessionCount;
  final int currentHourCount;
  final int currentDayCount;
  final DateTime? lastShownAt;
  final DateTime sessionStartedAt;

  const AdFrequencyCap({
    required this.placementId,
    required this.format,
    required this.maxAdsPerSession,
    required this.maxAdsPerHour,
    required this.maxAdsPerDay,
    required this.currentSessionCount,
    required this.currentHourCount,
    required this.currentDayCount,
    this.lastShownAt,
    required this.sessionStartedAt,
  });

  /// Creates AdFrequencyCap from JSON
  factory AdFrequencyCap.fromJson(Map<String, dynamic> json) {
    return AdFrequencyCap(
      placementId: json['placementId'] ?? '',
      format: json['format'] ?? '',
      maxAdsPerSession: json['maxAdsPerSession'] ?? 10,
      maxAdsPerHour: json['maxAdsPerHour'] ?? 15,
      maxAdsPerDay: json['maxAdsPerDay'] ?? 50,
      currentSessionCount: json['currentSessionCount'] ?? 0,
      currentHourCount: json['currentHourCount'] ?? 0,
      currentDayCount: json['currentDayCount'] ?? 0,
      lastShownAt: json['lastShownAt'] != null ? DateTime.parse(json['lastShownAt']) : null,
      sessionStartedAt: DateTime.parse(json['sessionStartedAt']),
    );
  }

  /// Converts AdFrequencyCap to JSON
  Map<String, dynamic> toJson() {
    return {
      'placementId': placementId,
      'format': format,
      'maxAdsPerSession': maxAdsPerSession,
      'maxAdsPerHour': maxAdsPerHour,
      'maxAdsPerDay': maxAdsPerDay,
      'currentSessionCount': currentSessionCount,
      'currentHourCount': currentHourCount,
      'currentDayCount': currentDayCount,
      'lastShownAt': lastShownAt?.toIso8601String(),
      'sessionStartedAt': sessionStartedAt.toIso8601String(),
    };
  }

  /// Checks if the frequency cap has been reached
  bool get isCapReached {
    return currentSessionCount >= maxAdsPerSession ||
           currentHourCount >= maxAdsPerHour ||
           currentDayCount >= maxAdsPerDay;
  }

  /// Checks if enough time has passed since the last ad for this format
  bool canShowAd(int minimumIntervalMinutes) {
    if (lastShownAt == null) return true;
    final timeSinceLastAd = DateTime.now().difference(lastShownAt!);
    return timeSinceLastAd.inMinutes >= minimumIntervalMinutes;
  }

  /// Creates a copy with incremented counters
  AdFrequencyCap withIncrementedCount() {
    return AdFrequencyCap(
      placementId: placementId,
      format: format,
      maxAdsPerSession: maxAdsPerSession,
      maxAdsPerHour: maxAdsPerHour,
      maxAdsPerDay: maxAdsPerDay,
      currentSessionCount: currentSessionCount + 1,
      currentHourCount: currentHourCount + 1,
      currentDayCount: currentDayCount + 1,
      lastShownAt: DateTime.now(),
      sessionStartedAt: sessionStartedAt,
    );
  }

  /// Creates a copy with reset session counters
  AdFrequencyCap withResetSession() {
    return AdFrequencyCap(
      placementId: placementId,
      format: format,
      maxAdsPerSession: maxAdsPerSession,
      maxAdsPerHour: maxAdsPerHour,
      maxAdsPerDay: maxAdsPerDay,
      currentSessionCount: 0,
      currentHourCount: currentHourCount,
      currentDayCount: currentDayCount,
      lastShownAt: lastShownAt,
      sessionStartedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AdFrequencyCap(placement: $placementId, format: $format, session: $currentSessionCount/$maxAdsPerSession)';
  }
}
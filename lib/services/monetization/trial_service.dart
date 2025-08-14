/// Enhanced trial system for user acquisition and retention.
/// 
/// Manages trial periods, extensions, conversions, and win-back campaigns
/// to maximize user retention and subscription conversions.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_service.dart';
import 'monetization_service.dart';

/// Trial states
enum TrialState {
  none,           // No trial started
  active,         // Currently in trial
  expired,        // Trial expired, not converted
  converted,      // Trial converted to paid
  extended,       // Trial extended with bonus days
  cancelled,      // Trial cancelled by user
}

/// Trial types
enum TrialType {
  standard,       // Standard trial offering
  promotional,    // Special promotional trial
  winback,        // Win-back trial for churned users
  referral,       // Referral reward trial
  retention,      // Retention campaign trial
}

/// Trial configuration
class TrialConfig {
  final UserTier tier;
  final int durationDays;
  final TrialType type;
  final String? promoCode;
  final DateTime? validUntil;
  final Map<String, dynamic> metadata;

  const TrialConfig({
    required this.tier,
    required this.durationDays,
    this.type = TrialType.standard,
    this.promoCode,
    this.validUntil,
    this.metadata = const {},
  });

  /// Check if trial offer is still valid
  bool get isValid => validUntil == null || DateTime.now().isBefore(validUntil!);

  /// Get display name for trial
  String get displayName {
    switch (type) {
      case TrialType.standard:
        return '$durationDays-Day ${tier.name.toUpperCase()} Trial';
      case TrialType.promotional:
        return 'Special $durationDays-Day ${tier.name.toUpperCase()} Trial';
      case TrialType.winback:
        return 'Welcome Back - $durationDays Days Free';
      case TrialType.referral:
        return 'Referral Bonus - $durationDays Days Free';
      case TrialType.retention:
        return 'Exclusive $durationDays-Day Extension';
    }
  }

  /// Get trial description
  String get description {
    switch (type) {
      case TrialType.standard:
        return 'Try all ${tier.name} features free for $durationDays days';
      case TrialType.promotional:
        return 'Limited time offer - Extended ${tier.name} trial';
      case TrialType.winback:
        return 'We miss you! Enjoy ${tier.name} features again';
      case TrialType.retention:
        return 'Enjoy more time to explore ${tier.name} features';
      default:
        return 'Experience ${tier.name} features for $durationDays days';
    }
  }
}

/// Active trial information
class TrialInfo {
  final UserTier tier;
  final TrialType type;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int originalDurationDays;
  final int extensionDays;
  final TrialState state;
  final String? promoCode;
  final Map<String, dynamic> analytics;

  const TrialInfo({
    required this.tier,
    required this.type,
    required this.startedAt,
    required this.expiresAt,
    required this.originalDurationDays,
    this.extensionDays = 0,
    this.state = TrialState.active,
    this.promoCode,
    this.analytics = const {},
  });

  /// Days remaining in trial
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays + 1;
  }

  /// Total trial duration including extensions
  int get totalDurationDays => originalDurationDays + extensionDays;

  /// Progress percentage (0-100)
  double get progressPercentage {
    final totalDuration = expiresAt.difference(startedAt).inDays;
    final elapsed = DateTime.now().difference(startedAt).inDays;
    return ((elapsed / totalDuration) * 100).clamp(0, 100);
  }

  /// Check if trial is about to expire (within 2 days)
  bool get isAboutToExpire => daysRemaining <= 2 && daysRemaining > 0;

  /// Check if trial has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if trial is still active
  bool get isActive => state == TrialState.active && !isExpired;

  /// Create a copy with updated data
  TrialInfo copyWith({
    UserTier? tier,
    TrialType? type,
    DateTime? startedAt,
    DateTime? expiresAt,
    int? originalDurationDays,
    int? extensionDays,
    TrialState? state,
    String? promoCode,
    Map<String, dynamic>? analytics,
  }) {
    return TrialInfo(
      tier: tier ?? this.tier,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      originalDurationDays: originalDurationDays ?? this.originalDurationDays,
      extensionDays: extensionDays ?? this.extensionDays,
      state: state ?? this.state,
      promoCode: promoCode ?? this.promoCode,
      analytics: analytics ?? this.analytics,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'type': type.name,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'original_duration_days': originalDurationDays,
      'extension_days': extensionDays,
      'state': state.name,
      'promo_code': promoCode,
      'analytics': analytics,
    };
  }

  /// Create from JSON
  factory TrialInfo.fromJson(Map<String, dynamic> json) {
    return TrialInfo(
      tier: UserTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => UserTier.premium,
      ),
      type: TrialType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TrialType.standard,
      ),
      startedAt: DateTime.parse(json['started_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      originalDurationDays: json['original_duration_days'] ?? 7,
      extensionDays: json['extension_days'] ?? 0,
      state: TrialState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => TrialState.active,
      ),
      promoCode: json['promo_code'],
      analytics: json['analytics'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Service for managing trials and conversion campaigns
class TrialService extends ChangeNotifier {
  static const String _currentTrialKey = 'current_trial';
  static const String _trialHistoryKey = 'trial_history';
  static const String _trialEligibilityKey = 'trial_eligibility';
  static const String _conversionAttemptsKey = 'conversion_attempts';
  
  SharedPreferences? _prefs;
  TrialInfo? _currentTrial;
  final List<TrialInfo> _trialHistory = [];
  final Map<UserTier, bool> _trialEligibility = {
    for (final tier in UserTier.values) tier: true
  };
  int _conversionAttempts = 0;
  final AnalyticsService _analytics = AnalyticsService();

  /// Current active trial
  TrialInfo? get currentTrial => _currentTrial;

  /// Trial history
  List<TrialInfo> get trialHistory => List.unmodifiable(_trialHistory);

  /// Trial eligibility by tier
  Map<UserTier, bool> get trialEligibility => Map.unmodifiable(_trialEligibility);

  /// Check if user has active trial
  bool get hasActiveTrial => _currentTrial?.isActive == true;

  /// Check if trial is about to expire
  bool get isTrialAboutToExpire => _currentTrial?.isAboutToExpire == true;

  /// Number of conversion attempts
  int get conversionAttempts => _conversionAttempts;

  /// Initialize trial service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCurrentTrial();
    await _loadTrialHistory();
    await _loadTrialEligibility();
    await _loadConversionAttempts();
    await _checkTrialExpiration();
  }

  /// Load current trial from storage
  Future<void> _loadCurrentTrial() async {
    if (_prefs == null) return;
    
    final trialJson = _prefs!.getString(_currentTrialKey);
    if (trialJson != null) {
      try {
        final data = Map<String, dynamic>.from(
          jsonDecode(Uri.decodeComponent(trialJson)) as Map
        );
        _currentTrial = TrialInfo.fromJson(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error loading current trial: $e');
        }
      }
    }
  }

  /// Load trial history from storage
  Future<void> _loadTrialHistory() async {
    if (_prefs == null) return;
    
    final historyJson = _prefs!.getStringList(_trialHistoryKey) ?? [];
    _trialHistory.clear();
    
    for (final json in historyJson) {
      try {
        final data = Map<String, dynamic>.from(
          Uri.decodeComponent(json) as Map
        );
        _trialHistory.add(TrialInfo.fromJson(data));
      } catch (e) {
        if (kDebugMode) {
          print('Error loading trial history: $e');
        }
      }
    }
  }

  /// Load trial eligibility from storage
  Future<void> _loadTrialEligibility() async {
    if (_prefs == null) return;
    
    for (final tier in UserTier.values) {
      _trialEligibility[tier] = _prefs!.getBool('trial_eligible_${tier.name}') ?? true;
    }
  }

  /// Load conversion attempts from storage
  Future<void> _loadConversionAttempts() async {
    if (_prefs == null) return;
    _conversionAttempts = _prefs!.getInt(_conversionAttemptsKey) ?? 0;
  }

  /// Check and update trial expiration status
  Future<void> _checkTrialExpiration() async {
    if (_currentTrial == null) return;
    
    if (_currentTrial!.isExpired && _currentTrial!.state == TrialState.active) {
      _currentTrial = _currentTrial!.copyWith(state: TrialState.expired);
      await _saveCurrentTrial();
      
      _analytics.trackMonetizationEvent(
        MonetizationEvent.trialExpired(
          tier: _currentTrial!.tier.name,
          trialType: _currentTrial!.type.name,
          durationDays: _currentTrial!.totalDurationDays,
        ),
      );
      
      notifyListeners();
    }
  }

  /// Start a new trial
  Future<bool> startTrial(TrialConfig config) async {
    // Check if user is eligible for this trial
    if (!_trialEligibility[config.tier]!) {
      return false;
    }

    // Check if there's already an active trial
    if (hasActiveTrial) {
      return false;
    }

    // Check if trial offer is still valid
    if (!config.isValid) {
      return false;
    }

    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: config.durationDays));
    
    _currentTrial = TrialInfo(
      tier: config.tier,
      type: config.type,
      startedAt: now,
      expiresAt: expiresAt,
      originalDurationDays: config.durationDays,
      promoCode: config.promoCode,
      analytics: {
        'started_from': 'trial_service',
        'campaign': config.metadata['campaign'] ?? 'standard',
        ...config.metadata,
      },
    );

    // Mark tier as used for trial
    _trialEligibility[config.tier] = false;
    
    await _saveCurrentTrial();
    await _saveTrialEligibility();
    
    // Track trial started
    _analytics.trackMonetizationEvent(
      MonetizationEvent.trialStarted(
        tier: config.tier.name,
        trialType: config.type.name,
        durationDays: config.durationDays,
        promoCode: config.promoCode,
      ),
    );

    notifyListeners();
    return true;
  }

  /// Extend current trial
  Future<bool> extendTrial(int additionalDays, {String? reason}) async {
    if (_currentTrial == null || !_currentTrial!.isActive) {
      return false;
    }

    final newExpiryDate = _currentTrial!.expiresAt.add(Duration(days: additionalDays));
    
    _currentTrial = _currentTrial!.copyWith(
      expiresAt: newExpiryDate,
      extensionDays: _currentTrial!.extensionDays + additionalDays,
      state: TrialState.extended,
    );

    await _saveCurrentTrial();
    
    // Track trial extension
    _analytics.trackMonetizationEvent(
      MonetizationEvent.trialExtended(
        tier: _currentTrial!.tier.name,
        additionalDays: additionalDays,
        reason: reason ?? 'manual_extension',
      ),
    );

    notifyListeners();
    return true;
  }

  /// Convert trial to paid subscription
  Future<bool> convertTrial(UserTier subscribedTier) async {
    if (_currentTrial == null) return false;

    // Move trial to history
    final convertedTrial = _currentTrial!.copyWith(state: TrialState.converted);
    _trialHistory.add(convertedTrial);
    _currentTrial = null;

    await _saveCurrentTrial();
    await _saveTrialHistory();
    
    // Track conversion
    _analytics.trackMonetizationEvent(
      MonetizationEvent.trialConverted(
        trialTier: convertedTrial.tier.name,
        subscribedTier: subscribedTier.name,
        trialDurationDays: convertedTrial.totalDurationDays,
        conversionDay: convertedTrial.startedAt.difference(DateTime.now()).inDays.abs(),
      ),
    );

    notifyListeners();
    return true;
  }

  /// Cancel current trial
  Future<bool> cancelTrial({String? reason}) async {
    if (_currentTrial == null || !_currentTrial!.isActive) {
      return false;
    }

    // Move trial to history
    final cancelledTrial = _currentTrial!.copyWith(state: TrialState.cancelled);
    _trialHistory.add(cancelledTrial);
    _currentTrial = null;

    await _saveCurrentTrial();
    await _saveTrialHistory();
    
    // Track cancellation
    _analytics.trackMonetizationEvent(
      MonetizationEvent.trialCancelled(
        tier: cancelledTrial.tier.name,
        reason: reason ?? 'user_cancelled',
        daysUsed: cancelledTrial.startedAt.difference(DateTime.now()).inDays.abs(),
      ),
    );

    notifyListeners();
    return true;
  }

  /// Record conversion attempt (when user views pricing but doesn't convert)
  Future<void> recordConversionAttempt({String? context}) async {
    _conversionAttempts++;
    await _prefs?.setInt(_conversionAttemptsKey, _conversionAttempts);
    
    _analytics.trackMonetizationEvent(
      MonetizationEvent.conversionAttempted(
        context: context ?? 'unknown',
        attemptNumber: _conversionAttempts,
        hasActiveTrial: hasActiveTrial,
      ),
    );
  }

  /// Get available trial offers for user
  List<TrialConfig> getAvailableTrials({String? userId}) {
    final trials = <TrialConfig>[];

    // Standard trials for eligible tiers
    for (final tier in [UserTier.premium, UserTier.pro]) {
      if (_trialEligibility[tier]!) {
        final durationDays = tier == UserTier.premium ? 7 : 14;
        trials.add(TrialConfig(
          tier: tier,
          durationDays: durationDays,
          type: TrialType.standard,
        ));
      }
    }

    // Promotional trials (if no standard trial used)
    if (_trialEligibility[UserTier.premium]! && _conversionAttempts >= 2) {
      trials.add(TrialConfig(
        tier: UserTier.premium,
        durationDays: 14, // Extended promotional trial
        type: TrialType.promotional,
        promoCode: 'TRYEXTENDED',
        validUntil: DateTime.now().add(const Duration(days: 7)),
        metadata: {'campaign': 'conversion_boost'},
      ));
    }

    // Win-back trial for users with expired trials
    final hasExpiredTrial = _trialHistory.any((t) => t.state == TrialState.expired);
    if (hasExpiredTrial && _conversionAttempts >= 1) {
      trials.add(TrialConfig(
        tier: UserTier.premium,
        durationDays: 10,
        type: TrialType.winback,
        promoCode: 'WELCOMEBACK',
        validUntil: DateTime.now().add(const Duration(days: 30)),
        metadata: {'campaign': 'winback'},
      ));
    }

    return trials;
  }

  /// Get trial conversion recommendations
  List<String> getConversionRecommendations() {
    if (_currentTrial == null) return [];

    final recommendations = <String>[];
    
    if (_currentTrial!.isAboutToExpire) {
      recommendations.add('Your trial expires in ${_currentTrial!.daysRemaining} day(s)');
      recommendations.add('Upgrade now to keep all your ${_currentTrial!.tier.name} features');
    }

    if (_currentTrial!.progressPercentage > 50) {
      recommendations.add('You\'ve been using ${_currentTrial!.tier.name} features for ${(_currentTrial!.progressPercentage).round()}% of your trial');
      recommendations.add('Continue with unlimited access for just \$1.99/month');
    }

    if (_conversionAttempts >= 2) {
      recommendations.add('Special offer: Get 20% off your first month');
    }

    return recommendations;
  }

  /// Save current trial to storage
  Future<void> _saveCurrentTrial() async {
    if (_prefs == null) return;
    
    try {
      if (_currentTrial != null) {
        final trialJson = Uri.encodeComponent(_currentTrial!.toJson().toString());
        await _prefs!.setString(_currentTrialKey, trialJson);
      } else {
        await _prefs!.remove(_currentTrialKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving current trial: $e');
      }
    }
  }

  /// Save trial history to storage
  Future<void> _saveTrialHistory() async {
    if (_prefs == null) return;
    
    try {
      final historyJson = _trialHistory.map((trial) {
        return Uri.encodeComponent(trial.toJson().toString());
      }).toList();
      
      await _prefs!.setStringList(_trialHistoryKey, historyJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving trial history: $e');
      }
    }
  }

  /// Save trial eligibility to storage
  Future<void> _saveTrialEligibility() async {
    if (_prefs == null) return;
    
    for (final entry in _trialEligibility.entries) {
      await _prefs!.setBool('trial_eligible_${entry.key.name}', entry.value);
    }
  }

  /// Get analytics data for reporting
  Map<String, dynamic> getAnalyticsData() {
    final totalTrials = _trialHistory.length + (hasActiveTrial ? 1 : 0);
    final conversions = _trialHistory.where((t) => t.state == TrialState.converted).length;
    final conversionRate = totalTrials > 0 ? (conversions / totalTrials * 100) : 0.0;

    return {
      'has_active_trial': hasActiveTrial,
      'current_trial_tier': _currentTrial?.tier.name,
      'current_trial_days_remaining': _currentTrial?.daysRemaining,
      'trial_about_to_expire': isTrialAboutToExpire,
      'total_trials_started': totalTrials,
      'total_conversions': conversions,
      'conversion_rate': conversionRate.toStringAsFixed(1),
      'conversion_attempts': _conversionAttempts,
      'eligible_for_trials': _trialEligibility.values.any((eligible) => eligible),
    };
  }
}

/// Extension for MonetizationEvent to add trial events
extension TrialMonetizationEvents on MonetizationEvent {
  /// Trial started
  static MonetizationEvent trialStarted({
    required String tier,
    required String trialType,
    required int durationDays,
    String? promoCode,
  }) {
    return MonetizationEvent(
      eventName: 'trial_started',
      parameters: {
        'tier': tier,
        'trial_type': trialType,
        'duration_days': durationDays,
        'promo_code': promoCode,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Trial extended
  static MonetizationEvent trialExtended({
    required String tier,
    required int additionalDays,
    required String reason,
  }) {
    return MonetizationEvent(
      eventName: 'trial_extended',
      parameters: {
        'tier': tier,
        'additional_days': additionalDays,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Trial expired
  static MonetizationEvent trialExpired({
    required String tier,
    required String trialType,
    required int durationDays,
  }) {
    return MonetizationEvent(
      eventName: 'trial_expired',
      parameters: {
        'tier': tier,
        'trial_type': trialType,
        'duration_days': durationDays,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Trial converted to paid subscription
  static MonetizationEvent trialConverted({
    required String trialTier,
    required String subscribedTier,
    required int trialDurationDays,
    required int conversionDay,
  }) {
    return MonetizationEvent(
      eventName: 'trial_converted',
      parameters: {
        'trial_tier': trialTier,
        'subscribed_tier': subscribedTier,
        'trial_duration_days': trialDurationDays,
        'conversion_day': conversionDay,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Trial cancelled
  static MonetizationEvent trialCancelled({
    required String tier,
    required String reason,
    required int daysUsed,
  }) {
    return MonetizationEvent(
      eventName: 'trial_cancelled',
      parameters: {
        'tier': tier,
        'reason': reason,
        'days_used': daysUsed,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Conversion attempted (viewed pricing but didn't convert)
  static MonetizationEvent conversionAttempted({
    required String context,
    required int attemptNumber,
    required bool hasActiveTrial,
  }) {
    return MonetizationEvent(
      eventName: 'conversion_attempted',
      parameters: {
        'context': context,
        'attempt_number': attemptNumber,
        'has_active_trial': hasActiveTrial,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
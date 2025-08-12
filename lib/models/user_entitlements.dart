import 'pricing_tier.dart';

/// Enum representing subscription types
enum SubscriptionType {
  none,
  monthly,
  lifetime,
  trial,
}

/// Model representing user entitlements and subscription status
class UserEntitlements {
  final PricingTier tier;
  final SubscriptionType subscriptionType;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final bool isTrialUsed;
  final String? subscriptionId;
  final String? originalPurchaseId;
  
  // Usage tracking for current period
  final int currentMonthVoiceNotes;
  final int currentMonthExports;
  final DateTime lastUsageReset;

  const UserEntitlements({
    required this.tier,
    required this.subscriptionType,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.trialStartDate,
    this.trialEndDate,
    required this.isTrialUsed,
    this.subscriptionId,
    this.originalPurchaseId,
    required this.currentMonthVoiceNotes,
    required this.currentMonthExports,
    required this.lastUsageReset,
  });

  /// Create default free user entitlements
  factory UserEntitlements.free() {
    final now = DateTime.now();
    return UserEntitlements(
      tier: PricingTier.free,
      subscriptionType: SubscriptionType.none,
      isTrialUsed: false,
      currentMonthVoiceNotes: 0,
      currentMonthExports: 0,
      lastUsageReset: DateTime(now.year, now.month, 1), // First of current month
    );
  }

  /// Create premium user entitlements
  factory UserEntitlements.premium({
    required SubscriptionType subscriptionType,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    String? subscriptionId,
    String? originalPurchaseId,
  }) {
    final now = DateTime.now();
    return UserEntitlements(
      tier: PricingTier.premium,
      subscriptionType: subscriptionType,
      subscriptionStartDate: subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate,
      isTrialUsed: true, // Assume trial is used if premium
      subscriptionId: subscriptionId,
      originalPurchaseId: originalPurchaseId,
      currentMonthVoiceNotes: 0,
      currentMonthExports: 0,
      lastUsageReset: DateTime(now.year, now.month, 1),
    );
  }

  /// Create trial user entitlements
  factory UserEntitlements.trial({
    required DateTime trialStartDate,
    required DateTime trialEndDate,
  }) {
    final now = DateTime.now();
    return UserEntitlements(
      tier: PricingTier.premium, // Trial gives premium access
      subscriptionType: SubscriptionType.trial,
      trialStartDate: trialStartDate,
      trialEndDate: trialEndDate,
      isTrialUsed: true,
      currentMonthVoiceNotes: 0,
      currentMonthExports: 0,
      lastUsageReset: DateTime(now.year, now.month, 1),
    );
  }

  /// Check if user is currently premium (including active trial)
  bool get isPremium {
    switch (subscriptionType) {
      case SubscriptionType.none:
        return false;
      case SubscriptionType.lifetime:
        return true; // Lifetime is always active
      case SubscriptionType.monthly:
        return subscriptionEndDate?.isAfter(DateTime.now()) ?? false;
      case SubscriptionType.trial:
        return trialEndDate?.isAfter(DateTime.now()) ?? false;
    }
  }

  /// Check if user has an active subscription (not trial)
  bool get hasActiveSubscription {
    switch (subscriptionType) {
      case SubscriptionType.none:
      case SubscriptionType.trial:
        return false;
      case SubscriptionType.lifetime:
        return true;
      case SubscriptionType.monthly:
        return subscriptionEndDate?.isAfter(DateTime.now()) ?? false;
    }
  }

  /// Check if user is in trial period
  bool get isInTrial {
    return subscriptionType == SubscriptionType.trial &&
        trialEndDate?.isAfter(DateTime.now()) == true;
  }

  /// Check if trial has expired
  bool get isTrialExpired {
    return subscriptionType == SubscriptionType.trial &&
        trialEndDate?.isBefore(DateTime.now()) == true;
  }

  /// Check if subscription has expired
  bool get isSubscriptionExpired {
    if (subscriptionType == SubscriptionType.lifetime) return false;
    if (subscriptionType == SubscriptionType.none) return false;
    
    return subscriptionEndDate?.isBefore(DateTime.now()) ?? true;
  }

  /// Check if user can start a trial
  bool get canStartTrial {
    return !isTrialUsed && subscriptionType == SubscriptionType.none;
  }

  /// Get days remaining in trial
  int get trialDaysRemaining {
    if (!isInTrial || trialEndDate == null) return 0;
    final diff = trialEndDate!.difference(DateTime.now());
    return diff.inDays.clamp(0, double.infinity).toInt();
  }

  /// Get current tier limits based on entitlements
  PricingTierLimits get currentLimits {
    return PricingTierLimits.forTier(isPremium ? PricingTier.premium : PricingTier.free);
  }

  /// Check if usage needs to be reset (new month)
  bool get needsUsageReset {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    return lastUsageReset.isBefore(currentMonthStart);
  }

  /// Reset usage counters for new month
  UserEntitlements resetUsage() {
    final now = DateTime.now();
    return copyWith(
      currentMonthVoiceNotes: 0,
      currentMonthExports: 0,
      lastUsageReset: DateTime(now.year, now.month, 1),
    );
  }

  /// Increment voice note usage
  UserEntitlements incrementVoiceNotes() {
    return copyWith(currentMonthVoiceNotes: currentMonthVoiceNotes + 1);
  }

  /// Increment export usage
  UserEntitlements incrementExports() {
    return copyWith(currentMonthExports: currentMonthExports + 1);
  }

  /// Copy with modifications
  UserEntitlements copyWith({
    PricingTier? tier,
    SubscriptionType? subscriptionType,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    bool? isTrialUsed,
    String? subscriptionId,
    String? originalPurchaseId,
    int? currentMonthVoiceNotes,
    int? currentMonthExports,
    DateTime? lastUsageReset,
  }) {
    return UserEntitlements(
      tier: tier ?? this.tier,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      isTrialUsed: isTrialUsed ?? this.isTrialUsed,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      originalPurchaseId: originalPurchaseId ?? this.originalPurchaseId,
      currentMonthVoiceNotes: currentMonthVoiceNotes ?? this.currentMonthVoiceNotes,
      currentMonthExports: currentMonthExports ?? this.currentMonthExports,
      lastUsageReset: lastUsageReset ?? this.lastUsageReset,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'subscriptionType': subscriptionType.name,
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'isTrialUsed': isTrialUsed,
      'subscriptionId': subscriptionId,
      'originalPurchaseId': originalPurchaseId,
      'currentMonthVoiceNotes': currentMonthVoiceNotes,
      'currentMonthExports': currentMonthExports,
      'lastUsageReset': lastUsageReset.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserEntitlements.fromJson(Map<String, dynamic> json) {
    return UserEntitlements(
      tier: PricingTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => PricingTier.free,
      ),
      subscriptionType: SubscriptionType.values.firstWhere(
        (t) => t.name == json['subscriptionType'],
        orElse: () => SubscriptionType.none,
      ),
      subscriptionStartDate: json['subscriptionStartDate'] != null
          ? DateTime.parse(json['subscriptionStartDate'])
          : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.parse(json['subscriptionEndDate'])
          : null,
      trialStartDate: json['trialStartDate'] != null
          ? DateTime.parse(json['trialStartDate'])
          : null,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'])
          : null,
      isTrialUsed: json['isTrialUsed'] ?? false,
      subscriptionId: json['subscriptionId'],
      originalPurchaseId: json['originalPurchaseId'],
      currentMonthVoiceNotes: json['currentMonthVoiceNotes'] ?? 0,
      currentMonthExports: json['currentMonthExports'] ?? 0,
      lastUsageReset: DateTime.parse(
        json['lastUsageReset'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  String toString() {
    return 'UserEntitlements(tier: $tier, subscriptionType: $subscriptionType, isPremium: $isPremium)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntitlements &&
        other.tier == tier &&
        other.subscriptionType == subscriptionType &&
        other.subscriptionStartDate == subscriptionStartDate &&
        other.subscriptionEndDate == subscriptionEndDate &&
        other.trialStartDate == trialStartDate &&
        other.trialEndDate == trialEndDate &&
        other.isTrialUsed == isTrialUsed &&
        other.subscriptionId == subscriptionId &&
        other.originalPurchaseId == originalPurchaseId &&
        other.currentMonthVoiceNotes == currentMonthVoiceNotes &&
        other.currentMonthExports == currentMonthExports &&
        other.lastUsageReset == lastUsageReset;
  }

  @override
  int get hashCode {
    return Object.hash(
      tier,
      subscriptionType,
      subscriptionStartDate,
      subscriptionEndDate,
      trialStartDate,
      trialEndDate,
      isTrialUsed,
      subscriptionId,
      originalPurchaseId,
      currentMonthVoiceNotes,
      currentMonthExports,
      lastUsageReset,
    );
  }
}
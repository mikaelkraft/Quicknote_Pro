/// Enum representing different subscription types
enum SubscriptionType {
  /// Free user with limited features
  free,
  
  /// Monthly Pro subscription
  monthly,
  
  /// Lifetime Pro purchase (one-time payment)
  lifetime,
}

/// Extension to provide additional functionality for SubscriptionType
extension SubscriptionTypeExtension on SubscriptionType {
  /// Check if this subscription type provides Pro features
  bool get isPro {
    switch (this) {
      case SubscriptionType.free:
        return false;
      case SubscriptionType.monthly:
      case SubscriptionType.lifetime:
        return true;
    }
  }

  /// Get display name for the subscription type
  String get displayName {
    switch (this) {
      case SubscriptionType.free:
        return 'Free';
      case SubscriptionType.monthly:
        return 'Monthly Pro';
      case SubscriptionType.lifetime:
        return 'Lifetime Pro';
    }
  }
}

/// Model representing the user's current entitlement/subscription status
class EntitlementStatus {
  /// Type of subscription (free, monthly, lifetime)
  final SubscriptionType subscriptionType;
  
  /// Whether the user currently has active Pro access
  final bool hasProAccess;
  
  /// Expiration date for monthly subscriptions (null for free/lifetime)
  final DateTime? expirationDate;
  
  /// When this status was last verified from the server
  final DateTime lastVerified;
  
  /// Whether this status is from offline cache
  final bool isOfflineCache;

  const EntitlementStatus({
    required this.subscriptionType,
    required this.hasProAccess,
    this.expirationDate,
    required this.lastVerified,
    this.isOfflineCache = false,
  });

  /// Create a free user status
  factory EntitlementStatus.free() {
    return EntitlementStatus(
      subscriptionType: SubscriptionType.free,
      hasProAccess: false,
      lastVerified: DateTime.now(),
      isOfflineCache: false,
    );
  }

  /// Create a monthly Pro status
  factory EntitlementStatus.monthlyPro({
    required DateTime expirationDate,
    bool isOfflineCache = false,
  }) {
    return EntitlementStatus(
      subscriptionType: SubscriptionType.monthly,
      hasProAccess: DateTime.now().isBefore(expirationDate),
      expirationDate: expirationDate,
      lastVerified: DateTime.now(),
      isOfflineCache: isOfflineCache,
    );
  }

  /// Create a lifetime Pro status
  factory EntitlementStatus.lifetimePro({
    bool isOfflineCache = false,
  }) {
    return EntitlementStatus(
      subscriptionType: SubscriptionType.lifetime,
      hasProAccess: true,
      lastVerified: DateTime.now(),
      isOfflineCache: isOfflineCache,
    );
  }

  /// Check if the subscription is expired (for monthly subscriptions)
  bool get isExpired {
    if (subscriptionType != SubscriptionType.monthly || expirationDate == null) {
      return false;
    }
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Check if the cached status is stale (older than 24 hours)
  bool get isStale {
    return DateTime.now().difference(lastVerified).inHours > 24;
  }

  /// Days until expiration (for monthly subscriptions)
  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    final difference = expirationDate!.difference(DateTime.now());
    return difference.inDays;
  }

  /// Create a copy with updated fields
  EntitlementStatus copyWith({
    SubscriptionType? subscriptionType,
    bool? hasProAccess,
    DateTime? expirationDate,
    DateTime? lastVerified,
    bool? isOfflineCache,
  }) {
    return EntitlementStatus(
      subscriptionType: subscriptionType ?? this.subscriptionType,
      hasProAccess: hasProAccess ?? this.hasProAccess,
      expirationDate: expirationDate ?? this.expirationDate,
      lastVerified: lastVerified ?? this.lastVerified,
      isOfflineCache: isOfflineCache ?? this.isOfflineCache,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'subscriptionType': subscriptionType.toString().split('.').last,
      'hasProAccess': hasProAccess,
      'expirationDate': expirationDate?.millisecondsSinceEpoch,
      'lastVerified': lastVerified.millisecondsSinceEpoch,
      'isOfflineCache': isOfflineCache,
    };
  }

  /// Create from JSON
  factory EntitlementStatus.fromJson(Map<String, dynamic> json) {
    return EntitlementStatus(
      subscriptionType: SubscriptionType.values.firstWhere(
        (type) => type.toString().split('.').last == json['subscriptionType'],
        orElse: () => SubscriptionType.free,
      ),
      hasProAccess: json['hasProAccess'] ?? false,
      expirationDate: json['expirationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expirationDate'])
          : null,
      lastVerified: DateTime.fromMillisecondsSinceEpoch(
        json['lastVerified'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isOfflineCache: json['isOfflineCache'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntitlementStatus &&
        other.subscriptionType == subscriptionType &&
        other.hasProAccess == hasProAccess &&
        other.expirationDate == expirationDate &&
        other.lastVerified == lastVerified &&
        other.isOfflineCache == isOfflineCache;
  }

  @override
  int get hashCode {
    return Object.hash(
      subscriptionType,
      hasProAccess,
      expirationDate,
      lastVerified,
      isOfflineCache,
    );
  }

  @override
  String toString() {
    return 'EntitlementStatus('
        'subscriptionType: $subscriptionType, '
        'hasProAccess: $hasProAccess, '
        'expirationDate: $expirationDate, '
        'lastVerified: $lastVerified, '
        'isOfflineCache: $isOfflineCache)';
  }
}
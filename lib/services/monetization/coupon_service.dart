/// Coupon system for promotional pricing and discounts.
/// 
/// Manages discount codes, validation, and application to subscription pricing.
/// Supports various discount types and usage restrictions for marketing campaigns.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_service.dart';
import 'monetization_service.dart';
import 'pricing_models.dart';

/// Types of coupon discounts
enum CouponDiscountType {
  percentage,     // Percentage off (e.g., 20% off)
  fixedAmount,    // Fixed amount off (e.g., $5 off)
  freeMonths,     // Free months (e.g., first month free)
  freeTrial,      // Extended trial period
}

/// Coupon eligibility restrictions
enum CouponEligibility {
  all,              // All users
  newUsersOnly,     // First-time subscribers only
  existingUsers,    // Current subscribers only
  specificTier,     // Specific tier only
  upgradeOnly,      // Upgrade from free only
  renewalOnly,      // Subscription renewal only
}

/// Coupon configuration and rules
class CouponConfig {
  final String code;
  final String displayName;
  final String description;
  final CouponDiscountType discountType;
  final double discountValue;
  final CouponEligibility eligibility;
  final List<UserTier> applicableTiers;
  final List<PlanTerm> applicableTerms;
  final DateTime startsAt;
  final DateTime expiresAt;
  final int? maxUses;
  final int? maxUsesPerUser;
  final double? minimumPurchase;
  final bool stackable;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const CouponConfig({
    required this.code,
    required this.displayName,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.eligibility = CouponEligibility.all,
    this.applicableTiers = const [],
    this.applicableTerms = const [],
    required this.startsAt,
    required this.expiresAt,
    this.maxUses,
    this.maxUsesPerUser,
    this.minimumPurchase,
    this.stackable = false,
    this.isActive = true,
    this.metadata = const {},
  });

  /// Check if coupon is currently valid
  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startsAt) && 
           now.isBefore(expiresAt);
  }

  /// Check if coupon is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Calculate discount amount for a given price
  double calculateDiscount(double originalPrice) {
    switch (discountType) {
      case CouponDiscountType.percentage:
        return originalPrice * (discountValue / 100);
      case CouponDiscountType.fixedAmount:
        return discountValue.clamp(0, originalPrice);
      case CouponDiscountType.freeMonths:
        // For free months, return the monthly equivalent
        return originalPrice;
      case CouponDiscountType.freeTrial:
        // Trial extensions don't affect price directly
        return 0;
    }
  }

  /// Get display text for the discount
  String get discountDisplayText {
    switch (discountType) {
      case CouponDiscountType.percentage:
        return '${discountValue.round()}% off';
      case CouponDiscountType.fixedAmount:
        return '\$${discountValue.toStringAsFixed(2)} off';
      case CouponDiscountType.freeMonths:
        final months = discountValue.round();
        return '$months month${months > 1 ? 's' : ''} free';
      case CouponDiscountType.freeTrial:
        final days = discountValue.round();
        return '+$days trial days';
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'display_name': displayName,
      'description': description,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'eligibility': eligibility.name,
      'applicable_tiers': applicableTiers.map((t) => t.name).toList(),
      'applicable_terms': applicableTerms.map((t) => t.name).toList(),
      'starts_at': startsAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'max_uses': maxUses,
      'max_uses_per_user': maxUsesPerUser,
      'minimum_purchase': minimumPurchase,
      'stackable': stackable,
      'is_active': isActive,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CouponConfig.fromJson(Map<String, dynamic> json) {
    return CouponConfig(
      code: json['code'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      discountType: CouponDiscountType.values.firstWhere(
        (t) => t.name == json['discount_type'],
        orElse: () => CouponDiscountType.percentage,
      ),
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      eligibility: CouponEligibility.values.firstWhere(
        (e) => e.name == json['eligibility'],
        orElse: () => CouponEligibility.all,
      ),
      applicableTiers: (json['applicable_tiers'] as List<dynamic>?)
        ?.map((t) => UserTier.values.firstWhere(
          (tier) => tier.name == t,
          orElse: () => UserTier.free,
        )).toList() ?? [],
      applicableTerms: (json['applicable_terms'] as List<dynamic>?)
        ?.map((t) => PlanTerm.values.firstWhere(
          (term) => term.name == t,
          orElse: () => PlanTerm.monthly,
        )).toList() ?? [],
      startsAt: DateTime.parse(json['starts_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      maxUses: json['max_uses'],
      maxUsesPerUser: json['max_uses_per_user'],
      minimumPurchase: (json['minimum_purchase'] as num?)?.toDouble(),
      stackable: json['stackable'] ?? false,
      isActive: json['is_active'] ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Usage tracking for coupons
class CouponUsage {
  final String couponCode;
  final String userId;
  final DateTime usedAt;
  final double originalPrice;
  final double discountAmount;
  final UserTier tier;
  final PlanTerm term;
  final Map<String, dynamic> metadata;

  const CouponUsage({
    required this.couponCode,
    required this.userId,
    required this.usedAt,
    required this.originalPrice,
    required this.discountAmount,
    required this.tier,
    required this.term,
    this.metadata = const {},
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'coupon_code': couponCode,
      'user_id': userId,
      'used_at': usedAt.toIso8601String(),
      'original_price': originalPrice,
      'discount_amount': discountAmount,
      'tier': tier.name,
      'term': term.name,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory CouponUsage.fromJson(Map<String, dynamic> json) {
    return CouponUsage(
      couponCode: json['coupon_code'] ?? '',
      userId: json['user_id'] ?? '',
      usedAt: DateTime.parse(json['used_at']),
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      tier: UserTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => UserTier.free,
      ),
      term: PlanTerm.values.firstWhere(
        (t) => t.name == json['term'],
        orElse: () => PlanTerm.monthly,
      ),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Result of coupon validation
class CouponValidationResult {
  final bool isValid;
  final String? errorMessage;
  final CouponConfig? coupon;
  final double? discountAmount;

  const CouponValidationResult({
    required this.isValid,
    this.errorMessage,
    this.coupon,
    this.discountAmount,
  });

  /// Create successful validation result
  factory CouponValidationResult.success({
    required CouponConfig coupon,
    required double discountAmount,
  }) {
    return CouponValidationResult(
      isValid: true,
      coupon: coupon,
      discountAmount: discountAmount,
    );
  }

  /// Create failed validation result
  factory CouponValidationResult.failure(String errorMessage) {
    return CouponValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

/// Service for managing coupons and promotional pricing
class CouponService extends ChangeNotifier {
  static const String _couponsKey = 'available_coupons';
  static const String _usageKey = 'coupon_usage';
  static const String _appliedCouponsKey = 'applied_coupons';
  
  SharedPreferences? _prefs;
  final Map<String, CouponConfig> _availableCoupons = {};
  final List<CouponUsage> _usageHistory = [];
  final Map<String, CouponConfig> _appliedCoupons = {};
  final AnalyticsService _analytics = AnalyticsService();

  /// Currently available coupons
  Map<String, CouponConfig> get availableCoupons => Map.unmodifiable(_availableCoupons);

  /// Usage history
  List<CouponUsage> get usageHistory => List.unmodifiable(_usageHistory);

  /// Currently applied coupons
  Map<String, CouponConfig> get appliedCoupons => Map.unmodifiable(_appliedCoupons);

  /// Initialize coupon service with default promotional coupons
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCoupons();
    await _loadUsageHistory();
    await _loadAppliedCoupons();
    await _createDefaultCoupons();
  }

  /// Create default promotional coupons for user retention
  Future<void> _createDefaultCoupons() async {
    if (_availableCoupons.isNotEmpty) return; // Already initialized

    final now = DateTime.now();
    final defaultCoupons = [
      // Welcome coupon for new users
      CouponConfig(
        code: 'WELCOME25',
        displayName: '25% Off First Month',
        description: 'Get 25% off your first subscription purchase',
        discountType: CouponDiscountType.percentage,
        discountValue: 25,
        eligibility: CouponEligibility.newUsersOnly,
        applicableTiers: [UserTier.premium, UserTier.pro],
        applicableTerms: [PlanTerm.monthly, PlanTerm.annual],
        startsAt: now,
        expiresAt: now.add(const Duration(days: 365)),
        maxUsesPerUser: 1,
        metadata: {'campaign': 'welcome', 'priority': 'high'},
      ),

      // Back-to-school promotion
      CouponConfig(
        code: 'STUDENT20',
        displayName: '20% Student Discount',
        description: 'Special student pricing for note-taking excellence',
        discountType: CouponDiscountType.percentage,
        discountValue: 20,
        eligibility: CouponEligibility.all,
        applicableTiers: [UserTier.premium, UserTier.pro],
        applicableTerms: [PlanTerm.annual],
        startsAt: now,
        expiresAt: now.add(const Duration(days: 90)),
        metadata: {'campaign': 'student', 'priority': 'medium'},
      ),

      // Holiday promotion
      CouponConfig(
        code: 'HOLIDAY50',
        displayName: 'Holiday Special',
        description: 'Save \$5 on annual subscriptions this holiday season',
        discountType: CouponDiscountType.fixedAmount,
        discountValue: 5.0,
        eligibility: CouponEligibility.all,
        applicableTiers: [UserTier.premium, UserTier.pro],
        applicableTerms: [PlanTerm.annual],
        startsAt: now,
        expiresAt: now.add(const Duration(days: 60)),
        minimumPurchase: 15.0,
        metadata: {'campaign': 'holiday', 'priority': 'high'},
      ),

      // Win-back campaign for churned users
      CouponConfig(
        code: 'COMEBACK30',
        displayName: 'Welcome Back',
        description: 'We miss you! Come back with 30% off',
        discountType: CouponDiscountType.percentage,
        discountValue: 30,
        eligibility: CouponEligibility.existingUsers,
        applicableTiers: [UserTier.premium, UserTier.pro],
        applicableTerms: [PlanTerm.monthly, PlanTerm.annual],
        startsAt: now,
        expiresAt: now.add(const Duration(days: 30)),
        maxUsesPerUser: 1,
        metadata: {'campaign': 'winback', 'priority': 'high'},
      ),

      // Annual upgrade incentive
      CouponConfig(
        code: 'ANNUALBONUS',
        displayName: 'Annual Plan Bonus',
        description: 'Get 2 extra months free with annual subscription',
        discountType: CouponDiscountType.freeMonths,
        discountValue: 2,
        eligibility: CouponEligibility.upgradeOnly,
        applicableTiers: [UserTier.premium, UserTier.pro],
        applicableTerms: [PlanTerm.annual],
        startsAt: now,
        expiresAt: now.add(const Duration(days: 365)),
        metadata: {'campaign': 'annual_upgrade', 'priority': 'medium'},
      ),

      // Flash sale
      CouponConfig(
        code: 'FLASH48HR',
        displayName: '48-Hour Flash Sale',
        description: 'Limited time: 40% off all subscriptions',
        discountType: CouponDiscountType.percentage,
        discountValue: 40,
        eligibility: CouponEligibility.all,
        applicableTiers: [UserTier.premium, UserTier.pro],
        applicableTerms: [PlanTerm.monthly, PlanTerm.annual],
        startsAt: now,
        expiresAt: now.add(const Duration(hours: 48)),
        maxUses: 1000,
        metadata: {'campaign': 'flash_sale', 'priority': 'urgent'},
      ),
    ];

    for (final coupon in defaultCoupons) {
      _availableCoupons[coupon.code] = coupon;
    }

    await _saveCoupons();
  }

  /// Validate coupon code for specific purchase
  Future<CouponValidationResult> validateCoupon({
    required String code,
    required UserTier tier,
    required PlanTerm term,
    required double originalPrice,
    required String userId,
    required UserTier currentTier,
  }) async {
    // Check if coupon exists
    final coupon = _availableCoupons[code.toUpperCase()];
    if (coupon == null) {
      return CouponValidationResult.failure('Invalid coupon code');
    }

    // Check if coupon is valid and not expired
    if (!coupon.isValid) {
      if (coupon.isExpired) {
        return CouponValidationResult.failure('Coupon has expired');
      }
      return CouponValidationResult.failure('Coupon is not active');
    }

    // Check tier eligibility
    if (coupon.applicableTiers.isNotEmpty && !coupon.applicableTiers.contains(tier)) {
      return CouponValidationResult.failure('Coupon not valid for this plan');
    }

    // Check term eligibility
    if (coupon.applicableTerms.isNotEmpty && !coupon.applicableTerms.contains(term)) {
      return CouponValidationResult.failure('Coupon not valid for this billing term');
    }

    // Check user eligibility
    if (!_checkUserEligibility(coupon, currentTier, userId)) {
      return CouponValidationResult.failure('You are not eligible for this coupon');
    }

    // Check minimum purchase requirement
    if (coupon.minimumPurchase != null && originalPrice < coupon.minimumPurchase!) {
      return CouponValidationResult.failure(
        'Minimum purchase of \$${coupon.minimumPurchase!.toStringAsFixed(2)} required'
      );
    }

    // Check usage limits
    if (!_checkUsageLimits(coupon, userId)) {
      return CouponValidationResult.failure('Coupon usage limit reached');
    }

    // Calculate discount
    final discountAmount = coupon.calculateDiscount(originalPrice);

    return CouponValidationResult.success(
      coupon: coupon,
      discountAmount: discountAmount,
    );
  }

  /// Apply coupon to purchase
  Future<bool> applyCoupon({
    required String code,
    required UserTier tier,
    required PlanTerm term,
    required double originalPrice,
    required String userId,
  }) async {
    final validation = await validateCoupon(
      code: code,
      tier: tier,
      term: term,
      originalPrice: originalPrice,
      userId: userId,
      currentTier: UserTier.free, // Assume free for eligibility check
    );

    if (!validation.isValid || validation.coupon == null) {
      return false;
    }

    final coupon = validation.coupon!;
    _appliedCoupons[code.toUpperCase()] = coupon;

    // Record usage
    final usage = CouponUsage(
      couponCode: code.toUpperCase(),
      userId: userId,
      usedAt: DateTime.now(),
      originalPrice: originalPrice,
      discountAmount: validation.discountAmount!,
      tier: tier,
      term: term,
    );

    _usageHistory.add(usage);
    await _saveUsageHistory();
    await _saveAppliedCoupons();

    // Track analytics
    _analytics.trackMonetizationEvent(
      MonetizationEvent.couponApplied(
        couponCode: code.toUpperCase(),
        discountAmount: validation.discountAmount!,
        originalPrice: originalPrice,
        tier: tier.name,
        term: term.name,
      ),
    );

    notifyListeners();
    return true;
  }

  /// Remove applied coupon
  Future<void> removeCoupon(String code) async {
    _appliedCoupons.remove(code.toUpperCase());
    await _saveAppliedCoupons();
    notifyListeners();
  }

  /// Clear all applied coupons
  Future<void> clearAppliedCoupons() async {
    _appliedCoupons.clear();
    await _saveAppliedCoupons();
    notifyListeners();
  }

  /// Calculate total discount from applied coupons
  double calculateTotalDiscount(double originalPrice) {
    double totalDiscount = 0;
    
    for (final coupon in _appliedCoupons.values) {
      if (coupon.stackable || _appliedCoupons.length == 1) {
        totalDiscount += coupon.calculateDiscount(originalPrice);
      }
    }
    
    return totalDiscount.clamp(0, originalPrice);
  }

  /// Get applicable coupons for user
  List<CouponConfig> getApplicableCoupons({
    required UserTier currentTier,
    required UserTier targetTier,
    required PlanTerm term,
    required String userId,
  }) {
    return _availableCoupons.values
        .where((coupon) => 
          coupon.isValid &&
          (coupon.applicableTiers.isEmpty || coupon.applicableTiers.contains(targetTier)) &&
          (coupon.applicableTerms.isEmpty || coupon.applicableTerms.contains(term)) &&
          _checkUserEligibility(coupon, currentTier, userId) &&
          _checkUsageLimits(coupon, userId)
        )
        .toList()
        ..sort((a, b) => b.discountValue.compareTo(a.discountValue));
  }

  /// Check user eligibility for coupon
  bool _checkUserEligibility(CouponConfig coupon, UserTier currentTier, String userId) {
    switch (coupon.eligibility) {
      case CouponEligibility.all:
        return true;
      case CouponEligibility.newUsersOnly:
        return currentTier == UserTier.free;
      case CouponEligibility.existingUsers:
        return currentTier != UserTier.free;
      case CouponEligibility.specificTier:
        return coupon.applicableTiers.contains(currentTier);
      case CouponEligibility.upgradeOnly:
        return currentTier == UserTier.free;
      case CouponEligibility.renewalOnly:
        return currentTier != UserTier.free;
    }
  }

  /// Check usage limits for coupon
  bool _checkUsageLimits(CouponConfig coupon, String userId) {
    final totalUses = _usageHistory.where((u) => u.couponCode == coupon.code).length;
    final userUses = _usageHistory.where((u) => u.couponCode == coupon.code && u.userId == userId).length;

    // Check total usage limit
    if (coupon.maxUses != null && totalUses >= coupon.maxUses!) {
      return false;
    }

    // Check per-user usage limit
    if (coupon.maxUsesPerUser != null && userUses >= coupon.maxUsesPerUser!) {
      return false;
    }

    return true;
  }

  /// Load coupons from storage
  Future<void> _loadCoupons() async {
    if (_prefs == null) return;
    
    final couponsJson = _prefs!.getStringList(_couponsKey) ?? [];
    for (final json in couponsJson) {
      try {
        final data = Map<String, dynamic>.from(
          Uri.decodeComponent(json) as Map
        );
        final coupon = CouponConfig.fromJson(data);
        _availableCoupons[coupon.code] = coupon;
      } catch (e) {
        if (kDebugMode) {
          print('Error loading coupon: $e');
        }
      }
    }
  }

  /// Save coupons to storage
  Future<void> _saveCoupons() async {
    if (_prefs == null) return;
    
    try {
      final couponsJson = _availableCoupons.values.map((coupon) {
        return Uri.encodeComponent(coupon.toJson().toString());
      }).toList();
      
      await _prefs!.setStringList(_couponsKey, couponsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving coupons: $e');
      }
    }
  }

  /// Load usage history from storage
  Future<void> _loadUsageHistory() async {
    if (_prefs == null) return;
    
    final usageJson = _prefs!.getStringList(_usageKey) ?? [];
    _usageHistory.clear();
    
    for (final json in usageJson) {
      try {
        final data = Map<String, dynamic>.from(
          Uri.decodeComponent(json) as Map
        );
        _usageHistory.add(CouponUsage.fromJson(data));
      } catch (e) {
        if (kDebugMode) {
          print('Error loading usage: $e');
        }
      }
    }
  }

  /// Save usage history to storage
  Future<void> _saveUsageHistory() async {
    if (_prefs == null) return;
    
    try {
      final usageJson = _usageHistory.map((usage) {
        return Uri.encodeComponent(usage.toJson().toString());
      }).toList();
      
      await _prefs!.setStringList(_usageKey, usageJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving usage: $e');
      }
    }
  }

  /// Load applied coupons from storage
  Future<void> _loadAppliedCoupons() async {
    if (_prefs == null) return;
    
    final appliedJson = _prefs!.getStringList(_appliedCouponsKey) ?? [];
    _appliedCoupons.clear();
    
    for (final json in appliedJson) {
      try {
        final data = Map<String, dynamic>.from(
          Uri.decodeComponent(json) as Map
        );
        final coupon = CouponConfig.fromJson(data);
        _appliedCoupons[coupon.code] = coupon;
      } catch (e) {
        if (kDebugMode) {
          print('Error loading applied coupon: $e');
        }
      }
    }
  }

  /// Save applied coupons to storage
  Future<void> _saveAppliedCoupons() async {
    if (_prefs == null) return;
    
    try {
      final appliedJson = _appliedCoupons.values.map((coupon) {
        return Uri.encodeComponent(coupon.toJson().toString());
      }).toList();
      
      await _prefs!.setStringList(_appliedCouponsKey, appliedJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving applied coupons: $e');
      }
    }
  }

  /// Get analytics data for reporting
  Map<String, dynamic> getAnalyticsData() {
    final totalUsage = _usageHistory.length;
    final totalDiscount = _usageHistory.fold<double>(
      0, (sum, usage) => sum + usage.discountAmount
    );
    
    return {
      'available_coupons_count': _availableCoupons.length,
      'applied_coupons_count': _appliedCoupons.length,
      'total_usage_count': totalUsage,
      'total_discount_given': totalDiscount,
      'most_used_coupons': _getMostUsedCoupons(),
    };
  }

  /// Get most used coupons for analytics
  List<Map<String, dynamic>> _getMostUsedCoupons() {
    final usageMap = <String, int>{};
    for (final usage in _usageHistory) {
      usageMap[usage.couponCode] = (usageMap[usage.couponCode] ?? 0) + 1;
    }
    
    final sortedEntries = usageMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(5).map((entry) => {
      'coupon_code': entry.key,
      'usage_count': entry.value,
    }).toList();
  }
}

/// Extension for MonetizationEvent to add coupon events
extension CouponMonetizationEvents on MonetizationEvent {
  /// Coupon applied to purchase
  static MonetizationEvent couponApplied({
    required String couponCode,
    required double discountAmount,
    required double originalPrice,
    required String tier,
    required String term,
  }) {
    return MonetizationEvent(
      eventName: 'coupon_applied',
      parameters: {
        'coupon_code': couponCode,
        'discount_amount': discountAmount,
        'original_price': originalPrice,
        'final_price': originalPrice - discountAmount,
        'tier': tier,
        'term': term,
        'discount_percentage': ((discountAmount / originalPrice) * 100).round(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Coupon validation failed
  static MonetizationEvent couponValidationFailed({
    required String couponCode,
    required String reason,
  }) {
    return MonetizationEvent(
      eventName: 'coupon_validation_failed',
      parameters: {
        'coupon_code': couponCode,
        'failure_reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Coupon viewed by user
  static MonetizationEvent couponViewed({
    required String couponCode,
    required String context,
  }) {
    return MonetizationEvent(
      eventName: 'coupon_viewed',
      parameters: {
        'coupon_code': couponCode,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
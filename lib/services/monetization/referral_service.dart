/// Referral system for user retention and growth.
/// 
/// Manages referral codes, rewards, and tracking for both referrers and referees.
/// Provides incentives for users to invite friends and grow the user base.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_service.dart';
import 'monetization_service.dart';

/// Types of referral rewards
enum ReferralRewardType {
  extendedTrial,    // Additional trial days
  discountCoupon,   // Discount on subscription
  freeMonth,        // Free month of service
  premiumFeatures,  // Temporary access to premium features
  bonusStorage,     // Additional cloud storage
}

/// Referral reward configuration
class ReferralReward {
  final ReferralRewardType type;
  final String displayName;
  final String description;
  final Map<String, dynamic> config;
  final DateTime? expiresAt;

  const ReferralReward({
    required this.type,
    required this.displayName,
    required this.description,
    required this.config,
    this.expiresAt,
  });

  /// Create extended trial reward
  factory ReferralReward.extendedTrial({
    required int days,
    required UserTier tier,
    DateTime? expiresAt,
  }) {
    return ReferralReward(
      type: ReferralRewardType.extendedTrial,
      displayName: '$days-Day ${tier.name.toUpperCase()} Trial',
      description: 'Enjoy $days days of ${tier.name} features for free',
      config: {
        'trial_days': days,
        'tier': tier.name,
      },
      expiresAt: expiresAt,
    );
  }

  /// Create discount coupon reward
  factory ReferralReward.discountCoupon({
    required double discount,
    required bool isPercentage,
    DateTime? expiresAt,
  }) {
    final discountText = isPercentage ? '${discount.round()}% off' : '\$${discount.toStringAsFixed(2)} off';
    return ReferralReward(
      type: ReferralRewardType.discountCoupon,
      displayName: '$discountText Subscription',
      description: 'Get $discountText your next subscription purchase',
      config: {
        'discount': discount,
        'is_percentage': isPercentage,
        'max_uses': 1,
      },
      expiresAt: expiresAt,
    );
  }

  /// Create free month reward
  factory ReferralReward.freeMonth({
    required UserTier tier,
    DateTime? expiresAt,
  }) {
    return ReferralReward(
      type: ReferralRewardType.freeMonth,
      displayName: 'Free Month of ${tier.name.toUpperCase()}',
      description: 'Get one month of ${tier.name} subscription for free',
      config: {
        'tier': tier.name,
        'duration_months': 1,
      },
      expiresAt: expiresAt,
    );
  }

  /// Check if reward is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if reward is valid
  bool get isValid => !isExpired;
}

/// Referral tracking data
class ReferralData {
  final String referralCode;
  final String referrerId;
  final DateTime createdAt;
  final int totalReferrals;
  final int successfulReferrals;
  final List<ReferralReward> rewards;
  final Map<String, dynamic> analytics;

  const ReferralData({
    required this.referralCode,
    required this.referrerId,
    required this.createdAt,
    this.totalReferrals = 0,
    this.successfulReferrals = 0,
    this.rewards = const [],
    this.analytics = const {},
  });

  /// Create a copy with updated data
  ReferralData copyWith({
    String? referralCode,
    String? referrerId,
    DateTime? createdAt,
    int? totalReferrals,
    int? successfulReferrals,
    List<ReferralReward>? rewards,
    Map<String, dynamic>? analytics,
  }) {
    return ReferralData(
      referralCode: referralCode ?? this.referralCode,
      referrerId: referrerId ?? this.referrerId,
      createdAt: createdAt ?? this.createdAt,
      totalReferrals: totalReferrals ?? this.totalReferrals,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      rewards: rewards ?? this.rewards,
      analytics: analytics ?? this.analytics,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'referral_code': referralCode,
      'referrer_id': referrerId,
      'created_at': createdAt.toIso8601String(),
      'total_referrals': totalReferrals,
      'successful_referrals': successfulReferrals,
      'rewards': rewards.map((r) => {
        'type': r.type.name,
        'display_name': r.displayName,
        'description': r.description,
        'config': r.config,
        'expires_at': r.expiresAt?.toIso8601String(),
      }).toList(),
      'analytics': analytics,
    };
  }

  /// Create from JSON
  factory ReferralData.fromJson(Map<String, dynamic> json) {
    final rewardsJson = json['rewards'] as List<dynamic>? ?? [];
    final rewards = rewardsJson.map<ReferralReward>((r) {
      final rewardJson = r as Map<String, dynamic>;
      return ReferralReward(
        type: ReferralRewardType.values.firstWhere(
          (t) => t.name == rewardJson['type'],
          orElse: () => ReferralRewardType.discountCoupon,
        ),
        displayName: rewardJson['display_name'] ?? '',
        description: rewardJson['description'] ?? '',
        config: rewardJson['config'] as Map<String, dynamic>? ?? {},
        expiresAt: rewardJson['expires_at'] != null 
          ? DateTime.parse(rewardJson['expires_at']) 
          : null,
      );
    }).toList();

    return ReferralData(
      referralCode: json['referral_code'] ?? '',
      referrerId: json['referrer_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      totalReferrals: json['total_referrals'] ?? 0,
      successfulReferrals: json['successful_referrals'] ?? 0,
      rewards: rewards,
      analytics: json['analytics'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Service for managing referral system
class ReferralService extends ChangeNotifier {
  static const String _referralDataKey = 'referral_data';
  static const String _referredByKey = 'referred_by';
  static const String _pendingRewardsKey = 'pending_rewards';
  
  SharedPreferences? _prefs;
  ReferralData? _referralData;
  String? _referredBy;
  List<ReferralReward> _pendingRewards = [];
  final AnalyticsService _analytics = AnalyticsService();

  /// Current user's referral data
  ReferralData? get referralData => _referralData;

  /// Code that referred this user
  String? get referredBy => _referredBy;

  /// Pending rewards for this user
  List<ReferralReward> get pendingRewards => List.unmodifiable(_pendingRewards);

  /// Check if user has referral code
  bool get hasReferralCode => _referralData != null;

  /// Check if user was referred by someone
  bool get wasReferred => _referredBy != null;

  /// Initialize referral service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadReferralData();
    await _loadReferredBy();
    await _loadPendingRewards();
  }

  /// Load referral data from storage
  Future<void> _loadReferralData() async {
    if (_prefs == null) return;
    
    final dataJson = _prefs!.getString(_referralDataKey);
    if (dataJson != null) {
      try {
        final data = Map<String, dynamic>.from(
          jsonDecode(dataJson) as Map
        );
        _referralData = ReferralData.fromJson(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error loading referral data: $e');
        }
      }
    }
  }

  /// Load referred by data
  Future<void> _loadReferredBy() async {
    if (_prefs == null) return;
    _referredBy = _prefs!.getString(_referredByKey);
  }

  /// Load pending rewards
  Future<void> _loadPendingRewards() async {
    if (_prefs == null) return;
    
    final rewardsJson = _prefs!.getStringList(_pendingRewardsKey) ?? [];
    _pendingRewards = rewardsJson.map<ReferralReward>((json) {
      try {
        final data = Map<String, dynamic>.from(
          Uri.encodeComponent(json) as Map
        );
        return ReferralReward(
          type: ReferralRewardType.values.firstWhere(
            (t) => t.name == data['type'],
            orElse: () => ReferralRewardType.discountCoupon,
          ),
          displayName: data['display_name'] ?? '',
          description: data['description'] ?? '',
          config: data['config'] as Map<String, dynamic>? ?? {},
          expiresAt: data['expires_at'] != null 
            ? DateTime.parse(data['expires_at']) 
            : null,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error loading reward: $e');
        }
        return ReferralReward.discountCoupon(discount: 10, isPercentage: true);
      }
    }).toList();
  }

  /// Generate referral code for current user
  Future<String> generateReferralCode({required String userId}) async {
    if (_referralData != null) {
      return _referralData!.referralCode;
    }

    // Generate unique referral code
    final code = _generateUniqueCode();
    
    _referralData = ReferralData(
      referralCode: code,
      referrerId: userId,
      createdAt: DateTime.now(),
    );

    await _saveReferralData();
    
    // Track referral code generation
    _analytics.trackMonetizationEvent(
      MonetizationEvent.referralCodeGenerated(
        referralCode: code,
        userId: userId,
      ),
    );

    notifyListeners();
    return code;
  }

  /// Apply referral code when user signs up
  Future<bool> applyReferralCode(String code, {required String newUserId}) async {
    if (code.isEmpty || _referredBy != null) return false;

    // Validate referral code format
    if (!_isValidReferralCode(code)) return false;

    // Set that this user was referred
    _referredBy = code;
    await _prefs?.setString(_referredByKey, code);

    // Add welcome reward for new user
    final welcomeReward = ReferralReward.extendedTrial(
      days: 14,
      tier: UserTier.premium,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    
    await _addPendingReward(welcomeReward);

    // Track successful referral
    _analytics.trackMonetizationEvent(
      MonetizationEvent.referralApplied(
        referralCode: code,
        newUserId: newUserId,
      ),
    );

    notifyListeners();
    return true;
  }

  /// Record successful referral conversion
  Future<void> recordReferralConversion({
    required String referralCode,
    required String convertedUserId,
    required UserTier subscribedTier,
  }) async {
    if (_referralData?.referralCode == referralCode) {
      // Update referrer's data
      _referralData = _referralData!.copyWith(
        successfulReferrals: _referralData!.successfulReferrals + 1,
      );

      // Add reward for successful referral
      final referrerReward = ReferralReward.freeMonth(
        tier: subscribedTier,
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );
      
      await _addReferralReward(referrerReward);
      await _saveReferralData();
    }

    // Track conversion
    _analytics.trackMonetizationEvent(
      MonetizationEvent.referralConverted(
        referralCode: referralCode,
        convertedUserId: convertedUserId,
        subscribedTier: subscribedTier.name,
      ),
    );

    notifyListeners();
  }

  /// Add reward to user's pending rewards
  Future<void> _addPendingReward(ReferralReward reward) async {
    _pendingRewards.add(reward);
    await _savePendingRewards();
  }

  /// Add reward to referral data
  Future<void> _addReferralReward(ReferralReward reward) async {
    if (_referralData != null) {
      final updatedRewards = [..._referralData!.rewards, reward];
      _referralData = _referralData!.copyWith(rewards: updatedRewards);
    }
  }

  /// Claim a pending reward
  Future<bool> claimReward(ReferralReward reward) async {
    if (!_pendingRewards.contains(reward) || reward.isExpired) {
      return false;
    }

    _pendingRewards.remove(reward);
    await _savePendingRewards();

    // Track reward claimed
    _analytics.trackMonetizationEvent(
      MonetizationEvent.referralRewardClaimed(
        rewardType: reward.type.name,
        rewardConfig: reward.config,
      ),
    );

    notifyListeners();
    return true;
  }

  /// Get referral statistics
  Map<String, dynamic> getReferralStats() {
    if (_referralData == null) return {};

    return {
      'referral_code': _referralData!.referralCode,
      'total_referrals': _referralData!.totalReferrals,
      'successful_referrals': _referralData!.successfulReferrals,
      'conversion_rate': _referralData!.totalReferrals > 0 
        ? (_referralData!.successfulReferrals / _referralData!.totalReferrals * 100).toStringAsFixed(1)
        : '0.0',
      'total_rewards': _referralData!.rewards.length,
      'pending_rewards': _pendingRewards.length,
      'was_referred': wasReferred,
    };
  }

  /// Generate unique referral code
  String _generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    // Generate 8-character code: QN + 6 random chars
    String code = 'QN';
    for (int i = 0; i < 6; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    
    return code;
  }

  /// Validate referral code format
  bool _isValidReferralCode(String code) {
    return RegExp(r'^QN[A-Z0-9]{6}$').hasMatch(code);
  }

  /// Save referral data to storage
  Future<void> _saveReferralData() async {
    if (_prefs == null || _referralData == null) return;
    
    try {
      final dataJson = Uri.encodeComponent(_referralData!.toJson().toString());
      await _prefs!.setString(_referralDataKey, dataJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving referral data: $e');
      }
    }
  }

  /// Save pending rewards
  Future<void> _savePendingRewards() async {
    if (_prefs == null) return;
    
    try {
      final rewardsJson = _pendingRewards.map((reward) {
        return Uri.encodeComponent({
          'type': reward.type.name,
          'display_name': reward.displayName,
          'description': reward.description,
          'config': reward.config,
          'expires_at': reward.expiresAt?.toIso8601String(),
        }.toString());
      }).toList();
      
      await _prefs!.setStringList(_pendingRewardsKey, rewardsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving pending rewards: $e');
      }
    }
  }

  /// Get analytics data for reporting
  Map<String, dynamic> getAnalyticsData() {
    return {
      'has_referral_code': hasReferralCode,
      'was_referred': wasReferred,
      'referral_stats': getReferralStats(),
      'pending_rewards_count': _pendingRewards.length,
      'active_rewards_count': _pendingRewards.where((r) => r.isValid).length,
    };
  }
}

/// Extension for MonetizationEvent to add referral events
extension ReferralMonetizationEvents on MonetizationEvent {
  /// Referral code generated
  static MonetizationEvent referralCodeGenerated({
    required String referralCode,
    required String userId,
  }) {
    return MonetizationEvent(
      eventName: 'referral_code_generated',
      parameters: {
        'referral_code': referralCode,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Referral code applied by new user
  static MonetizationEvent referralApplied({
    required String referralCode,
    required String newUserId,
  }) {
    return MonetizationEvent(
      eventName: 'referral_applied',
      parameters: {
        'referral_code': referralCode,
        'new_user_id': newUserId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Referral converted to paid subscription
  static MonetizationEvent referralConverted({
    required String referralCode,
    required String convertedUserId,
    required String subscribedTier,
  }) {
    return MonetizationEvent(
      eventName: 'referral_converted',
      parameters: {
        'referral_code': referralCode,
        'converted_user_id': convertedUserId,
        'subscribed_tier': subscribedTier,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Referral reward claimed
  static MonetizationEvent referralRewardClaimed({
    required String rewardType,
    required Map<String, dynamic> rewardConfig,
  }) {
    return MonetizationEvent(
      eventName: 'referral_reward_claimed',
      parameters: {
        'reward_type': rewardType,
        'reward_config': rewardConfig,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
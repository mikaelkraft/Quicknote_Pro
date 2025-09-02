import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing pricing tiers, feature limits, and upgrade flows.
/// 
/// Provides centralized management of premium features, usage limits,
/// and upgrade paths for the monetization system.
class MonetizationService extends ChangeNotifier {
  static const String _userTierKey = 'user_tier';
  static const String _usageCountKey = 'usage_count_';
  static const String _upgradePromptCountKey = 'upgrade_prompt_count';
  
  SharedPreferences? _prefs;
  UserTier _currentTier = UserTier.free;
  final Map<FeatureType, int> _usageCounts = {};
  int _upgradePromptCount = 0;

  /// Current user tier
  UserTier get currentTier => _currentTier;

  /// Whether user has premium access
  bool get isPremium => _currentTier == UserTier.premium || _currentTier == UserTier.pro || _currentTier == UserTier.enterprise;

  /// Current usage counts by feature
  Map<FeatureType, int> get usageCounts => Map.unmodifiable(_usageCounts);

  /// Number of times upgrade prompt has been shown
  int get upgradePromptCount => _upgradePromptCount;

  /// Initialize the monetization service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserTier();
    await _loadUsageCounts();
    await _loadUpgradePromptCount();
  }

  /// Load user tier from storage
  Future<void> _loadUserTier() async {
    if (_prefs == null) return;
    
    final tierName = _prefs!.getString(_userTierKey);
    if (tierName != null) {
      _currentTier = UserTier.values.firstWhere(
        (tier) => tier.name == tierName,
        orElse: () => UserTier.free,
      );
    }
    notifyListeners();
  }

  /// Load usage counts from storage
  Future<void> _loadUsageCounts() async {
    if (_prefs == null) return;

    for (final feature in FeatureType.values) {
      _usageCounts[feature] = _prefs!.getInt('${_usageCountKey}${feature.name}') ?? 0;
    }
  }

  /// Load upgrade prompt count
  Future<void> _loadUpgradePromptCount() async {
    if (_prefs == null) return;
    
    _upgradePromptCount = _prefs!.getInt(_upgradePromptCountKey) ?? 0;
  }

  /// Set user tier (after purchase or restoration)
  Future<void> setUserTier(UserTier tier) async {
    _currentTier = tier;
    await _prefs?.setString(_userTierKey, tier.name);
    notifyListeners();
  }

  /// Check if a feature is available for the current tier
  bool isFeatureAvailable(FeatureType feature) {
    final limits = FeatureLimits.forTier(_currentTier);
    return limits.isFeatureAvailable(feature);
  }

  /// Check if feature usage is within limits
  bool canUseFeature(FeatureType feature) {
    if (!isFeatureAvailable(feature)) return false;

    final limits = FeatureLimits.forTier(_currentTier);
    final currentUsage = _usageCounts[feature] ?? 0;
    final featureLimit = limits.getFeatureLimit(feature);

    return featureLimit == -1 || currentUsage < featureLimit;
  }

  /// Record feature usage
  Future<void> recordFeatureUsage(FeatureType feature) async {
    _usageCounts[feature] = (_usageCounts[feature] ?? 0) + 1;
    await _prefs?.setInt('${_usageCountKey}${feature.name}', _usageCounts[feature]!);
    notifyListeners();
  }

  /// Get remaining usage for a feature
  int getRemainingUsage(FeatureType feature) {
    final limits = FeatureLimits.forTier(_currentTier);
    final currentUsage = _usageCounts[feature] ?? 0;
    final featureLimit = limits.getFeatureLimit(feature);

    if (featureLimit == -1) return -1; // Unlimited
    return (featureLimit - currentUsage).clamp(0, featureLimit);
  }

  /// Check if upgrade prompt should be shown
  bool shouldShowUpgradePrompt(FeatureType feature, {String? context}) {
    if (isPremium) return false;
    
    // Don't show if already shown too many times
    if (_upgradePromptCount >= 10) return false;

    // Show if feature is not available or limit reached
    return !canUseFeature(feature);
  }

  /// Record that upgrade prompt was shown
  Future<void> recordUpgradePromptShown() async {
    _upgradePromptCount++;
    await _prefs?.setInt(_upgradePromptCountKey, _upgradePromptCount);
    notifyListeners();
  }

  /// Get upgrade benefits for current tier
  List<String> getUpgradeBenefits() {
    switch (_currentTier) {
      case UserTier.free:
        return [
          'Unlimited notes and folders',
          'Advanced voice note features',
          'Extended drawing tools',
          'Premium export formats',
          'Priority cloud sync',
          'No ads',
        ];
      case UserTier.premium:
        return [
          'All premium features',
          'Advanced analytics',
          'Extended storage',
          'Priority support',
        ];
      case UserTier.pro:
        return [
          'All pro features',
        ];
      case UserTier.enterprise:
        return [
          'Team management',
          'Admin controls',
          'SSO integration',
          'Compliance features',
          'Bulk user management',
        ];
    }
  }

  /// Get recommended upgrade tier
  UserTier getRecommendedUpgrade() {
    switch (_currentTier) {
      case UserTier.free:
        return UserTier.premium;
      case UserTier.premium:
        return UserTier.pro;
      case UserTier.pro:
        return UserTier.enterprise;
      case UserTier.enterprise:
        return UserTier.enterprise; // Already at highest tier
    }
  }

  /// Reset monthly usage counters
  Future<void> resetMonthlyUsage() async {
    final monthlyFeatures = [
      FeatureType.voiceNoteRecording,
      FeatureType.cloudSync,
      FeatureType.advancedExport,
    ];

    for (final feature in monthlyFeatures) {
      _usageCounts[feature] = 0;
      await _prefs?.setInt('${_usageCountKey}${feature.name}', 0);
    }
    
    notifyListeners();
  }

  /// Get monetization analytics data
  Map<String, dynamic> getAnalyticsData() {
    return {
      'current_tier': _currentTier.name,
      'is_premium': isPremium,
      'usage_counts': _usageCounts.map((key, value) => MapEntry(key.name, value)),
      'upgrade_prompt_count': _upgradePromptCount,
    };
  }
}

/// User subscription tiers
enum UserTier {
  free,
  premium,
  pro,
  enterprise,
}

/// Feature types with usage limits
enum FeatureType {
  noteCreation,
  voiceNoteRecording,
  advancedDrawing,
  cloudSync,
  advancedExport,
  folders,
  attachments,
}

/// Feature limits by tier
class FeatureLimits {
  final Map<FeatureType, int> limits;
  final Set<FeatureType> unavailableFeatures;

  const FeatureLimits({
    required this.limits,
    this.unavailableFeatures = const {},
  });

  /// Get limits for a specific tier
  static FeatureLimits forTier(UserTier tier) {
    switch (tier) {
      case UserTier.free:
        return const FeatureLimits(
          limits: {
            FeatureType.noteCreation: 50,
            FeatureType.voiceNoteRecording: 5,
            FeatureType.cloudSync: 10,
            FeatureType.folders: 3,
            FeatureType.attachments: 10,
          },
          unavailableFeatures: {
            FeatureType.advancedDrawing,
            FeatureType.advancedExport,
          },
        );
      
      case UserTier.premium:
        return const FeatureLimits(
          limits: {
            FeatureType.noteCreation: -1, // Unlimited
            FeatureType.voiceNoteRecording: 100,
            FeatureType.advancedDrawing: -1,
            FeatureType.cloudSync: -1,
            FeatureType.advancedExport: 20,
            FeatureType.folders: -1,
            FeatureType.attachments: -1,
          },
        );
      
      case UserTier.pro:
        return const FeatureLimits(
          limits: {
            FeatureType.noteCreation: -1,
            FeatureType.voiceNoteRecording: -1,
            FeatureType.advancedDrawing: -1,
            FeatureType.cloudSync: -1,
            FeatureType.advancedExport: -1,
            FeatureType.folders: -1,
            FeatureType.attachments: -1,
          },
        );
      
      case UserTier.enterprise:
        return const FeatureLimits(
          limits: {
            FeatureType.noteCreation: -1,
            FeatureType.voiceNoteRecording: -1,
            FeatureType.advancedDrawing: -1,
            FeatureType.cloudSync: -1,
            FeatureType.advancedExport: -1,
            FeatureType.folders: -1,
            FeatureType.attachments: -1,
          },
        );
    }
  }

  /// Check if a feature is available
  bool isFeatureAvailable(FeatureType feature) {
    return !unavailableFeatures.contains(feature);
  }

  /// Get limit for a specific feature (-1 means unlimited)
  int getFeatureLimit(FeatureType feature) {
    return limits[feature] ?? 0;
  }
}

/// Pricing information for tiers
class PricingInfo {
  final UserTier tier;
  final String displayName;
  final String price;
  final String billingPeriod;
  final List<String> features;

  const PricingInfo({
    required this.tier,
    required this.displayName,
    required this.price,
    required this.billingPeriod,
    required this.features,
  });

  /// Get pricing info for all tiers
  static List<PricingInfo> getAllTiers() {
    return [
      const PricingInfo(
        tier: UserTier.free,
        displayName: 'Free',
        price: '\$0',
        billingPeriod: 'forever',
        features: [
          '50 notes per month',
          '5 voice recordings',
          '3 folders',
          'Basic sync',
        ],
      ),
      const PricingInfo(
        tier: UserTier.premium,
        displayName: 'Premium',
        price: '\$0.99',
        billingPeriod: 'month',
        features: [
          'Unlimited notes',
          '100 voice recordings',
          'Advanced drawing tools',
          'Premium export formats',
          'No ads',
        ],
      ),
      const PricingInfo(
        tier: UserTier.pro,
        displayName: 'Pro',
        price: '\$1.99',
        billingPeriod: 'month',
        features: [
          'Everything in Premium',
          'Unlimited voice recordings',
          'Priority support',
          'Advanced analytics',
          'Extended storage',
          'API access',
        ],
      ),
      const PricingInfo(
        tier: UserTier.enterprise,
        displayName: 'Enterprise',
        price: '\$4.99',
        billingPeriod: 'user/month',
        features: [
          'Everything in Pro',
          'Team management',
          'Admin controls',
          'SSO integration',
          'Compliance features',
          'Bulk user management',
          'Dedicated support',
        ],
      ),
    ];
  }
}
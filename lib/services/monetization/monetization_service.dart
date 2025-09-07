import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../analytics/analytics_service.dart';
import 'referral_service.dart';
import 'coupon_service.dart';
import 'trial_service.dart';

/// Service for managing pricing tiers, feature limits, and upgrade flows.
///
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
  final AnalyticsService _analyticsService = AnalyticsService();

  // Retention services
  final ReferralService _referralService = ReferralService();
  final CouponService _couponService = CouponService();
  final TrialService _trialService = TrialService();

  /// Current user tier
  UserTier get currentTier => _currentTier;

  /// Whether user has premium access
  bool get isPremium => _currentTier == UserTier.premium || _currentTier == UserTier.pro || _currentTier == UserTier.enterprise;

  /// Current usage counts by feature
  Map<FeatureType, int> get usageCounts => Map.unmodifiable(_usageCounts);

  /// Number of times upgrade prompt has been shown
  int get upgradePromptCount => _upgradePromptCount;

  /// Access to referral service
  ReferralService get referralService => _referralService;

  /// Access to coupon service
  CouponService get couponService => _couponService;

  /// Access to trial service
  TrialService get trialService => _trialService;

  /// Whether user has an active trial
  bool get hasActiveTrial => _trialService.hasActiveTrial;

  /// Whether user has premium access (including trial)
  bool get hasPremiumAccess => isPremium || hasActiveTrial;

  /// Initialize the monetization service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserTier();
    await _loadUsageCounts();
    await _loadUpgradePromptCount();

    // Initialize retention services
    await _referralService.initialize();
    await _couponService.initialize();
    await _trialService.initialize();
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
      _usageCounts[feature] =
          _prefs!.getInt('$_usageCountKey${feature.name}') ?? 0;
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

    // Set analytics user property
    String subscriptionStatus;
    switch (tier) {
      case UserTier.free:
        subscriptionStatus = 'free';
        break;
      case UserTier.premium:
        subscriptionStatus = 'premium';
        break;
      case UserTier.pro:
        subscriptionStatus = 'pro';
        break;
      case UserTier.enterprise:
        subscriptionStatus = 'enterprise';
        break;
    }
    await _analyticsService.setSubscriptionStatus(subscriptionStatus);

    notifyListeners();
  }

  /// Check if a feature is available for the current tier
  bool isFeatureAvailable(FeatureType feature) {
    // Check if user has trial access
    if (hasActiveTrial) {
      final trialTier = _trialService.currentTrial?.tier ?? UserTier.free;
      final trialLimits = FeatureLimits.forTier(trialTier);
      if (trialLimits.isFeatureAvailable(feature)) {
        return true;
      }
    }

    final limits = FeatureLimits.forTier(_currentTier);
    return limits.isFeatureAvailable(feature);
  }

  /// Check if feature usage is within limits
  bool canUseFeature(FeatureType feature) {
    if (!isFeatureAvailable(feature)) return false;

    // Use trial limits if in trial
    final effectiveTier =
        hasActiveTrial ? (_trialService.currentTrial?.tier ?? _currentTier) : _currentTier;

    final limits = FeatureLimits.forTier(effectiveTier);
    final currentUsage = _usageCounts[feature] ?? 0;
    final featureLimit = limits.getFeatureLimit(feature);

    return featureLimit == -1 || currentUsage < featureLimit;
  }

  /// Record feature usage
  Future<void> recordFeatureUsage(FeatureType feature) async {
    // Check if user can use this feature before recording
    if (!canUseFeature(feature)) {
      // Feature is blocked - emit limit reached event
      final limits = FeatureLimits.forTier(_currentTier);
      final currentUsage = _usageCounts[feature] ?? 0;
      final featureLimit = limits.getFeatureLimit(feature);

      _analyticsService.trackMonetizationEvent(
        MonetizationEvent.featureLimitReached(
          feature: feature.name,
          currentUsage: currentUsage,
          limit: featureLimit,
          userTier: _currentTier.name,
        ),
      );
      return;
    }

    // Record feature usage
    _usageCounts[feature] = (_usageCounts[feature] ?? 0) + 1;
    await _prefs?.setInt('$_usageCountKey${feature.name}', _usageCounts[feature]!);

    // If this is a premium feature and user has premium access, track premium feature usage
    if (hasPremiumAccess && _isPremiumFeature(feature)) {
      _analyticsService.trackMonetizationEvent(
        MonetizationEvent.premiumFeatureUsed(
          feature: feature.name,
          userTier: hasActiveTrial
              ? 'trial_${_trialService.currentTrial!.tier.name}'
              : _currentTier.name,
        ),
      );
    }

    notifyListeners();
  }

  /// Check if a feature is premium-only
  bool _isPremiumFeature(FeatureType feature) {
    final freeLimits = FeatureLimits.forTier(UserTier.free);
    return !freeLimits.isFeatureAvailable(feature);
  }

  /// Get remaining usage for a feature
  int getRemainingUsage(FeatureType feature) {
    // Use trial limits if in trial
    final effectiveTier =
        hasActiveTrial ? (_trialService.currentTrial?.tier ?? _currentTier) : _currentTier;

    final limits = FeatureLimits.forTier(effectiveTier);
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
  Future<void> recordUpgradePromptShown(
      {String? context, String? featureBlocked}) async {
    _upgradePromptCount++;
    await _prefs?.setInt(_upgradePromptCountKey, _upgradePromptCount);

    // Emit analytics event
    _analyticsService.trackMonetizationEvent(
      MonetizationEvent.upgradePromptShown(
        context: context,
        featureBlocked: featureBlocked,
        userTier: _currentTier.name,
      ),
    );

    notifyListeners();
  }

  /// Get upgrade benefits for current tier
  List<String> getUpgradeBenefits() {
    // If user has trial, show conversion benefits
    if (hasActiveTrial) {
      final trial = _trialService.currentTrial!;
      return [
        'Continue unlimited ${trial.tier.name} features',
        'No interruption to your workflow',
        'Keep all your premium notes and features',
        'Cancel anytime with full refund guarantee',
        'Priority customer support',
      ];
    }

    switch (_currentTier) {
      case UserTier.free:
        // Benefits for upgrading to Premium
        return [
          'Unlimited notes and folders',
          'Advanced voice note features',
          'Extended drawing tools',
          'Premium export formats',
          'Priority cloud sync',
          'Automatic device sync (3 devices)',
          'No ads',
        ];
      case UserTier.premium:
        // Benefits for upgrading to Pro
        return [
          'Advanced analytics & insights',
          'Extended device sync (10 devices)',
          'Automation & scheduled backups',
          'API access and custom templates',
          'Advanced encryption options',
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
        return UserTier.enterprise;
      case UserTier.enterprise:
        return UserTier.enterprise; // Already at highest tier
    }
  }

  /// Reset monthly usage counters
  Future<void> resetMonthlyUsage() async {
    final monthlyFeatures = [
      FeatureType.noteCreation,
      FeatureType.voiceNoteRecording,
      FeatureType.attachments,
      FeatureType.imageAttachments,
      FeatureType.fileAttachments,
      FeatureType.ocrTextExtraction,
      FeatureType.advancedExport,
      FeatureType.cloudExportImport,
    ];

    for (final feature in monthlyFeatures) {
      _usageCounts[feature] = 0;
      await _prefs?.setInt('$_usageCountKey${feature.name}', 0);
    }


    notifyListeners();
  }

  /// Get monetization analytics data
  Map<String, dynamic> getAnalyticsData() {
    return {
      'current_tier': _currentTier.name,
      'is_premium': isPremium,
      'has_active_trial': hasActiveTrial,
      'has_premium_access': hasPremiumAccess,
      'usage_counts':
          _usageCounts.map((key, value) => MapEntry(key.name, value)),
      'upgrade_prompt_count': _upgradePromptCount,
      'referral_data': _referralService.getAnalyticsData(),
      'coupon_data': _couponService.getAnalyticsData(),
      'trial_data': _trialService.getAnalyticsData(),
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
  // Core note-taking features
  noteCreation,
  folders,

  // Voice features
  voiceNoteRecording,
  voiceTranscription,

  // Visual features
  advancedDrawing,
  doodling,
  canvasLayers,

  // Content features
  attachments,
  imageAttachments,
  fileAttachments,
  ocrTextExtraction,

  // Sync and storage
  cloudSync,
  cloudStorage,
  deviceSync, // Automatic sync between devices
  localBackup,

  // Export and import
  basicExport, // Text export for free tier
  advancedExport, // PDF, DOCX, Markdown for paid tiers
  localExportImport, // Local file system for free tier
  cloudExportImport, // Cloud export/import for paid tiers

  // Premium features
  analyticsInsights,
  prioritySupport,
  customThemes,
  adRemoval,

  // Pro features
  apiAccess,
  advancedSearch,
  automatedBackup,
  customExportTemplates,
  advancedEncryption,

  // Enterprise features (team collaboration)
  teamWorkspace,
  adminDashboard,
  userManagement,
  ssoIntegration,
  auditLogs,
  complianceFeatures,
  customBranding,
  dedicatedSupport,
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
            // Core features with limits
            FeatureType.noteCreation: 50, // 50 notes per month
            FeatureType.voiceNoteRecording: 5, // 5 recordings per month (2min each)
            FeatureType.folders: 3, // 3 folders maximum
            FeatureType.attachments: 10, // 10 attachments per month

            // Available basic features
            FeatureType.localBackup: -1, // Unlimited local backup
            FeatureType.basicExport: -1, // Basic text export only
            FeatureType.localExportImport: -1, // Local file system access
            FeatureType.doodling: -1, // Basic doodling allowed
          },
          unavailableFeatures: {
            // Premium-only features
            FeatureType.advancedDrawing,
            FeatureType.canvasLayers,
            FeatureType.voiceTranscription,
            FeatureType.ocrTextExtraction,
            FeatureType.advancedExport,
            FeatureType.cloudExportImport,
            FeatureType.cloudSync,
            FeatureType.cloudStorage,
            FeatureType.deviceSync,
            FeatureType.customThemes,
            FeatureType.adRemoval,
            FeatureType.analyticsInsights,
            FeatureType.prioritySupport,

            // Pro-only features
            FeatureType.apiAccess,
            FeatureType.advancedSearch,
            FeatureType.automatedBackup,
            FeatureType.customExportTemplates,
            FeatureType.advancedEncryption,

            // Enterprise-only features
            FeatureType.teamWorkspace,
            FeatureType.adminDashboard,
            FeatureType.userManagement,
            FeatureType.ssoIntegration,
            FeatureType.auditLogs,
            FeatureType.complianceFeatures,
            FeatureType.customBranding,
            FeatureType.dedicatedSupport,
          },
        );


      case UserTier.premium:
        return const FeatureLimits(
          limits: {
            // Unlimited core features
            FeatureType.noteCreation: -1,
            FeatureType.folders: -1,
            FeatureType.attachments: -1,
            FeatureType.cloudSync: -1,
            FeatureType.deviceSync: 3, // 3 device sync limit

            // Voice features with premium limits
            FeatureType.voiceNoteRecording: 100, // 100 recordings per month (10min each)
            FeatureType.voiceTranscription: -1, // Unlimited transcription

            // Visual features
            FeatureType.advancedDrawing: -1,
            FeatureType.canvasLayers: -1,
            FeatureType.doodling: -1,

            // Content features
            FeatureType.imageAttachments: -1,
            FeatureType.fileAttachments: -1,
            FeatureType.ocrTextExtraction: -1,

            // Export and backup
            FeatureType.basicExport: -1,
            FeatureType.advancedExport: -1, // PDF, DOCX, Markdown
            FeatureType.localExportImport: -1,
            FeatureType.cloudExportImport: -1,
            FeatureType.localBackup: -1,

            // Premium features
            FeatureType.adRemoval: -1,
            FeatureType.customThemes: -1,
            FeatureType.prioritySupport: -1,
          },
          unavailableFeatures: {
            // Pro-only features
            FeatureType.analyticsInsights,
            FeatureType.apiAccess,
            FeatureType.advancedSearch,
            FeatureType.automatedBackup,
            FeatureType.customExportTemplates,
            FeatureType.advancedEncryption,

            // Enterprise-only features
            FeatureType.teamWorkspace,
            FeatureType.adminDashboard,
            FeatureType.userManagement,
            FeatureType.ssoIntegration,
            FeatureType.auditLogs,
            FeatureType.complianceFeatures,
            FeatureType.customBranding,
            FeatureType.dedicatedSupport,
          },
        );


      case UserTier.pro:
        return const FeatureLimits(
          limits: {
            // Everything from Premium unlimited
            FeatureType.noteCreation: -1,
            FeatureType.folders: -1,
            FeatureType.attachments: -1,
            FeatureType.cloudSync: -1,
            FeatureType.deviceSync: 10, // 10 device sync limit

            // Voice features - Pro gets unlimited with longer recordings
            FeatureType.voiceNoteRecording: -1, // Unlimited (30min each)
            FeatureType.voiceTranscription: -1,

            // All visual features
            FeatureType.advancedDrawing: -1,
            FeatureType.canvasLayers: -1,
            FeatureType.doodling: -1,

            // All content features
            FeatureType.imageAttachments: -1,
            FeatureType.fileAttachments: -1,
            FeatureType.ocrTextExtraction: -1,

            // All export and backup
            FeatureType.basicExport: -1,
            FeatureType.advancedExport: -1,
            FeatureType.localExportImport: -1,
            FeatureType.cloudExportImport: -1,
            FeatureType.localBackup: -1,
            FeatureType.automatedBackup: -1,

            // All premium features
            FeatureType.adRemoval: -1,
            FeatureType.customThemes: -1,
            FeatureType.prioritySupport: -1,

            // Pro-exclusive features
            FeatureType.analyticsInsights: -1,
            FeatureType.apiAccess: -1,
            FeatureType.advancedSearch: -1,
            FeatureType.customExportTemplates: -1,
            FeatureType.advancedEncryption: -1,
          },
          unavailableFeatures: {
            // Enterprise-only features
            FeatureType.teamWorkspace,
            FeatureType.adminDashboard,
            FeatureType.userManagement,
            FeatureType.ssoIntegration,
            FeatureType.auditLogs,
            FeatureType.complianceFeatures,
            FeatureType.customBranding,
            FeatureType.dedicatedSupport,
          },
        );

      case UserTier.enterprise:
        return const FeatureLimits(
          limits: {
            // Everything from Pro unlimited
            FeatureType.noteCreation: -1,
            FeatureType.folders: -1,
            FeatureType.attachments: -1,
            FeatureType.cloudSync: -1,
            FeatureType.deviceSync: -1, // Unlimited device sync

            // Voice features
            FeatureType.voiceNoteRecording: -1,
            FeatureType.voiceTranscription: -1,

            // All visual features
            FeatureType.advancedDrawing: -1,
            FeatureType.canvasLayers: -1,
            FeatureType.doodling: -1,

            // All content features
            FeatureType.imageAttachments: -1,
            FeatureType.fileAttachments: -1,
            FeatureType.ocrTextExtraction: -1,

            // All export and backup
            FeatureType.basicExport: -1,
            FeatureType.advancedExport: -1,
            FeatureType.localExportImport: -1,
            FeatureType.cloudExportImport: -1,
            FeatureType.localBackup: -1,
            FeatureType.automatedBackup: -1,

            // All premium and pro features
            FeatureType.adRemoval: -1,
            FeatureType.customThemes: -1,
            FeatureType.prioritySupport: -1,
            FeatureType.analyticsInsights: -1,
            FeatureType.apiAccess: -1,
            FeatureType.advancedSearch: -1,
            FeatureType.customExportTemplates: -1,
            FeatureType.advancedEncryption: -1,

            // Enterprise-exclusive features
            FeatureType.teamWorkspace: -1,
            FeatureType.adminDashboard: -1,
            FeatureType.userManagement: -1,
            FeatureType.ssoIntegration: -1,
            FeatureType.auditLogs: -1,
            FeatureType.complianceFeatures: -1,
            FeatureType.customBranding: -1,
            FeatureType.dedicatedSupport: -1,
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

/// Pricing information for tiers (Updated with retention features)
class PricingInfo {
  final UserTier tier;
  final String displayName;
  final String price;
  final String billingPeriod;
  final List<String> features;
  final bool hasTrial;
  final int? trialDays;

  const PricingInfo({
    required this.tier,
    required this.displayName,
    required this.price,
    required this.billingPeriod,
    required this.features,
    this.hasTrial = false,
    this.trialDays,
  });

  /// Get pricing info for all tiers (updated with trial information)
  static List<PricingInfo> getAllTiers() {
    return const [
      PricingInfo(
        tier: UserTier.free,
        displayName: 'Free',
        price: '\$0',
        billingPeriod: 'forever',
        hasTrial: false,
        features: [
          '50 notes per month',
          '5 voice recordings (2min each)',
          '3 folders maximum',
          '10 attachments per month',
          'Basic doodling and canvas',
          'Local export/import only',
        ],
      ),
      PricingInfo(
        tier: UserTier.premium,
        displayName: 'Premium',
        price: '\$0.99',
        billingPeriod: 'month',
        hasTrial: true,
        trialDays: 7,
        features: [
          'Unlimited notes and folders',
          '100 voice recordings (10min each)',
          'Voice note transcription',
          'Advanced drawing tools & layers',
          'OCR text extraction',
          'All export formats (PDF, DOCX)',
          'Cloud sync capabilities',
          'Custom themes',
          'No ads',
        ],
      ),
      PricingInfo(
        tier: UserTier.pro,
        displayName: 'Pro',
        price: '\$1.99',
        billingPeriod: 'month',
        hasTrial: true,
        trialDays: 14,
        features: [
          'Everything in Premium',
          'Unlimited voice recordings (30min each)',
          'Advanced search with OCR',
          'Usage analytics & insights',
          'Automated backup scheduling',
          'Custom export templates',
          'Advanced encryption options',
          'API access for integrations',
          'Enhanced cloud sync capabilities',
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

  /// Get trial info text
  String get trialText {
    if (!hasTrial || trialDays == null) return '';
    return '$trialDays-day free trial';
  }
}

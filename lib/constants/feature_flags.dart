/// Feature flags for controlling monetization and experimental features.
/// 
/// This system provides ENV-driven configuration for all monetization-related
/// features, enabling safe rollouts, A/B testing, and quick rollbacks.
class FeatureFlags {
  FeatureFlags._(); // Private constructor to prevent instantiation

  /// Environment-based configuration keys
  static const String _envPrefix = 'FEATURE_FLAG_';

  // Core monetization flags
  static const bool monetizationEnabled = bool.fromEnvironment(
    '${_envPrefix}MONETIZATION_ENABLED',
    defaultValue: true,
  );

  static const bool iapEnabled = bool.fromEnvironment(
    '${_envPrefix}IAP_ENABLED',
    defaultValue: true,
  );

  static const bool subscriptionsEnabled = bool.fromEnvironment(
    '${_envPrefix}SUBSCRIPTIONS_ENABLED',
    defaultValue: true,
  );

  // Analytics flags
  static const bool analyticsEnabled = bool.fromEnvironment(
    '${_envPrefix}ANALYTICS_ENABLED',
    defaultValue: true,
  );

  static const bool firebaseAnalyticsEnabled = bool.fromEnvironment(
    '${_envPrefix}FIREBASE_ANALYTICS_ENABLED',
    defaultValue: true,
  );

  static const bool eventTrackingEnabled = bool.fromEnvironment(
    '${_envPrefix}EVENT_TRACKING_ENABLED',
    defaultValue: true,
  );

  // Ads system flags
  static const bool adsEnabled = bool.fromEnvironment(
    '${_envPrefix}ADS_ENABLED',
    defaultValue: true,
  );

  static const bool adMobEnabled = bool.fromEnvironment(
    '${_envPrefix}ADMOB_ENABLED',
    defaultValue: true,
  );

  static const bool bannerAdsEnabled = bool.fromEnvironment(
    '${_envPrefix}BANNER_ADS_ENABLED',
    defaultValue: true,
  );

  static const bool interstitialAdsEnabled = bool.fromEnvironment(
    '${_envPrefix}INTERSTITIAL_ADS_ENABLED',
    defaultValue: true,
  );

  static const bool nativeAdsEnabled = bool.fromEnvironment(
    '${_envPrefix}NATIVE_ADS_ENABLED',
    defaultValue: true,
  );

  static const bool rewardedAdsEnabled = bool.fromEnvironment(
    '${_envPrefix}REWARDED_ADS_ENABLED',
    defaultValue: false, // Disabled by default, experimental
  );

  // Pricing and upgrade flags
  static const bool paywallEnabled = bool.fromEnvironment(
    '${_envPrefix}PAYWALL_ENABLED',
    defaultValue: true,
  );

  static const bool upgradePromptsEnabled = bool.fromEnvironment(
    '${_envPrefix}UPGRADE_PROMPTS_ENABLED',
    defaultValue: true,
  );

  static const bool trialsEnabled = bool.fromEnvironment(
    '${_envPrefix}TRIALS_ENABLED',
    defaultValue: true,
  );

  static const bool couponsEnabled = bool.fromEnvironment(
    '${_envPrefix}COUPONS_ENABLED',
    defaultValue: true,
  );

  static const bool referralsEnabled = bool.fromEnvironment(
    '${_envPrefix}REFERRALS_ENABLED',
    defaultValue: true,
  );

  // Premium feature flags
  static const bool premiumThemesEnabled = bool.fromEnvironment(
    '${_envPrefix}PREMIUM_THEMES_ENABLED',
    defaultValue: true,
  );

  static const bool advancedExportEnabled = bool.fromEnvironment(
    '${_envPrefix}ADVANCED_EXPORT_ENABLED',
    defaultValue: true,
  );

  static const bool cloudSyncEnabled = bool.fromEnvironment(
    '${_envPrefix}CLOUD_SYNC_ENABLED',
    defaultValue: true,
  );

  static const bool voiceTranscriptionEnabled = bool.fromEnvironment(
    '${_envPrefix}VOICE_TRANSCRIPTION_ENABLED',
    defaultValue: true,
  );

  static const bool ocrEnabled = bool.fromEnvironment(
    '${_envPrefix}OCR_ENABLED',
    defaultValue: true,
  );

  // Pro feature flags
  static const bool analyticsInsightsEnabled = bool.fromEnvironment(
    '${_envPrefix}ANALYTICS_INSIGHTS_ENABLED',
    defaultValue: true,
  );

  static const bool apiAccessEnabled = bool.fromEnvironment(
    '${_envPrefix}API_ACCESS_ENABLED',
    defaultValue: true,
  );

  static const bool advancedSearchEnabled = bool.fromEnvironment(
    '${_envPrefix}ADVANCED_SEARCH_ENABLED',
    defaultValue: true,
  );

  static const bool automatedBackupEnabled = bool.fromEnvironment(
    '${_envPrefix}AUTOMATED_BACKUP_ENABLED',
    defaultValue: true,
  );

  // Enterprise feature flags
  static const bool teamWorkspaceEnabled = bool.fromEnvironment(
    '${_envPrefix}TEAM_WORKSPACE_ENABLED',
    defaultValue: false, // Beta feature
  );

  static const bool ssoIntegrationEnabled = bool.fromEnvironment(
    '${_envPrefix}SSO_INTEGRATION_ENABLED',
    defaultValue: false, // Beta feature
  );

  static const bool adminDashboardEnabled = bool.fromEnvironment(
    '${_envPrefix}ADMIN_DASHBOARD_ENABLED',
    defaultValue: false, // Beta feature
  );

  // A/B testing flags
  static const bool abTestingEnabled = bool.fromEnvironment(
    '${_envPrefix}AB_TESTING_ENABLED',
    defaultValue: true,
  );

  static const bool experimentalFeaturesEnabled = bool.fromEnvironment(
    '${_envPrefix}EXPERIMENTAL_FEATURES_ENABLED',
    defaultValue: false,
  );

  // Debug and development flags
  static const bool debugMonetizationEnabled = bool.fromEnvironment(
    '${_envPrefix}DEBUG_MONETIZATION_ENABLED',
    defaultValue: false,
  );

  static const bool mockPurchasesEnabled = bool.fromEnvironment(
    '${_envPrefix}MOCK_PURCHASES_ENABLED',
    defaultValue: false,
  );

  static const bool bypassPremiumChecks = bool.fromEnvironment(
    '${_envPrefix}BYPASS_PREMIUM_CHECKS',
    defaultValue: false,
  );

  // Percentage rollout flags (0-100)
  static const int adsRolloutPercentage = int.fromEnvironment(
    '${_envPrefix}ADS_ROLLOUT_PERCENTAGE',
    defaultValue: 100,
  );

  static const int paywallRolloutPercentage = int.fromEnvironment(
    '${_envPrefix}PAYWALL_ROLLOUT_PERCENTAGE',
    defaultValue: 100,
  );

  static const int trialRolloutPercentage = int.fromEnvironment(
    '${_envPrefix}TRIAL_ROLLOUT_PERCENTAGE',
    defaultValue: 100,
  );

  static const int newUiRolloutPercentage = int.fromEnvironment(
    '${_envPrefix}NEW_UI_ROLLOUT_PERCENTAGE',
    defaultValue: 0,
  );

  // Configuration values
  static const int adFrequencyCapDaily = int.fromEnvironment(
    '${_envPrefix}AD_FREQUENCY_CAP_DAILY',
    defaultValue: 10,
  );

  static const int upgradePromptMaxDaily = int.fromEnvironment(
    '${_envPrefix}UPGRADE_PROMPT_MAX_DAILY',
    defaultValue: 3,
  );

  static const int trialDurationPremium = int.fromEnvironment(
    '${_envPrefix}TRIAL_DURATION_PREMIUM',
    defaultValue: 7,
  );

  static const int trialDurationPro = int.fromEnvironment(
    '${_envPrefix}TRIAL_DURATION_PRO',
    defaultValue: 14,
  );

  /// Get all feature flags as a map for debugging and analytics
  static Map<String, dynamic> getAllFlags() {
    return {
      // Core monetization
      'monetization_enabled': monetizationEnabled,
      'iap_enabled': iapEnabled,
      'subscriptions_enabled': subscriptionsEnabled,
      
      // Analytics
      'analytics_enabled': analyticsEnabled,
      'firebase_analytics_enabled': firebaseAnalyticsEnabled,
      'event_tracking_enabled': eventTrackingEnabled,
      
      // Ads system
      'ads_enabled': adsEnabled,
      'admob_enabled': adMobEnabled,
      'banner_ads_enabled': bannerAdsEnabled,
      'interstitial_ads_enabled': interstitialAdsEnabled,
      'native_ads_enabled': nativeAdsEnabled,
      'rewarded_ads_enabled': rewardedAdsEnabled,
      
      // Pricing and upgrades
      'paywall_enabled': paywallEnabled,
      'upgrade_prompts_enabled': upgradePromptsEnabled,
      'trials_enabled': trialsEnabled,
      'coupons_enabled': couponsEnabled,
      'referrals_enabled': referralsEnabled,
      
      // Premium features
      'premium_themes_enabled': premiumThemesEnabled,
      'advanced_export_enabled': advancedExportEnabled,
      'cloud_sync_enabled': cloudSyncEnabled,
      'voice_transcription_enabled': voiceTranscriptionEnabled,
      'ocr_enabled': ocrEnabled,
      
      // Pro features
      'analytics_insights_enabled': analyticsInsightsEnabled,
      'api_access_enabled': apiAccessEnabled,
      'advanced_search_enabled': advancedSearchEnabled,
      'automated_backup_enabled': automatedBackupEnabled,
      
      // Enterprise features
      'team_workspace_enabled': teamWorkspaceEnabled,
      'sso_integration_enabled': ssoIntegrationEnabled,
      'admin_dashboard_enabled': adminDashboardEnabled,
      
      // A/B testing
      'ab_testing_enabled': abTestingEnabled,
      'experimental_features_enabled': experimentalFeaturesEnabled,
      
      // Debug flags
      'debug_monetization_enabled': debugMonetizationEnabled,
      'mock_purchases_enabled': mockPurchasesEnabled,
      'bypass_premium_checks': bypassPremiumChecks,
      
      // Rollout percentages
      'ads_rollout_percentage': adsRolloutPercentage,
      'paywall_rollout_percentage': paywallRolloutPercentage,
      'trial_rollout_percentage': trialRolloutPercentage,
      'new_ui_rollout_percentage': newUiRolloutPercentage,
      
      // Configuration values
      'ad_frequency_cap_daily': adFrequencyCapDaily,
      'upgrade_prompt_max_daily': upgradePromptMaxDaily,
      'trial_duration_premium': trialDurationPremium,
      'trial_duration_pro': trialDurationPro,
    };
  }

  /// Check if a feature is enabled for a specific user (for percentage rollouts)
  static bool isFeatureEnabledForUser(String featureName, String userId, int rolloutPercentage) {
    if (rolloutPercentage >= 100) return true;
    if (rolloutPercentage <= 0) return false;
    
    // Use user ID hash to determine if user is in rollout percentage
    final userHash = userId.hashCode.abs();
    final userPercentile = userHash % 100;
    
    return userPercentile < rolloutPercentage;
  }

  /// Get effective ad frequency cap considering environment overrides
  static int getAdFrequencyCap(AdPlacement placement) {
    switch (placement) {
      case AdPlacement.noteListBanner:
        return adFrequencyCapDaily;
      case AdPlacement.noteCreationInterstitial:
        return int.fromEnvironment('${_envPrefix}AD_INTERSTITIAL_CAP_DAILY', defaultValue: 3);
      case AdPlacement.settingsBanner:
        return int.fromEnvironment('${_envPrefix}AD_SETTINGS_CAP_DAILY', defaultValue: 5);
      default:
        return adFrequencyCapDaily;
    }
  }

  /// Get kill switch status for emergency shutdowns
  static bool get isKillSwitchActive {
    return bool.fromEnvironment('${_envPrefix}KILL_SWITCH_ACTIVE', defaultValue: false);
  }

  /// Check if monetization should be completely disabled (kill switch)
  static bool get shouldDisableMonetization {
    return isKillSwitchActive || !monetizationEnabled;
  }
}

/// Ad placement enum (moved here for feature flag integration)
enum AdPlacement {
  noteListBanner,
  noteCreationInterstitial,
  settingsBanner,
  premiumPromptInterstitial,
  featureDiscoveryNative,
}
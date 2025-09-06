/// Monetization events schema for Firebase Analytics.
/// 
/// This file defines the canonical event names and parameter keys used
/// for tracking monetization-related events throughout the application.
/// 
/// All event names and parameters follow Firebase Analytics best practices
/// and are consistent with the documentation in docs/monetization/events.md.

/// Monetization event names
class MonetizationEvents {
  static const String adRequested = 'ad_requested';
  static const String adLoaded = 'ad_loaded';
  static const String adShown = 'ad_shown';
  static const String adClicked = 'ad_clicked';
  static const String adClosed = 'ad_closed';
  static const String adFailed = 'ad_failed';
  static const String adRevenue = 'ad_revenue';
  
  static const String upgradePromptShown = 'upgrade_prompt_shown';
  static const String upgradeStarted = 'upgrade_started';
  static const String upgradeCompleted = 'upgrade_completed';
  static const String upgradeCancelled = 'upgrade_cancelled';
  static const String upgradeRestored = 'upgrade_restored';
  
  static const String featureLimitReached = 'feature_limit_reached';
  static const String featureBlocked = 'feature_blocked';
  static const String premiumFeatureUsed = 'premium_feature_used';
  
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionRenewed = 'subscription_renewed';
  static const String subscriptionCancelled = 'subscription_cancelled';
  static const String subscriptionExpired = 'subscription_expired';
  
  static const String trialStarted = 'trial_started';
  static const String trialEnded = 'trial_ended';
  static const String trialConverted = 'trial_converted';
}

/// Monetization event parameter keys
class MonetizationParams {
  // Ad-related parameters
  static const String adPlacement = 'ad_placement';
  static const String adFormat = 'ad_format';
  static const String adUnit = 'ad_unit';
  static const String adNetwork = 'ad_network';
  static const String adRevenue = 'ad_revenue';
  static const String currency = 'currency';
  static const String errorCode = 'error_code';
  static const String errorMessage = 'error_message';
  
  // Upgrade/purchase parameters
  static const String productId = 'product_id';
  static const String priceTier = 'price_tier';
  static const String upgradeContext = 'upgrade_context';
  static const String paymentMethod = 'payment_method';
  static const String transactionId = 'transaction_id';
  static const String originalTransactionId = 'original_transaction_id';
  
  // New pricing parameters
  static const String planTerm = 'plan_term';           // monthly|annual|lifetime
  static const String region = 'region';               // base|africa
  static const String perUser = 'per_user';            // boolean for enterprise
  static const String seats = 'seats';                 // number of seats for enterprise
  static const String basePrice = 'base_price';        // base price before localization
  static const String localizedPrice = 'localized_price'; // final price in local currency
  
  // Feature-related parameters
  static const String featureName = 'feature_name';
  static const String limitType = 'limit_type';
  static const String currentUsage = 'current_usage';
  static const String maxUsage = 'max_usage';
  static const String isPremium = 'is_premium';
  
  // Subscription parameters
  static const String subscriptionType = 'subscription_type';
  static const String periodType = 'period_type';
  static const String cancellationReason = 'cancellation_reason';
  static const String renewalDate = 'renewal_date';
  
  // Trial parameters
  static const String trialDuration = 'trial_duration';
  static const String trialType = 'trial_type';
  static const String conversionRate = 'conversion_rate';
  
  // Context parameters
  static const String source = 'source';
  static const String sessionId = 'session_id';
  static const String userId = 'user_id';
  static const String appVersion = 'app_version';
  static const String platform = 'platform';
}

/// Ad placement constants for consistent tracking
class AdPlacements {
  static const String homeScreen = 'home_screen';
  static const String noteEditor = 'note_editor';
  static const String settingsScreen = 'settings_screen';
  static const String searchResults = 'search_results';
  static const String exportDialog = 'export_dialog';
  static const String upgradePrompt = 'upgrade_prompt';
  static const String interstitial = 'interstitial';
  static const String banner = 'banner';
  static const String rewarded = 'rewarded';
}

/// Feature names for limit tracking
class FeatureNames {
  static const String noteCreation = 'note_creation';
  static const String cloudSync = 'cloud_sync';
  static const String voiceNotes = 'voice_notes';
  static const String doodling = 'doodling';
  static const String ocrScanning = 'ocr_scanning';
  static const String exportOptions = 'export_options';
  static const String themes = 'themes';
  static const String backupRestore = 'backup_restore';
  static const String attachments = 'attachments';
  static const String widgets = 'widgets';
}

/// Product ID constants for purchases
class ProductIds {
  static const String premiumMonthly = 'premium_monthly';
  static const String premiumYearly = 'premium_yearly';
  static const String premiumLifetime = 'premium_lifetime';
  static const String adRemoval = 'ad_removal';
  static const String cloudStorage = 'cloud_storage';
}

/// Helper functions for creating consistent event parameters
class MonetizationEventHelpers {
  /// Create standard ad event parameters
  static Map<String, Object?> adEventParams({
    required String placement,
    String? format,
    String? unit,
    String? network,
    double? revenue,
    String? currency,
    String? errorCode,
    String? errorMessage,
  }) {
    final params = <String, Object?>{
      MonetizationParams.adPlacement: placement,
    };
    
    if (format != null) params[MonetizationParams.adFormat] = format;
    if (unit != null) params[MonetizationParams.adUnit] = unit;
    if (network != null) params[MonetizationParams.adNetwork] = network;
    if (revenue != null) params[MonetizationParams.adRevenue] = revenue;
    if (currency != null) params[MonetizationParams.currency] = currency;
    if (errorCode != null) params[MonetizationParams.errorCode] = errorCode;
    if (errorMessage != null) params[MonetizationParams.errorMessage] = errorMessage;
    
    return params..removeWhere((key, value) => value == null);
  }
  
  /// Create standard upgrade event parameters
  static Map<String, Object?> upgradeEventParams({
    required String context,
    String? productId,
    String? priceTier,
    String? paymentMethod,
    String? transactionId,
    String? planTerm,
    String? region,
    bool? perUser,
    int? seats,
    double? basePrice,
    double? localizedPrice,
  }) {
    final params = <String, Object?>{
      MonetizationParams.upgradeContext: context,
    };
    
    if (productId != null) params[MonetizationParams.productId] = productId;
    if (priceTier != null) params[MonetizationParams.priceTier] = priceTier;
    if (paymentMethod != null) params[MonetizationParams.paymentMethod] = paymentMethod;
    if (transactionId != null) params[MonetizationParams.transactionId] = transactionId;
    if (planTerm != null) params[MonetizationParams.planTerm] = planTerm;
    if (region != null) params[MonetizationParams.region] = region;
    if (perUser != null) params[MonetizationParams.perUser] = perUser;
    if (seats != null) params[MonetizationParams.seats] = seats;
    if (basePrice != null) params[MonetizationParams.basePrice] = basePrice;
    if (localizedPrice != null) params[MonetizationParams.localizedPrice] = localizedPrice;
    
    return params..removeWhere((key, value) => value == null);
  }
  
  /// Create standard feature limit event parameters
  static Map<String, Object?> featureLimitParams({
    required String featureName,
    String? limitType,
    int? currentUsage,
    int? maxUsage,
    bool? isPremium,
  }) {
    final params = <String, Object?>{
      MonetizationParams.featureName: featureName,
    };
    
    if (limitType != null) params[MonetizationParams.limitType] = limitType;
    if (currentUsage != null) params[MonetizationParams.currentUsage] = currentUsage;
    if (maxUsage != null) params[MonetizationParams.maxUsage] = maxUsage;
    if (isPremium != null) params[MonetizationParams.isPremium] = isPremium;
    
    return params..removeWhere((key, value) => value == null);
  }
  
  /// Add common context parameters to any event
  static Map<String, Object?> addContextParams(
    Map<String, Object?> params, {
    String? source,
    String? sessionId,
    String? userId,
    String? appVersion,
    String? platform,
  }) {
    final result = Map<String, Object?>.from(params);
    
    if (source != null) result[MonetizationParams.source] = source;
    if (sessionId != null) result[MonetizationParams.sessionId] = sessionId;
    if (userId != null) result[MonetizationParams.userId] = userId;
    if (appVersion != null) result[MonetizationParams.appVersion] = appVersion;
    if (platform != null) result[MonetizationParams.platform] = platform;
    
    return result..removeWhere((key, value) => value == null);
  }
}
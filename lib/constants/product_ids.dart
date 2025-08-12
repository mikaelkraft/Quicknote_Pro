/// Centralized premium product IDs for consistent usage across the app.
/// 
/// These IDs must match exactly with the ones configured in:
/// - Google Play Console (Android)
/// - App Store Connect (iOS) 
/// - Web payment provider
class ProductIds {
  ProductIds._(); // Private constructor to prevent instantiation

  /// Monthly premium subscription product ID
  /// Price: $2.99/month
  static const String premiumMonthly = 'quicknote_premium_monthly';

  /// Lifetime premium purchase product ID  
  /// Price: $14.99 one-time
  static const String premiumLifetime = 'quicknote_premium_lifetime';

  /// Free trial product ID (for tracking)
  static const String freeTrial = 'quicknote_free_trial';

  /// List of all premium product IDs for easy iteration
  static const List<String> allProductIds = [
    premiumMonthly,
    premiumLifetime,
  ];

  /// List of subscription product IDs
  static const List<String> subscriptionProductIds = [
    premiumMonthly,
  ];

  /// List of one-time purchase product IDs
  static const List<String> oneTimeProductIds = [
    premiumLifetime,
  ];

  /// Map of product IDs to their display names
  static const Map<String, String> productDisplayNames = {
    premiumMonthly: 'Premium Monthly',
    premiumLifetime: 'Premium Lifetime',
    freeTrial: 'Free Trial',
  };

  /// Map of product IDs to their prices (for display when store data unavailable)
  static const Map<String, String> fallbackPrices = {
    premiumMonthly: '\$2.99',
    premiumLifetime: '\$14.99',
  };

  /// Map of product IDs to their detailed descriptions
  static const Map<String, String> productDescriptions = {
    premiumMonthly: 'Monthly subscription with all premium features. Cancel anytime.',
    premiumLifetime: 'One-time purchase for lifetime access to all premium features.',
    freeTrial: '7-day free trial with all premium features.',
  };

  /// Map of product IDs to their savings information
  static const Map<String, String?> productSavings = {
    premiumMonthly: null,
    premiumLifetime: 'Save 75% vs monthly',
    freeTrial: 'Free for 7 days',
  };

  /// Pricing configuration
  static const Map<String, dynamic> pricingConfig = {
    'monthly_price_usd': 2.99,
    'lifetime_price_usd': 14.99,
    'trial_days': 7,
    'monthly_billing_cycle_days': 30,
    'lifetime_savings_percent': 75,
    'currency_symbol': '\$',
  };

  /// Feature flags for premium functionality
  static const bool iapEnabled = true; // Set to false to disable IAP completely
  static const bool allowDevBypass = true; // Allow dev toggle in debug builds
  static const bool trialsEnabled = true; // Set to false to disable trials
  static const bool giftingEnabled = false; // Set to true to enable gifting
  static const bool discountsEnabled = false; // Set to true to enable promotional pricing

  /// Trial configuration
  static const int defaultTrialDays = 7;
  static const bool trialRequiresPaymentMethod = false;

  /// Upgrade prompts configuration
  static const Map<String, dynamic> upgradePromptConfig = {
    'show_after_days': 3, // Show upgrade prompts after X days of usage
    'max_prompts_per_day': 2, // Maximum upgrade prompts per day
    'prompt_cooldown_hours': 4, // Hours between prompts
    'trial_reminder_days': [5, 2, 1], // Days before trial expiry to remind
  };

  /// Get localized price string
  static String getLocalizedPrice(String productId, {String? locale}) {
    // In a real implementation, this would use the store's localized pricing
    // For now, return fallback prices
    return fallbackPrices[productId] ?? '\$0.00';
  }

  /// Get product savings percentage
  static int? getSavingsPercent(String productId) {
    switch (productId) {
      case premiumLifetime:
        return pricingConfig['lifetime_savings_percent'] as int;
      default:
        return null;
    }
  }

  /// Check if product is a subscription
  static bool isSubscription(String productId) {
    return subscriptionProductIds.contains(productId);
  }

  /// Check if product is a one-time purchase
  static bool isOneTimePurchase(String productId) {
    return oneTimeProductIds.contains(productId);
  }

  /// Get recommended product ID based on context
  static String getRecommendedProduct() {
    return premiumLifetime; // Lifetime is the recommended option
  }
}
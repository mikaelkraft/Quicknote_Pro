/// Centralized premium product IDs for consistent usage across the app.
/// 
/// These IDs must match exactly with the ones configured in:
/// - Google Play Console (Android)
/// - App Store Connect (iOS) 
/// - Web payment provider
class ProductIds {
  ProductIds._(); // Private constructor to prevent instantiation

  /// Monthly premium subscription product ID
  /// Price: $0.99/month
  static const String premiumMonthly = 'quicknote_premium_monthly';

  /// Monthly pro subscription product ID
  /// Price: $1.99/month
  static const String proMonthly = 'quicknote_pro_monthly';

  /// Lifetime premium purchase product ID  
  /// Price: $9.99 one-time
  static const String premiumLifetime = 'quicknote_premium_lifetime';

  /// Lifetime pro purchase product ID
  /// Price: $19.99 one-time
  static const String proLifetime = 'quicknote_pro_lifetime';

  /// List of all premium product IDs for easy iteration
  static const List<String> allProductIds = [
    premiumMonthly,
    premiumLifetime,
    proMonthly,
    proLifetime,
  ];

  /// Map of product IDs to their display names
  static const Map<String, String> productDisplayNames = {
    premiumMonthly: 'Premium Monthly',
    premiumLifetime: 'Premium Lifetime',
    proMonthly: 'Pro Monthly',
    proLifetime: 'Pro Lifetime',
  };

  /// Map of product IDs to their prices (for display when store data unavailable)
  static const Map<String, String> fallbackPrices = {
    premiumMonthly: '\$0.99',
    premiumLifetime: '\$9.99',
    proMonthly: '\$1.99',
    proLifetime: '\$19.99',
  };

  /// Feature flags for premium functionality
  static const bool iapEnabled = true; // Set to false to disable IAP completely
  static const bool allowDevBypass = true; // Allow dev toggle in debug builds
}
/// Centralized premium product IDs for consistent usage across the app.
/// 
/// These IDs must match exactly with the ones configured in:
/// - Google Play Console (Android)
/// - App Store Connect (iOS) 
/// - Web payment provider
class ProductIds {
  ProductIds._(); // Private constructor to prevent instantiation

  /// Monthly premium subscription product ID
  /// Price: $1.00/month
  static const String premiumMonthly = 'quicknote_premium_monthly';

  /// Lifetime premium purchase product ID  
  /// Price: $5.00 one-time
  static const String premiumLifetime = 'quicknote_premium_lifetime';

  /// List of all premium product IDs for easy iteration
  static const List<String> allProductIds = [
    premiumMonthly,
    premiumLifetime,
  ];

  /// Map of product IDs to their display names
  static const Map<String, String> productDisplayNames = {
    premiumMonthly: 'Premium Monthly',
    premiumLifetime: 'Premium Lifetime',
  };

  /// Map of product IDs to their prices (for display when store data unavailable)
  static const Map<String, String> fallbackPrices = {
    premiumMonthly: '\$1.00',
    premiumLifetime: '\$5.00',
  };

  /// Feature flags for premium functionality
  static const bool iapEnabled = true; // Set to false to disable IAP completely
  static const bool allowDevBypass = true; // Allow dev toggle in debug builds
}
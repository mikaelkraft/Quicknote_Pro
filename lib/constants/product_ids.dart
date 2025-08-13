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

  /// Weekly trial product ID  
  /// Price: Free for 7 days, then $2.99/month
  static const String premiumWeeklyTrial = 'quicknote_premium_weekly_trial';

  /// List of all premium product IDs for easy iteration
  static const List<String> allProductIds = [
    premiumMonthly,
    premiumLifetime,
    premiumWeeklyTrial,
  ];

  /// Map of product IDs to their display names
  static const Map<String, String> productDisplayNames = {
    premiumMonthly: 'Premium Monthly',
    premiumLifetime: 'Premium Lifetime',
    premiumWeeklyTrial: 'Premium Trial',
  };

  /// Map of product IDs to their prices (for display when store data unavailable)
  static const Map<String, String> fallbackPrices = {
    premiumMonthly: '\$2.99',
    premiumLifetime: '\$14.99',
    premiumWeeklyTrial: 'Free',
  };

  /// Feature flags for premium functionality
  static const bool iapEnabled = true; // Set to false to disable IAP completely
  static const bool allowDevBypass = true; // Allow dev toggle in debug builds

  /// Free tier limits
  static const int freeNotesLimit = 50;
  static const int freeVoiceNotesLimit = 10;
  static const int freeAttachmentsLimit = 5;
  static const int freeCloudStorageMB = 100;

  /// Premium tier benefits
  static const List<String> premiumFeatures = [
    'Unlimited notes and voice recordings',
    'Advanced drawing tools with layers',
    'Cloud sync across all devices',
    'Ad-free experience',
    'Premium support',
    'Export to multiple formats',
    'OCR text recognition',
    'Folder organization',
    'Backup and restore',
  ];
}
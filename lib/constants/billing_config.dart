/// Configuration for billing and payment providers
/// 
/// This file contains API keys and configuration for RevenueCat and Paystack.
/// In production, these should be loaded from environment variables or secure storage.
class BillingConfig {
  BillingConfig._(); // Private constructor

  /// RevenueCat Configuration
  static const String revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: 'your_revenuecat_android_api_key_here', // Placeholder
  );

  static const String revenueCatApiKeyIOS = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS', 
    defaultValue: 'your_revenuecat_ios_api_key_here', // Placeholder
  );

  static const String revenueCatRestApiKey = String.fromEnvironment(
    'REVENUECAT_REST_API_KEY',
    defaultValue: 'your_revenuecat_rest_api_key_here', // Placeholder
  );

  /// Paystack Configuration
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'your_paystack_public_key_here', // Placeholder
  );

  static const String paystackSecretKey = String.fromEnvironment(
    'PAYSTACK_SECRET_KEY',
    defaultValue: 'your_paystack_secret_key_here', // Placeholder
  );

  /// Webhook Configuration
  static const String webhookEndpoint = String.fromEnvironment(
    'WEBHOOK_ENDPOINT',
    defaultValue: 'https://your-domain.com/webhook/paystack', // Placeholder
  );

  static const String webhookSecret = String.fromEnvironment(
    'WEBHOOK_SECRET',
    defaultValue: 'your_webhook_secret_here', // Placeholder
  );

  /// Environment Configuration
  static const bool isProduction = bool.fromEnvironment(
    'BILLING_PRODUCTION',
    defaultValue: false,
  );

  static const bool enableLogging = bool.fromEnvironment(
    'BILLING_ENABLE_LOGGING',
    defaultValue: true,
  );

  /// RevenueCat Entitlement Identifiers
  static const String premiumEntitlementId = 'premium';
  static const String proEntitlementId = 'pro';
  static const String enterpriseEntitlementId = 'enterprise';

  /// Paystack Metadata Keys
  static const String paystackMetadataUserIdKey = 'user_id';
  static const String paystackMetadataProductIdKey = 'product_id';
  static const String paystackMetadataEntitlementKey = 'entitlement_id';
  static const String paystackMetadataPlatformKey = 'platform';

  /// Get the appropriate RevenueCat API key for the current platform
  static String getRevenueCatApiKey() {
    // This would be determined by the platform in a real implementation
    // For now, return Android key as we're focusing on Android first
    return revenueCatApiKeyAndroid;
  }

  /// Validate configuration
  static bool isConfigurationValid() {
    if (!revenueCatApiKeyAndroid.startsWith('your_') && 
        !paystackPublicKey.startsWith('your_')) {
      return true;
    }
    return false;
  }

  /// Get configuration for debugging
  static Map<String, dynamic> getDebugInfo() {
    return {
      'revenuecat_configured': !revenueCatApiKeyAndroid.startsWith('your_'),
      'paystack_configured': !paystackPublicKey.startsWith('your_'),
      'is_production': isProduction,
      'logging_enabled': enableLogging,
      'webhook_endpoint': webhookEndpoint,
    };
  }
}
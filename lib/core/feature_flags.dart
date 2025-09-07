/// Feature flags for controlling optional functionality
/// These flags allow the app to build and run without external dependencies
class FeatureFlags {
  // Private constructor to prevent instantiation
  const FeatureFlags._();
  
  // IAP feature flag - disable for builds without store configuration
  static const bool enableIAP = false;
  
  // iCloud sync feature flag - disable without proper entitlements
  static const bool enableiCloudSync = false;
  
  // Development mode for testing premium features
  static const bool isDevelopment = true;
  
  // Enable local entitlement simulation for testing
  static const bool enableLocalEntitlements = true;
}
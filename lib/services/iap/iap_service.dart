import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/product_ids.dart';

/// In-App Purchase service skeleton with feature flags
/// 
/// Provides IAP functionality with dev bypass and proper
/// entitlement management. Full implementation requires
/// platform-specific store integration.
class IAPService extends ChangeNotifier {
  static const String _devBypassKey = 'dev_premium_bypass';
  static const String _entitlementKey = 'user_entitlement';

  bool _isInitialized = false;
  bool _devBypassEnabled = false;
  Set<String> _activeEntitlements = {};
  SharedPreferences? _prefs;

  /// Whether IAP is enabled via feature flag
  bool get isIAPEnabled => ProductIds.iapEnabled;
  
  /// Whether dev bypass is allowed
  bool get isDevBypassAllowed => ProductIds.allowDevBypass && kDebugMode;
  
  /// Whether dev bypass is currently enabled
  bool get isDevBypassEnabled => _devBypassEnabled;
  
  /// Whether the user has any premium entitlement
  bool get hasPremiumAccess => 
      _activeEntitlements.isNotEmpty || (_devBypassEnabled && isDevBypassAllowed);
  
  /// Whether user has monthly subscription
  bool get hasMonthlySubscription => 
      _activeEntitlements.contains(ProductIds.premiumMonthly);
  
  /// Whether user has lifetime purchase
  bool get hasLifetimePurchase => 
      _activeEntitlements.contains(ProductIds.premiumLifetime);
  
  /// All active entitlements
  Set<String> get activeEntitlements => Set.unmodifiable(_activeEntitlements);

  /// Initialize the IAP service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadStoredEntitlements();
    
    if (isIAPEnabled) {
      await _initializePlatformStore();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Load stored entitlements from preferences
  Future<void> _loadStoredEntitlements() async {
    if (_prefs == null) return;

    // Load dev bypass setting
    _devBypassEnabled = _prefs!.getBool(_devBypassKey) ?? false;
    
    // Load entitlements
    final entitlementsJson = _prefs!.getStringList(_entitlementKey) ?? [];
    _activeEntitlements = entitlementsJson.toSet();
  }

  /// Initialize platform-specific store
  Future<void> _initializePlatformStore() async {
    // TODO: Initialize platform stores
    // - For Android: Initialize Google Play Billing
    // - For iOS: Initialize StoreKit
    // - For Web: Initialize web payment provider
    
    debugPrint('IAP: Platform store initialization placeholder');
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    if (!isIAPEnabled) {
      return false;
    }

    try {
      // TODO: Implement actual purchase flow
      // This is a placeholder that simulates purchase
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful purchase
      await _grantEntitlement(productId);
      return true;
    } catch (e) {
      debugPrint('IAP: Purchase failed: $e');
      return false;
    }
  }

  /// Restore purchases (for iOS and lost purchases)
  Future<bool> restorePurchases() async {
    if (!isIAPEnabled) {
      return false;
    }

    try {
      // TODO: Implement actual restore flow
      // Query platform stores for existing purchases
      await Future.delayed(const Duration(seconds: 1));
      
      // For now, no purchases to restore
      return true;
    } catch (e) {
      debugPrint('IAP: Restore failed: $e');
      return false;
    }
  }

  /// Grant an entitlement (internal method for purchase completion)
  Future<void> _grantEntitlement(String productId) async {
    _activeEntitlements.add(productId);
    
    if (_prefs != null) {
      await _prefs!.setStringList(_entitlementKey, _activeEntitlements.toList());
    }
    
    notifyListeners();
  }

  /// Revoke an entitlement (for subscription cancellation)
  Future<void> _revokeEntitlement(String productId) async {
    _activeEntitlements.remove(productId);
    
    if (_prefs != null) {
      await _prefs!.setStringList(_entitlementKey, _activeEntitlements.toList());
    }
    
    notifyListeners();
  }

  /// Toggle dev bypass (debug builds only)
  Future<void> toggleDevBypass() async {
    if (!isDevBypassAllowed) return;

    _devBypassEnabled = !_devBypassEnabled;
    
    if (_prefs != null) {
      await _prefs!.setBool(_devBypassKey, _devBypassEnabled);
    }
    
    notifyListeners();
  }

  /// Check if a specific feature is available
  bool hasFeatureAccess(String featureId) {
    // All premium features require premium access
    return hasPremiumAccess;
  }

  /// Get user's subscription status for display
  Map<String, dynamic> getSubscriptionStatus() {
    return {
      'hasPremium': hasPremiumAccess,
      'hasMonthly': hasMonthlySubscription,
      'hasLifetime': hasLifetimePurchase,
      'devBypass': _devBypassEnabled && isDevBypassAllowed,
      'entitlements': _activeEntitlements.toList(),
    };
  }

  /// Validate entitlements with server (if applicable)
  Future<void> validateEntitlements() async {
    // TODO: Implement server-side validation if needed
    // This would be used for subscription verification
    // and anti-piracy measures
  }

  /// Clear all entitlements (for testing or account deletion)
  Future<void> clearAllEntitlements() async {
    _activeEntitlements.clear();
    _devBypassEnabled = false;
    
    if (_prefs != null) {
      await _prefs!.remove(_entitlementKey);
      await _prefs!.remove(_devBypassKey);
    }
    
    notifyListeners();
  }

  /// Get pricing information for products
  Future<Map<String, String>> getProductPrices() async {
    if (!isIAPEnabled) {
      return ProductIds.fallbackPrices;
    }

    try {
      // TODO: Query actual prices from platform stores
      // Return platform-specific pricing
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For now, return fallback prices
      return ProductIds.fallbackPrices;
    } catch (e) {
      debugPrint('IAP: Failed to get prices: $e');
      return ProductIds.fallbackPrices;
    }
  }

  /// Dispose of IAP service
  @override
  void dispose() {
    // TODO: Dispose of platform store connections
    super.dispose();
  }
}
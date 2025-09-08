import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monetization_service.dart';
import '../../constants/product_ids.dart';
import '../analytics/analytics_service.dart';

/// Service for managing RevenueCat integration and subscription entitlements.
/// 
/// Provides tiered entitlement management through RevenueCat's subscription platform.
/// Handles subscription status, product offerings, and entitlement verification.
class RevenueCatService extends ChangeNotifier {
  static const String _entitlementKey = 'revenuecat_entitlement';
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _customerInfoKey = 'customer_info';

  SharedPreferences? _prefs;
  final AnalyticsService _analyticsService = AnalyticsService();
  
  // Current entitlement status
  Map<String, bool> _entitlements = {};
  String _activeSubscription = '';
  DateTime? _subscriptionExpiryDate;
  bool _isInitialized = false;

  /// Current entitlements map
  Map<String, bool> get entitlements => Map.unmodifiable(_entitlements);

  /// Active subscription product ID
  String get activeSubscription => _activeSubscription;

  /// Subscription expiry date
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;

  /// Whether RevenueCat is initialized
  bool get isInitialized => _isInitialized;

  /// Whether user has premium entitlement
  bool get hasPremiumEntitlement => _entitlements['premium'] == true;

  /// Whether user has pro entitlement  
  bool get hasProEntitlement => _entitlements['pro'] == true;

  /// Whether user has enterprise entitlement
  bool get hasEnterpriseEntitlement => _entitlements['enterprise'] == true;

  /// Initialize RevenueCat service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadStoredData();
      
      // TODO: Initialize RevenueCat SDK when available
      // await Purchases.setDebugLogsEnabled(kDebugMode);
      // await Purchases.configure(PurchasesConfiguration(apiKey));
      
      _isInitialized = true;
      await _refreshEntitlements();
      
      _analyticsService.trackMonetizationEvent(
        MonetizationEvent.entitlementCheck(),
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
      // Fallback to cached data
      _isInitialized = false;
    }
  }

  /// Get current user tier based on entitlements
  UserTier getCurrentTier() {
    if (hasEnterpriseEntitlement) return UserTier.enterprise;
    if (hasProEntitlement) return UserTier.pro;
    if (hasPremiumEntitlement) return UserTier.premium;
    return UserTier.free;
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    try {
      _analyticsService.trackMonetizationEvent(
        MonetizationEvent.upgradeStarted(
          tier: _getProductTier(productId),
          context: 'revenuecat_purchase',
        ),
      );

      // TODO: Implement actual RevenueCat purchase flow
      // final result = await Purchases.purchaseProduct(productId);
      // await _handlePurchaseResult(result);
      
      // For now, simulate successful purchase in debug mode
      if (kDebugMode) {
        await _simulatePurchase(productId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      _analyticsService.trackMonetizationEvent(
        MonetizationEvent.upgradeCancelled(
          tier: _getProductTier(productId),
          reason: 'purchase_error',
        ),
      );
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      _analyticsService.trackMonetizationEvent(
        MonetizationEvent.restorePurchases(source: 'user_initiated'),
      );

      // TODO: Implement actual RevenueCat restore
      // final result = await Purchases.restorePurchases();
      // await _handleRestoreResult(result);
      
      await _refreshEntitlements();
      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  /// Check if user has access to a specific feature
  bool hasFeatureAccess(String feature) {
    switch (feature) {
      case 'premium_features':
        return hasPremiumEntitlement || hasProEntitlement || hasEnterpriseEntitlement;
      case 'pro_features':
        return hasProEntitlement || hasEnterpriseEntitlement;
      case 'enterprise_features':
        return hasEnterpriseEntitlement;
      case 'unlimited_voice_recording':
        return hasProEntitlement || hasEnterpriseEntitlement;
      case 'advanced_drawing':
        return hasPremiumEntitlement || hasProEntitlement || hasEnterpriseEntitlement;
      case 'ocr_features':
        return hasPremiumEntitlement || hasProEntitlement || hasEnterpriseEntitlement;
      case 'team_management':
        return hasEnterpriseEntitlement;
      default:
        return false;
    }
  }

  /// Get available products for purchase
  List<ProductInfo> getAvailableProducts() {
    return [
      ProductInfo(
        id: ProductIds.premiumMonthly,
        title: ProductIds.productDisplayNames[ProductIds.premiumMonthly]!,
        price: ProductIds.fallbackPrices[ProductIds.premiumMonthly]!,
        tier: UserTier.premium,
      ),
      ProductInfo(
        id: ProductIds.premiumAnnual,
        title: ProductIds.productDisplayNames[ProductIds.premiumAnnual]!,
        price: ProductIds.fallbackPrices[ProductIds.premiumAnnual]!,
        tier: UserTier.premium,
      ),
      ProductInfo(
        id: ProductIds.premiumLifetime,
        title: ProductIds.productDisplayNames[ProductIds.premiumLifetime]!,
        price: ProductIds.fallbackPrices[ProductIds.premiumLifetime]!,
        tier: UserTier.premium,
      ),
      ProductInfo(
        id: ProductIds.proMonthly,
        title: ProductIds.productDisplayNames[ProductIds.proMonthly]!,
        price: ProductIds.fallbackPrices[ProductIds.proMonthly]!,
        tier: UserTier.pro,
      ),
      ProductInfo(
        id: ProductIds.proAnnual,
        title: ProductIds.productDisplayNames[ProductIds.proAnnual]!,
        price: ProductIds.fallbackPrices[ProductIds.proAnnual]!,
        tier: UserTier.pro,
      ),
      ProductInfo(
        id: ProductIds.proLifetime,
        title: ProductIds.productDisplayNames[ProductIds.proLifetime]!,
        price: ProductIds.fallbackPrices[ProductIds.proLifetime]!,
        tier: UserTier.pro,
      ),
      ProductInfo(
        id: ProductIds.enterpriseMonthly,
        title: ProductIds.productDisplayNames[ProductIds.enterpriseMonthly]!,
        price: ProductIds.fallbackPrices[ProductIds.enterpriseMonthly]!,
        tier: UserTier.enterprise,
      ),
      ProductInfo(
        id: ProductIds.enterpriseAnnual,
        title: ProductIds.productDisplayNames[ProductIds.enterpriseAnnual]!,
        price: ProductIds.fallbackPrices[ProductIds.enterpriseAnnual]!,
        tier: UserTier.enterprise,
      ),
    ];
  }

  /// Load stored data from preferences
  Future<void> _loadStoredData() async {
    final entitlementsJson = _prefs?.getString(_entitlementKey);
    if (entitlementsJson != null) {
      // TODO: Implement JSON parsing when needed
      // _entitlements = Map<String, bool>.from(jsonDecode(entitlementsJson));
    }
    
    _activeSubscription = _prefs?.getString(_subscriptionStatusKey) ?? '';
    
    final expiryTimestamp = _prefs?.getInt('subscription_expiry');
    if (expiryTimestamp != null) {
      _subscriptionExpiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    }
  }

  /// Refresh entitlements from RevenueCat
  Future<void> _refreshEntitlements() async {
    try {
      // TODO: Implement actual RevenueCat entitlement check
      // final customerInfo = await Purchases.getCustomerInfo();
      // _processCustomerInfo(customerInfo);
      
      // For now, use stored data or defaults
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh entitlements: $e');
    }
  }

  /// Simulate purchase for testing
  Future<void> _simulatePurchase(String productId) async {
    final tier = _getProductTier(productId);
    
    // Grant appropriate entitlements
    switch (tier) {
      case 'premium':
        _entitlements['premium'] = true;
        break;
      case 'pro':
        _entitlements['premium'] = true;
        _entitlements['pro'] = true;
        break;
      case 'enterprise':
        _entitlements['premium'] = true;
        _entitlements['pro'] = true;
        _entitlements['enterprise'] = true;
        break;
    }
    
    _activeSubscription = productId;
    _subscriptionExpiryDate = DateTime.now().add(const Duration(days: 365));
    
    await _saveEntitlements();
    
    _analyticsService.trackMonetizationEvent(
      MonetizationEvent.upgradeCompleted(tier: tier),
    );
    
    notifyListeners();
  }

  /// Save entitlements to storage
  Future<void> _saveEntitlements() async {
    // TODO: Implement JSON encoding when needed
    // final entitlementsJson = jsonEncode(_entitlements);
    // await _prefs?.setString(_entitlementKey, entitlementsJson);
    
    await _prefs?.setString(_subscriptionStatusKey, _activeSubscription);
    
    if (_subscriptionExpiryDate != null) {
      await _prefs?.setInt('subscription_expiry', 
          _subscriptionExpiryDate!.millisecondsSinceEpoch);
    }
  }

  /// Get tier name from product ID
  String _getProductTier(String productId) {
    if (productId.contains('enterprise')) return 'enterprise';
    if (productId.contains('pro')) return 'pro';
    if (productId.contains('premium')) return 'premium';
    return 'free';
  }
}

/// Product information for RevenueCat integration
class ProductInfo {
  final String id;
  final String title;
  final String price;
  final UserTier tier;

  const ProductInfo({
    required this.id,
    required this.title,
    required this.price,
    required this.tier,
  });
}
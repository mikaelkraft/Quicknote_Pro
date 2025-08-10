import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/feature_flags.dart';

// Conditional import for IAP - only when enabled
import 'package:in_app_purchase/in_app_purchase.dart' as iap_lib
    show InAppPurchase, ProductDetails, PurchaseDetails, IAPError;

/// In-App Purchase service with local entitlement fallback
/// Provides a safe interface for premium features without requiring store setup
class IAPService extends ChangeNotifier {
  static const String monthlyProductId = 'quicknote_premium_monthly';
  static const String lifetimeProductId = 'quicknote_premium_lifetime';
  static const String _localEntitlementKey = 'local_premium_entitlement';
  
  // Product pricing (fallback when store is not configured)
  static const String monthlyPrice = '\$1.00';
  static const String lifetimePrice = '\$5.00';
  
  bool _isInitialized = false;
  bool _hasLocalEntitlement = false;
  bool _hasRealEntitlement = false;
  List<Product> _products = [];
  StreamSubscription? _purchaseSubscription;
  
  /// Available products
  List<Product> get products => List.unmodifiable(_products);
  
  /// Whether the user has premium access (local or real)
  bool get hasPremiumAccess => _hasRealEntitlement || _hasLocalEntitlement;
  
  /// Whether IAP is available and configured
  bool get isIAPAvailable => FeatureFlags.enableIAP && !kIsWeb;
  
  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Initialize the IAP service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load local entitlement
      await _loadLocalEntitlement();
      
      if (isIAPAvailable) {
        await _initializeRealIAP();
      } else {
        // Initialize with mock products
        _initializeMockProducts();
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('IAP initialization failed: $e');
      // Fall back to local entitlement mode
      _initializeMockProducts();
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Initialize real IAP when available
  Future<void> _initializeRealIAP() async {
    if (!isIAPAvailable) return;
    
    try {
      // This will only work when IAP is enabled
      if (FeatureFlags.enableIAP) {
        final iapInstance = iap_lib.InAppPurchase.instance;
        final available = await iapInstance.isAvailable();
        
        if (available) {
          // Load products
          final response = await iapInstance.queryProductDetails({
            monthlyProductId,
            lifetimeProductId,
          });
          
          if (response.error == null) {
            _products = response.productDetails.map((pd) => Product(
              id: pd.id,
              title: pd.title,
              description: pd.description,
              price: pd.price,
              rawPrice: pd.rawPrice,
              currencyCode: pd.currencyCode,
            )).toList();
          }
          
          // Listen to purchase updates
          _purchaseSubscription = iapInstance.purchaseStream.listen(
            _handlePurchaseUpdate,
            onError: _handlePurchaseError,
          );
        }
      }
    } catch (e) {
      debugPrint('Real IAP initialization failed: $e');
      _initializeMockProducts();
    }
  }
  
  /// Initialize mock products for testing/development
  void _initializeMockProducts() {
    _products = [
      Product(
        id: monthlyProductId,
        title: 'QuickNote Pro Monthly',
        description: 'Monthly subscription with all premium features',
        price: monthlyPrice,
        rawPrice: 1.00,
        currencyCode: 'USD',
      ),
      Product(
        id: lifetimeProductId,
        title: 'QuickNote Pro Lifetime',
        description: 'One-time purchase with lifetime access',
        price: lifetimePrice,
        rawPrice: 5.00,
        currencyCode: 'USD',
      ),
    ];
  }
  
  /// Handle purchase updates from real IAP
  void _handlePurchaseUpdate(List<dynamic> purchaseDetailsList) {
    // This would handle real purchase updates
    // For now, simulate success
    for (final purchase in purchaseDetailsList) {
      _hasRealEntitlement = true;
      notifyListeners();
    }
  }
  
  /// Handle purchase errors
  void _handlePurchaseError(dynamic error) {
    debugPrint('Purchase error: $error');
  }
  
  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      if (isIAPAvailable && FeatureFlags.enableIAP) {
        // Attempt real purchase
        return await _purchaseReal(productId);
      } else {
        // Simulate purchase for development/testing
        return await _simulatePurchase(productId);
      }
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }
  
  /// Real purchase implementation
  Future<bool> _purchaseReal(String productId) async {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      
      // This would use real IAP when enabled
      if (FeatureFlags.enableIAP) {
        final iapInstance = iap_lib.InAppPurchase.instance;
        // Convert our Product back to ProductDetails for purchase
        // This is a simplified version - real implementation would store ProductDetails
        
        // For now, simulate success in development
        if (FeatureFlags.isDevelopment) {
          await Future.delayed(const Duration(seconds: 1));
          _hasRealEntitlement = true;
          notifyListeners();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Real purchase error: $e');
      return false;
    }
  }
  
  /// Simulate purchase for development/testing
  Future<bool> _simulatePurchase(String productId) async {
    if (!FeatureFlags.enableLocalEntitlements) {
      return false;
    }
    
    // Simulate purchase delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Grant local entitlement
    await _setLocalEntitlement(true);
    
    return true;
  }
  
  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      if (isIAPAvailable && FeatureFlags.enableIAP) {
        final iapInstance = iap_lib.InAppPurchase.instance;
        await iapInstance.restorePurchases();
        return true;
      } else {
        // Check local entitlement
        await _loadLocalEntitlement();
        return _hasLocalEntitlement;
      }
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
  
  /// Load local entitlement from storage
  Future<void> _loadLocalEntitlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasLocalEntitlement = prefs.getBool(_localEntitlementKey) ?? false;
    } catch (e) {
      _hasLocalEntitlement = false;
    }
  }
  
  /// Set local entitlement
  Future<void> _setLocalEntitlement(bool hasEntitlement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_localEntitlementKey, hasEntitlement);
      _hasLocalEntitlement = hasEntitlement;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save local entitlement: $e');
    }
  }
  
  /// Clear local entitlement (for testing)
  Future<void> clearLocalEntitlement() async {
    await _setLocalEntitlement(false);
  }
  
  /// Get entitlement status info
  Map<String, dynamic> getEntitlementInfo() {
    return {
      'hasPremiumAccess': hasPremiumAccess,
      'hasRealEntitlement': _hasRealEntitlement,
      'hasLocalEntitlement': _hasLocalEntitlement,
      'isIAPAvailable': isIAPAvailable,
      'isInitialized': _isInitialized,
    };
  }
  
  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

/// Product model for IAP items
class Product {
  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
  
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
  });
  
  bool get isMonthly => id == IAPService.monthlyProductId;
  bool get isLifetime => id == IAPService.lifetimeProductId;
}
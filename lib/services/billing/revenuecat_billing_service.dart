import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../constants/billing_config.dart';
import '../../constants/feature_flags.dart';
import '../../constants/product_ids.dart';
import '../analytics/analytics_service.dart';

/// Exception thrown when billing operations fail
class BillingException implements Exception {
  final String message;
  final String? code;
  
  const BillingException(this.message, {this.code});
  
  @override
  String toString() => 'BillingException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Represents a purchase result
class PurchaseResult {
  final bool success;
  final String? error;
  final CustomerInfo? customerInfo;
  final String? productId;
  
  const PurchaseResult({
    required this.success,
    this.error,
    this.customerInfo,
    this.productId,
  });
}

/// Represents available products
class BillingProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String? introductoryPrice;
  final bool isSubscription;
  
  const BillingProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.introductoryPrice,
    required this.isSubscription,
  });
  
  factory BillingProduct.fromStoreProduct(StoreProduct product) {
    return BillingProduct(
      id: product.identifier,
      title: product.title,
      description: product.description,
      price: product.priceString,
      introductoryPrice: product.introductoryPrice?.priceString,
      isSubscription: product.productCategory == ProductCategory.subscription,
    );
  }
}

/// Service for managing RevenueCat billing operations
class RevenueCatBillingService extends ChangeNotifier {
  static RevenueCatBillingService? _instance;
  static RevenueCatBillingService get instance => _instance ??= RevenueCatBillingService._();
  
  RevenueCatBillingService._();

  bool _isInitialized = false;
  bool _isLoading = false;
  CustomerInfo? _customerInfo;
  List<BillingProduct> _availableProducts = [];
  final AnalyticsService _analytics = AnalyticsService();
  
  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether a billing operation is in progress
  bool get isLoading => _isLoading;
  
  /// Current customer information
  CustomerInfo? get customerInfo => _customerInfo;
  
  /// Available products for purchase
  List<BillingProduct> get availableProducts => List.unmodifiable(_availableProducts);
  
  /// Whether user has premium entitlement
  bool get hasPremiumEntitlement {
    return _customerInfo?.entitlements.active
        .containsKey(BillingConfig.premiumEntitlementId) ?? false;
  }
  
  /// Whether user has pro entitlement
  bool get hasProEntitlement {
    return _customerInfo?.entitlements.active
        .containsKey(BillingConfig.proEntitlementId) ?? false;
  }
  
  /// Whether user has enterprise entitlement
  bool get hasEnterpriseEntitlement {
    return _customerInfo?.entitlements.active
        .containsKey(BillingConfig.enterpriseEntitlementId) ?? false;
  }

  /// Initialize RevenueCat
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;
    
    if (!FeatureFlags.revenueCatEnabled) {
      if (kDebugMode) {
        print('RevenueCat: Disabled via feature flags');
      }
      return;
    }

    try {
      _setLoading(true);
      
      // Configure RevenueCat
      await Purchases.setLogLevel(BillingConfig.enableLogging ? LogLevel.debug : LogLevel.info);
      await Purchases.configure(PurchasesConfiguration(BillingConfig.getRevenueCatApiKey()));
      
      // Set user ID if provided
      if (userId != null) {
        await Purchases.logIn(userId);
      }
      
      // Set up listeners
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      
      // Get initial customer info
      _customerInfo = await Purchases.getCustomerInfo();
      
      // Load available products
      await _loadProducts();
      
      _isInitialized = true;
      
      // Track initialization
      _analytics.trackEvent(AnalyticsEvent(
        name: 'billing_service_initialized',
        properties: {
          'provider': 'revenuecat',
          'user_id': userId,
          'has_entitlements': _customerInfo?.entitlements.active.isNotEmpty ?? false,
        },
      ));
      
      if (kDebugMode) {
        print('RevenueCat: Successfully initialized');
        print('RevenueCat: Customer info: ${_customerInfo?.toJson()}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Initialization failed: $e');
      }
      
      _analytics.trackEvent(AnalyticsEvent(
        name: 'billing_service_init_failed',
        properties: {
          'provider': 'revenuecat',
          'error': e.toString(),
        },
      ));
      
      throw BillingException('Failed to initialize RevenueCat: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load available products
  Future<void> _loadProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      final products = <BillingProduct>[];
      
      // Get products from current offering
      final currentOffering = offerings.current;
      if (currentOffering != null) {
        for (final package in currentOffering.availablePackages) {
          products.add(BillingProduct.fromStoreProduct(package.storeProduct));
        }
      }
      
      // Also get products by ID
      final productIds = ProductIds.allProductIds;
      try {
        final storeProducts = await Purchases.getProducts(productIds);
        for (final product in storeProducts) {
          // Avoid duplicates
          if (!products.any((p) => p.id == product.identifier)) {
            products.add(BillingProduct.fromStoreProduct(product));
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('RevenueCat: Failed to load products by ID: $e');
        }
      }
      
      _availableProducts = products;
      
      if (kDebugMode) {
        print('RevenueCat: Loaded ${products.length} products');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Failed to load products: $e');
      }
    }
  }

  /// Purchase a product
  Future<PurchaseResult> purchaseProduct(String productId) async {
    if (!_isInitialized) {
      throw const BillingException('RevenueCat not initialized');
    }

    try {
      _setLoading(true);
      
      _analytics.trackEvent(AnalyticsEvent(
        name: 'purchase_initiated',
        properties: {
          'provider': 'revenuecat',
          'product_id': productId,
        },
      ));
      
      // Find the product in available offerings
      final offerings = await Purchases.getOfferings();
      Package? packageToPurchase;
      
      // Look for the product in current offering
      final currentOffering = offerings.current;
      if (currentOffering != null) {
        packageToPurchase = currentOffering.availablePackages
            .where((package) => package.storeProduct.identifier == productId)
            .firstOrNull;
      }
      
      CustomerInfo customerInfo;
      
      if (packageToPurchase != null) {
        // Purchase package
        customerInfo = await Purchases.purchasePackage(packageToPurchase);
      } else {
        // Fallback: purchase by product ID
        final storeProducts = await Purchases.getProducts([productId]);
        if (storeProducts.isEmpty) {
          throw BillingException('Product not found: $productId');
        }
        customerInfo = await Purchases.purchaseStoreProduct(storeProducts.first);
      }
      
      _customerInfo = customerInfo;
      
      final success = customerInfo.entitlements.active.isNotEmpty;
      
      _analytics.logEvent('purchase_completed', {
        'provider': 'revenuecat',
        'product_id': productId,
        'success': success,
        'entitlements': customerInfo.entitlements.active.keys.toList(),
      });
      
      if (kDebugMode) {
        print('RevenueCat: Purchase completed for $productId. Success: $success');
      }
      
      return PurchaseResult(
        success: success,
        customerInfo: customerInfo,
        productId: productId,
      );
      
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      String errorMessage = 'Purchase failed';
      
      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          errorMessage = 'Purchase was cancelled';
          break;
        case PurchasesErrorCode.purchaseNotAllowedError:
          errorMessage = 'Purchase not allowed';
          break;
        case PurchasesErrorCode.purchaseInvalidError:
          errorMessage = 'Purchase invalid';
          break;
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
          errorMessage = 'Product not available for purchase';
          break;
        case PurchasesErrorCode.networkError:
          errorMessage = 'Network error occurred';
          break;
        default:
          errorMessage = e.message ?? 'Unknown error occurred';
      }
      
      _analytics.logEvent('purchase_failed', {
        'provider': 'revenuecat',
        'product_id': productId,
        'error_code': errorCode.toString(),
        'error_message': errorMessage,
      });
      
      if (kDebugMode) {
        print('RevenueCat: Purchase failed: $errorMessage');
      }
      
      return PurchaseResult(
        success: false,
        error: errorMessage,
        productId: productId,
      );
      
    } catch (e) {
      _analytics.logEvent('purchase_failed', {
        'provider': 'revenuecat', 
        'product_id': productId,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('RevenueCat: Purchase failed with unexpected error: $e');
      }
      
      return PurchaseResult(
        success: false,
        error: e.toString(),
        productId: productId,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Restore purchases
  Future<PurchaseResult> restorePurchases() async {
    if (!_isInitialized) {
      throw const BillingException('RevenueCat not initialized');
    }

    try {
      _setLoading(true);
      
      _analytics.logEvent('restore_purchases_initiated', {
        'provider': 'revenuecat',
      });
      
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      
      final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;
      
      _analytics.logEvent('restore_purchases_completed', {
        'provider': 'revenuecat',
        'success': hasActiveEntitlements,
        'entitlements': customerInfo.entitlements.active.keys.toList(),
      });
      
      if (kDebugMode) {
        print('RevenueCat: Restore completed. Active entitlements: ${customerInfo.entitlements.active.keys}');
      }
      
      return PurchaseResult(
        success: true,
        customerInfo: customerInfo,
      );
      
    } catch (e) {
      _analytics.logEvent('restore_purchases_failed', {
        'provider': 'revenuecat',
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('RevenueCat: Restore failed: $e');
      }
      
      return PurchaseResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Set user ID for RevenueCat
  Future<void> setUserId(String userId) async {
    if (!_isInitialized) return;
    
    try {
      final logInResult = await Purchases.logIn(userId);
      _customerInfo = logInResult.customerInfo;
      
      _analytics.logEvent('billing_user_identified', {
        'provider': 'revenuecat',
        'user_id': userId,
      });
      
      if (kDebugMode) {
        print('RevenueCat: User identified: $userId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Failed to set user ID: $e');
      }
    }
  }

  /// Log out current user
  Future<void> logOut() async {
    if (!_isInitialized) return;
    
    try {
      final customerInfo = await Purchases.logOut();
      _customerInfo = customerInfo;
      
      _analytics.logEvent('billing_user_logged_out', {
        'provider': 'revenuecat',
      });
      
      if (kDebugMode) {
        print('RevenueCat: User logged out');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Failed to log out: $e');
      }
    }
  }

  /// Get product by ID
  BillingProduct? getProduct(String productId) {
    return _availableProducts
        .where((product) => product.id == productId)
        .firstOrNull;
  }

  /// Check if user has any active subscription
  bool get hasActiveSubscription {
    return _customerInfo?.entitlements.active.isNotEmpty ?? false;
  }

  /// Get active entitlement IDs
  List<String> get activeEntitlements {
    return _customerInfo?.entitlements.active.keys.toList() ?? [];
  }

  /// Handle customer info updates
  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    notifyListeners();
    
    if (kDebugMode) {
      print('RevenueCat: Customer info updated');
      print('RevenueCat: Active entitlements: ${customerInfo.entitlements.active.keys}');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Dispose of resources
  @override
  void dispose() {
    // Note: RevenueCat doesn't have a dispose method, but we can clean up listeners
    super.dispose();
  }
}
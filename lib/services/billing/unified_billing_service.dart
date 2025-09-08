import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../constants/feature_flags.dart';
import '../analytics/analytics_service.dart';
import 'revenuecat_billing_service.dart';
import 'paystack_service.dart';

/// Enum for different billing providers
enum BillingProvider {
  revenueCat,
  paystack,
  mock, // For testing
}

/// Unified purchase result that works across providers
class UnifiedPurchaseResult {
  final bool success;
  final String? error;
  final String? productId;
  final BillingProvider provider;
  final Map<String, dynamic>? metadata;
  
  const UnifiedPurchaseResult({
    required this.success,
    this.error,
    this.productId,
    required this.provider,
    this.metadata,
  });
}

/// Unified billing service that coordinates RevenueCat and Paystack
class UnifiedBillingService extends ChangeNotifier {
  static UnifiedBillingService? _instance;
  static UnifiedBillingService get instance => _instance ??= UnifiedBillingService._();
  
  UnifiedBillingService._();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _currentUserId;
  final AnalyticsService _analytics = AnalyticsService();
  
  // Service instances
  final RevenueCatBillingService _revenueCatService = RevenueCatBillingService.instance;
  final PaystackService _paystackService = PaystackService.instance;
  
  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether any billing operation is in progress
  bool get isLoading => _isLoading || _revenueCatService.isLoading || _paystackService.isLoading;
  
  /// Current user ID
  String? get currentUserId => _currentUserId;
  
  /// Whether user has premium access from any provider
  bool get hasPremiumAccess {
    if (FeatureFlags.bypassPremiumChecks && kDebugMode) {
      return true;
    }
    
    // Check RevenueCat entitlements
    if (_revenueCatService.isInitialized) {
      return _revenueCatService.hasPremiumEntitlement || 
             _revenueCatService.hasProEntitlement || 
             _revenueCatService.hasEnterpriseEntitlement;
    }
    
    // TODO: Add logic to check Paystack/RevenueCat entitlements from web purchases
    // This would involve checking a local cache or making an API call to verify entitlements
    
    return false;
  }
  
  /// Get the appropriate billing provider for the current platform
  BillingProvider get preferredProvider {
    if (FeatureFlags.mockPurchasesEnabled && kDebugMode) {
      return BillingProvider.mock;
    }
    
    // Use RevenueCat for mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      return BillingProvider.revenueCat;
    }
    
    // Use Paystack for web/other platforms
    return BillingProvider.paystack;
  }

  /// Initialize the unified billing service
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;
    
    if (FeatureFlags.shouldDisableMonetization) {
      if (kDebugMode) {
        print('UnifiedBilling: Disabled via feature flags');
      }
      return;
    }

    try {
      _setLoading(true);
      _currentUserId = userId;
      
      // Initialize appropriate services based on platform and feature flags
      final futures = <Future<void>>[];
      
      // Always initialize RevenueCat if enabled (for entitlement management)
      if (FeatureFlags.revenueCatEnabled) {
        futures.add(_revenueCatService.initialize(userId: userId));
      }
      
      // Initialize Paystack for web checkout if enabled
      if (FeatureFlags.paystackEnabled && FeatureFlags.webCheckoutEnabled) {
        futures.add(_paystackService.initialize());
      }
      
      // Wait for all services to initialize
      await Future.wait(futures);
      
      _isInitialized = true;
      
      _analytics.logEvent('unified_billing_initialized', {
        'user_id': userId,
        'revenuecat_enabled': FeatureFlags.revenueCatEnabled,
        'paystack_enabled': FeatureFlags.paystackEnabled,
        'preferred_provider': preferredProvider.name,
        'has_premium_access': hasPremiumAccess,
      });
      
      if (kDebugMode) {
        print('UnifiedBilling: Successfully initialized');
        print('UnifiedBilling: Preferred provider: ${preferredProvider.name}');
        print('UnifiedBilling: Has premium access: $hasPremiumAccess');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedBilling: Initialization failed: $e');
      }
      
      _analytics.logEvent('unified_billing_init_failed', {
        'error': e.toString(),
      });
      
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Purchase a product using the appropriate provider
  Future<UnifiedPurchaseResult> purchaseProduct({
    required String productId,
    String? userEmail,
    BillingProvider? forceProvider,
  }) async {
    if (!_isInitialized) {
      throw Exception('UnifiedBillingService not initialized');
    }

    final provider = forceProvider ?? preferredProvider;
    
    try {
      _setLoading(true);
      
      _analytics.logEvent('unified_purchase_initiated', {
        'product_id': productId,
        'provider': provider.name,
        'user_id': _currentUserId,
      });
      
      switch (provider) {
        case BillingProvider.revenueCat:
          return await _purchaseWithRevenueCat(productId);
          
        case BillingProvider.paystack:
          if (userEmail == null || _currentUserId == null) {
            throw Exception('User email and ID required for Paystack purchases');
          }
          return await _purchaseWithPaystack(productId, userEmail);
          
        case BillingProvider.mock:
          return await _mockPurchase(productId);
      }
      
    } catch (e) {
      _analytics.logEvent('unified_purchase_failed', {
        'product_id': productId,
        'provider': provider.name,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('UnifiedBilling: Purchase failed: $e');
      }
      
      return UnifiedPurchaseResult(
        success: false,
        error: e.toString(),
        productId: productId,
        provider: provider,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Restore purchases
  Future<UnifiedPurchaseResult> restorePurchases() async {
    if (!_isInitialized) {
      throw Exception('UnifiedBillingService not initialized');
    }

    try {
      _setLoading(true);
      
      _analytics.logEvent('unified_restore_initiated', {
        'user_id': _currentUserId,
      });
      
      // For now, only RevenueCat supports restore purchases
      if (_revenueCatService.isInitialized) {
        final result = await _revenueCatService.restorePurchases();
        
        return UnifiedPurchaseResult(
          success: result.success,
          error: result.error,
          provider: BillingProvider.revenueCat,
          metadata: {'entitlements': _revenueCatService.activeEntitlements},
        );
      }
      
      return const UnifiedPurchaseResult(
        success: false,
        error: 'No restore-capable billing provider available',
        provider: BillingProvider.revenueCat,
      );
      
    } catch (e) {
      _analytics.logEvent('unified_restore_failed', {
        'error': e.toString(),
      });
      
      return UnifiedPurchaseResult(
        success: false,
        error: e.toString(),
        provider: BillingProvider.revenueCat,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Purchase with RevenueCat
  Future<UnifiedPurchaseResult> _purchaseWithRevenueCat(String productId) async {
    if (!_revenueCatService.isInitialized) {
      throw Exception('RevenueCat not initialized');
    }
    
    final result = await _revenueCatService.purchaseProduct(productId);
    
    return UnifiedPurchaseResult(
      success: result.success,
      error: result.error,
      productId: productId,
      provider: BillingProvider.revenueCat,
      metadata: {
        'entitlements': _revenueCatService.activeEntitlements,
      },
    );
  }

  /// Purchase with Paystack (returns checkout URL)
  Future<UnifiedPurchaseResult> _purchaseWithPaystack(String productId, String userEmail) async {
    if (!_paystackService.isInitialized) {
      throw Exception('Paystack not initialized');
    }
    
    final result = await _paystackService.initializePayment(
      productId: productId,
      userId: _currentUserId!,
      userEmail: userEmail,
    );
    
    return UnifiedPurchaseResult(
      success: result.success,
      error: result.error,
      productId: productId,
      provider: BillingProvider.paystack,
      metadata: {
        'checkout_url': result.checkoutUrl,
        'reference': result.reference,
        'access_code': result.accessCode,
      },
    );
  }

  /// Mock purchase for testing
  Future<UnifiedPurchaseResult> _mockPurchase(String productId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (kDebugMode) {
      print('MockBilling: Simulating successful purchase for $productId');
    }
    
    return UnifiedPurchaseResult(
      success: true,
      productId: productId,
      provider: BillingProvider.mock,
      metadata: {'mock': true},
    );
  }

  /// Set user ID and update all services
  Future<void> setUserId(String userId) async {
    _currentUserId = userId;
    
    if (_revenueCatService.isInitialized) {
      await _revenueCatService.setUserId(userId);
    }
    
    _analytics.logEvent('unified_billing_user_set', {
      'user_id': userId,
    });
  }

  /// Log out from all billing services
  Future<void> logOut() async {
    if (_revenueCatService.isInitialized) {
      await _revenueCatService.logOut();
    }
    
    _currentUserId = null;
    
    _analytics.trackEvent(AnalyticsEvent(name: 'unified_billing_user_logged_out', properties: {}));
  }

  /// Get available products from the preferred provider
  List<dynamic> getAvailableProducts() {
    switch (preferredProvider) {
      case BillingProvider.revenueCat:
        return _revenueCatService.availableProducts;
      case BillingProvider.paystack:
        return _currentUserId != null 
            ? _paystackService.getSupportedProducts(_currentUserId!)
            : [];
      case BillingProvider.mock:
        return []; // Mock products would be defined here
    }
  }

  /// Check if a specific product is available
  bool isProductAvailable(String productId) {
    final products = getAvailableProducts();
    return products.any((product) => product.id == productId);
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
    _revenueCatService.dispose();
    _paystackService.dispose();
    super.dispose();
  }
}
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../../constants/product_ids.dart';

/// Service for handling in-app purchases and billing across platforms
class BillingService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Set<String> _purchasedProductIds = {};
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get hasPremium => _purchasedProductIds.isNotEmpty;
  
  /// Check if user has purchased a specific product
  bool hasProduct(String productId) => _purchasedProductIds.contains(productId);
  
  /// Check if user has any premium entitlement
  bool get isPremiumUser => hasProduct(ProductIds.premiumLifetime) || 
                           hasProduct(ProductIds.premiumMonthly);

  /// Initialize the billing service
  Future<void> initialize() async {
    _setLoading(true);
    _setError(null);
    
    try {
      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        _setError('In-app purchases not available');
        return;
      }
      
      // Set up purchase listener
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (error) => _setError('Purchase stream error: $error'),
      );
      
      // Load available products
      await _loadProducts();
      
      // Restore previous purchases
      await _restorePurchases();
      
    } catch (e) {
      _setError('Failed to initialize billing: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(
        ProductIds.allProductIds.toSet(),
      );
      
      if (response.error != null) {
        _setError('Failed to load products: ${response.error!.message}');
        return;
      }
      
      _products = response.productDetails;
      notifyListeners();
      
    } catch (e) {
      _setError('Error loading products: $e');
    }
  }
  
  /// Restore previous purchases
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _setError('Failed to restore purchases: $e');
    }
  }
  
  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      _setError('In-app purchases not available');
      return false;
    }
    
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw ArgumentError('Product not found: $productId'),
    );
    
    try {
      _setLoading(true);
      _setError(null);
      
      final purchaseParam = PurchaseParam(productDetails: product);
      
      final result = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      return result;
      
    } catch (e) {
      _setError('Purchase failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _processPurchase(purchaseDetails);
    }
  }
  
  /// Process individual purchase
  Future<void> _processPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      // Purchase is pending, show loading state
      _setLoading(true);
      notifyListeners();
      return;
    }
    
    if (purchaseDetails.status == PurchaseStatus.error) {
      _setError('Purchase error: ${purchaseDetails.error?.message}');
      _setLoading(false);
      return;
    }
    
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      
      // Verify purchase on server (in production)
      final isValid = await _verifyPurchase(purchaseDetails);
      
      if (isValid) {
        // Add to purchased products
        _purchasedProductIds.add(purchaseDetails.productID);
        _setError(null);
      } else {
        _setError('Purchase verification failed');
      }
    }
    
    // Complete the purchase transaction
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
    
    _setLoading(false);
    notifyListeners();
  }
  
  /// Verify purchase (mock implementation - should verify with your server)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In production, send verification data to your server
    // For now, we'll trust the platform verification
    
    if (Platform.isAndroid) {
      // Android purchase verification
      return purchaseDetails.verificationData.localVerificationData.isNotEmpty;
    } else if (Platform.isIOS) {
      // iOS purchase verification  
      return purchaseDetails.verificationData.localVerificationData.isNotEmpty;
    }
    
    return false;
  }
  
  /// Get product details by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get formatted price for a product
  String getProductPrice(String productId) {
    final product = getProduct(productId);
    if (product != null) {
      return product.price;
    }
    
    // Fallback to static price if product not loaded
    return ProductIds.fallbackPrices[productId] ?? 'N/A';
  }
  
  /// Refresh products and purchases
  Future<void> refresh() async {
    await _loadProducts();
    await _restorePurchases();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
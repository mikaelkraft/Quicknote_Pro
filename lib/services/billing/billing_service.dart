import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../../constants/product_ids.dart';

/// Service responsible for handling in-app purchases and billing
class BillingService extends ChangeNotifier {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isInitialized = false;
  String? _lastError;

  /// Whether the billing service is available
  bool get isAvailable => _isAvailable;

  /// Available products for purchase
  List<ProductDetails> get products => _products;

  /// Active purchases
  List<PurchaseDetails> get purchases => _purchases;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Last error that occurred
  String? get lastError => _lastError;

  /// Initialize the billing service
  Future<void> initialize() async {
    try {
      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        _lastError = 'In-app purchases not available on this device';
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Initialize platform-specific configurations
      if (Platform.isIOS) {
        await _initializeIOS();
      } else if (Platform.isAndroid) {
        await _initializeAndroid();
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: _onPurchaseError,
        onDone: () => debugPrint('Purchase stream closed'),
      );

      // Load available products
      await _loadProducts();

      // Restore previous purchases
      await restorePurchases();

      _isInitialized = true;
      _lastError = null;
      notifyListeners();

    } catch (e) {
      _lastError = 'Failed to initialize billing service: $e';
      _isInitialized = true;
      notifyListeners();
      debugPrint('BillingService initialization error: $e');
    }
  }

  /// Initialize iOS-specific configuration
  Future<void> _initializeIOS() async {
    if (Platform.isIOS) {
      final iosPlatformAddition = _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
    }
  }

  /// Initialize Android-specific configuration
  Future<void> _initializeAndroid() async {
    if (Platform.isAndroid) {
      // Android platform addition doesn't require special initialization in newer versions
      // The pending purchases are handled automatically
    }
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
        ProductIds.allProductIds.toSet(),
      );

      if (response.error != null) {
        _lastError = 'Failed to load products: ${response.error!.message}';
        notifyListeners();
        return;
      }

      _products = response.productDetails;
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found in store: ${response.notFoundIDs}');
      }

      notifyListeners();
    } catch (e) {
      _lastError = 'Error loading products: $e';
      notifyListeners();
      debugPrint('Error loading products: $e');
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable || !_isInitialized) {
      _lastError = 'Billing service not available';
      notifyListeners();
      return false;
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw StateError('Product not found: $productId'),
      );

      final purchaseParam = PurchaseParam(productDetails: product);
      
      bool success;
      if (productId == ProductIds.premiumMonthly) {
        // Monthly subscription
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Lifetime purchase
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

      if (!success) {
        _lastError = 'Failed to initiate purchase';
        notifyListeners();
      }

      return success;

    } catch (e) {
      _lastError = 'Purchase failed: $e';
      notifyListeners();
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable || !_isInitialized) {
      return;
    }

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _lastError = 'Failed to restore purchases: $e';
      notifyListeners();
      debugPrint('Restore purchases error: $e');
    }
  }

  /// Get active purchases
  Future<List<PurchaseDetails>> getActivePurchases() async {
    await restorePurchases();
    return _purchases.where((purchase) => 
      purchase.status == PurchaseStatus.purchased &&
      ProductIds.allProductIds.contains(purchase.productID)
    ).toList();
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    try {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('Purchase pending: ${purchaseDetails.productID}');
          break;

        case PurchaseStatus.purchased:
          debugPrint('Purchase successful: ${purchaseDetails.productID}');
          
          // Verify purchase (in production, this should be done server-side)
          if (await _verifyPurchase(purchaseDetails)) {
            _purchases.add(purchaseDetails);
            notifyListeners();
          }

          // Complete the purchase
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.error:
          _lastError = 'Purchase error: ${purchaseDetails.error?.message}';
          notifyListeners();
          debugPrint('Purchase error: ${purchaseDetails.error}');
          break;

        case PurchaseStatus.restored:
          debugPrint('Purchase restored: ${purchaseDetails.productID}');
          if (await _verifyPurchase(purchaseDetails)) {
            _purchases.add(purchaseDetails);
            notifyListeners();
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('Purchase canceled: ${purchaseDetails.productID}');
          break;
      }
    } catch (e) {
      debugPrint('Error handling purchase: $e');
    }
  }

  /// Verify a purchase (simplified version - in production, use server-side verification)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In a real app, you should verify purchases server-side
    // This is a simplified client-side verification
    try {
      if (Platform.isIOS) {
        // For iOS, you would typically send the receipt to your server
        // or Apple's servers for verification
        return purchaseDetails.verificationData.serverVerificationData.isNotEmpty;
      } else if (Platform.isAndroid) {
        // For Android, you would verify the purchase token and signature
        return purchaseDetails.verificationData.serverVerificationData.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase verification error: $e');
      return false;
    }
  }

  /// Handle purchase stream errors
  void _onPurchaseError(Object error) {
    _lastError = 'Purchase stream error: $error';
    notifyListeners();
    debugPrint('Purchase stream error: $error');
  }

  /// Get product details by ID
  ProductDetails? getProductDetails(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Clear the last error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// iOS Payment Queue Delegate
class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/product_ids.dart';
import 'premium_service.dart';

/// Service responsible for handling in-app purchases
class IAPService extends ChangeNotifier {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  // Getters
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  String? get queryProductError => _queryProductError;

  /// Initialize the IAP service
  Future<void> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (_isAvailable) {
        // Listen to purchase updates
        _subscription = _inAppPurchase.purchaseStream.listen(
          _listenToPurchaseUpdated,
          onDone: () => _subscription.cancel(),
          onError: (error) => debugPrint('Purchase stream error: $error'),
        );
        
        // Query available products
        await _queryProducts();
        
        // Restore previous purchases
        await restorePurchases();
      }
    } catch (e) {
      debugPrint('IAP initialization error: $e');
      _isAvailable = false;
    }
    
    notifyListeners();
  }

  /// Query available products from the store
  Future<void> _queryProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
        ProductIds.allProductIds.toSet(),
      );

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      _queryProductError = response.error?.message;
    } catch (e) {
      _queryProductError = e.toString();
      debugPrint('Query products error: $e');
    }
    
    notifyListeners();
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      debugPrint('IAP not available');
      return false;
    }

    final ProductDetails? productDetails = _products
        .where((product) => product.id == productId)
        .firstOrNull;

    if (productDetails == null) {
      debugPrint('Product not found: $productId');
      return false;
    }

    try {
      _purchasePending = true;
      notifyListeners();

      late PurchaseParam purchaseParam;

      if (Platform.isIOS) {
        purchaseParam = PurchaseParam(
          productDetails: productDetails,
          applicationUserName: await _getApplicationUserName(),
        );
      } else {
        purchaseParam = PurchaseParam(productDetails: productDetails);
      }

      final bool success = productId == ProductIds.premiumMonthly
          ? await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam)
          : await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      return success;
    } catch (e) {
      debugPrint('Purchase error: $e');
      _purchasePending = false;
      notifyListeners();
      return false;
    }
  }

  /// Purchase with promo code (iOS) or apply discount (Android)
  Future<bool> purchaseWithPromoCode(String productId, String promoCode) async {
    if (!_isAvailable) return false;

    if (Platform.isIOS) {
      // iOS: Use offer codes through App Store
      return await _presentCodeRedemptionSheet();
    } else {
      // Android: Apply promo code discount
      return await _purchaseWithDiscount(productId, promoCode);
    }
  }

  /// Present code redemption sheet (iOS)
  Future<bool> _presentCodeRedemptionSheet() async {
    try {
      if (Platform.isIOS) {
        await InAppPurchaseStoreKitPlatformAddition.presentCodeRedemptionSheet();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Code redemption error: $e');
      return false;
    }
  }

  /// Purchase with discount code (Android)
  Future<bool> _purchaseWithDiscount(String productId, String promoCode) async {
    try {
      final ProductDetails? productDetails = _products
          .where((product) => product.id == productId)
          .firstOrNull;

      if (productDetails == null) return false;

      // Validate promo code
      final bool isValidPromo = await _validatePromoCode(promoCode);
      if (!isValidPromo) return false;

      _purchasePending = true;
      notifyListeners();

      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // For Android, we'll need to implement discount logic on our backend
      // For now, proceed with regular purchase and apply discount post-validation
      final success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (success) {
        // Store promo code for backend validation
        await _storeUsedPromoCode(promoCode);
      }

      return success;
    } catch (e) {
      debugPrint('Discount purchase error: $e');
      _purchasePending = false;
      notifyListeners();
      return false;
    }
  }

  /// Validate promo code
  Future<bool> _validatePromoCode(String promoCode) async {
    // This would typically validate against your backend
    // For now, implement basic validation
    final validCodes = ['WELCOME10', 'FRIEND50', 'LAUNCH25'];
    return validCodes.contains(promoCode.toUpperCase());
  }

  /// Store used promo code
  Future<void> _storeUsedPromoCode(String promoCode) async {
    final prefs = await SharedPreferences.getInstance();
    final usedCodes = prefs.getStringList('used_promo_codes') ?? [];
    usedCodes.add(promoCode);
    await prefs.setStringList('used_promo_codes', usedCodes);
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }

  /// Listen to purchase updates
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        _purchasePending = false;
        
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // Verify purchase
          _verifyPurchase(purchaseDetails);
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
    
    _purchases = purchaseDetailsList;
    notifyListeners();
  }

  /// Verify purchase (implement server-side validation)
  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Here you would typically validate the purchase with your backend server
      // For now, we'll do basic local validation and activate premium
      
      final bool isValid = await _validatePurchaseReceipt(purchaseDetails);
      
      if (isValid) {
        // Activate premium features
        await PremiumService().activatePremium(purchaseDetails.productID);
        debugPrint('Premium activated for product: ${purchaseDetails.productID}');
      }
    } catch (e) {
      debugPrint('Purchase verification error: $e');
    }
  }

  /// Validate purchase receipt
  Future<bool> _validatePurchaseReceipt(PurchaseDetails purchaseDetails) async {
    // Basic validation - in production, validate with backend
    return purchaseDetails.verificationData.serverVerificationData.isNotEmpty;
  }

  /// Get application username for iOS
  Future<String?> _getApplicationUserName() async {
    // Generate or retrieve user identifier for iOS purchase tracking
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('iap_user_id');
    
    if (userId == null) {
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('iap_user_id', userId);
    }
    
    return userId;
  }

  /// Get product price by ID
  String getProductPrice(String productId) {
    final product = _products.where((p) => p.id == productId).firstOrNull;
    return product?.price ?? ProductIds.fallbackPrices[productId] ?? 'N/A';
  }

  /// Check if user has purchased a specific product
  bool hasPurchased(String productId) {
    return _purchases.any((purchase) => 
        purchase.productID == productId && 
        purchase.status == PurchaseStatus.purchased);
  }

  /// Check if any premium product is purchased
  bool get hasPremiumAccess {
    return ProductIds.allProductIds.any((productId) => hasPurchased(productId));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/product_ids.dart';

/// Service for managing premium subscriptions and entitlements.
/// Handles both Play Billing (Android) and StoreKit (iOS) integration.
class PremiumService extends ChangeNotifier {
  static const String _premiumStatusKey = 'premium_status';
  static const String _premiumExpiryKey = 'premium_expiry';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  SharedPreferences? _prefs;
  bool _isAvailable = false;
  bool _isPremium = false;
  DateTime? _premiumExpiry;
  bool _isLoading = false;
  String? _lastError;
  List<ProductDetails> _products = [];

  /// Whether in-app purchases are available on this platform
  bool get isAvailable => _isAvailable;
  
  /// Whether the user has an active premium subscription
  bool get isPremium => _isPremium;
  
  /// Premium subscription expiry date (null for lifetime purchases)
  DateTime? get premiumExpiry => _premiumExpiry;
  
  /// Whether a purchase/restore operation is in progress
  bool get isLoading => _isLoading;
  
  /// Last error that occurred during purchase operations
  String? get lastError => _lastError;
  
  /// Available products for purchase
  List<ProductDetails> get products => _products;

  /// Initialize the premium service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadStoredPremiumStatus();
      
      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (_isAvailable) {
        await _loadProducts();
        _setupPurchaseListener();
      }
      
      // Verify existing purchases
      if (_isPremium) {
        await _verifyPurchases();
      }
      
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize premium service: $e';
      debugPrint('PremiumService initialization error: $e');
      notifyListeners();
    }
  }

  /// Load stored premium status from local storage
  void _loadStoredPremiumStatus() {
    if (_prefs == null) return;
    
    _isPremium = _prefs!.getBool(_premiumStatusKey) ?? false;
    
    final expiryMs = _prefs!.getInt(_premiumExpiryKey);
    if (expiryMs != null) {
      _premiumExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
      
      // Check if subscription has expired
      if (_premiumExpiry!.isBefore(DateTime.now())) {
        _isPremium = false;
        _premiumExpiry = null;
        _storePremiumStatus();
      }
    }
  }

  /// Store premium status to local storage
  Future<void> _storePremiumStatus() async {
    if (_prefs == null) return;
    
    await _prefs!.setBool(_premiumStatusKey, _isPremium);
    
    if (_premiumExpiry != null) {
      await _prefs!.setInt(_premiumExpiryKey, _premiumExpiry!.millisecondsSinceEpoch);
    } else {
      await _prefs!.remove(_premiumExpiryKey);
    }
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    if (!_isAvailable) return;
    
    try {
      final response = await _inAppPurchase.queryProductDetails(
        ProductIds.allProductIds.toSet()
      );
      
      if (response.error != null) {
        _lastError = 'Failed to load products: ${response.error!.message}';
        return;
      }
      
      _products = response.productDetails;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to load products: $e';
      debugPrint('Product loading error: $e');
    }
  }

  /// Setup purchase stream listener
  void _setupPurchaseListener() {
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        _lastError = 'Purchase stream error: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Handle purchase updates from the stream
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
          _handleSuccessfulPurchase(purchase);
          break;
        case PurchaseStatus.error:
          _handlePurchaseError(purchase);
          break;
        case PurchaseStatus.pending:
          // Purchase is pending (e.g., user needs to complete authentication)
          _isLoading = true;
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _handlePurchaseCancellation();
          break;
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchase);
          break;
      }
      
      // Complete the purchase if it's not pending
      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  /// Handle successful purchase
  void _handleSuccessfulPurchase(PurchaseDetails purchase) {
    _isPremium = true;
    _lastError = null;
    _isLoading = false;
    
    // Set expiry based on product type
    if (purchase.productID == ProductIds.premiumMonthly) {
      _premiumExpiry = DateTime.now().add(const Duration(days: 30));
    } else if (purchase.productID == ProductIds.premiumLifetime) {
      _premiumExpiry = null; // Lifetime purchase
    }
    
    _storePremiumStatus();
    notifyListeners();
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchase) {
    _lastError = purchase.error?.message ?? 'Purchase failed';
    _isLoading = false;
    notifyListeners();
  }

  /// Handle purchase cancellation
  void _handlePurchaseCancellation() {
    _lastError = null; // Not really an error
    _isLoading = false;
    notifyListeners();
  }

  /// Purchase a premium product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      _lastError = 'In-app purchases not available';
      return false;
    }
    
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw ArgumentError('Product not found: $productId'),
    );
    
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      
      bool success;
      if (Platform.isIOS || product.id == ProductIds.premiumLifetime) {
        // Use non-consumable purchase for iOS and lifetime purchases
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Use subscription purchase for Android monthly
        success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
      
      if (!success) {
        _lastError = 'Failed to initiate purchase';
        _isLoading = false;
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _lastError = 'Purchase error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      _lastError = 'In-app purchases not available';
      return;
    }
    
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    
    try {
      await _inAppPurchase.restorePurchases();
      // The restore results will come through the purchase stream
    } catch (e) {
      _lastError = 'Restore failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify existing purchases with the store
  Future<void> _verifyPurchases() async {
    if (!_isAvailable || !_isPremium) return;
    
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Purchase verification error: $e');
    }
  }

  /// Get product details by ID
  ProductDetails? getProductDetails(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Clear last error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// For development/testing: manually set premium status
  Future<void> setDevelopmentPremiumStatus(bool isPremium) async {
    if (!kDebugMode || !ProductIds.allowDevBypass) return;
    
    _isPremium = isPremium;
    _premiumExpiry = isPremium ? null : null; // Lifetime for dev
    await _storePremiumStatus();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
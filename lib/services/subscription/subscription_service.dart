import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/product_ids.dart';

/// Service to manage subscription state and Pro entitlements.
/// 
/// Handles subscription status checking, purchase verification,
/// and provides reactive updates for UI components.
class SubscriptionService extends ChangeNotifier {
  static const String _isPremiumKey = 'is_premium_user';
  static const String _premiumTypeKey = 'premium_type';
  static const String _lastVerificationKey = 'last_verification';

  bool _isPremium = false;
  String? _premiumType; // 'monthly' or 'lifetime'
  SharedPreferences? _prefs;
  InAppPurchase? _iap;
  bool _isInitialized = false;

  /// Whether the user has premium access
  bool get isPremium => _isPremium;

  /// Type of premium subscription ('monthly' or 'lifetime')
  String? get premiumType => _premiumType;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the subscription service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _iap = InAppPurchase.instance;
      
      await _loadSubscriptionState();
      await _verifySubscriptionStatus();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing subscription service: $e');
      _isInitialized = true; // Still mark as initialized to prevent blocking
    }
  }

  /// Load subscription state from local storage
  Future<void> _loadSubscriptionState() async {
    if (_prefs == null) return;

    _isPremium = _prefs!.getBool(_isPremiumKey) ?? false;
    _premiumType = _prefs!.getString(_premiumTypeKey);
    
    // Check if verification is older than 24 hours
    final lastVerification = _prefs!.getInt(_lastVerificationKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dayInMs = 24 * 60 * 60 * 1000;
    
    if (now - lastVerification > dayInMs) {
      // Force re-verification if it's been more than 24 hours
      await _verifySubscriptionStatus();
    }
  }

  /// Verify current subscription status with the store
  Future<void> _verifySubscriptionStatus() async {
    if (_iap == null || !await _iap!.isAvailable()) {
      return;
    }

    try {
      // For debug builds, allow dev bypass
      if (kDebugMode && ProductIds.allowDevBypass) {
        // Check for debug premium flag
        final debugPremium = _prefs?.getBool('debug_premium') ?? false;
        if (debugPremium) {
          await _setPremiumStatus(true, 'debug');
          return;
        }
      }

      // Get past purchases to verify active subscriptions
      final response = await _iap!.restorePurchases();
      
      bool hasPremium = false;
      String? type;
      
      for (final purchase in response.pastPurchases) {
        if (purchase.productID == ProductIds.premiumLifetime) {
          if (purchase.status == PurchaseStatus.purchased) {
            hasPremium = true;
            type = 'lifetime';
            break;
          }
        } else if (purchase.productID == ProductIds.premiumMonthly) {
          if (purchase.status == PurchaseStatus.purchased) {
            hasPremium = true;
            type = 'monthly';
            // For monthly, we'd need additional logic to check if it's still active
            // This is simplified for demo purposes
          }
        }
      }
      
      await _setPremiumStatus(hasPremium, type);
      
      // Update last verification timestamp
      if (_prefs != null) {
        await _prefs!.setInt(_lastVerificationKey, DateTime.now().millisecondsSinceEpoch);
      }
      
    } catch (e) {
      debugPrint('Error verifying subscription status: $e');
    }
  }

  /// Set premium status and persist to storage
  Future<void> _setPremiumStatus(bool isPremium, String? type) async {
    if (_isPremium == isPremium && _premiumType == type) return;

    _isPremium = isPremium;
    _premiumType = type;
    
    if (_prefs != null) {
      await _prefs!.setBool(_isPremiumKey, isPremium);
      if (type != null) {
        await _prefs!.setString(_premiumTypeKey, type);
      } else {
        await _prefs!.remove(_premiumTypeKey);
      }
    }
    
    notifyListeners();
  }

  /// Handle successful purchase
  Future<void> handlePurchaseSuccess(String productId) async {
    String type = productId == ProductIds.premiumLifetime ? 'lifetime' : 'monthly';
    await _setPremiumStatus(true, type);
  }

  /// Check if a specific feature is available
  bool isFeatureAvailable(String feature) {
    if (_isPremium) return true;
    
    // Define free tier limitations
    switch (feature) {
      case 'unlimited_voice_notes':
        return false;
      case 'advanced_drawing_tools':
        return false;
      case 'cloud_sync':
        return false;
      case 'ad_free':
        return false;
      case 'unlimited_notes':
        return false;
      default:
        return true; // Default features are available
    }
  }

  /// For debugging: toggle premium status
  Future<void> debugTogglePremium() async {
    if (kDebugMode) {
      final newValue = !(_prefs?.getBool('debug_premium') ?? false);
      await _prefs?.setBool('debug_premium', newValue);
      await _verifySubscriptionStatus();
    }
  }

  /// Get premium status display text
  String get statusText {
    if (!_isPremium) return 'Free';
    return _premiumType == 'lifetime' ? 'Premium Lifetime' : 'Premium Monthly';
  }

  /// Refresh subscription status (can be called manually)
  Future<void> refresh() async {
    await _verifySubscriptionStatus();
  }
}
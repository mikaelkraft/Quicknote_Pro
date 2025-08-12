import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage theme entitlements and Pro feature access
/// 
/// Handles checking if user has access to Pro-only themes and features,
/// managing purchase state, and providing fallback behaviors.
class ThemeEntitlementService extends ChangeNotifier {
  static const String _isPremiumKey = 'is_premium_user';
  static const String _purchaseTypeKey = 'purchase_type'; // 'monthly' or 'lifetime'
  static const String _purchaseDateKey = 'purchase_date';
  
  SharedPreferences? _prefs;
  bool _isPremium = false;
  String? _purchaseType;
  DateTime? _purchaseDate;

  /// List of Pro-only theme IDs
  static const Set<String> proThemes = {
    'futuristic',
    'neon', 
    'floral',
  };

  /// Current premium status
  bool get isPremium => _isPremium;
  
  /// Purchase type (monthly/lifetime)
  String? get purchaseType => _purchaseType;
  
  /// Purchase date
  DateTime? get purchaseDate => _purchaseDate;

  /// Initialize the service and load saved entitlements
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadEntitlements();
  }

  /// Load entitlements from storage
  Future<void> _loadEntitlements() async {
    if (_prefs == null) return;

    _isPremium = _prefs!.getBool(_isPremiumKey) ?? false;
    _purchaseType = _prefs!.getString(_purchaseTypeKey);
    
    final purchaseDateMs = _prefs!.getInt(_purchaseDateKey);
    if (purchaseDateMs != null) {
      _purchaseDate = DateTime.fromMillisecondsSinceEpoch(purchaseDateMs);
    }

    notifyListeners();
  }

  /// Check if user has access to a specific theme
  bool hasThemeAccess(String themeId) {
    // Free themes are always accessible
    if (!proThemes.contains(themeId)) {
      return true;
    }
    
    // Pro themes require premium access
    return _isPremium;
  }

  /// Check if user needs to see paywall for theme
  bool shouldShowPaywallForTheme(String themeId) {
    return proThemes.contains(themeId) && !_isPremium;
  }

  /// Grant premium access after successful purchase
  Future<void> grantPremiumAccess({
    required String purchaseType,
    DateTime? purchaseDate,
  }) async {
    if (_prefs == null) return;

    _isPremium = true;
    _purchaseType = purchaseType;
    _purchaseDate = purchaseDate ?? DateTime.now();

    await _prefs!.setBool(_isPremiumKey, true);
    await _prefs!.setString(_purchaseTypeKey, purchaseType);
    await _prefs!.setInt(_purchaseDateKey, _purchaseDate!.millisecondsSinceEpoch);

    notifyListeners();
  }

  /// Revoke premium access (for testing or subscription expiry)
  Future<void> revokePremiumAccess() async {
    if (_prefs == null) return;

    _isPremium = false;
    _purchaseType = null;
    _purchaseDate = null;

    await _prefs!.remove(_isPremiumKey);
    await _prefs!.remove(_purchaseTypeKey);
    await _prefs!.remove(_purchaseDateKey);

    notifyListeners();
  }

  /// Check if monthly subscription is still valid
  bool isMonthlySubscriptionValid() {
    if (_purchaseType != 'monthly' || _purchaseDate == null) {
      return false;
    }

    final now = DateTime.now();
    final expiryDate = _purchaseDate!.add(const Duration(days: 30));
    
    return now.isBefore(expiryDate);
  }

  /// Get subscription status text
  String getSubscriptionStatusText() {
    if (!_isPremium) {
      return 'Free Plan';
    }

    if (_purchaseType == 'lifetime') {
      return 'Pro Lifetime';
    }

    if (_purchaseType == 'monthly' && isMonthlySubscriptionValid()) {
      return 'Pro Monthly';
    }

    return 'Subscription Expired';
  }

  /// Restore purchases from platform stores
  Future<bool> restorePurchases() async {
    try {
      // In a real implementation, this would call the platform store APIs
      // For now, we'll simulate the restoration process
      
      if (kDebugMode) {
        print('Attempting to restore purchases...');
      }

      // Simulate network call
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, restore if there was a previous purchase
      final hadPreviousPurchase = _prefs?.getBool('_had_previous_purchase') ?? false;
      
      if (hadPreviousPurchase) {
        await grantPremiumAccess(purchaseType: 'lifetime');
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore purchases: $e');
      }
      return false;
    }
  }

  /// Simulate a purchase for testing
  Future<void> simulatePurchaseForTesting(String purchaseType) async {
    if (_prefs == null) return;
    
    await _prefs!.setBool('_had_previous_purchase', true);
    await grantPremiumAccess(purchaseType: purchaseType);
  }

  /// Reset all entitlements (for testing)
  Future<void> resetForTesting() async {
    if (_prefs == null) return;
    
    await _prefs!.remove('_had_previous_purchase');
    await revokePremiumAccess();
  }
}
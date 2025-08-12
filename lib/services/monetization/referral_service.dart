import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Service for managing referral codes and promotional discounts
class ReferralService extends ChangeNotifier {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  String? _userReferralCode;
  List<String> _usedPromoCodes = [];
  Map<String, dynamic> _referralStats = {};
  
  // Available promo codes and their discounts
  final Map<String, PromoCode> _availablePromoCodes = {
    'WELCOME10': PromoCode(
      code: 'WELCOME10',
      discountPercent: 10,
      type: PromoType.newUser,
      expiryDate: DateTime(2025, 12, 31),
      usageLimit: 1000,
      description: 'Welcome discount for new users',
    ),
    'FRIEND50': PromoCode(
      code: 'FRIEND50',
      discountPercent: 50,
      type: PromoType.referral,
      expiryDate: DateTime(2025, 12, 31),
      usageLimit: null, // Unlimited
      description: 'Friend referral discount',
    ),
    'LAUNCH25': PromoCode(
      code: 'LAUNCH25',
      discountPercent: 25,
      type: PromoType.promotional,
      expiryDate: DateTime(2024, 12, 31),
      usageLimit: 500,
      description: 'Launch celebration discount',
    ),
  };

  // Getters
  String? get userReferralCode => _userReferralCode;
  List<String> get usedPromoCodes => _usedPromoCodes;
  Map<String, dynamic> get referralStats => _referralStats;

  /// Initialize referral service
  Future<void> initialize() async {
    await _loadReferralData();
    await _generateUserReferralCode();
    notifyListeners();
  }

  /// Load referral data from shared preferences
  Future<void> _loadReferralData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _userReferralCode = prefs.getString('user_referral_code');
    _usedPromoCodes = prefs.getStringList('used_promo_codes') ?? [];
    
    final statsJson = prefs.getString('referral_stats');
    if (statsJson != null) {
      _referralStats = jsonDecode(statsJson);
    } else {
      _referralStats = {
        'referrals_made': 0,
        'referrals_successful': 0,
        'total_savings_earned': 0.0,
        'codes_used': [],
      };
    }
  }

  /// Save referral data to shared preferences
  Future<void> _saveReferralData() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_userReferralCode != null) {
      await prefs.setString('user_referral_code', _userReferralCode!);
    }
    
    await prefs.setStringList('used_promo_codes', _usedPromoCodes);
    await prefs.setString('referral_stats', jsonEncode(_referralStats));
  }

  /// Generate unique referral code for user
  Future<void> _generateUserReferralCode() async {
    if (_userReferralCode != null) return;

    try {
      // Generate unique code based on user ID and timestamp
      final uuid = const Uuid().v4();
      final hash = sha256.convert(utf8.encode(uuid)).toString();
      _userReferralCode = 'REF${hash.substring(0, 6).toUpperCase()}';
      
      await _saveReferralData();
      debugPrint('Generated referral code: $_userReferralCode');
    } catch (e) {
      debugPrint('Error generating referral code: $e');
    }
  }

  /// Validate promo code
  Future<PromoCodeValidation> validatePromoCode(String code) async {
    final upperCode = code.toUpperCase();
    
    // Check if code exists
    if (!_availablePromoCodes.containsKey(upperCode)) {
      return PromoCodeValidation(
        isValid: false,
        errorMessage: 'Invalid promo code',
      );
    }

    final promoCode = _availablePromoCodes[upperCode]!;

    // Check if already used
    if (_usedPromoCodes.contains(upperCode)) {
      return PromoCodeValidation(
        isValid: false,
        errorMessage: 'Promo code already used',
      );
    }

    // Check expiry
    if (DateTime.now().isAfter(promoCode.expiryDate)) {
      return PromoCodeValidation(
        isValid: false,
        errorMessage: 'Promo code has expired',
      );
    }

    // Check usage limit
    if (promoCode.usageLimit != null) {
      final currentUsage = await _getPromoCodeUsage(upperCode);
      if (currentUsage >= promoCode.usageLimit!) {
        return PromoCodeValidation(
          isValid: false,
          errorMessage: 'Promo code usage limit reached',
        );
      }
    }

    // Check type-specific conditions
    if (promoCode.type == PromoType.newUser) {
      final isNewUser = await _isNewUser();
      if (!isNewUser) {
        return PromoCodeValidation(
          isValid: false,
          errorMessage: 'This code is only for new users',
        );
      }
    }

    return PromoCodeValidation(
      isValid: true,
      promoCode: promoCode,
      discountAmount: _calculateDiscountAmount(promoCode),
    );
  }

  /// Calculate discount amount for a promo code
  double _calculateDiscountAmount(PromoCode promoCode) {
    // Base prices from ProductIds
    const monthlyPrice = 1.00;
    const lifetimePrice = 5.00;
    
    // For simplicity, calculate discount on monthly price
    return monthlyPrice * (promoCode.discountPercent / 100);
  }

  /// Apply promo code
  Future<bool> applyPromoCode(String code) async {
    final validation = await validatePromoCode(code);
    
    if (!validation.isValid) {
      debugPrint('Cannot apply promo code: ${validation.errorMessage}');
      return false;
    }

    final upperCode = code.toUpperCase();
    
    // Mark as used
    _usedPromoCodes.add(upperCode);
    
    // Update stats
    _referralStats['codes_used'] = (_referralStats['codes_used'] ?? [])..add(upperCode);
    _referralStats['total_savings_earned'] = 
        (_referralStats['total_savings_earned'] ?? 0.0) + validation.discountAmount!;
    
    // Increment global usage
    await _incrementPromoCodeUsage(upperCode);
    
    await _saveReferralData();
    notifyListeners();
    
    debugPrint('Promo code applied: $upperCode');
    return true;
  }

  /// Get current usage count for a promo code
  Future<int> _getPromoCodeUsage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('promo_usage_$code') ?? 0;
  }

  /// Increment promo code usage count
  Future<void> _incrementPromoCodeUsage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsage = await _getPromoCodeUsage(code);
    await prefs.setInt('promo_usage_$code', currentUsage + 1);
  }

  /// Check if user is new (hasn't made purchases)
  Future<bool> _isNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey('has_made_purchase');
  }

  /// Mark user as having made a purchase
  Future<void> markUserAsPurchaser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_made_purchase', true);
  }

  /// Process referral when someone uses your code
  Future<void> processReferral(String referredByCode) async {
    try {
      // In a real app, this would be handled by your backend
      // For now, we'll simulate the process locally
      
      _referralStats['referrals_made'] = (_referralStats['referrals_made'] ?? 0) + 1;
      
      await _saveReferralData();
      notifyListeners();
      
      debugPrint('Referral processed for code: $referredByCode');
    } catch (e) {
      debugPrint('Error processing referral: $e');
    }
  }

  /// Generate referral link
  String generateReferralLink() {
    if (_userReferralCode == null) return '';
    
    // In a real app, this would be your app's deep link
    return 'https://quicknotepro.app/ref/$_userReferralCode';
  }

  /// Share referral code
  Map<String, String> getReferralShareContent() {
    return {
      'title': 'Join me on QuickNote Pro!',
      'message': 'Hey! I\'m loving QuickNote Pro for taking notes. '
                'Use my referral code $_userReferralCode to get 50% off your first month!',
      'link': generateReferralLink(),
    };
  }

  /// Get available promo codes for user
  List<PromoCode> getAvailablePromoCodes() {
    final now = DateTime.now();
    
    return _availablePromoCodes.values
        .where((code) => 
            !_usedPromoCodes.contains(code.code) && 
            now.isBefore(code.expiryDate))
        .toList();
  }

  /// Get referral earnings summary
  Map<String, dynamic> getReferralEarnings() {
    return {
      'total_referrals': _referralStats['referrals_made'] ?? 0,
      'successful_referrals': _referralStats['referrals_successful'] ?? 0,
      'total_savings': _referralStats['total_savings_earned'] ?? 0.0,
      'codes_used_count': (_referralStats['codes_used'] ?? []).length,
      'user_referral_code': _userReferralCode,
    };
  }

  /// Create custom promo code (admin function)
  Future<void> createCustomPromoCode({
    required String code,
    required int discountPercent,
    required DateTime expiryDate,
    int? usageLimit,
    PromoType type = PromoType.promotional,
    String? description,
  }) async {
    if (kDebugMode) {
      _availablePromoCodes[code.toUpperCase()] = PromoCode(
        code: code.toUpperCase(),
        discountPercent: discountPercent,
        type: type,
        expiryDate: expiryDate,
        usageLimit: usageLimit,
        description: description ?? 'Custom promo code',
      );
      
      notifyListeners();
      debugPrint('Custom promo code created: $code');
    }
  }

  /// Reset referral data (for testing)
  Future<void> resetReferralData() async {
    if (kDebugMode) {
      _userReferralCode = null;
      _usedPromoCodes.clear();
      _referralStats.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_referral_code');
      await prefs.remove('used_promo_codes');
      await prefs.remove('referral_stats');
      
      await initialize();
      debugPrint('Referral data reset');
    }
  }
}

/// Promo code model
class PromoCode {
  final String code;
  final int discountPercent;
  final PromoType type;
  final DateTime expiryDate;
  final int? usageLimit;
  final String description;

  PromoCode({
    required this.code,
    required this.discountPercent,
    required this.type,
    required this.expiryDate,
    this.usageLimit,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'discountPercent': discountPercent,
    'type': type.toString(),
    'expiryDate': expiryDate.toIso8601String(),
    'usageLimit': usageLimit,
    'description': description,
  };
}

/// Promo code validation result
class PromoCodeValidation {
  final bool isValid;
  final String? errorMessage;
  final PromoCode? promoCode;
  final double? discountAmount;

  PromoCodeValidation({
    required this.isValid,
    this.errorMessage,
    this.promoCode,
    this.discountAmount,
  });
}

/// Types of promo codes
enum PromoType {
  newUser,
  referral,
  promotional,
  seasonal,
}
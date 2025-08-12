import 'package:flutter/foundation.dart';

import 'iap_service.dart';
import 'premium_service.dart';
import 'ads_service.dart';
import 'consent_service.dart';
import 'referral_service.dart';
import 'analytics_service.dart';

/// Main monetization manager that orchestrates all monetization services
class MonetizationManager extends ChangeNotifier {
  static final MonetizationManager _instance = MonetizationManager._internal();
  factory MonetizationManager() => _instance;
  MonetizationManager._internal();

  // Service instances
  final IAPService _iapService = IAPService();
  final PremiumService _premiumService = PremiumService();
  final AdsService _adsService = AdsService();
  final ConsentService _consentService = ConsentService();
  final ReferralService _referralService = ReferralService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _initialized = false;

  // Getters for services
  IAPService get iap => _iapService;
  PremiumService get premium => _premiumService;
  AdsService get ads => _adsService;
  ConsentService get consent => _consentService;
  ReferralService get referral => _referralService;
  AnalyticsService get analytics => _analyticsService;

  bool get initialized => _initialized;

  /// Initialize all monetization services
  Future<void> initialize() async {
    try {
      debugPrint('Initializing monetization manager...');

      // Initialize services in order
      await _consentService.initialize();
      await _premiumService.initialize();
      await _analyticsService.initialize();
      await _referralService.initialize();
      
      // Initialize IAP service
      await _iapService.initialize();
      
      // Initialize ads service (only if consent and not premium)
      if (_consentService.canShowAds && !_premiumService.adFree) {
        await _adsService.initialize();
      }

      // Set up service listeners
      _setupServiceListeners();

      _initialized = true;
      notifyListeners();

      // Track initialization
      await _analyticsService.trackEvent('monetization_initialized', {
        'iap_available': _iapService.isAvailable,
        'premium_active': _premiumService.isPremium,
        'ads_enabled': _adsService.shouldShowAds,
        'consent_granted': _consentService.canShowAds,
      });

      debugPrint('Monetization manager initialized successfully');
      
    } catch (e) {
      debugPrint('Monetization initialization error: $e');
      _initialized = false;
    }
  }

  /// Set up listeners for service interactions
  void _setupServiceListeners() {
    // Listen to premium changes
    _premiumService.addListener(() {
      if (_premiumService.adFree) {
        _adsService.disableAds();
      } else {
        _adsService.enableAds();
      }
      notifyListeners();
    });

    // Listen to IAP changes
    _iapService.addListener(() {
      notifyListeners();
    });

    // Listen to consent changes
    _consentService.addListener(() {
      if (!_consentService.canShowAds) {
        _adsService.disableAds();
      } else if (!_premiumService.adFree) {
        _adsService.enableAds();
      }
      notifyListeners();
    });
  }

  /// Purchase a product with optional promo code
  Future<bool> purchaseProduct(String productId, {String? promoCode}) async {
    if (!_initialized || !_iapService.isAvailable) {
      await _analyticsService.trackPurchaseFailure(
        productId, 
        'Service not initialized or IAP unavailable',
        promoCode: promoCode,
      );
      return false;
    }

    try {
      // Track purchase attempt
      await _analyticsService.trackPurchaseAttempt(productId, promoCode: promoCode);

      bool success;
      
      if (promoCode != null) {
        // Validate promo code first
        final validation = await _referralService.validatePromoCode(promoCode);
        if (!validation.isValid) {
          await _analyticsService.trackPurchaseFailure(
            productId, 
            'Invalid promo code: ${validation.errorMessage}',
            promoCode: promoCode,
          );
          return false;
        }
        
        // Apply promo code and purchase
        await _referralService.applyPromoCode(promoCode);
        success = await _iapService.purchaseWithPromoCode(productId, promoCode);
      } else {
        success = await _iapService.purchaseProduct(productId);
      }

      if (success) {
        // Track successful purchase
        final price = _iapService.getProductPrice(productId);
        await _analyticsService.trackPurchaseSuccess(
          productId, 
          double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
          promoCode: promoCode,
        );
        
        // Mark user as purchaser for referral system
        await _referralService.markUserAsPurchaser();
      } else {
        await _analyticsService.trackPurchaseFailure(
          productId, 
          'Purchase failed',
          promoCode: promoCode,
        );
      }

      return success;
      
    } catch (e) {
      await _analyticsService.trackPurchaseFailure(
        productId, 
        'Purchase error: $e',
        promoCode: promoCode,
      );
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_initialized || !_iapService.isAvailable) return;

    try {
      await _iapService.restorePurchases();
      await _analyticsService.trackEvent('purchases_restored', {});
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }

  /// Check if a feature is available to the user
  bool isFeatureAvailable(PremiumFeature feature) {
    return _premiumService.isFeatureAvailable(feature);
  }

  /// Try to use a feature (checks limits for free users)
  Future<bool> tryUseFeature(String feature) async {
    if (_premiumService.isPremium) {
      await _analyticsService.trackFeatureUsage(feature, context: {'user_type': 'premium'});
      return true;
    }

    final canUse = await _premiumService.canUseFeature(feature);
    if (canUse) {
      await _premiumService.incrementUsage(feature);
      await _analyticsService.trackFeatureUsage(feature, context: {'user_type': 'free'});
      
      // Maybe show interstitial ad after feature usage
      await _adsService.maybeShowInterstitialAd();
      
      return true;
    } else {
      // Track feature limit hit
      await _analyticsService.trackEvent('feature_limit_hit', {
        'feature': feature,
        'user_type': 'free',
      });
      return false;
    }
  }

  /// Show upgrade prompt when feature is locked
  Future<void> showUpgradePrompt(String feature) async {
    await _analyticsService.trackFunnelStep('upgrade_funnel', 'prompt_shown', extra: {
      'trigger_feature': feature,
    });
  }

  /// Get pricing for A/B test
  String getTestPrice(String productId) {
    final variant = _analyticsService.getABTestVariant('${productId}_price');
    if (variant != null) {
      return '\$$variant';
    }
    
    // Fallback to default prices
    return _iapService.getProductPrice(productId);
  }

  /// Get upgrade button text for A/B test
  String getUpgradeButtonText() {
    final variant = _analyticsService.getABTestVariant('upgrade_button_text');
    return variant ?? 'Upgrade Now';
  }

  /// Get featured premium benefit for A/B test
  String getFeaturedBenefit() {
    final variant = _analyticsService.getABTestVariant('feature_highlight');
    return variant ?? 'ad_free';
  }

  /// Generate and share referral code
  Map<String, String> getReferralShareContent() {
    _referralService.processReferral(_referralService.userReferralCode ?? '');
    _analyticsService.trackReferralGenerated(_referralService.userReferralCode ?? '');
    
    return _referralService.getReferralShareContent();
  }

  /// Process when someone uses a referral code
  Future<void> useReferralCode(String code) async {
    await _referralService.processReferral(code);
    await _analyticsService.trackReferralUsed(code);
  }

  /// Get monetization analytics dashboard data
  Map<String, dynamic> getAnalyticsDashboard() {
    return {
      'conversion': _analyticsService.getConversionAnalytics(),
      'referral': _referralService.getReferralEarnings(),
      'premium': {
        'is_premium': _premiumService.isPremium,
        'active_product': _premiumService.activeProductId,
        'days_until_expiry': _premiumService.daysUntilExpiry,
        'is_lifetime': _premiumService.isLifetime,
      },
      'ads': {
        'enabled': _adsService.shouldShowAds,
        'banner_loaded': _adsService.isBannerAdLoaded,
        'interstitial_loaded': _adsService.isInterstitialAdLoaded,
      },
      'consent': _consentService.getConsentStatus(),
    };
  }

  /// Emergency disable for compliance
  Future<void> emergencyDisable() async {
    await _adsService.dispose();
    await _consentService.revokeConsent();
    
    await _analyticsService.trackEvent('emergency_disable', {
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    debugPrint('Monetization emergency disabled');
  }

  /// Debug tools for testing
  Future<void> debugSetPremiumState(bool isPremium) async {
    if (kDebugMode) {
      await _premiumService.setDebugPremiumState(isPremium);
      await _analyticsService.trackEvent('debug_premium_toggle', {
        'premium_state': isPremium,
      });
    }
  }

  Future<void> debugResetAllData() async {
    if (kDebugMode) {
      await _premiumService.setDebugPremiumState(false);
      await _referralService.resetReferralData();
      await _analyticsService.resetAnalyticsData();
      await _consentService.resetConsent();
      
      debugPrint('All monetization data reset for debugging');
    }
  }

  @override
  void dispose() {
    _iapService.dispose();
    _adsService.dispose();
    super.dispose();
  }
}
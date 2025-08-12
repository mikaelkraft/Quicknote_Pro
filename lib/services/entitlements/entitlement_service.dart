import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../billing/billing_service.dart';
import '../../constants/product_ids.dart';

/// Service responsible for managing premium entitlements and feature access
class EntitlementService extends ChangeNotifier {
  static const String _premiumStatusKey = 'premium_status';
  static const String _premiumProductIdKey = 'premium_product_id';
  static const String _premiumPurchaseDateKey = 'premium_purchase_date';

  final BillingService _billingService;
  SharedPreferences? _prefs;
  
  bool _isPremium = false;
  String? _premiumProductId;
  DateTime? _premiumPurchaseDate;
  bool _isInitialized = false;

  EntitlementService(this._billingService);

  /// Whether the user has premium access
  bool get isPremium => _isPremium;

  /// The product ID of the active premium subscription/purchase
  String? get premiumProductId => _premiumProductId;

  /// Date when premium was purchased/activated
  DateTime? get premiumPurchaseDate => _premiumPurchaseDate;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the entitlement service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadStoredEntitlements();
      await _billingService.initialize();
      await _refreshEntitlements();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('EntitlementService initialization error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Load stored entitlements from local storage
  Future<void> _loadStoredEntitlements() async {
    _isPremium = _prefs?.getBool(_premiumStatusKey) ?? false;
    _premiumProductId = _prefs?.getString(_premiumProductIdKey);
    
    final purchaseDateMs = _prefs?.getInt(_premiumPurchaseDateKey);
    if (purchaseDateMs != null) {
      _premiumPurchaseDate = DateTime.fromMillisecondsSinceEpoch(purchaseDateMs);
    }
  }

  /// Refresh entitlements from the billing service
  Future<void> refreshEntitlements() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }
    await _refreshEntitlements();
  }

  Future<void> _refreshEntitlements() async {
    try {
      final activePurchases = await _billingService.getActivePurchases();
      
      bool foundPremium = false;
      String? foundProductId;
      DateTime? foundPurchaseDate;

      for (final purchase in activePurchases) {
        if (ProductIds.allProductIds.contains(purchase.productID)) {
          foundPremium = true;
          foundProductId = purchase.productID;
          foundPurchaseDate = DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(purchase.transactionDate ?? '0') ?? 0
          );
          break;
        }
      }

      if (_isPremium != foundPremium || 
          _premiumProductId != foundProductId ||
          _premiumPurchaseDate != foundPurchaseDate) {
        
        _isPremium = foundPremium;
        _premiumProductId = foundProductId;
        _premiumPurchaseDate = foundPurchaseDate;
        
        await _saveEntitlements();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing entitlements: $e');
    }
  }

  /// Save entitlements to local storage
  Future<void> _saveEntitlements() async {
    await _prefs?.setBool(_premiumStatusKey, _isPremium);
    
    if (_premiumProductId != null) {
      await _prefs?.setString(_premiumProductIdKey, _premiumProductId!);
    } else {
      await _prefs?.remove(_premiumProductIdKey);
    }
    
    if (_premiumPurchaseDate != null) {
      await _prefs?.setInt(_premiumPurchaseDateKey, _premiumPurchaseDate!.millisecondsSinceEpoch);
    } else {
      await _prefs?.remove(_premiumPurchaseDateKey);
    }
  }

  /// Grant premium access (for testing or special cases)
  Future<void> grantPremium({String? productId, DateTime? purchaseDate}) async {
    _isPremium = true;
    _premiumProductId = productId ?? ProductIds.premiumLifetime;
    _premiumPurchaseDate = purchaseDate ?? DateTime.now();
    
    await _saveEntitlements();
    notifyListeners();
  }

  /// Revoke premium access (for testing or special cases)
  Future<void> revokePremium() async {
    _isPremium = false;
    _premiumProductId = null;
    _premiumPurchaseDate = null;
    
    await _saveEntitlements();
    notifyListeners();
  }

  /// Check if a specific premium feature is available
  bool hasFeature(PremiumFeature feature) {
    // Allow dev bypass in debug mode if enabled
    if (kDebugMode && ProductIds.allowDevBypass) {
      return true;
    }
    
    return _isPremium;
  }

  /// Get the user's entitlement level
  EntitlementLevel get entitlementLevel {
    if (_isPremium) {
      return _premiumProductId == ProductIds.premiumMonthly 
          ? EntitlementLevel.premiumMonthly
          : EntitlementLevel.premiumLifetime;
    }
    return EntitlementLevel.free;
  }

  @override
  void dispose() {
    _billingService.dispose();
    super.dispose();
  }
}

/// Premium features that can be gated
enum PremiumFeature {
  unlimitedVoiceNotes,
  voiceTranscription,
  longerRecordings,
  backgroundRecording,
  advancedDrawingTools,
  layersSupport,
  exportFormats,
  cloudSync,
  adFree,
  prioritySupport,
}

/// User entitlement levels
enum EntitlementLevel {
  free,
  premiumMonthly,
  premiumLifetime,
}

/// Extension methods for premium features
extension PremiumFeatureExtension on PremiumFeature {
  String get displayName {
    switch (this) {
      case PremiumFeature.unlimitedVoiceNotes:
        return 'Unlimited Voice Notes';
      case PremiumFeature.voiceTranscription:
        return 'Voice Transcription';
      case PremiumFeature.longerRecordings:
        return 'Longer Recordings';
      case PremiumFeature.backgroundRecording:
        return 'Background Recording';
      case PremiumFeature.advancedDrawingTools:
        return 'Advanced Drawing Tools';
      case PremiumFeature.layersSupport:
        return 'Layers Support';
      case PremiumFeature.exportFormats:
        return 'Export Formats';
      case PremiumFeature.cloudSync:
        return 'Cloud Sync';
      case PremiumFeature.adFree:
        return 'Ad-Free Experience';
      case PremiumFeature.prioritySupport:
        return 'Priority Support';
    }
  }

  String get description {
    switch (this) {
      case PremiumFeature.unlimitedVoiceNotes:
        return 'Record unlimited voice notes without restrictions';
      case PremiumFeature.voiceTranscription:
        return 'Automatically transcribe your voice notes to text';
      case PremiumFeature.longerRecordings:
        return 'Record voice notes up to 1 hour long';
      case PremiumFeature.backgroundRecording:
        return 'Keep recording even when the app is in background';
      case PremiumFeature.advancedDrawingTools:
        return 'Access professional drawing tools and brushes';
      case PremiumFeature.layersSupport:
        return 'Work with multiple layers in your drawings';
      case PremiumFeature.exportFormats:
        return 'Export notes in PDF, Word, and other formats';
      case PremiumFeature.cloudSync:
        return 'Sync your notes across all your devices';
      case PremiumFeature.adFree:
        return 'Enjoy the app without any advertisements';
      case PremiumFeature.prioritySupport:
        return 'Get priority customer support and faster response times';
    }
  }
}
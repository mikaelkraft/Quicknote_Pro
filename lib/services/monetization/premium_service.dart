import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/product_ids.dart';

/// Service for managing premium subscription state and features
class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  bool _isPremium = false;
  String? _activeProductId;
  DateTime? _subscriptionExpiry;
  bool _isLifetime = false;

  // Premium feature flags
  bool _unlimitedVoiceNotes = false;
  bool _advancedDrawingTools = false;
  bool _cloudSync = false;
  bool _adFree = false;

  // Getters
  bool get isPremium => _isPremium;
  String? get activeProductId => _activeProductId;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  bool get isLifetime => _isLifetime;
  
  // Feature getters
  bool get unlimitedVoiceNotes => _unlimitedVoiceNotes;
  bool get advancedDrawingTools => _advancedDrawingTools;
  bool get cloudSync => _cloudSync;
  bool get adFree => _adFree;

  /// Initialize premium service
  Future<void> initialize() async {
    await _loadPremiumState();
    notifyListeners();
  }

  /// Load premium state from shared preferences
  Future<void> _loadPremiumState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isPremium = prefs.getBool('is_premium') ?? false;
      _activeProductId = prefs.getString('active_product_id');
      _isLifetime = prefs.getBool('is_lifetime') ?? false;
      
      final expiryTimestamp = prefs.getInt('subscription_expiry');
      if (expiryTimestamp != null) {
        _subscriptionExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
        
        // Check if subscription has expired
        if (!_isLifetime && DateTime.now().isAfter(_subscriptionExpiry!)) {
          await _deactivatePremium();
          return;
        }
      }

      // Update feature flags based on premium status
      _updateFeatureFlags();
      
    } catch (e) {
      debugPrint('Error loading premium state: $e');
      _resetToDefaults();
    }
  }

  /// Save premium state to shared preferences
  Future<void> _savePremiumState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('is_premium', _isPremium);
      await prefs.setBool('is_lifetime', _isLifetime);
      
      if (_activeProductId != null) {
        await prefs.setString('active_product_id', _activeProductId!);
      } else {
        await prefs.remove('active_product_id');
      }
      
      if (_subscriptionExpiry != null) {
        await prefs.setInt('subscription_expiry', _subscriptionExpiry!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('subscription_expiry');
      }
      
    } catch (e) {
      debugPrint('Error saving premium state: $e');
    }
  }

  /// Activate premium features for a specific product
  Future<void> activatePremium(String productId) async {
    _isPremium = true;
    _activeProductId = productId;

    if (productId == ProductIds.premiumLifetime) {
      _isLifetime = true;
      _subscriptionExpiry = null; // Lifetime doesn't expire
    } else if (productId == ProductIds.premiumMonthly) {
      _isLifetime = false;
      _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
    }

    _updateFeatureFlags();
    await _savePremiumState();
    notifyListeners();

    debugPrint('Premium activated: $productId');
  }

  /// Deactivate premium features
  Future<void> _deactivatePremium() async {
    _isPremium = false;
    _activeProductId = null;
    _subscriptionExpiry = null;
    _isLifetime = false;
    
    _updateFeatureFlags();
    await _savePremiumState();
    notifyListeners();

    debugPrint('Premium deactivated');
  }

  /// Update feature flags based on premium status
  void _updateFeatureFlags() {
    if (_isPremium) {
      _unlimitedVoiceNotes = true;
      _advancedDrawingTools = true;
      _cloudSync = true;
      _adFree = true;
    } else {
      _unlimitedVoiceNotes = false;
      _advancedDrawingTools = false;
      _cloudSync = false;
      _adFree = false;
    }
  }

  /// Reset to default free tier state
  void _resetToDefaults() {
    _isPremium = false;
    _activeProductId = null;
    _subscriptionExpiry = null;
    _isLifetime = false;
    _updateFeatureFlags();
  }

  /// Check if a specific feature is available
  bool isFeatureAvailable(PremiumFeature feature) {
    if (!_isPremium) return false;

    switch (feature) {
      case PremiumFeature.unlimitedVoiceNotes:
        return _unlimitedVoiceNotes;
      case PremiumFeature.advancedDrawingTools:
        return _advancedDrawingTools;
      case PremiumFeature.cloudSync:
        return _cloudSync;
      case PremiumFeature.adFree:
        return _adFree;
    }
  }

  /// Get days until subscription expires (null for lifetime)
  int? get daysUntilExpiry {
    if (_isLifetime || _subscriptionExpiry == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(_subscriptionExpiry!)) return 0;
    
    return _subscriptionExpiry!.difference(now).inDays;
  }

  /// Check if subscription is expiring soon (within 3 days)
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 3 && days > 0;
  }

  /// Get usage limits for free tier features
  Map<String, int> get freeTierLimits => {
    'voice_notes_per_month': 10,
    'cloud_storage_mb': 0,
    'drawing_layers': 1,
  };

  /// Check current usage against limits
  Future<Map<String, int>> getCurrentUsage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Reset monthly counters if new month
    final lastResetMonth = prefs.getInt('last_reset_month') ?? 0;
    final currentMonth = DateTime.now().month;
    
    if (lastResetMonth != currentMonth) {
      await prefs.setInt('voice_notes_used', 0);
      await prefs.setInt('last_reset_month', currentMonth);
    }

    return {
      'voice_notes_used': prefs.getInt('voice_notes_used') ?? 0,
      'cloud_storage_used_mb': prefs.getInt('cloud_storage_used_mb') ?? 0,
      'drawing_layers_used': prefs.getInt('drawing_layers_used') ?? 1,
    };
  }

  /// Increment usage counter
  Future<void> incrementUsage(String feature) async {
    if (_isPremium) return; // No limits for premium users
    
    final prefs = await SharedPreferences.getInstance();
    final currentValue = prefs.getInt(feature) ?? 0;
    await prefs.setInt(feature, currentValue + 1);
  }

  /// Check if user can use a feature based on usage limits
  Future<bool> canUseFeature(String feature) async {
    if (_isPremium) return true;
    
    final usage = await getCurrentUsage();
    final limits = freeTierLimits;
    
    final usedKey = '${feature}_used';
    final limitKey = '${feature}_per_month';
    
    final used = usage[usedKey] ?? 0;
    final limit = limits[limitKey] ?? 0;
    
    return used < limit;
  }

  /// Manual override for testing/debugging
  Future<void> setDebugPremiumState(bool isPremium) async {
    if (kDebugMode && ProductIds.allowDevBypass) {
      if (isPremium) {
        await activatePremium(ProductIds.premiumLifetime);
      } else {
        await _deactivatePremium();
      }
    }
  }

  /// Get premium benefits summary
  List<Map<String, dynamic>> get premiumBenefits => [
    {
      'title': 'Unlimited Voice Notes',
      'description': 'Record and transcribe unlimited voice memos',
      'free_limit': '10/month',
      'premium_limit': 'Unlimited',
      'available': _unlimitedVoiceNotes,
    },
    {
      'title': 'Advanced Drawing Tools',
      'description': 'Professional drawing tools with layers and effects',
      'free_limit': 'Basic tools',
      'premium_limit': 'Pro tools + Layers',
      'available': _advancedDrawingTools,
    },
    {
      'title': 'Cloud Sync',
      'description': 'Sync notes across all your devices',
      'free_limit': 'Local only',
      'premium_limit': 'All devices',
      'available': _cloudSync,
    },
    {
      'title': 'Ad-Free Experience',
      'description': 'Clean interface without interruptions',
      'free_limit': 'With ads',
      'premium_limit': 'Ad-free',
      'available': _adFree,
    },
  ];
}

/// Enum for premium features
enum PremiumFeature {
  unlimitedVoiceNotes,
  advancedDrawingTools,
  cloudSync,
  adFree,
}
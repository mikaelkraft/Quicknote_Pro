import 'dart:async';
import '../local/hive_initializer.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  static const String _premiumKey = 'is_premium';
  static const String _premiumExpiryKey = 'premium_expiry';

  // Stream controller for premium status changes
  final _premiumController = StreamController<bool>.broadcast();

  /// Stream of premium status changes
  Stream<bool> get premiumStatusStream => _premiumController.stream;

  /// Check if user has premium access
  bool get isPremium {
    try {
      final box = HiveInitializer.settingsBox;
      final isPremium = box.get(_premiumKey, defaultValue: false) as bool;
      
      // Check if premium has expired (if there's an expiry date)
      final expiryString = box.get(_premiumExpiryKey) as String?;
      if (expiryString != null) {
        final expiry = DateTime.parse(expiryString);
        if (DateTime.now().isAfter(expiry)) {
          // Premium has expired, revoke access
          _setPremiumStatus(false);
          return false;
        }
      }
      
      return isPremium;
    } catch (e) {
      // If there's any error, default to free tier
      print('Error checking premium status: $e');
      return false;
    }
  }

  /// Set premium status (for development/testing)
  Future<void> _setPremiumStatus(bool isPremium, {DateTime? expiryDate}) async {
    try {
      final box = HiveInitializer.settingsBox;
      await box.put(_premiumKey, isPremium);
      
      if (expiryDate != null) {
        await box.put(_premiumExpiryKey, expiryDate.toIso8601String());
      } else {
        await box.delete(_premiumExpiryKey);
      }
      
      _premiumController.add(isPremium);
    } catch (e) {
      print('Error setting premium status: $e');
    }
  }

  /// Grant premium access (for development/testing)
  Future<void> grantPremium({DateTime? expiryDate}) async {
    await _setPremiumStatus(true, expiryDate: expiryDate);
  }

  /// Revoke premium access
  Future<void> revokePremium() async {
    await _setPremiumStatus(false);
  }

  /// Grant premium for a specific duration (for testing)
  Future<void> grantPremiumForDuration(Duration duration) async {
    final expiry = DateTime.now().add(duration);
    await _setPremiumStatus(true, expiryDate: expiry);
  }

  /// Get premium expiry date (if any)
  DateTime? get premiumExpiryDate {
    try {
      final box = HiveInitializer.settingsBox;
      final expiryString = box.get(_premiumExpiryKey) as String?;
      return expiryString != null ? DateTime.parse(expiryString) : null;
    } catch (e) {
      return null;
    }
  }

  /// Check if a specific feature is available
  bool isFeatureAvailable(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.doodling:
      case PremiumFeature.fileAttachments:
      case PremiumFeature.cloudSync:
      case PremiumFeature.advancedSearch:
        return isPremium;
      case PremiumFeature.basicNotes:
      case PremiumFeature.textFormatting:
      case PremiumFeature.imageInsertion:
        return true; // Free features
    }
  }

  /// Get localized feature name
  String getFeatureName(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.doodling:
        return 'Drawing & Doodling';
      case PremiumFeature.fileAttachments:
        return 'File Attachments';
      case PremiumFeature.cloudSync:
        return 'Cloud Synchronization';
      case PremiumFeature.advancedSearch:
        return 'Advanced Search';
      case PremiumFeature.basicNotes:
        return 'Basic Note Taking';
      case PremiumFeature.textFormatting:
        return 'Text Formatting';
      case PremiumFeature.imageInsertion:
        return 'Image Insertion';
    }
  }

  /// Get upsell message for a feature
  String getUpsellMessage(PremiumFeature feature) {
    final featureName = getFeatureName(feature);
    return 'Upgrade to Premium to unlock $featureName and more advanced features!';
  }

  /// Show premium upsell dialog for a feature
  /// Returns true if user should be navigated to premium upgrade page
  Future<bool> showFeatureUpsell(PremiumFeature feature) async {
    // This would typically show a dialog and return the user's choice
    // For now, we'll just return false (don't navigate to upgrade)
    // TODO: Implement actual dialog in the UI layer
    print('Feature requires premium: ${getFeatureName(feature)}');
    return false;
  }

  /// Initialize the service
  void init() {
    // Emit initial premium status
    _premiumController.add(isPremium);
  }

  /// Dispose the service
  void dispose() {
    _premiumController.close();
  }

  /// Simulate purchase flow (for development)
  Future<bool> simulatePurchase(PremiumPlan plan) async {
    // Simulate purchase delay
    await Future.delayed(const Duration(seconds: 2));
    
    switch (plan) {
      case PremiumPlan.monthly:
        await grantPremiumForDuration(const Duration(days: 30));
        break;
      case PremiumPlan.yearly:
        await grantPremiumForDuration(const Duration(days: 365));
        break;
      case PremiumPlan.lifetime:
        await grantPremium(); // No expiry for lifetime
        break;
    }
    
    return true; // Purchase successful
  }

  /// Get plan price (for display purposes)
  String getPlanPrice(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return '\$2.99/month';
      case PremiumPlan.yearly:
        return '\$19.99/year';
      case PremiumPlan.lifetime:
        return '\$49.99 one-time';
    }
  }

  /// Get plan savings text
  String? getPlanSavings(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.yearly:
        return 'Save 44%';
      case PremiumPlan.lifetime:
        return 'Best Value';
      case PremiumPlan.monthly:
        return null;
    }
  }
}

enum PremiumFeature {
  // Free features
  basicNotes,
  textFormatting,
  imageInsertion,
  
  // Premium features
  doodling,
  fileAttachments,
  cloudSync,
  advancedSearch,
}

enum PremiumPlan {
  monthly,
  yearly,
  lifetime,
}
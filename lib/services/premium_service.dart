import 'package:flutter/material.dart';

/// Service to manage premium features and gating
class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  // Mock premium status - in real app this would be from subscription service
  bool _isPremium = false;

  /// Check if user has premium subscription
  bool get isPremium => _isPremium;

  /// Set premium status (for demo/testing purposes)
  void setPremiumStatus(bool premium) {
    _isPremium = premium;
  }

  /// Check if file uploads are allowed (premium feature)
  bool canUploadFiles() {
    return _isPremium;
  }

  /// Check if drawing/doodling is allowed (premium feature)
  bool canUseDoodling() {
    return _isPremium;
  }

  /// Check if cloud sync is allowed (premium feature)
  bool canUseCloudSync() {
    return _isPremium;
  }

  /// Check if multi-provider sync is allowed (premium feature)
  bool canUseMultiProviderSync() {
    return _isPremium;
  }

  /// Show premium upsell dialog
  static void showPremiumUpsell(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Premium Feature'),
        content: Text('$feature requires a premium subscription. Upgrade to unlock unlimited cloud sync, file uploads, and advanced drawing tools.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/premium-upgrade');
            },
            child: Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  /// Validate if action is allowed, show upsell if not
  static bool validatePremiumAction(BuildContext context, String action) {
    final premiumService = PremiumService();
    
    switch (action) {
      case 'upload':
        if (!premiumService.canUploadFiles()) {
          showPremiumUpsell(context, 'File uploads');
          return false;
        }
        break;
      case 'doodle':
        if (!premiumService.canUseDoodling()) {
          showPremiumUpsell(context, 'Advanced drawing tools');
          return false;
        }
        break;
      case 'cloud_sync':
        if (!premiumService.canUseCloudSync()) {
          showPremiumUpsell(context, 'Cloud sync');
          return false;
        }
        break;
      case 'multi_sync':
        if (!premiumService.canUseMultiProviderSync()) {
          showPremiumUpsell(context, 'Multi-provider sync');
          return false;
        }
        break;
    }
    
    return true;
  }
}
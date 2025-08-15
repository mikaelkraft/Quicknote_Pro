import 'package:flutter/material.dart';

import '../analytics/analytics_service.dart';
import '../monetization/monetization_service.dart';
import '../ads/ads_service.dart';
import '../../widgets/monetization/paywall_dialog.dart';
import '../../widgets/monetization/ad_widgets.dart';

/// Helper service for easy integration of monetization features into existing screens.
/// 
/// Provides simplified methods for common monetization tasks like feature gating,
/// usage tracking, and ad display.
class MonetizationHelper {
  final MonetizationService _monetizationService;
  final AnalyticsService _analyticsService;
  final AdsService _adsService;

  MonetizationHelper({
    required MonetizationService monetizationService,
    required AnalyticsService analyticsService,
    required AdsService adsService,
  })  : _monetizationService = monetizationService,
        _analyticsService = analyticsService,
        _adsService = adsService;

  /// Check if user can use a feature and show upgrade prompt if not
  Future<bool> checkFeatureAccess(
    BuildContext context, {
    required FeatureType featureType,
    required String featureContext,
    String? upgradeTitle,
    String? upgradeDescription,
  }) async {
    if (_monetizationService.canUseFeature(featureType)) {
      return true;
    }

    // Track feature limit reached
    _analyticsService.trackMonetizationEvent(
      MonetizationEvent.featureLimitReached(feature: featureType.name),
    );

    // Show upgrade prompt
    final result = await PaywallDialog.show(
      context,
      featureContext: featureContext,
      title: upgradeTitle ?? _getDefaultUpgradeTitle(featureType),
      description: upgradeDescription ?? _getDefaultUpgradeDescription(featureType),
    );

    return result == true;
  }

  /// Record feature usage and track analytics
  Future<void> recordFeatureUsage(FeatureType featureType, {
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _monetizationService.recordFeatureUsage(featureType);
    
    // Track feature usage analytics
    _analyticsService.trackFeatureEvent(
      FeatureEvent(featureType.name, 'used', additionalProperties ?? {}),
    );
  }

  /// Check if an ad should be shown and return appropriate widget
  Widget? buildAdWidget(AdPlacement placement, {
    NativeAdTemplate? nativeTemplate,
    double? bannerHeight,
    EdgeInsets? margin,
  }) {
    if (!_adsService.canShowAd(placement)) {
      return null;
    }

    final config = AdConfig.forPlacement(placement);
    
    switch (config.format) {
      case AdFormat.banner:
        return SimpleBannerAd(
          placement: placement,
          height: bannerHeight,
          margin: margin,
        );
      
      case AdFormat.native:
        return SimpleNativeAd(
          placement: placement,
          template: nativeTemplate ?? NativeAdTemplate.medium,
        );
      
      case AdFormat.interstitial:
        // Interstitials are shown programmatically, not as widgets
        return null;
      
      case AdFormat.rewarded:
        // Rewarded ads are shown programmatically
        return null;
    }
  }

  /// Show interstitial ad with smart timing
  Future<void> showSmartInterstitial(
    BuildContext context,
    AdPlacement placement, {
    bool isImportantTransition = false,
  }) async {
    await SmartInterstitialHelper.showSmartInterstitial(
      context,
      placement,
      isImportantTransition: isImportantTransition,
    );
  }

  /// Get user's current tier information
  MonetizationStatus get status => MonetizationStatus(
    currentTier: _monetizationService.currentTier,
    isPremium: _monetizationService.isPremium,
    usageCounts: _monetizationService.usageCounts,
    upgradePromptCount: _monetizationService.upgradePromptCount,
  );

  /// Check if user is approaching any limits (>80% usage)
  bool hasApproachingLimits() {
    for (final featureType in FeatureType.values) {
      if (_getUsagePercentage(featureType) > 0.8) {
        return true;
      }
    }
    return false;
  }

  /// Get usage percentage for a feature (0.0 to 1.0, or -1 for unlimited)
  double _getUsagePercentage(FeatureType featureType) {
    final limits = FeatureLimits.forTier(_monetizationService.currentTier);
    final limit = limits.getFeatureLimit(featureType);
    final used = _monetizationService.usageCounts[featureType] ?? 0;
    
    if (limit == -1) return -1; // Unlimited
    if (limit == 0) return 1.0; // No access
    
    return used / limit;
  }

  /// Show upgrade prompt with context
  Future<bool?> showUpgradePrompt(
    BuildContext context, {
    required String featureContext,
    String? title,
    String? description,
  }) async {
    return await PaywallDialog.show(
      context,
      featureContext: featureContext,
      title: title,
      description: description,
    );
  }

  /// Get default upgrade title for feature type
  String _getDefaultUpgradeTitle(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.noteCreation:
        return 'Unlimited Notes';
      case FeatureType.voiceNoteRecording:
        return 'Unlimited Voice Recordings';
      case FeatureType.advancedDrawing:
        return 'Advanced Drawing Tools';
      case FeatureType.cloudSync:
        return 'Unlimited Cloud Sync';
      case FeatureType.advancedExport:
        return 'Premium Export Formats';
      case FeatureType.folders:
        return 'Unlimited Folders';
      case FeatureType.attachments:
        return 'Unlimited Attachments';
    }
  }

  /// Get default upgrade description for feature type
  String _getDefaultUpgradeDescription(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.noteCreation:
        return 'Create unlimited notes without monthly restrictions. Upgrade to Premium now.';
      case FeatureType.voiceNoteRecording:
        return 'Record unlimited voice notes with longer duration and transcription. Upgrade to Premium.';
      case FeatureType.advancedDrawing:
        return 'Access professional drawing tools, brushes, and layers. Available with Premium.';
      case FeatureType.cloudSync:
        return 'Sync unlimited notes across all your devices. Upgrade to Premium.';
      case FeatureType.advancedExport:
        return 'Export notes to PDF, DOCX, and other premium formats. Available with Premium.';
      case FeatureType.folders:
        return 'Organize your notes with unlimited folders and advanced organization. Upgrade to Premium.';
      case FeatureType.attachments:
        return 'Add unlimited images, files, and media to your notes. Available with Premium.';
    }
  }

  /// Track common monetization events
  void trackEvent(MonetizationEventType eventType, {
    Map<String, dynamic>? properties,
  }) {
    switch (eventType) {
      case MonetizationEventType.featureLimitReached:
        _analyticsService.trackMonetizationEvent(
          MonetizationEvent.featureLimitReached(
            feature: properties?['feature'],
          ),
        );
        break;
      
      case MonetizationEventType.upgradePromptShown:
        _analyticsService.trackMonetizationEvent(
          MonetizationEvent.upgradePromptShown(
            context: properties?['context'],
          ),
        );
        break;
      
      case MonetizationEventType.upgradeStarted:
        _analyticsService.trackMonetizationEvent(
          MonetizationEvent.upgradeStarted(
            tier: properties?['tier'],
          ),
        );
        break;
      
      case MonetizationEventType.upgradeCompleted:
        _analyticsService.trackMonetizationEvent(
          MonetizationEvent.upgradeCompleted(
            tier: properties?['tier'],
          ),
        );
        break;
      
      case MonetizationEventType.adShown:
        _analyticsService.trackMonetizationEvent(
          MonetizationEvent.adShown(
            placement: properties?['placement'],
            format: properties?['format'],
          ),
        );
        break;
      
      case MonetizationEventType.adClicked:
        _analyticsService.trackMonetizationEvent(
          MonetizationEvent.adClicked(
            placement: properties?['placement'],
          ),
        );
        break;
    }
  }
}

/// Current monetization status snapshot
class MonetizationStatus {
  final UserTier currentTier;
  final bool isPremium;
  final Map<FeatureType, int> usageCounts;
  final int upgradePromptCount;

  const MonetizationStatus({
    required this.currentTier,
    required this.isPremium,
    required this.usageCounts,
    required this.upgradePromptCount,
  });

  /// Get remaining usage for a feature
  int getRemainingUsage(FeatureType featureType) {
    final limits = FeatureLimits.forTier(currentTier);
    final limit = limits.getFeatureLimit(featureType);
    final used = usageCounts[featureType] ?? 0;
    
    if (limit == -1) return -1; // Unlimited
    return (limit - used).clamp(0, limit);
  }

  /// Check if approaching limit (>80% usage)
  bool isApproachingLimit(FeatureType featureType) {
    final limits = FeatureLimits.forTier(currentTier);
    final limit = limits.getFeatureLimit(featureType);
    final used = usageCounts[featureType] ?? 0;
    
    if (limit == -1) return false; // Unlimited
    return used / limit > 0.8;
  }

  /// Check if at limit
  bool isAtLimit(FeatureType featureType) {
    return getRemainingUsage(featureType) <= 0;
  }
}

/// Common monetization event types for tracking
enum MonetizationEventType {
  featureLimitReached,
  upgradePromptShown,
  upgradeStarted,
  upgradeCompleted,
  adShown,
  adClicked,
}

/// Extension methods for easy monetization integration
extension MonetizationWidgetExtensions on Widget {
  /// Wrap widget with feature gate
  Widget gateFeature(
    FeatureType featureType,
    String featureContext, {
    String? upgradeTitle,
    String? upgradeDescription,
    bool showAsBlocked = true,
  }) {
    return Builder(
      builder: (context) => FeatureGate(
        featureType: featureType,
        featureContext: featureContext,
        upgradeTitle: upgradeTitle,
        upgradeDescription: upgradeDescription,
        showAsBlocked: showAsBlocked,
        child: this,
      ),
    );
  }
}

/// Extension methods for BuildContext to access monetization features
extension MonetizationContextExtensions on BuildContext {
  /// Get monetization helper instance
  MonetizationHelper get monetization => MonetizationHelper(
    monetizationService: read<MonetizationService>(),
    analyticsService: read<AnalyticsService>(),
    adsService: read<AdsService>(),
  );
  
  /// Quick access to monetization service
  MonetizationService get monetizationService => read<MonetizationService>();
  
  /// Quick access to analytics service
  AnalyticsService get analyticsService => read<AnalyticsService>();
  
  /// Quick access to ads service
  AdsService get adsService => read<AdsService>();
}
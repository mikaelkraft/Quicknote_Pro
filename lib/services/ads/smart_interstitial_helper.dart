import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../constants/ads_config.dart';
import '../services/ads/ads_service.dart';
import '../widgets/ads/interstitial_ad_widget.dart';

/// Helper class for managing interstitial ad display with intelligent timing
class SmartInterstitialHelper {
  static const String _keyLastInterstitialTime = 'last_interstitial_time';
  static const String _keyInterstitialCount = 'interstitial_count_today';
  static const String _keyInterstitialDate = 'interstitial_date';
  
  /// Determines if an interstitial ad should be shown based on user behavior
  static bool shouldShowInterstitial({
    required String placementId,
    int sessionActions = 0,
    bool isImportantTransition = false,
  }) {
    // Don't show ads too frequently
    if (sessionActions < 3 && !isImportantTransition) return false;
    
    // Show ads with decreasing probability based on recent activity
    final random = Random();
    double probability = 0.15; // 15% base chance
    
    if (isImportantTransition) {
      probability = 0.25; // 25% for important transitions
    }
    
    // Increase probability for certain placements
    if (placementId == AdsConfig.placementNoteList) {
      probability += 0.1;
    }
    
    return random.nextDouble() < probability;
  }

  /// Shows an interstitial ad with smart timing and frequency control
  static Future<bool> showSmartInterstitial(
    BuildContext context,
    String placementId, {
    VoidCallback? onAdClosed,
    bool isImportantTransition = false,
    int sessionActions = 0,
  }) async {
    final adsService = context.read<AdsService>();
    
    if (!adsService.shouldShowAds) {
      return false;
    }

    // Check if we should show an ad based on smart logic
    if (!shouldShowInterstitial(
      placementId: placementId,
      sessionActions: sessionActions,
      isImportantTransition: isImportantTransition,
    )) {
      return false;
    }

    // Check if we can show an interstitial ad for this placement
    final placement = adsService.placements[placementId];
    if (placement == null || 
        !placement.supportedFormats.contains(AdsConfig.formatInterstitial)) {
      return false;
    }

    try {
      // Show the interstitial overlay
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) => InterstitialAdOverlay(
          placementId: placementId,
          onAdClosed: onAdClosed,
        ),
      ) ?? false;
    } catch (e) {
      debugPrint('SmartInterstitialHelper: Failed to show interstitial: $e');
      return false;
    }
  }

  /// Preloads an interstitial ad for better performance
  static Future<void> preloadSmartInterstitial(
    BuildContext context,
    String placementId,
  ) async {
    final adsService = context.read<AdsService>();
    if (!adsService.shouldShowAds) return;
    
    try {
      await adsService.loadAd(
        placementId,
        preferredFormat: AdsConfig.formatInterstitial,
      );
    } catch (e) {
      debugPrint('SmartInterstitialHelper: Failed to preload interstitial: $e');
    }
  }

  /// Shows interstitial ads on app state changes (pause/resume)
  static Future<void> handleAppStateChange(
    BuildContext context,
    AppLifecycleState state,
  ) async {
    if (state == AppLifecycleState.resumed) {
      // User returned to app - small chance of interstitial
      await Future.delayed(const Duration(seconds: 2));
      
      if (shouldShowInterstitial(
        placementId: AdsConfig.placementHome,
        isImportantTransition: false,
      )) {
        await showSmartInterstitial(
          context,
          AdsConfig.placementHome,
          isImportantTransition: false,
        );
      }
    }
  }
}

/// Widget that handles automatic interstitial ad display
class InterstitialTrigger extends StatefulWidget {
  final Widget child;
  final String placementId;
  final bool triggerOnInit;
  final int delaySeconds;
  final VoidCallback? onAdShown;

  const InterstitialTrigger({
    Key? key,
    required this.child,
    required this.placementId,
    this.triggerOnInit = false,
    this.delaySeconds = 3,
    this.onAdShown,
  }) : super(key: key);

  @override
  State<InterstitialTrigger> createState() => _InterstitialTriggerState();
}

class _InterstitialTriggerState extends State<InterstitialTrigger> {
  @override
  void initState() {
    super.initState();
    if (widget.triggerOnInit) {
      _scheduleInterstitial();
    }
  }

  void _scheduleInterstitial() {
    Future.delayed(Duration(seconds: widget.delaySeconds), () {
      if (mounted) {
        SmartInterstitialHelper.showSmartInterstitial(
          context,
          widget.placementId,
          onAdClosed: widget.onAdShown,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Example integration of monetization features into an existing screen
/// This shows how to add feature gates, usage tracking, and ads
class MonetizationDemoScreen extends StatefulWidget {
  const MonetizationDemoScreen({Key? key}) : super(key: key);

  @override
  State<MonetizationDemoScreen> createState() => _MonetizationDemoScreenState();
}

class _MonetizationDemoScreenState extends State<MonetizationDemoScreen> {
  bool _usageDashboardExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monetization Demo'),
        actions: [
          // Tier status badge in app bar
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: const TierStatusBadge(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Usage dashboard at the top
            UsageDashboard(
              isExpanded: _usageDashboardExpanded,
              onToggleExpanded: () {
                setState(() => _usageDashboardExpanded = !_usageDashboardExpanded);
              },
            ),

            // Quick monetization actions
            const MonetizationQuickActions(),

            // Example: Banner ad placement
            const SimpleBannerAd(
              placement: AdPlacement.noteListBanner,
            ),

            // Example: Feature-gated buttons
            _buildFeatureGatedExamples(),

            // Example: Usage indicators
            _buildUsageExamples(),

            // Example: Native ad in content
            const SimpleNativeAd(
              placement: AdPlacement.featureDiscoveryNative,
              template: NativeAdTemplate.medium,
            ),

            // Example: Manual paywall trigger
            _buildManualPaywallExample(),

            SizedBox(height: 10.h),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeatureGatedExamples() {
    return Card(
      margin: EdgeInsets.all(4.w),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Gates Demo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3.h),

            // Note creation with limit
            FeatureGate(
              featureType: FeatureType.noteCreation,
              featureContext: 'note_creation_demo',
              upgradeTitle: 'Unlimited Note Creation',
              upgradeDescription: 'Create as many notes as you need with Premium.',
              child: ElevatedButton.icon(
                onPressed: () => _createNote(),
                icon: const Icon(Icons.note_add),
                label: const Text('Create Note'),
              ),
            ),
            SizedBox(height: 2.h),

            // Voice recording with limit
            FeatureGate(
              featureType: FeatureType.voiceNoteRecording,
              featureContext: 'voice_recording_demo',
              child: ElevatedButton.icon(
                onPressed: () => _recordVoiceNote(),
                icon: const Icon(Icons.mic),
                label: const Text('Record Voice Note'),
              ),
            ),
            SizedBox(height: 2.h),

            // Advanced drawing (premium feature)
            FeatureGate(
              featureType: FeatureType.advancedDrawing,
              featureContext: 'advanced_drawing_demo',
              upgradeTitle: 'Advanced Drawing Tools',
              upgradeDescription: 'Unlock professional drawing tools and brushes.',
              child: ElevatedButton.icon(
                onPressed: () => _useAdvancedDrawing(),
                icon: const Icon(Icons.brush),
                label: const Text('Advanced Drawing'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageExamples() {
    return Card(
      margin: EdgeInsets.all(4.w),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Indicators Demo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3.h),

            _buildUsageIndicatorRow('Notes Created', FeatureType.noteCreation),
            SizedBox(height: 2.h),
            _buildUsageIndicatorRow('Voice Recordings', FeatureType.voiceNoteRecording),
            SizedBox(height: 2.h),
            _buildUsageIndicatorRow('Cloud Syncs', FeatureType.cloudSync),
            SizedBox(height: 2.h),
            _buildUsageIndicatorRow('Attachments', FeatureType.attachments),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageIndicatorRow(String label, FeatureType featureType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        FeatureUsageIndicator(
          featureType: featureType,
          showDetails: true,
        ),
      ],
    );
  }

  Widget _buildManualPaywallExample() {
    return Card(
      margin: EdgeInsets.all(4.w),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Paywall Demo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'These buttons manually trigger the paywall for testing different contexts.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 3.h),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPaywall('theme_selection'),
                    child: const Text('Theme Paywall'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPaywall('export_feature'),
                    child: const Text('Export Paywall'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPaywall('storage_limit'),
                    child: const Text('Storage Paywall'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showInterstitialAd(),
                    child: const Text('Interstitial Ad'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleCreateNote() async {
    final monetizationService = context.read<MonetizationService>();
    final analyticsService = context.read<AnalyticsService>();

    // Check if user can create notes
    if (!monetizationService.canUseFeature(FeatureType.noteCreation)) {
      // Show feature gate dialog
      final result = await PaywallDialog.show(
        context,
        featureContext: 'note_creation_fab',
        title: 'Note Limit Reached',
        description: 'You\'ve reached your monthly note creation limit. Upgrade to Premium for unlimited notes.',
      );

      if (result != true) return;
    }

    // Record feature usage
    await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
    
    // Track analytics
    analyticsService.trackEngagementEvent(EngagementEvent.noteCreated());

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note created! (Demo)')),
      );
    }

    // Potentially show interstitial ad after creating multiple notes
    await SmartInterstitialHelper.showSmartInterstitial(
      context,
      AdPlacement.noteCreationInterstitial,
      isImportantTransition: false,
    );
  }

  void _createNote() async {
    final monetizationService = context.read<MonetizationService>();
    
    await monetizationService.recordFeatureUsage(FeatureType.noteCreation);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note created! (Demo)')),
    );
    
    setState(() {}); // Refresh UI to show updated usage
  }

  void _recordVoiceNote() async {
    final monetizationService = context.read<MonetizationService>();
    
    await monetizationService.recordFeatureUsage(FeatureType.voiceNoteRecording);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice note recorded! (Demo)')),
    );
    
    setState(() {}); // Refresh UI to show updated usage
  }

  void _useAdvancedDrawing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advanced drawing tools opened! (Demo)')),
    );
  }

  void _showPaywall(String context) {
    PaywallDialog.show(
      this.context,
      featureContext: context,
      title: 'Upgrade Required',
      description: 'This feature requires a Premium subscription.',
    );
  }

  void _showInterstitialAd() {
    SmartInterstitialHelper.showSmartInterstitial(
      context,
      AdPlacement.premiumPromptInterstitial,
      isImportantTransition: true,
    );
  }
}

/// Analytics integration example
class AnalyticsIntegrationExample {
  static void trackAppLaunch(AnalyticsService analyticsService) {
    analyticsService.trackEvent(AnalyticsEvent.appStarted());
  }

  static void trackNoteCreation(AnalyticsService analyticsService) {
    analyticsService.trackEngagementEvent(EngagementEvent.noteCreated());
  }

  static void trackFeatureLimitReached(
    AnalyticsService analyticsService,
    FeatureType featureType,
  ) {
    analyticsService.trackMonetizationEvent(
      MonetizationEvent.featureLimitReached(feature: featureType.name),
    );
  }

  static void trackUpgradeFlow(
    AnalyticsService analyticsService,
    String stage,
    UserTier targetTier,
  ) {
    switch (stage) {
      case 'started':
        analyticsService.trackMonetizationEvent(
          MonetizationEvent.upgradeStarted(tier: targetTier.name),
        );
        break;
      case 'completed':
        analyticsService.trackMonetizationEvent(
          MonetizationEvent.upgradeCompleted(tier: targetTier.name),
        );
        break;
      case 'cancelled':
        analyticsService.trackMonetizationEvent(
          MonetizationEvent.upgradeCancelled(tier: targetTier.name),
        );
        break;
    }
  }
}

/// Ad integration example
class AdIntegrationExample {
  static Widget buildNoteListWithAds(List<Widget> noteWidgets) {
    final List<Widget> widgetsWithAds = [];
    
    for (int i = 0; i < noteWidgets.length; i++) {
      widgetsWithAds.add(noteWidgets[i]);
      
      // Add banner ad every 5 notes
      if ((i + 1) % 5 == 0) {
        widgetsWithAds.add(
          const SimpleBannerAd(
            placement: AdPlacement.noteListBanner,
          ),
        );
      }
    }
    
    return Column(children: widgetsWithAds);
  }

  static void showContextualAd(BuildContext context, String context) {
    AdPlacement placement;
    
    switch (context) {
      case 'settings':
        placement = AdPlacement.settingsBanner;
        break;
      case 'note_creation':
        placement = AdPlacement.noteCreationInterstitial;
        break;
      case 'premium_prompt':
        placement = AdPlacement.premiumPromptInterstitial;
        break;
      default:
        placement = AdPlacement.featureDiscoveryNative;
    }

    SmartInterstitialHelper.showSmartInterstitial(
      context,
      placement,
      isImportantTransition: context == 'premium_prompt',
    );
  }
}
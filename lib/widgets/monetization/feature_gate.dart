import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import 'paywall_dialog.dart';

/// Widget that gates premium features and shows upgrade prompts.
/// 
/// Wraps child widgets to control access based on user tier and feature limits.
class FeatureGate extends StatelessWidget {
  final Widget child;
  final FeatureType featureType;
  final String featureContext;
  final String? upgradeTitle;
  final String? upgradeDescription;
  final VoidCallback? onUpgradeSuccess;
  final bool showAsBlocked;

  const FeatureGate({
    Key? key,
    required this.child,
    required this.featureType,
    required this.featureContext,
    this.upgradeTitle,
    this.upgradeDescription,
    this.onUpgradeSuccess,
    this.showAsBlocked = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationService>(
      builder: (context, monetizationService, _) {
        final canUse = monetizationService.canUseFeature(featureType);
        final isAvailable = monetizationService.isFeatureAvailable(featureType);

        if (canUse) {
          return child;
        }

        if (showAsBlocked) {
          return _buildBlockedFeature(context, monetizationService, isAvailable);
        }

        return GestureDetector(
          onTap: () => _showUpgradePrompt(context),
          child: Opacity(
            opacity: 0.5,
            child: AbsorbPointer(child: child),
          ),
        );
      },
    );
  }

  Widget _buildBlockedFeature(BuildContext context, MonetizationService monetizationService, bool isAvailable) {
    final theme = Theme.of(context);
    
    if (!isAvailable) {
      // Feature is completely unavailable for current tier
      return _buildUnavailableFeature(context, theme);
    } else {
      // Feature is available but usage limit reached
      return _buildLimitReachedFeature(context, theme, monetizationService);
    }
  }

  Widget _buildUnavailableFeature(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 8.w,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            _getFeatureDisplayName(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'This feature is available with Premium subscription',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () => _showUpgradePrompt(context),
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade Now'),
          ),
          SizedBox(height: 1.h),
          TextButton(
            onPressed: () => _learnMore(context),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitReachedFeature(BuildContext context, ThemeData theme, MonetizationService monetizationService) {
    final remaining = monetizationService.getRemainingUsage(featureType);
    final limits = FeatureLimits.forTier(monetizationService.currentTier);
    final limit = limits.getFeatureLimit(featureType);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.errorContainer.withOpacity(0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 8.w,
            color: theme.colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Monthly Limit Reached',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'You\'ve reached your monthly limit of $limit ${_getFeatureDisplayName().toLowerCase()}.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Upgrade to Premium for unlimited access',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _waitForReset(context),
                  child: const Text('Wait for Reset'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpgradePrompt(context),
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Upgrade'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFeatureDisplayName() {
    switch (featureType) {
      case FeatureType.noteCreation:
        return 'Note Creation';
      case FeatureType.voiceNoteRecording:
        return 'Voice Recordings';
      case FeatureType.voiceTranscription:
        return 'Voice Transcription';
      case FeatureType.advancedDrawing:
        return 'Advanced Drawing Tools';
      case FeatureType.cloudSync:
        return 'Cloud Sync';
      case FeatureType.advancedExport:
        return 'Premium Export';
      case FeatureType.folders:
        return 'Folders';
      case FeatureType.attachments:
        return 'Attachments';
      default:
        return 'Premium Feature';
    }
  }

  void _showUpgradePrompt(BuildContext context) {
    final analyticsService = context.read<AnalyticsService>();
    
    // Track feature limit reached
    analyticsService.trackMonetizationEvent(
      MonetizationEvent.featureLimitReached(feature: featureType.name),
    );

    PaywallDialog.show(
      context,
      featureContext: featureContext,
      title: upgradeTitle ?? 'Unlock ${_getFeatureDisplayName()}',
      description: upgradeDescription ?? 
        'Get unlimited access to ${_getFeatureDisplayName().toLowerCase()} and all premium features.',
      onPurchaseSuccess: onUpgradeSuccess,
    );
  }

  void _learnMore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getFeatureDisplayName()),
        content: Text(_getFeatureDescription()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpgradePrompt(context);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  String _getFeatureDescription() {
    switch (featureType) {
      case FeatureType.noteCreation:
        return 'Create unlimited notes with Premium. Currently limited to 50 notes per month on the free plan.';
      case FeatureType.voiceNoteRecording:
        return 'Record unlimited voice notes with Premium. Get longer recording times and transcription features.';
      case FeatureType.voiceTranscription:
        return 'Automatically transcribe your voice notes to text with Premium. Save time and improve searchability.';
      case FeatureType.advancedDrawing:
        return 'Access professional drawing tools including brushes, shapes, layers, and advanced editing features.';
      case FeatureType.cloudSync:
        return 'Unlimited cloud synchronization across all your devices. Keep your notes in sync everywhere.';
      case FeatureType.advancedExport:
        return 'Export your notes in premium formats like PDF, DOCX, and custom templates.';
      case FeatureType.folders:
        return 'Organize your notes with unlimited folders and advanced organization features.';
      case FeatureType.attachments:
        return 'Add unlimited images, files, and media to your notes with Premium.';
      default:
        return 'This premium feature is available with an upgraded plan.';
    }
  }

  void _waitForReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Reset'),
        content: const Text(
          'Your monthly usage limits reset on the first day of each month. '
          'Until then, you can upgrade to Premium for unlimited access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Okay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpgradePrompt(context);
            },
            child: const Text('Upgrade Instead'),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for showing feature usage status
class FeatureUsageIndicator extends StatelessWidget {
  final FeatureType featureType;
  final bool showDetails;

  const FeatureUsageIndicator({
    Key? key,
    required this.featureType,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationService>(
      builder: (context, monetizationService, _) {
        final theme = Theme.of(context);
        final limits = FeatureLimits.forTier(monetizationService.currentTier);
        final limit = limits.getFeatureLimit(featureType);
        final used = monetizationService.usageCounts[featureType] ?? 0;
        final remaining = monetizationService.getRemainingUsage(featureType);

        if (limit == -1) {
          // Unlimited
          return showDetails
              ? Text(
                  'Unlimited',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const SizedBox.shrink();
        }

        final progress = used / limit;
        final isNearLimit = progress > 0.8;
        final isAtLimit = remaining <= 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDetails) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Used this month',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '$used of $limit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isAtLimit
                          ? theme.colorScheme.error
                          : isNearLimit
                              ? theme.colorScheme.tertiary
                              : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
            ],
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAtLimit
                    ? theme.colorScheme.error
                    : isNearLimit
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
              ),
            ),
            if (showDetails && isNearLimit) ...[
              SizedBox(height: 1.h),
              Text(
                isAtLimit
                    ? 'Monthly limit reached'
                    : '$remaining remaining this month',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isAtLimit
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
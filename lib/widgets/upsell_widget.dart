import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// A gentle upsell widget that appears in context when users try to access premium features.
/// Provides a non-intrusive way to inform users about premium benefits.
class ContextualUpsellWidget extends StatelessWidget {
  final String featureName;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onDismiss;
  final bool showCloseButton;

  const ContextualUpsellWidget({
    Key? key,
    required this.featureName,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onDismiss,
    this.showCloseButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        // Don't show upsell if user is already premium
        if (premiumService.isPremium) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.all(4.w),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.1),
                (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCloseButton)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ),
              
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 3.h),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.5),
                        ),
                      ),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _showPremiumUpgrade(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Upgrade Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPremiumUpgrade(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
  }
}

/// Pre-configured upsell widgets for common premium features
class UpsellWidgets {
  UpsellWidgets._();

  static Widget voiceNotes({VoidCallback? onDismiss}) {
    return ContextualUpsellWidget(
      featureName: 'voice notes',
      title: 'Unlimited Voice Notes',
      subtitle: 'Record unlimited voice memos with AI transcription and background recording.',
      icon: Icons.mic,
      onDismiss: onDismiss,
    );
  }

  static Widget advancedDrawing({VoidCallback? onDismiss}) {
    return ContextualUpsellWidget(
      featureName: 'drawing tools',
      title: 'Advanced Drawing Tools',
      subtitle: 'Unlock professional drawing tools with layers, effects, and advanced brushes.',
      icon: Icons.brush,
      onDismiss: onDismiss,
    );
  }

  static Widget cloudSync({VoidCallback? onDismiss}) {
    return ContextualUpsellWidget(
      featureName: 'cloud sync',
      title: 'Cloud Sync',
      subtitle: 'Sync your notes across all devices with secure cloud storage.',
      icon: Icons.cloud_sync,
      onDismiss: onDismiss,
    );
  }

  static Widget exportFormats({VoidCallback? onDismiss}) {
    return ContextualUpsellWidget(
      featureName: 'export',
      title: 'Advanced Export',
      subtitle: 'Export notes to PDF, DOCX, Markdown, and other professional formats.',
      icon: Icons.file_download,
      onDismiss: onDismiss,
    );
  }

  static Widget backgroundRecording({VoidCallback? onDismiss}) {
    return ContextualUpsellWidget(
      featureName: 'background recording',
      title: 'Background Recording',
      subtitle: 'Record voice notes even when the app is in the background.',
      icon: Icons.record_voice_over,
      onDismiss: onDismiss,
    );
  }

  static Widget customFeature({
    required String featureName,
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onDismiss,
  }) {
    return ContextualUpsellWidget(
      featureName: featureName,
      title: title,
      subtitle: subtitle,
      icon: icon,
      onDismiss: onDismiss,
    );
  }
}

/// Helper function to show an upsell dialog for a feature
void showFeatureUpsellDialog(
  BuildContext context, {
  required String featureName,
  required String title,
  required String description,
  required IconData icon,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 2.h),
          Text(
            FeatureGate.getUpgradeMessage(featureName),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
          },
          child: const Text('Upgrade Now'),
        ),
      ],
    ),
  );
}

/// Simple banner widget to show at the top of screens for premium features
class PremiumFeatureBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;
  final bool showIcon;

  const PremiumFeatureBanner({
    Key? key,
    required this.message,
    this.onTap,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        if (premiumService.isPremium) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          margin: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade400,
                Colors.orange.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: onTap ?? () => Navigator.pushNamed(context, AppRoutes.premiumUpgrade),
            child: Row(
              children: [
                if (showIcon) ...[
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
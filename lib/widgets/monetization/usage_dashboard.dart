import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import 'feature_gate.dart';
import 'paywall_dialog.dart';

/// Usage dashboard widget showing current tier status and limits
class UsageDashboard extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const UsageDashboard({
    Key? key,
    this.isExpanded = false,
    this.onToggleExpanded,
  }) : super(key: key);

  @override
  State<UsageDashboard> createState() => _UsageDashboardState();
}

class _UsageDashboardState extends State<UsageDashboard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationService>(
      builder: (context, monetizationService, _) {
        final theme = Theme.of(context);
        
        return Card(
          margin: EdgeInsets.all(4.w),
          child: Column(
            children: [
              // Header
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: monetizationService.isPremium 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                  child: Icon(
                    monetizationService.isPremium ? Icons.star : Icons.person,
                    color: monetizationService.isPremium
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  ),
                ),
                title: Text(
                  _getTierDisplayName(monetizationService.currentTier),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(_getTierDescription(monetizationService.currentTier)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!monetizationService.isPremium) ...[
                      TextButton(
                        onPressed: () => _showUpgradeDialog(context),
                        child: const Text('Upgrade'),
                      ),
                      SizedBox(width: 2.w),
                    ],
                    IconButton(
                      onPressed: () {
                        setState(() => _isExpanded = !_isExpanded);
                        widget.onToggleExpanded?.call();
                      },
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Expanded content
              if (_isExpanded) ...[
                Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.3)),
                _buildUsageDetails(context, monetizationService),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageDetails(BuildContext context, MonetizationService monetizationService) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage This Month',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          
          // Feature usage items
          _buildUsageItem(
            context,
            FeatureType.noteCreation,
            'Notes Created',
            Icons.note,
            monetizationService,
          ),
          SizedBox(height: 2.h),
          
          _buildUsageItem(
            context,
            FeatureType.voiceNoteRecording,
            'Voice Recordings',
            Icons.mic,
            monetizationService,
          ),
          SizedBox(height: 2.h),
          
          _buildUsageItem(
            context,
            FeatureType.cloudSync,
            'Cloud Syncs',
            Icons.cloud_sync,
            monetizationService,
          ),
          SizedBox(height: 2.h),
          
          _buildUsageItem(
            context,
            FeatureType.attachments,
            'Attachments',
            Icons.attach_file,
            monetizationService,
          ),
          SizedBox(height: 2.h),
          
          _buildUsageItem(
            context,
            FeatureType.folders,
            'Folders',
            Icons.folder,
            monetizationService,
          ),
          SizedBox(height: 3.h),
          
          // Premium features status
          if (!monetizationService.isPremium) ...[
            _buildPremiumFeatures(context),
            SizedBox(height: 3.h),
          ],
          
          // Upgrade button
          if (!monetizationService.isPremium)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUpgradeDialog(context),
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade to Premium'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(
    BuildContext context,
    FeatureType featureType,
    String label,
    IconData icon,
    MonetizationService monetizationService,
  ) {
    final theme = Theme.of(context);
    final limits = FeatureLimits.forTier(monetizationService.currentTier);
    final limit = limits.getFeatureLimit(featureType);
    final used = monetizationService.usageCounts[featureType] ?? 0;
    final remaining = monetizationService.getRemainingUsage(featureType);
    final isAvailable = limits.isFeatureAvailable(featureType);
    
    if (!isAvailable) {
      return _buildLockedFeatureItem(context, label, icon);
    }
    
    final progress = limit == -1 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final isNearLimit = progress > 0.8;
    final isAtLimit = remaining <= 0 && limit != -1;
    
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: isAtLimit
                ? theme.colorScheme.errorContainer
                : isNearLimit
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isAtLimit
                ? theme.colorScheme.onErrorContainer
                : isNearLimit
                    ? theme.colorScheme.onTertiaryContainer
                    : theme.colorScheme.onPrimaryContainer,
            size: 5.w,
          ),
        ),
        SizedBox(width: 3.w),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    limit == -1 ? 'Unlimited' : '$used of $limit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isAtLimit
                          ? theme.colorScheme.error
                          : isNearLimit
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (limit != -1) ...[
                SizedBox(height: 1.h),
                FeatureUsageIndicator(featureType: featureType),
                if (isAtLimit || isNearLimit) ...[
                  SizedBox(height: 1.h),
                  Text(
                    isAtLimit 
                        ? 'Limit reached - upgrade to continue'
                        : '$remaining remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isAtLimit
                          ? theme.colorScheme.error
                          : theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedFeatureItem(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.lock,
            color: theme.colorScheme.outline,
            size: 5.w,
          ),
        ),
        SizedBox(width: 3.w),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                'Premium feature',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        
        TextButton(
          onPressed: () => _showUpgradeDialog(context),
          child: const Text('Unlock'),
        ),
      ],
    );
  }

  Widget _buildPremiumFeatures(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        
        _buildPremiumFeatureRow('Advanced Drawing Tools', Icons.brush),
        SizedBox(height: 1.h),
        _buildPremiumFeatureRow('Premium Export Formats', Icons.file_download),
        SizedBox(height: 1.h),
        _buildPremiumFeatureRow('Voice Note Transcription', Icons.transcribe),
        SizedBox(height: 1.h),
        _buildPremiumFeatureRow('No Ads', Icons.block),
      ],
    );
  }

  Widget _buildPremiumFeatureRow(String feature, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 4.w,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: 3.w),
        Text(
          feature,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Icon(
          Icons.lock,
          size: 4.w,
          color: theme.colorScheme.outline,
        ),
      ],
    );
  }

  String _getTierDisplayName(UserTier tier) {
    switch (tier) {
      case UserTier.free:
        return 'Free Plan';
      case UserTier.premium:
        return 'Premium Plan';
      case UserTier.pro:
        return 'Pro Plan';
      case UserTier.enterprise:
        return 'Enterprise Plan';
    }
  }

  String _getTierDescription(UserTier tier) {
    switch (tier) {
      case UserTier.free:
        return 'Basic features with usage limits';
      case UserTier.premium:
        return 'Unlimited core features + premium tools';
      case UserTier.pro:
        return 'Everything + advanced capabilities';
      case UserTier.enterprise:
        return 'Team management + enterprise features';
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    PaywallDialog.show(
      context,
      featureContext: 'usage_dashboard',
      title: 'Upgrade Your Plan',
      description: 'Get unlimited access to all features and remove usage limits.',
    );
  }
}

/// Compact tier status widget for app bars or headers
class TierStatusBadge extends StatelessWidget {
  final bool showUpgradeButton;

  const TierStatusBadge({
    Key? key,
    this.showUpgradeButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationService>(
      builder: (context, monetizationService, _) {
        final theme = Theme.of(context);
        final isPremium = monetizationService.isPremium;
        
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isPremium 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: isPremium 
                ? null 
                : Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPremium ? Icons.star : Icons.person,
                size: 4.w,
                color: isPremium 
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
              SizedBox(width: 2.w),
              Text(
                _getTierName(monetizationService.currentTier),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isPremium 
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isPremium && showUpgradeButton) ...[
                SizedBox(width: 2.w),
                GestureDetector(
                  onTap: () => _showUpgradeDialog(context),
                  child: Icon(
                    Icons.upgrade,
                    size: 4.w,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getTierName(UserTier tier) {
    switch (tier) {
      case UserTier.free:
        return 'Free';
      case UserTier.premium:
        return 'Premium';
      case UserTier.pro:
        return 'Pro';
      case UserTier.enterprise:
        return 'Enterprise';
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    PaywallDialog.show(
      context,
      featureContext: 'tier_badge',
    );
  }
}

/// Quick action card for common monetization actions
class MonetizationQuickActions extends StatelessWidget {
  const MonetizationQuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationService>(
      builder: (context, monetizationService, _) {
        final theme = Theme.of(context);
        
        if (monetizationService.isPremium) {
          return _buildPremiumActions(context, theme);
        } else {
          return _buildFreeActions(context, theme, monetizationService);
        }
      },
    );
  }

  Widget _buildPremiumActions(BuildContext context, ThemeData theme) {
    return Card(
      margin: EdgeInsets.all(4.w),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.star, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Text(
                  'Premium Features',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Advanced Drawing',
                    Icons.brush,
                    () => _showFeatureDemo(context, 'drawing'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Premium Export',
                    Icons.file_download,
                    () => _showFeatureDemo(context, 'export'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeActions(BuildContext context, ThemeData theme, MonetizationService monetizationService) {
    final hasNearLimits = _checkForNearLimits(monetizationService);
    
    return Card(
      margin: EdgeInsets.all(4.w),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            if (hasNearLimits) ...[
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: theme.colorScheme.error,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'You\'re approaching your monthly limits',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUpgradeDialog(context),
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade to Premium'),
              ),
            ),
            SizedBox(height: 2.h),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showBenefits(context),
                    child: const Text('View Benefits'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showComparison(context),
                    child: const Text('Compare Plans'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return Material(
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(height: 1.h),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _checkForNearLimits(MonetizationService monetizationService) {
    for (final featureType in FeatureType.values) {
      final limits = FeatureLimits.forTier(monetizationService.currentTier);
      final limit = limits.getFeatureLimit(featureType);
      final used = monetizationService.usageCounts[featureType] ?? 0;
      
      if (limit != -1 && used / limit > 0.8) {
        return true;
      }
    }
    return false;
  }

  void _showUpgradeDialog(BuildContext context) {
    PaywallDialog.show(
      context,
      featureContext: 'quick_actions',
    );
  }

  void _showFeatureDemo(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $feature feature...')),
    );
  }

  void _showBenefits(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Benefits'),
        content: const Text(
          '• Unlimited notes and voice recordings\n'
          '• Advanced drawing tools\n'
          '• Premium export formats\n'
          '• No ads\n'
          '• Priority cloud sync\n'
          '• Email support',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpgradeDialog(context);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showComparison(BuildContext context) {
    PaywallDialog.show(
      context,
      featureContext: 'plan_comparison',
      title: 'Compare Plans',
      description: 'Choose the plan that works best for you.',
    );
  }
}
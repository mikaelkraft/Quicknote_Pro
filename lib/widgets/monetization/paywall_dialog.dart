import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../constants/product_ids.dart';

/// Paywall dialog for prompting users to upgrade to premium features.
/// 
/// Shows pricing options, benefits, and handles purchase flows.
class PaywallDialog extends StatefulWidget {
  final String featureContext;
  final String? title;
  final String? description;
  final VoidCallback? onPurchaseSuccess;
  final VoidCallback? onCancel;

  const PaywallDialog({
    Key? key,
    required this.featureContext,
    this.title,
    this.description,
    this.onPurchaseSuccess,
    this.onCancel,
  }) : super(key: key);

  /// Show paywall dialog
  static Future<bool?> show(
    BuildContext context, {
    required String featureContext,
    String? title,
    String? description,
    VoidCallback? onPurchaseSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaywallDialog(
        featureContext: featureContext,
        title: title,
        description: description,
        onPurchaseSuccess: onPurchaseSuccess,
      ),
    );
  }

  @override
  State<PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends State<PaywallDialog> {
  int _selectedIndex = 1; // Default to Premium
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Track paywall shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().trackMonetizationEvent(
        MonetizationEvent.upgradePromptShown(context: widget.featureContext),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monetizationService = context.read<MonetizationService>();

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      semanticLabel: widget.title != null
          ? '${widget.title} dialog'
          : 'Upgrade to premium subscription dialog',
      child: Container(
        constraints: BoxConstraints(maxWidth: 90.w, maxHeight: 80.h),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title ?? 'Upgrade to Pro',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => _handleCancel(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Description
            if (widget.description != null) ...[
              Text(
                widget.description!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
            ],

            // Pricing options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPricingOption(
                      index: 0,
                      tier: UserTier.free,
                      title: 'Free',
                      price: '\$0',
                      period: 'forever',
                      description: 'Current plan',
                      features: const [
                        '50 notes per month',
                        '5 voice recordings',
                        '3 folders',
                        'Basic sync',
                        'With ads',
                      ],
                      isRecommended: false,
                      enabled: false,
                    ),
                    SizedBox(height: 2.h),
                    _buildPricingOption(
                      index: 1,
                      tier: UserTier.premium,
                      title: 'Premium',
                      price: '\$0.99',
                      period: 'month',
                      description: 'Most popular',
                      features: const [
                        'Unlimited notes',
                        '100 voice recordings',
                        'Advanced drawing tools',
                        'Premium export formats',
                        'No ads',
                        'Priority sync',
                      ],
                      isRecommended: true,
                    ),
                    SizedBox(height: 2.h),
                    _buildPricingOption(
                      index: 2,
                      tier: UserTier.pro,
                      title: 'Pro',
                      price: '\$1.99',
                      period: 'month',
                      description: 'Best value',
                      features: const [
                        'Everything in Premium',
                        'Unlimited voice recordings',
                        'Priority support',
                        'Advanced analytics',
                        'Extended storage',
                        'API access',
                      ],
                      isRecommended: false,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Lifetime options note
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Lifetime options available: Premium $9.99, Pro $19.99 one-time!',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 3.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _handleCancel(),
                    child: const Text('Maybe Later'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleUpgrade(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_getUpgradeButtonText()),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Terms and restore
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _showTerms(),
                  child: Text(
                    'Terms & Privacy',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => _restorePurchases(),
                  child: Text(
                    'Restore Purchases',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingOption({
    required int index,
    required UserTier tier,
    required String title,
    required String price,
    required String period,
    required String description,
    required List<String> features,
    required bool isRecommended,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: enabled ? () => setState(() => _selectedIndex = index) : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isRecommended
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<int>(
                  value: index,
                  groupValue: enabled ? _selectedIndex : -1,
                  onChanged: enabled ? (value) => setState(() => _selectedIndex = value!) : null,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: enabled ? null : theme.disabledColor,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          if (isRecommended)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                description,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '$price/$period',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: enabled ? theme.colorScheme.primary : theme.disabledColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ...features.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 4.w,
                    color: enabled ? theme.colorScheme.primary : theme.disabledColor,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled ? null : theme.disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _getUpgradeButtonText() {
    switch (_selectedIndex) {
      case 1:
        return 'Start Premium - \$0.99/month';
      case 2:
        return 'Start Pro - \$1.99/month';
      default:
        return 'Upgrade Now';
    }
  }

  void _handleCancel() {
    context.read<AnalyticsService>().trackMonetizationEvent(
      MonetizationEvent.upgradeCancelled(tier: _getSelectedTier().name),
    );
    widget.onCancel?.call();
    Navigator.of(context).pop(false);
  }

  Future<void> _handleUpgrade() async {
    setState(() => _isLoading = true);

    final selectedTier = _getSelectedTier();
    final analyticsService = context.read<AnalyticsService>();
    final monetizationService = context.read<MonetizationService>();

    try {
      // Track upgrade started
      analyticsService.trackMonetizationEvent(
        MonetizationEvent.upgradeStarted(tier: selectedTier.name),
      );

      // In a real implementation, this would integrate with platform billing
      await _simulatePurchaseFlow(selectedTier);

      // Update user tier
      await monetizationService.setUserTier(selectedTier);

      // Track successful upgrade
      analyticsService.trackMonetizationEvent(
        MonetizationEvent.upgradeCompleted(tier: selectedTier.name),
      );

      setState(() => _isLoading = false);

      widget.onPurchaseSuccess?.call();
      Navigator.of(context).pop(true);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to ${selectedTier.name.toUpperCase()}! 🎉'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // Track failed upgrade
      analyticsService.trackMonetizationEvent(
        MonetizationEvent.upgradeCancelled(tier: selectedTier.name),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  UserTier _getSelectedTier() {
    switch (_selectedIndex) {
      case 1:
        return UserTier.premium;
      case 2:
        return UserTier.pro;
      default:
        return UserTier.free;
    }
  }

  Future<void> _simulatePurchaseFlow(UserTier tier) async {
    // Simulate purchase processing
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real implementation, this would:
    // 1. Call platform billing APIs (Google Play, App Store)
    // 2. Validate receipts
    // 3. Update server-side entitlements
    // 4. Handle errors and retries
    
    // For demo purposes, we'll just simulate success
    // Throw an exception to simulate failure: throw Exception('Payment failed');
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Privacy'),
        content: const Text(
          'By purchasing, you agree to our Terms of Service and Privacy Policy. '
          'Subscriptions automatically renew unless canceled 24 hours before renewal. '
          'You can manage subscriptions in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    try {
      // In a real implementation, this would restore purchases from the platform
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checking for existing purchases...')),
      );

      // Simulate restore process
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchases found')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: ${e.toString()}')),
      );
    }
  }
}
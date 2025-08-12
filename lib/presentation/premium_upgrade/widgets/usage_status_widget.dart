import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/pricing_tier_service.dart';
import '../../../services/limit_enforcement_service.dart';

/// Widget for displaying current usage status and limits
class UsageStatusWidget extends StatelessWidget {
  final bool showTitle;
  final bool showUpgradeButton;
  final VoidCallback? onUpgradePressed;

  const UsageStatusWidget({
    Key? key,
    this.showTitle = true,
    this.showUpgradeButton = true,
    this.onUpgradePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<PricingTierService>(
      builder: (context, pricingService, child) {
        final limitService = LimitEnforcementService(pricingService);
        final summary = limitService.getUsageSummary();
        final isPremium = summary['isPremium'] as bool;
        
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (showTitle) ...[
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: isPremium ? 'star' : 'info',
                      color: isPremium 
                          ? Colors.amber 
                          : (isDark ? AppTheme.primaryDark : AppTheme.primaryLight),
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        isPremium ? 'Premium Status' : 'Usage & Limits',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (isPremium) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3.h),
              ],

              // Usage items
              if (isPremium) ...[
                _buildPremiumStatus(context, summary, isDark),
              ] else ...[
                _buildUsageItem(
                  context,
                  'Voice Notes',
                  summary['voiceNotes']['used'],
                  summary['voiceNotes']['limit'],
                  summary['voiceNotes']['unlimited'],
                  'mic',
                  Colors.blue,
                  isDark,
                ),
                SizedBox(height: 2.h),
                _buildUsageItem(
                  context,
                  'Exports',
                  summary['exports']['used'],
                  summary['exports']['limit'],
                  summary['exports']['unlimited'],
                  'export',
                  Colors.purple,
                  isDark,
                ),
                SizedBox(height: 2.h),
                _buildFeatureStatus(context, summary, isDark),
              ],

              // Trial status
              if (summary['trial']['isInTrial'] == true) ...[
                SizedBox(height: 3.h),
                _buildTrialStatus(context, summary, isDark),
              ],

              // Upgrade button
              if (!isPremium && showUpgradeButton) ...[
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUpgradePressed ?? () => _handleUpgrade(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 3.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          color: Colors.white,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          summary['trial']['canStartTrial'] == true 
                              ? 'Start Free Trial'
                              : 'Upgrade to Premium',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageItem(
    BuildContext context,
    String title,
    int used,
    int limit,
    bool unlimited,
    String iconName,
    Color color,
    bool isDark,
  ) {
    final percentage = unlimited ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final isNearLimit = percentage >= 0.8;
    final isAtLimit = percentage >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: color,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Text(
              unlimited ? 'Unlimited' : '$used/$limit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isAtLimit ? Colors.red : (isDark ? Colors.grey[300] : Colors.grey[600]),
              ),
            ),
          ],
        ),
        if (!unlimited) ...[
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isAtLimit ? Colors.red : (isNearLimit ? Colors.orange : color),
            ),
            minHeight: 0.8.h,
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureStatus(BuildContext context, Map<String, dynamic> summary, bool isDark) {
    final features = summary['features'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [
            _buildFeatureChip('Cloud Sync', features['cloudSync'], isDark),
            _buildFeatureChip('Ad-Free', features['adFree'], isDark),
            _buildFeatureChip('Custom Themes', features['customThemes'], isDark),
            _buildFeatureChip('Advanced Drawing', features['advancedDrawing'], isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String label, bool enabled, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: enabled 
            ? Colors.green.withOpacity(0.2)
            : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled 
              ? Colors.green.withOpacity(0.5)
              : (isDark ? Colors.white : Colors.black).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: enabled ? 'check' : 'close',
            color: enabled ? Colors.green : Colors.grey,
            size: 3.w,
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled 
                  ? Colors.green[700]
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatus(BuildContext context, Map<String, dynamic> summary, bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.2),
            Colors.orange.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'star',
                color: Colors.amber[700]!,
                size: 8.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Active',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                    Text(
                      'You have access to all premium features',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(child: _buildPremiumFeature('Unlimited Notes', isDark)),
              SizedBox(width: 2.w),
              Expanded(child: _buildPremiumFeature('Cloud Sync', isDark)),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(child: _buildPremiumFeature('No Ads', isDark)),
              SizedBox(width: 2.w),
              Expanded(child: _buildPremiumFeature('All Features', isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String feature, bool isDark) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: 'check',
          color: Colors.green,
          size: 3.w,
        ),
        SizedBox(width: 1.w),
        Expanded(
          child: Text(
            feature,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[700] : Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrialStatus(BuildContext context, Map<String, dynamic> summary, bool isDark) {
    final daysRemaining = summary['trial']['daysRemaining'] as int;
    
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'time',
            color: Colors.blue,
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Trial Active',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpgrade(BuildContext context) {
    // Navigate to premium upgrade screen
    Navigator.pushNamed(context, '/premium_upgrade');
  }
}
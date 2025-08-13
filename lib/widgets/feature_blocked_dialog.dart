import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

/// Widget that shows when a feature is blocked due to free tier limitations
class FeatureBlockedDialog extends StatelessWidget {
  final String featureName;
  final String description;
  final String currentLimit;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const FeatureBlockedDialog({
    Key? key,
    required this.featureName,
    required this.description,
    required this.currentLimit,
    this.onUpgrade,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.red.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                color: Colors.white,
                size: 8.w,
              ),
            ),
            
            SizedBox(height: 3.h),
            
            // Title
            Text(
              'Upgrade to Continue',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 2.h),
            
            // Feature Description
            Text(
              'You\'ve reached the limit for $featureName',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 1.h),
            
            // Current Limit
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Free tier: $currentLimit',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            
            SizedBox(height: 2.h),
            
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 3.h),
            
            // Premium Benefits
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50.withValues(alpha: isDark ? 0.1 : 1.0),
                    Colors.purple.shade50.withValues(alpha: isDark ? 0.1 : 1.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Premium Benefits',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  ..._buildBenefitsList(isDark),
                ],
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Action Buttons
            Row(
              children: [
                if (onDismiss != null) ...[
                  Expanded(
                    child: TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onUpgrade ?? () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBenefitsList(bool isDark) {
    final benefits = [
      'Unlimited notes and recordings',
      'Advanced tools and features',
      'Ad-free experience',
    ];

    return benefits.map((benefit) => Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  /// Show the feature blocked dialog
  static Future<bool?> show(
    BuildContext context, {
    required String featureName,
    required String description,
    required String currentLimit,
    VoidCallback? onUpgrade,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FeatureBlockedDialog(
        featureName: featureName,
        description: description,
        currentLimit: currentLimit,
        onUpgrade: onUpgrade ?? () {
          Navigator.pop(context, true);
          Navigator.pushNamed(context, '/premium-upgrade');
        },
        onDismiss: () => Navigator.pop(context, false),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Widget to display current usage statistics and limits for free tier users
class UsageStatsWidget extends StatelessWidget {
  final Map<String, dynamic> usageStats;

  const UsageStatsWidget({
    Key? key,
    required this.usageStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (usageStats['is_premium'] == true) {
      return Container(
        padding: EdgeInsets.all(4.w),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.blue.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.white,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'You have Premium - Enjoy unlimited access!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.grey.shade800.withValues(alpha: 0.8)
          : Colors.grey.shade100.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
            ? Colors.grey.shade600
            : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Current Usage',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          _buildUsageItem(
            'Notes',
            usageStats['notes_count'] ?? 0,
            usageStats['notes_limit'] ?? 50,
            usageStats['notes_percentage'] ?? 0.0,
            Icons.note,
            isDark,
          ),
          SizedBox(height: 1.h),
          _buildUsageItem(
            'Voice Notes',
            usageStats['voice_notes_count'] ?? 0,
            usageStats['voice_notes_limit'] ?? 10,
            usageStats['voice_notes_percentage'] ?? 0.0,
            Icons.mic,
            isDark,
          ),
          SizedBox(height: 1.h),
          _buildUsageItem(
            'Attachments',
            usageStats['attachments_count'] ?? 0,
            usageStats['attachments_limit'] ?? 5,
            usageStats['attachments_percentage'] ?? 0.0,
            Icons.attach_file,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(
    String label,
    int current,
    int limit,
    double percentage,
    IconData icon,
    bool isDark,
  ) {
    final isNearLimit = percentage > 80;
    final color = isNearLimit ? Colors.orange : Colors.blue;

    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 5.w,
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
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    '$current / $limit',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isNearLimit ? Colors.orange : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: isDark 
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 0.5.h,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
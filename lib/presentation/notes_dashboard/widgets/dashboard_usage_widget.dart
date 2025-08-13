import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

/// Widget that shows usage statistics in the dashboard header
class DashboardUsageWidget extends StatefulWidget {
  const DashboardUsageWidget({Key? key}) : super(key: key);

  @override
  State<DashboardUsageWidget> createState() => _DashboardUsageWidgetState();
}

class _DashboardUsageWidgetState extends State<DashboardUsageWidget> {
  final MonetizationService _monetization = MonetizationService();
  Map<String, dynamic>? _usageStats;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUsageStats();
  }

  Future<void> _loadUsageStats() async {
    await _monetization.initialize();
    final stats = await _monetization.getUsageStats();
    if (mounted) {
      setState(() {
        _usageStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usageStats == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = _usageStats!['is_premium'] == true;

    if (isPremium) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.blue.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Premium Active - Unlimited Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show usage summary for free users
    final notesUsed = _usageStats!['notes_count'] ?? 0;
    final notesLimit = _usageStats!['notes_limit'] ?? 50;
    final voiceNotesUsed = _usageStats!['voice_notes_count'] ?? 0;
    final voiceNotesLimit = _usageStats!['voice_notes_limit'] ?? 10;

    final highestUsagePercentage = [
      _usageStats!['notes_percentage'] ?? 0.0,
      _usageStats!['voice_notes_percentage'] ?? 0.0,
      _usageStats!['attachments_percentage'] ?? 0.0,
    ].reduce((a, b) => a > b ? a : b);

    final isNearLimit = highestUsagePercentage > 80;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withValues(alpha: 0.6)
            : Colors.grey.shade100.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNearLimit
              ? Colors.orange.withValues(alpha: 0.5)
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isNearLimit ? Icons.warning_amber : Icons.analytics,
                      color: isNearLimit ? Colors.orange : Colors.blue,
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        isNearLimit
                            ? 'Approaching Free Tier Limit'
                            : 'Free Tier Usage',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '$notesUsed/$notesLimit notes',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: isDark ? Colors.white60 : Colors.black54,
                      size: 5.w,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  SizedBox(height: 2.h),
                  _buildDetailedUsage(isDark),
                  if (isNearLimit) ...[
                    SizedBox(height: 2.h),
                    _buildUpgradePrompt(isDark),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedUsage(bool isDark) {
    return Column(
      children: [
        _buildUsageRow(
          'Notes',
          _usageStats!['notes_count'] ?? 0,
          _usageStats!['notes_limit'] ?? 50,
          _usageStats!['notes_percentage'] ?? 0.0,
          Icons.note,
          isDark,
        ),
        SizedBox(height: 1.h),
        _buildUsageRow(
          'Voice Notes',
          _usageStats!['voice_notes_count'] ?? 0,
          _usageStats!['voice_notes_limit'] ?? 10,
          _usageStats!['voice_notes_percentage'] ?? 0.0,
          Icons.mic,
          isDark,
        ),
        SizedBox(height: 1.h),
        _buildUsageRow(
          'Attachments',
          _usageStats!['attachments_count'] ?? 0,
          _usageStats!['attachments_limit'] ?? 5,
          _usageStats!['attachments_percentage'] ?? 0.0,
          Icons.attach_file,
          isDark,
        ),
      ],
    );
  }

  Widget _buildUsageRow(
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
          size: 4.w,
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
                      fontSize: 11.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    '$current / $limit',
                    style: TextStyle(
                      fontSize: 11.sp,
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
                minHeight: 0.3.h,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradePrompt(bool isDark) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.purple.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Upgrade for unlimited access',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/premium-upgrade');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              minimumSize: Size(15.w, 4.h),
              padding: EdgeInsets.symmetric(horizontal: 3.w),
            ),
            child: Text(
              'Upgrade',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
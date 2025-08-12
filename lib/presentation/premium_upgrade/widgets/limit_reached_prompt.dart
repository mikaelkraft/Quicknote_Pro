import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../constants/product_ids.dart';

/// Widget for displaying limit reached prompts with upgrade options
class LimitReachedPrompt extends StatelessWidget {
  final String title;
  final String message;
  final String ctaText;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;
  final String? featureIcon;
  final List<Color>? gradientColors;
  final bool showTrialOption;

  const LimitReachedPrompt({
    Key? key,
    required this.title,
    required this.message,
    this.ctaText = 'Upgrade Now',
    this.onUpgrade,
    this.onDismiss,
    this.featureIcon,
    this.gradientColors,
    this.showTrialOption = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient = [
      isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
      isDark ? AppTheme.primaryDark.withOpacity(0.7) : AppTheme.primaryLight.withOpacity(0.7),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors ?? defaultGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: featureIcon ?? 'lock',
                  color: Colors.white,
                  size: 8.w,
                ),
              ),
            ),
            
            SizedBox(height: 3.h),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 2.h),
            
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[300] : Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 4.h),
            
            // Benefits list
            _buildBenefitsList(isDark),
            
            SizedBox(height: 4.h),
            
            // Action buttons
            Column(
              children: [
                // Primary upgrade button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 4.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
                          ctaText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Trial button (if applicable)
                if (showTrialOption) ...[
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle trial start
                        Navigator.pop(context, 'trial');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                        side: BorderSide(
                          color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                          width: 1.5,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 3.5.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Start ${ProductIds.defaultTrialDays}-Day Free Trial',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Dismiss button
                SizedBox(height: 2.h),
                TextButton(
                  onPressed: onDismiss ?? () => Navigator.pop(context),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
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

  Widget _buildBenefitsList(bool isDark) {
    final benefits = [
      'Unlimited notes, voice recordings & exports',
      'Sync across all your devices',
      'Advanced drawing tools & custom themes',
      'Ad-free experience',
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Premium includes:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          ...benefits.map((benefit) => Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'check',
                  color: Colors.green,
                  size: 4.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    benefit,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// Show a limit reached prompt dialog
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String message,
    String ctaText = 'Upgrade Now',
    VoidCallback? onUpgrade,
    String? featureIcon,
    List<Color>? gradientColors,
    bool showTrialOption = true,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LimitReachedPrompt(
        title: title,
        message: message,
        ctaText: ctaText,
        onUpgrade: onUpgrade ?? () {
          Navigator.pop(context, 'upgrade');
        },
        featureIcon: featureIcon,
        gradientColors: gradientColors,
        showTrialOption: showTrialOption,
      ),
    );
  }

  /// Show a voice note limit prompt
  static Future<String?> showVoiceNoteLimit(BuildContext context) {
    return show(
      context: context,
      title: 'Voice Note Limit Reached',
      message: 'You\'ve used all 10 voice notes this month. Upgrade to Premium for unlimited voice recordings!',
      featureIcon: 'mic',
      gradientColors: [Color(0xFF06B6D4), Color(0xFF67E8F9)],
    );
  }

  /// Show an export limit prompt
  static Future<String?> showExportLimit(BuildContext context) {
    return show(
      context: context,
      title: 'Export Limit Reached',
      message: 'You\'ve used all 5 exports this month. Upgrade to Premium for unlimited exports!',
      featureIcon: 'export',
      gradientColors: [Color(0xFFEC4899), Color(0xFFF472B6)],
    );
  }

  /// Show a note limit prompt
  static Future<String?> showNoteLimit(BuildContext context) {
    return show(
      context: context,
      title: 'Note Limit Reached',
      message: 'You\'ve reached the 100 note limit. Upgrade to Premium for unlimited notes!',
      featureIcon: 'note',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    );
  }

  /// Show a cloud sync prompt
  static Future<String?> showCloudSyncLimit(BuildContext context) {
    return show(
      context: context,
      title: 'Cloud Sync Unavailable',
      message: 'Cloud sync is a Premium feature. Upgrade to sync your notes across all devices!',
      ctaText: 'Enable Sync',
      featureIcon: 'cloud_sync',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    );
  }

  /// Show a custom themes prompt
  static Future<String?> showCustomThemesLimit(BuildContext context) {
    return show(
      context: context,
      title: 'Custom Themes',
      message: 'Custom themes are available with Premium. Personalize your note-taking experience!',
      ctaText: 'Unlock Themes',
      featureIcon: 'palette',
      gradientColors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    );
  }
}
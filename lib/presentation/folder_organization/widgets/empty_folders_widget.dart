import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyFoldersWidget extends StatelessWidget {
  final VoidCallback onCreateFolder;

  const EmptyFoldersWidget({
    Key? key,
    required this.onCreateFolder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'folder_open',
                  color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                  size: 60,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              'Organize Your Notes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Description
            Text(
              'Create folders to keep your notes organized and easily accessible. Group related notes together for better productivity.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Create folder button
            ElevatedButton.icon(
              onPressed: onCreateFolder,
              icon: CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 20,
              ),
              label: const Text('Create Your First Folder'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Tips section
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.accentDark : AppTheme.accentLight)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppTheme.accentDark : AppTheme.accentLight)
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'lightbulb',
                        color:
                            isDark ? AppTheme.accentDark : AppTheme.accentLight,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Pro Tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.accentDark
                                  : AppTheme.accentLight,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  _buildTipItem(
                    context,
                    'Long press folders for quick actions',
                    isDark,
                  ),
                  SizedBox(height: 1.h),
                  _buildTipItem(
                    context,
                    'Swipe right to pin, left to delete',
                    isDark,
                  ),
                  SizedBox(height: 1.h),
                  _buildTipItem(
                    context,
                    'Choose colors to categorize folders',
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 1.w,
          height: 1.w,
          margin: EdgeInsets.only(top: 1.5.w),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
          ),
        ),
      ],
    );
  }
}

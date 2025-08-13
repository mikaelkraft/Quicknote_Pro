import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NoteTypeSelectorWidget extends StatelessWidget {
  final Function(String)? onNoteTypeSelected;

  const NoteTypeSelectorWidget({
    Key? key,
    this.onNoteTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          Text(
            'Create New Note',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 3.h),

          // Note type options
          _buildNoteTypeOption(
            context,
            icon: 'text_fields',
            title: 'Text Note',
            subtitle: 'Write with rich text formatting',
            onTap: () => _selectNoteType(context, 'text'),
          ),
          SizedBox(height: 2.h),

          _buildNoteTypeOption(
            context,
            icon: 'mic',
            title: 'Voice Note',
            subtitle: 'Record audio with speech-to-text',
            onTap: () => _selectNoteType(context, 'voice'),
            isPremium: false,
          ),
          SizedBox(height: 2.h),

          _buildNoteTypeOption(
            context,
            icon: 'brush',
            title: 'Drawing',
            subtitle: 'Sketch and doodle your ideas',
            onTap: () => _selectNoteType(context, 'drawing'),
            isPremium: true,
          ),
          SizedBox(height: 2.h),

          _buildNoteTypeOption(
            context,
            icon: 'description',
            title: 'Template',
            subtitle: 'Start with pre-made layouts',
            onTap: () => _selectNoteType(context, 'template'),
          ),
          SizedBox(height: 2.h),

          _buildNoteTypeOption(
            context,
            icon: 'attach_file',
            title: 'Note with Attachments',
            subtitle: 'Add photos, files, and camera images',
            onTap: () => _selectNoteType(context, 'attachments'),
            isPremium: false,
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildNoteTypeOption(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                size: 24,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (isPremium) ...[
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.warningDark
                                : AppTheme.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PRO',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8.sp,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _selectNoteType(BuildContext context, String type) {
    Navigator.pop(context);
    onNoteTypeSelected?.call(type);
  }
}

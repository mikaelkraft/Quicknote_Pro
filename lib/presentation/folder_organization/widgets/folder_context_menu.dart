import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FolderContextMenu extends StatelessWidget {
  final Map<String, dynamic> folder;
  final VoidCallback onRename;
  final VoidCallback onChangeColor;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const FolderContextMenu({
    Key? key,
    required this.folder,
    required this.onRename,
    required this.onChangeColor,
    required this.onDelete,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String folderName = folder['name'] as String;
    final bool isDefaultFolder = folder['isDefault'] as bool? ?? false;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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

          // Folder info header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: _getFolderColor(folder['color'] as String, isDark)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'folder',
                    color: _getFolderColor(folder['color'] as String, isDark),
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folderName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${folder['noteCount']} ${folder['noteCount'] == 1 ? 'note' : 'notes'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          Divider(
            color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
            height: 1,
          ),

          // Menu options
          _buildMenuOption(
            context,
            icon: 'edit',
            title: 'Rename',
            onTap: () {
              Navigator.of(context).pop();
              onRename();
            },
            enabled: !isDefaultFolder,
          ),

          _buildMenuOption(
            context,
            icon: 'palette',
            title: 'Change Color',
            onTap: () {
              Navigator.of(context).pop();
              onChangeColor();
            },
          ),

          _buildMenuOption(
            context,
            icon: 'share',
            title: 'Share Folder',
            onTap: () {
              Navigator.of(context).pop();
              onShare();
            },
          ),

          if (!isDefaultFolder)
            _buildMenuOption(
              context,
              icon: 'delete',
              title: 'Delete',
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
              isDestructive: true,
            ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
    bool isDestructive = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      enabled: enabled,
      leading: CustomIconWidget(
        iconName: icon,
        color: !enabled
            ? (isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight)
                .withOpacity(0.5)
            : isDestructive
                ? (isDark ? AppTheme.errorDark : AppTheme.errorLight)
                : (isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight),
        size: 24,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: !enabled
                  ? (isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight)
                      .withOpacity(0.5)
                  : isDestructive
                      ? (isDark ? AppTheme.errorDark : AppTheme.errorLight)
                      : (isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight),
              fontWeight: FontWeight.w500,
            ),
      ),
      onTap: enabled ? onTap : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }

  Color _getFolderColor(String colorName, bool isDark) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
      case 'green':
        return isDark ? AppTheme.successDark : AppTheme.successLight;
      case 'orange':
        return isDark ? AppTheme.warningDark : AppTheme.warningLight;
      case 'purple':
        return isDark ? AppTheme.accentDark : AppTheme.accentLight;
      case 'red':
        return isDark ? AppTheme.errorDark : AppTheme.errorLight;
      default:
        return isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    }
  }
}

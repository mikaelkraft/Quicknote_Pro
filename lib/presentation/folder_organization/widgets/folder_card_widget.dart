import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FolderCardWidget extends StatelessWidget {
  final Map<String, dynamic> folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPinSwipe;
  final VoidCallback onDeleteSwipe;

  const FolderCardWidget({
    Key? key,
    required this.folder,
    required this.onTap,
    required this.onLongPress,
    required this.onPinSwipe,
    required this.onDeleteSwipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String folderName = folder['name'] as String;
    final int noteCount = folder['noteCount'] as int;
    final String colorName = folder['color'] as String;
    final bool isPinned = folder['isPinned'] as bool;
    final List<String> previewImages =
        (folder['previewImages'] as List).cast<String>();

    Color folderColor = _getFolderColor(colorName, isDark);

    return Dismissible(
      key: Key('folder_${folder['id']}'),
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.getSuccessColor(isDark).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 4.w),
        child: CustomIconWidget(
          iconName: 'push_pin',
          color: AppTheme.getSuccessColor(isDark),
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.errorDark : AppTheme.errorLight)
              .withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        child: CustomIconWidget(
          iconName: 'delete',
          color: isDark ? AppTheme.errorDark : AppTheme.errorLight,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onPinSwipe();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context);
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDeleteSwipe();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 20.h,
            maxHeight: 25.h,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: folderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with folder icon and pin indicator
              Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: folderColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'folder',
                        color: folderColor,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    if (isPinned)
                      CustomIconWidget(
                        iconName: 'push_pin',
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        size: 16,
                      ),
                  ],
                ),
              ),

              // Folder name
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Text(
                  folderName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 1.h),

              // Note count
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Text(
                  '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                ),
              ),

              const Spacer(),

              // Preview thumbnails
              if (previewImages.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Row(
                    children: [
                      ...previewImages
                          .take(3)
                          .map((imageUrl) => Container(
                                margin: EdgeInsets.only(right: 1.w),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CustomImageWidget(
                                    imageUrl: imageUrl,
                                    width: 8.w,
                                    height: 8.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ))
                          .toList(),
                      if (previewImages.length > 3)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: folderColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '+${previewImages.length - 3}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: folderColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
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

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Delete Folder',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: Text(
                'Are you sure you want to delete "${folder['name']}"? This action cannot be undone.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.errorDark
                            : AppTheme.errorLight,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

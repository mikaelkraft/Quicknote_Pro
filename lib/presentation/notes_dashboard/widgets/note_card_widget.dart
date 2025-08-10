import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NoteCardWidget extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onShare;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;
  final VoidCallback? onSetReminder;

  const NoteCardWidget({
    Key? key,
    required this.note,
    this.onTap,
    this.onPin,
    this.onShare,
    this.onMove,
    this.onDelete,
    this.onDuplicate,
    this.onExport,
    this.onSetReminder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key('note_${note["id"]}'),
      background: _buildSwipeBackground(context, isLeft: true),
      secondaryBackground: _buildSwipeBackground(context, isLeft: false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Right swipe - Quick actions
          _showQuickActions(context);
        } else {
          // Left swipe - Delete
          _showDeleteConfirmation(context);
        }
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(12),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note["title"] ?? "Untitled Note",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  _buildNoteTypeIcon(context),
                  if (note["isPinned"] == true) ...[
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: 'push_pin',
                      color:
                          isDark ? AppTheme.accentDark : AppTheme.accentLight,
                      size: 16,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                note["preview"] ?? note["content"] ?? "",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  Text(
                    _formatDate(note["createdAt"]),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                  const Spacer(),
                  if (note["hasReminder"] == true) ...[
                    CustomIconWidget(
                      iconName: 'alarm',
                      color:
                          isDark ? AppTheme.warningDark : AppTheme.warningLight,
                      size: 14,
                    ),
                    SizedBox(width: 2.w),
                  ],
                  if (note["folder"] != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppTheme.primaryDark
                                : AppTheme.primaryLight)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note["folder"],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.primaryDark
                                  : AppTheme.primaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTypeIcon(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    String iconName;
    Color iconColor =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    switch (note["type"]) {
      case "voice":
        iconName = 'mic';
        iconColor = isDark ? AppTheme.accentDark : AppTheme.accentLight;
        break;
      case "drawing":
        iconName = 'brush';
        iconColor = isDark ? AppTheme.accentDark : AppTheme.accentLight;
        break;
      case "template":
        iconName = 'description';
        iconColor = isDark ? AppTheme.warningDark : AppTheme.warningLight;
        break;
      default:
        iconName = 'text_fields';
    }

    return CustomIconWidget(
      iconName: iconName,
      color: iconColor,
      size: 18,
    );
  }

  Widget _buildSwipeBackground(BuildContext context, {required bool isLeft}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isLeft
            ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                .withOpacity(0.2)
            : (isDark ? AppTheme.errorDark : AppTheme.errorLight)
                .withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: isLeft ? 'more_horiz' : 'delete',
                color: isLeft
                    ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                    : (isDark ? AppTheme.errorDark : AppTheme.errorLight),
                size: 24,
              ),
              SizedBox(height: 0.5.h),
              Text(
                isLeft ? 'Actions' : 'Delete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isLeft
                          ? (isDark
                              ? AppTheme.primaryDark
                              : AppTheme.primaryLight)
                          : (isDark ? AppTheme.errorDark : AppTheme.errorLight),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'push_pin',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: Text(note["isPinned"] == true ? 'Unpin Note' : 'Pin Note'),
              onTap: () {
                Navigator.pop(context);
                onPin?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                onShare?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'folder',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(context);
                onMove?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
            'Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                onDuplicate?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Export'),
              onTap: () {
                Navigator.pop(context);
                onExport?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'alarm',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Set Reminder'),
              onTap: () {
                Navigator.pop(context);
                onSetReminder?.call();
              },
            ),
            const Divider(),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

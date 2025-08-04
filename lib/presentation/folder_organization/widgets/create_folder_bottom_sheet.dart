import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CreateFolderBottomSheet extends StatefulWidget {
  final Function(String name, String color) onCreateFolder;

  const CreateFolderBottomSheet({
    Key? key,
    required this.onCreateFolder,
  }) : super(key: key);

  @override
  State<CreateFolderBottomSheet> createState() =>
      _CreateFolderBottomSheetState();
}

class _CreateFolderBottomSheetState extends State<CreateFolderBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = 'blue';
  final List<Map<String, dynamic>> _colors = [
    {'name': 'blue', 'color': AppTheme.primaryLight},
    {'name': 'green', 'color': AppTheme.successLight},
    {'name': 'orange', 'color': AppTheme.warningLight},
    {'name': 'purple', 'color': AppTheme.accentLight},
    {'name': 'red', 'color': AppTheme.errorLight},
    {'name': 'gray', 'color': AppTheme.secondaryLight},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 2.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Title
          Text(
            'Create New Folder',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
          ),

          SizedBox(height: 3.h),

          // Folder name input
          Text(
            'Folder Name',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
          ),

          SizedBox(height: 1.h),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter folder name',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'folder',
                  color: _getSelectedColor(isDark),
                  size: 20,
                ),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) {
              return Text(
                '$currentLength/${maxLength ?? 0}',
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
          ),

          SizedBox(height: 2.h),

          // Color selection
          Text(
            'Folder Color',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
          ),

          SizedBox(height: 1.h),

          Wrap(
            spacing: 3.w,
            runSpacing: 2.h,
            children: _colors.map((colorData) {
              final bool isSelected = _selectedColor == colorData['name'];
              final Color color = _getColorForTheme(colorData['name'], isDark);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = colorData['name'];
                  });
                },
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                            width: 3,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Center(
                          child: CustomIconWidget(
                            iconName: 'check',
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 4.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nameController.text.trim().isEmpty
                      ? null
                      : () {
                          widget.onCreateFolder(
                              _nameController.text.trim(), _selectedColor);
                          Navigator.of(context).pop();
                        },
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSelectedColor(bool isDark) {
    return _getColorForTheme(_selectedColor, isDark);
  }

  Color _getColorForTheme(String colorName, bool isDark) {
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

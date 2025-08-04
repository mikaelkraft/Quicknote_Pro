import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FormattingToolbarWidget extends StatelessWidget {
  final Function(String) onFormatAction;
  final bool isVisible;

  const FormattingToolbarWidget({
    Key? key,
    required this.onFormatAction,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      height: 8.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Row(
          children: [
            _buildFormatButton(
              context,
              icon: 'format_bold',
              action: 'bold',
              tooltip: 'Bold',
            ),
            SizedBox(width: 3.w),
            _buildFormatButton(
              context,
              icon: 'format_italic',
              action: 'italic',
              tooltip: 'Italic',
            ),
            SizedBox(width: 3.w),
            _buildFormatButton(
              context,
              icon: 'format_list_bulleted',
              action: 'bullet_list',
              tooltip: 'Bullet List',
            ),
            SizedBox(width: 3.w),
            _buildFormatButton(
              context,
              icon: 'format_list_numbered',
              action: 'numbered_list',
              tooltip: 'Numbered List',
            ),
            SizedBox(width: 3.w),
            _buildFormatButton(
              context,
              icon: 'title',
              action: 'heading',
              tooltip: 'Heading',
            ),
            SizedBox(width: 3.w),
            _buildFormatButton(
              context,
              icon: 'format_quote',
              action: 'quote',
              tooltip: 'Quote',
            ),
            SizedBox(width: 3.w),
            _buildFormatButton(
              context,
              icon: 'code',
              action: 'code',
              tooltip: 'Code',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton(
    BuildContext context, {
    required String icon,
    required String action,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onFormatAction(action),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: CustomIconWidget(
            iconName: icon,
            size: 5.w,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

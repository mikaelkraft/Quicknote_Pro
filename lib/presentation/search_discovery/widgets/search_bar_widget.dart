import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onVoiceSearch;
  final Function(String)? onChanged;
  final VoidCallback? onFilterTap;
  final bool isVoiceSearching;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    this.onVoiceSearch,
    this.onChanged,
    this.onFilterTap,
    this.isVoiceSearching = false,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: CustomIconWidget(
              iconName: 'search',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ),
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
              },
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notes, voice memos, drawings...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.6),
                      ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          if (widget.isVoiceSearching)
            Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 4.w,
                height: 4.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else
            InkWell(
              onTap: widget.onVoiceSearch,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: EdgeInsets.only(right: 2.w),
                padding: EdgeInsets.all(2.w),
                child: CustomIconWidget(
                  iconName: 'mic',
                  color: Theme.of(context).colorScheme.primary,
                  size: 5.w,
                ),
              ),
            ),
          InkWell(
            onTap: widget.onFilterTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'tune',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

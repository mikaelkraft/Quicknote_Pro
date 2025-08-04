import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchBarWidget extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool isExpanded;
  final List<String> recentSearches;
  final List<String> suggestions;

  const SearchBarWidget({
    Key? key,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.isExpanded = false,
    this.recentSearches = const [],
    this.suggestions = const [],
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isExpanded) {
        _expandSearch();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _expandSearch() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
    widget.onTap?.call();
  }

  void _collapseSearch() {
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
    _focusNode.unfocus();
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                  : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: _focusNode.hasFocus
                      ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                      : (isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight),
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Search notes...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 2.h,
                    ),
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (_isExpanded) ...[
                GestureDetector(
                  onTap: _collapseSearch,
                  child: Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Expanded search content
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _animation,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.recentSearches.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Text(
                          'Recent Searches',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      ...widget.recentSearches.take(3).map((search) => ListTile(
                            leading: CustomIconWidget(
                              iconName: 'history',
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                              size: 16,
                            ),
                            title: Text(
                              search,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            onTap: () {
                              _textController.text = search;
                              widget.onChanged?.call(search);
                            },
                          )),
                    ],
                    if (widget.suggestions.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Text(
                          'AI Suggestions',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      ...widget.suggestions
                          .take(3)
                          .map((suggestion) => ListTile(
                                leading: CustomIconWidget(
                                  iconName: 'auto_awesome',
                                  color: isDark
                                      ? AppTheme.accentDark
                                      : AppTheme.accentLight,
                                  size: 16,
                                ),
                                title: Text(
                                  suggestion,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                onTap: () {
                                  _textController.text = suggestion;
                                  widget.onChanged?.call(suggestion);
                                },
                              )),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

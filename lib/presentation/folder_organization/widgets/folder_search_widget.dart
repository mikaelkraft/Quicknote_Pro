import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FolderSearchWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final String searchQuery;

  const FolderSearchWidget({
    Key? key,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<FolderSearchWidget> createState() => _FolderSearchWidgetState();
}

class _FolderSearchWidgetState extends State<FolderSearchWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.searchQuery.isNotEmpty) {
      _isSearchActive = true;
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
    });

    if (_isSearchActive) {
      _animationController.forward();
    } else {
      _animationController.reverse();
      _searchController.clear();
      widget.onClearSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          if (!_isSearchActive) ...[
            // Search icon button when search is inactive
            Expanded(
              child: GestureDetector(
                onTap: _toggleSearch,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'search',
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        size: 20,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Search folders...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Active search field
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search folders...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'search',
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        size: 20,
                      ),
                    ),
                    suffixIcon: widget.searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              widget.onClearSearch();
                            },
                            icon: CustomIconWidget(
                              iconName: 'clear',
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                              size: 20,
                            ),
                          )
                        : null,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  ),
                  onChanged: widget.onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),

            SizedBox(width: 2.w),

            // Cancel button
            FadeTransition(
              opacity: _fadeAnimation,
              child: TextButton(
                onPressed: _toggleSearch,
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

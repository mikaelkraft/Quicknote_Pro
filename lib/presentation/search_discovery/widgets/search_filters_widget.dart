import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchFiltersWidget extends StatefulWidget {
  final Map<String, bool> selectedFilters;
  final Function(Map<String, bool>)? onFiltersChanged;
  final DateTimeRange? dateRange;
  final Function(DateTimeRange?)? onDateRangeChanged;
  final List<String> selectedFolders;
  final Function(List<String>)? onFoldersChanged;
  final bool isPremium;

  const SearchFiltersWidget({
    Key? key,
    required this.selectedFilters,
    this.onFiltersChanged,
    this.dateRange,
    this.onDateRangeChanged,
    required this.selectedFolders,
    this.onFoldersChanged,
    this.isPremium = false,
  }) : super(key: key);

  @override
  State<SearchFiltersWidget> createState() => _SearchFiltersWidgetState();
}

class _SearchFiltersWidgetState extends State<SearchFiltersWidget> {
  late Map<String, bool> _filters;
  late List<String> _selectedFolders;

  final List<String> _availableFolders = [
    'Work',
    'Personal',
    'Ideas',
    'Meeting Notes',
    'Shopping Lists',
    'Projects',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.selectedFilters);
    _selectedFolders = List.from(widget.selectedFolders);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Filters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 6.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Content Type Filters
          _buildSectionTitle('Content Type'),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: [
              _buildFilterChip('text', 'Text Notes', Icons.text_fields),
              _buildFilterChip('voice', 'Voice Memos', Icons.mic),
              _buildFilterChip('drawing', 'Drawings', Icons.brush),
              _buildFilterChip('image', 'Images', Icons.image),
            ],
          ),

          SizedBox(height: 3.h),

          // Date Range Filter
          _buildSectionTitle('Date Range'),
          SizedBox(height: 1.h),
          InkWell(
            onTap: _showDateRangePicker,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'date_range',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      widget.dateRange != null
                          ? '${_formatDate(widget.dateRange!.start)} - ${_formatDate(widget.dateRange!.end)}'
                          : 'Select date range',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (widget.dateRange != null)
                    InkWell(
                      onTap: () => widget.onDateRangeChanged?.call(null),
                      child: CustomIconWidget(
                        iconName: 'clear',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 4.w,
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Folder Selection
          _buildSectionTitle('Folders'),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _availableFolders.map((folder) {
              final isSelected = _selectedFolders.contains(folder);
              return InkWell(
                onTap: () => _toggleFolder(folder),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        CustomIconWidget(
                          iconName: 'check',
                          color: Theme.of(context).colorScheme.primary,
                          size: 4.w,
                        ),
                      if (isSelected) SizedBox(width: 1.w),
                      Text(
                        folder,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (widget.isPremium) ...[
            SizedBox(height: 3.h),
            _buildSectionTitle('AI Search (Premium)'),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                _buildFilterChip(
                    'ocr', 'OCR Text Search', Icons.text_rotation_none),
                _buildFilterChip(
                    'handwriting', 'Handwriting Recognition', Icons.gesture),
                _buildFilterChip(
                    'semantic', 'Semantic Search', Icons.psychology),
              ],
            ),
          ] else ...[
            SizedBox(height: 3.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.getWarningColor(
                        Theme.of(context).brightness == Brightness.light)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.getWarningColor(
                          Theme.of(context).brightness == Brightness.light)
                      .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'star',
                    color: AppTheme.getWarningColor(
                        Theme.of(context).brightness == Brightness.light),
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium AI Search',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          'Unlock OCR, handwriting recognition, and semantic search',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 4.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final isSelected = _filters[key] ?? false;
    return InkWell(
      onTap: () => _toggleFilter(key),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon.toString().split('.').last,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 4.w,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFilter(String key) {
    setState(() {
      _filters[key] = !(_filters[key] ?? false);
    });
  }

  void _toggleFolder(String folder) {
    setState(() {
      if (_selectedFolders.contains(folder)) {
        _selectedFolders.remove(folder);
      } else {
        _selectedFolders.add(folder);
      }
    });
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: widget.dateRange,
    );
    if (picked != null) {
      widget.onDateRangeChanged?.call(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'text': false,
        'voice': false,
        'drawing': false,
        'image': false,
        'ocr': false,
        'handwriting': false,
        'semantic': false,
      };
      _selectedFolders.clear();
    });
    widget.onFiltersChanged?.call(_filters);
    widget.onFoldersChanged?.call(_selectedFolders);
    widget.onDateRangeChanged?.call(null);
  }

  void _applyFilters() {
    widget.onFiltersChanged?.call(_filters);
    widget.onFoldersChanged?.call(_selectedFolders);
    Navigator.pop(context);
  }
}

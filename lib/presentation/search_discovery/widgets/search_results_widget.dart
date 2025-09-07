import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchResultsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;
  final String searchQuery;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Function(Map<String, dynamic>)? onNoteTap;

  const SearchResultsWidget({
    Key? key,
    required this.searchResults,
    required this.searchQuery,
    this.isLoading = false,
    this.onLoadMore,
    this.onNoteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Searching...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty && searchQuery.isNotEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: searchResults.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == searchResults.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }

        final note = searchResults[index];
        return _buildNoteCard(context, note);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5),
              size: 15.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try different keywords or check your spelling',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            _buildSearchTips(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTips(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Tips:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 1.h),
          _buildTip(context, '• Use keywords from your note content'),
          _buildTip(context, '• Try searching by folder names'),
          _buildTip(context, '• Use hashtags like #meeting or #idea'),
          _buildTip(context, '• Search by date or time periods'),
        ],
      ),
    );
  }

  Widget _buildTip(BuildContext context, String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Text(
        tip,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Map<String, dynamic> note) {
    final noteType = note['type'] as String;
    final title = note['title'] as String;
    final content = note['content'] as String;
    final folder = note['folder'] as String;
    final createdAt = note['createdAt'] as DateTime;
    final matchingSnippet = note['matchingSnippet'] as String?;
    final relevanceScore = note['relevanceScore'] as double;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => onNoteTap?.call(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildNoteTypeIcon(context, noteType),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                folder,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _formatDate(createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildRelevanceIndicator(context, relevanceScore),
                ],
              ),
              if (matchingSnippet != null) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    matchingSnippet,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                SizedBox(height: 1.h),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTypeIcon(BuildContext context, String noteType) {
    IconData iconData;
    Color iconColor;

    switch (noteType) {
      case 'text':
        iconData = Icons.text_fields;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case 'voice':
        iconData = Icons.mic;
        iconColor = AppTheme.getSuccessColor(
            Theme.of(context).brightness == Brightness.light);
        break;
      case 'drawing':
        iconData = Icons.brush;
        iconColor = AppTheme.getAccentColor(
            Theme.of(context).brightness == Brightness.light);
        break;
      case 'image':
        iconData = Icons.image;
        iconColor = AppTheme.getWarningColor(
            Theme.of(context).brightness == Brightness.light);
        break;
      default:
        iconData = Icons.note;
        iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomIconWidget(
        iconName: iconData.toString().split('.').last,
        color: iconColor,
        size: 5.w,
      ),
    );
  }

  Widget _buildRelevanceIndicator(BuildContext context, double relevanceScore) {
    final int stars = (relevanceScore * 5).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return CustomIconWidget(
          iconName: index < stars ? 'star' : 'star_border',
          color: index < stars
              ? AppTheme.getWarningColor(
                  Theme.of(context).brightness == Brightness.light)
              : Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.3),
          size: 3.w,
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

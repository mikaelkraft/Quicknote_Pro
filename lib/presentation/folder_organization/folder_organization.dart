import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/create_folder_bottom_sheet.dart';
import './widgets/empty_folders_widget.dart';
import './widgets/folder_card_widget.dart';
import './widgets/folder_context_menu.dart';
import './widgets/folder_search_widget.dart';

class FolderOrganization extends StatefulWidget {
  const FolderOrganization({Key? key}) : super(key: key);

  @override
  State<FolderOrganization> createState() => _FolderOrganizationState();
}

class _FolderOrganizationState extends State<FolderOrganization>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isRefreshing = false;

  // Mock folder data
  List<Map<String, dynamic>> _folders = [
    {
      'id': 1,
      'name': 'Work',
      'color': 'blue',
      'noteCount': 12,
      'isPinned': true,
      'isDefault': true,
      'previewImages': [
        'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
        'https://images.pexels.com/photos/590022/pexels-photo-590022.jpeg?w=400',
        'https://images.pixabay.com/photo/2016/11/30/20/58/programming-1873854_1280.jpg?w=400',
      ],
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
    },
    {
      'id': 2,
      'name': 'Personal',
      'color': 'green',
      'noteCount': 8,
      'isPinned': false,
      'isDefault': true,
      'previewImages': [
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
        'https://images.pexels.com/photos/1181533/pexels-photo-1181533.jpeg?w=400',
      ],
      'createdAt': DateTime.now().subtract(const Duration(days: 25)),
    },
    {
      'id': 3,
      'name': 'Project Ideas',
      'color': 'purple',
      'noteCount': 15,
      'isPinned': true,
      'isDefault': false,
      'previewImages': [
        'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=400',
        'https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg?w=400',
        'https://images.pixabay.com/photo/2017/01/29/21/16/invention-2017267_1280.jpg?w=400',
        'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=400',
      ],
      'createdAt': DateTime.now().subtract(const Duration(days: 15)),
    },
    {
      'id': 4,
      'name': 'Meeting Notes',
      'color': 'orange',
      'noteCount': 6,
      'isPinned': false,
      'isDefault': false,
      'previewImages': [
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=400',
        'https://images.pexels.com/photos/1181396/pexels-photo-1181396.jpeg?w=400',
      ],
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
    },
    {
      'id': 5,
      'name': 'Travel Plans',
      'color': 'red',
      'noteCount': 4,
      'isPinned': false,
      'isDefault': false,
      'previewImages': [
        'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400',
      ],
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sortFolders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _sortFolders() {
    _folders.sort((a, b) {
      // Default folders first
      if (a['isDefault'] && !b['isDefault']) return -1;
      if (!a['isDefault'] && b['isDefault']) return 1;

      // Pinned folders next
      if (a['isPinned'] && !b['isPinned']) return -1;
      if (!a['isPinned'] && b['isPinned']) return 1;

      // Then alphabetically
      return (a['name'] as String).compareTo(b['name'] as String);
    });
  }

  List<Map<String, dynamic>> get _filteredFolders {
    if (_searchQuery.isEmpty) return _folders;

    return _folders.where((folder) {
      final name = (folder['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _refreshFolders() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folders synced successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _createFolder(String name, String color) {
    final newFolder = {
      'id': _folders.length + 1,
      'name': name,
      'color': color,
      'noteCount': 0,
      'isPinned': false,
      'isDefault': false,
      'previewImages': <String>[],
      'createdAt': DateTime.now(),
    };

    setState(() {
      _folders.add(newFolder);
      _sortFolders();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Folder "$name" created successfully'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCreateFolderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateFolderBottomSheet(
        onCreateFolder: _createFolder,
      ),
    );
  }

  void _showFolderContextMenu(Map<String, dynamic> folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FolderContextMenu(
        folder: folder,
        onRename: () => _renameFolder(folder),
        onChangeColor: () => _changeFolderColor(folder),
        onDelete: () => _deleteFolder(folder),
        onShare: () => _shareFolder(folder),
      ),
    );
  }

  void _renameFolder(Map<String, dynamic> folder) {
    final TextEditingController controller =
        TextEditingController(text: folder['name']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter new folder name',
          ),
          textCapitalization: TextCapitalization.words,
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != folder['name']) {
                setState(() {
                  folder['name'] = newName;
                  _sortFolders();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Folder renamed to "$newName"')),
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _changeFolderColor(Map<String, dynamic> folder) {
    final colors = ['blue', 'green', 'orange', 'purple', 'red', 'gray'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Folder Color'),
        content: Wrap(
          spacing: 3.w,
          runSpacing: 2.h,
          children: colors.map((colorName) {
            final bool isSelected = folder['color'] == colorName;
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final Color color = _getColorForTheme(colorName, isDark);

            return GestureDetector(
              onTap: () {
                setState(() {
                  folder['color'] = colorName;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Folder color updated')),
                );
              },
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).primaryColor, width: 3)
                      : null,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(Map<String, dynamic> folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete "${folder['name']}"? This action cannot be undone and will delete all notes in this folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _folders.removeWhere((f) => f['id'] == folder['id']);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Folder "${folder['name']}" deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.errorDark
                  : AppTheme.errorLight,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareFolder(Map<String, dynamic> folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share "${folder['name']}" with others'),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Read-only link copied to clipboard')),
                      );
                    },
                    child: const Text('Read Only'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Editable link copied to clipboard')),
                      );
                    },
                    child: const Text('Editable'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleFolderPin(Map<String, dynamic> folder) {
    setState(() {
      folder['isPinned'] = !folder['isPinned'];
      _sortFolders();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(folder['isPinned'] ? 'Folder pinned' : 'Folder unpinned'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openFolder(Map<String, dynamic> folder) {
    // Navigate to folder contents - placeholder for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening "${folder['name']}" folder'),
        duration: const Duration(seconds: 1),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredFolders = _filteredFolders;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Folders'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color:
                isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/notes-dashboard'),
            icon: CustomIconWidget(
              iconName: 'home',
              color:
                  isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Folders'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Folders tab
            Column(
              children: [
                // Search widget
                FolderSearchWidget(
                  searchQuery: _searchQuery,
                  onSearchChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                  onClearSearch: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),

                // Folders grid
                Expanded(
                  child: filteredFolders.isEmpty
                      ? _searchQuery.isNotEmpty
                          ? _buildNoSearchResults()
                          : EmptyFoldersWidget(
                              onCreateFolder: _showCreateFolderBottomSheet,
                            )
                      : RefreshIndicator(
                          onRefresh: _refreshFolders,
                          child: CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.all(4.w),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      // Insert native ad after every 6 folders
                                      if (index != 0 && (index + 1) % 7 == 0) {
                                        return Container(
                                          height: 200,
                                          child: const SimpleNativeAd(
                                            placementId: AdsConfig.placementFolders,
                                            template: NativeAdTemplate.medium,
                                          ),
                                        );
                                      }
                                      
                                      // Calculate the actual folder index (accounting for ads)
                                      final folderIndex = index - (index ~/ 7);
                                      if (folderIndex >= filteredFolders.length) return const SizedBox.shrink();
                                      
                                      final folder = filteredFolders[folderIndex];
                                      return FolderCardWidget(
                                        folder: folder,
                                        onTap: () => _openFolder(folder),
                                        onLongPress: () =>
                                            _showFolderContextMenu(folder),
                                        onPinSwipe: () => _toggleFolderPin(folder),
                                        onDeleteSwipe: () => _deleteFolder(folder),
                                      );
                                    },
                                    childCount: filteredFolders.length + (filteredFolders.length ~/ 6),
                                  ),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 4.w,
                                    mainAxisSpacing: 2.h,
                                    childAspectRatio: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            // Recent tab
            _buildRecentFolders(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFolderBottomSheet,
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'No folders found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try searching with different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFolders() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final recentFolders = List<Map<String, dynamic>>.from(_folders)
      ..sort((a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: recentFolders.length,
      itemBuilder: (context, index) {
        final folder = recentFolders[index];
        final createdAt = folder['createdAt'] as DateTime;
        final daysAgo = DateTime.now().difference(createdAt).inDays;

        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: _getColorForTheme(folder['color'], isDark)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'folder',
                color: _getColorForTheme(folder['color'], isDark),
                size: 24,
              ),
            ),
            title: Text(
              folder['name'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: Text(
              '${folder['noteCount']} notes • ${daysAgo == 0 ? 'Today' : '$daysAgo days ago'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: folder['isPinned']
                ? CustomIconWidget(
                    iconName: 'push_pin',
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    size: 16,
                  )
                : null,
            onTap: () => _openFolder(folder),
            onLongPress: () => _showFolderContextMenu(folder),
          ),
        );
      },
    );
  }
}

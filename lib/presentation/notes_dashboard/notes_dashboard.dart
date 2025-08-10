import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/local/note_repository.dart';
import '../../services/sync/sync_manager.dart';
import '../../models/note.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/note_card_widget.dart';
import './widgets/note_type_selector_widget.dart';
import './widgets/search_bar_widget.dart';

class NotesDashboard extends StatefulWidget {
  const NotesDashboard({Key? key}) : super(key: key);

  @override
  State<NotesDashboard> createState() => _NotesDashboardState();
}

class _NotesDashboardState extends State<NotesDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = false;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  // Repository and sync manager
  final NoteRepository _noteRepository = NoteRepository();
  final SyncManager _syncManager = SyncManager();
  
  // Current notes from repository
  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];
  
  final List<String> _recentSearches = ['meeting notes', 'grocery', 'travel'];
  final List<String> _aiSuggestions = [
    'Find notes with reminders',
    'Show pinned notes',
    'Notes from last week'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Listen to notes stream from repository
    _noteRepository.notesStream.listen((notes) {
      if (mounted) {
        setState(() {
          _allNotes = notes;
          _filterNotes();
        });
      }
    });
    
    // Load initial notes
    _loadInitialNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialNotes() {
    setState(() {
      _allNotes = _noteRepository.getAllNotes();
      _filterNotes();
    });
  }

  void _filterNotes() {
    setState(() {
      _filteredNotes = _allNotes.where((note) {
        bool matchesFilter = _selectedFilter == 'All' ||
            note.folderId == _selectedFilter ||
            (_selectedFilter == 'Pinned' && note.isPinned == true) ||
            (_selectedFilter == 'Reminders' && note.hasReminder == true);

        bool matchesSearch = _searchQuery.isEmpty ||
            note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));

        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterNotes();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterNotes();
  }

  void _showNoteTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteTypeSelectorWidget(
        onNoteTypeSelected: (type) {
          _createNote(type);
        },
      ),
    );
  }

  void _createNote(String type) async {
    // Create a new note via repository
    final note = await _noteRepository.createNote(
      title: '',
      content: '',
      noteType: type,
    );
    
    // Navigate to note editor with the new note ID
    Navigator.pushNamed(
      context, 
      '/note-creation-editor',
      arguments: {'noteId': note.id},
    );
  }

  void _onNoteAction(String noteId, String action) async {
    switch (action) {
      case 'pin':
        await _noteRepository.togglePinNote(noteId);
        break;
      case 'delete':
        await _noteRepository.deleteNote(noteId);
        break;
      case 'duplicate':
        await _noteRepository.duplicateNote(noteId);
        break;
    }
    // No need to call _filterNotes() here since the repository stream will update automatically
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // App title and actions
                  Row(
                    children: [
                      Text(
                        'QuickNote Pro',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight,
                                ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppTheme.primaryDark
                                    : AppTheme.primaryLight)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: _isGridView ? 'view_list' : 'view_module',
                            color: isDark
                                ? AppTheme.primaryDark
                                : AppTheme.primaryLight,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Search bar
                  SearchBarWidget(
                    hintText: 'Search notes...',
                    onChanged: _onSearchChanged,
                    onTap: () {
                      setState(() {
                        _isSearchExpanded = true;
                      });
                    },
                    isExpanded: _isSearchExpanded,
                    recentSearches: _recentSearches,
                    suggestions: _aiSuggestions,
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Notes'),
                  Tab(text: 'Folders'),
                  Tab(text: 'Search'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),

            // Filter chips
            if (!_isSearchExpanded) ...[
              Container(
                height: 6.h,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  children: [
                    FilterChipWidget(
                      label: 'All',
                      count: _allNotes.length,
                      isSelected: _selectedFilter == 'All',
                      onTap: () => _onFilterSelected('All'),
                    ),
                    FilterChipWidget(
                      label: 'Work',
                      count: _allNotes
                          .where((note) => note.folderId == 'Work')
                          .length,
                      isSelected: _selectedFilter == 'Work',
                      onTap: () => _onFilterSelected('Work'),
                    ),
                    FilterChipWidget(
                      label: 'Personal',
                      count: _allNotes
                          .where((note) => note.folderId == 'Personal')
                          .length,
                      isSelected: _selectedFilter == 'Personal',
                      onTap: () => _onFilterSelected('Personal'),
                    ),
                    FilterChipWidget(
                      label: 'Pinned',
                      count: _allNotes
                          .where((note) => note.isPinned == true)
                          .length,
                      isSelected: _selectedFilter == 'Pinned',
                      onTap: () => _onFilterSelected('Pinned'),
                    ),
                    FilterChipWidget(
                      label: 'Reminders',
                      count: _allNotes
                          .where((note) => note.hasReminder == true)
                          .length,
                      isSelected: _selectedFilter == 'Reminders',
                      onTap: () => _onFilterSelected('Reminders'),
                    ),
                  ],
                ),
              ),
            ],

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Notes tab
                  _buildNotesTab(),

                  // Folders tab
                  _buildFoldersTab(),

                  // Search tab
                  _buildSearchTab(),

                  // Settings tab
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNoteTypeSelector,
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    if (_filteredNotes.isEmpty) {
      return EmptyStateWidget(
        onCreateNote: _showNoteTypeSelector,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger cloud sync if connected
        if (_syncManager.isConnected) {
          await _syncManager.syncNow();
        } else {
          // Just reload local data
          _loadInitialNotes();
        }
      },
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 10.h),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return NoteCardWidget(
          note: _noteToMap(note), // Convert Note to Map for compatibility
          onTap: () {
            Navigator.pushNamed(
              context, 
              '/note-creation-editor',
              arguments: {'noteId': note.id},
            );
          },
          onPin: () => _onNoteAction(note.id, 'pin'),
          onShare: () {
            // Implement share functionality
          },
          onMove: () {
            Navigator.pushNamed(context, '/folder-organization');
          },
          onDelete: () => _onNoteAction(note.id, 'delete'),
          onDuplicate: () => _onNoteAction(note.id, 'duplicate'),
          onExport: () {
            // Implement export functionality
          },
          onSetReminder: () {
            // Implement reminder functionality
          },
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(4.w).copyWith(bottom: 10.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return NoteCardWidget(
          note: _noteToMap(note), // Convert Note to Map for compatibility
          onTap: () {
            Navigator.pushNamed(
              context, 
              '/note-creation-editor',
              arguments: {'noteId': note.id},
            );
          },
          onPin: () => _onNoteAction(note.id, 'pin'),
          onShare: () {
            // Implement share functionality
          },
          onMove: () {
            Navigator.pushNamed(context, '/folder-organization');
          },
          onDelete: () => _onNoteAction(note.id, 'delete'),
          onDuplicate: () => _onNoteAction(note.id, 'duplicate'),
          onExport: () {
            // Implement export functionality
          },
          onSetReminder: () {
            // Implement reminder functionality
          },
        );
      },
    );
  }

  // Helper method to convert Note object to Map for existing NoteCardWidget
  Map<String, dynamic> _noteToMap(Note note) {
    return {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'preview': note.preview,
      'type': note.noteType ?? 'text',
      'folder': note.folderId,
      'createdAt': note.createdAt.toIso8601String(),
      'isPinned': note.isPinned,
      'hasReminder': note.hasReminder,
    };
  }

  Widget _buildFoldersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'folder',
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Folder Organization',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 1.h),
          Text(
            'Organize your notes into folders',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/folder-organization');
            },
            child: const Text('Manage Folders'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search',
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Advanced Search',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 1.h),
          Text(
            'Find notes with AI-powered search',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/search-discovery');
            },
            child: const Text('Open Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Premium section
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? AppTheme.warningDark : AppTheme.warningLight,
                (isDark ? AppTheme.warningDark : AppTheme.warningLight)
                    .withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'star',
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 1.h),
              Text(
                'Upgrade to Premium',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Unlock unlimited features',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isDark
                            ? AppTheme.warningDark
                            : AppTheme.warningLight,
                      ),
                      child: const Text('\$2.99/month'),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isDark
                            ? AppTheme.warningDark
                            : AppTheme.warningLight,
                      ),
                      child: const Text('\$14.99 Lifetime'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),

        // Settings options
        _buildSettingsTile(
          icon: 'cloud_sync',
          title: 'Cloud Storage',
          subtitle: 'Sync across devices',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.cloudConnections);
          },
        ),
        _buildSettingsTile(
          icon: 'dark_mode',
          title: 'Dark Mode',
          subtitle: 'Automatic scheduling',
          onTap: () {},
        ),
        _buildSettingsTile(
          icon: 'backup',
          title: 'Backup & Export',
          subtitle: 'Local backup options',
          onTap: () {},
        ),
        _buildSettingsTile(
          icon: 'settings',
          title: 'Settings & Profile',
          subtitle: 'Manage your account and preferences',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.settingsProfile);
          },
        ),
        _buildSettingsTile(
          icon: 'feedback',
          title: 'Send Feedback',
          subtitle: 'Help us improve',
          onTap: () {},
        ),
        _buildSettingsTile(
          icon: 'share',
          title: 'Refer Friends',
          subtitle: 'Get 1 month free premium',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: Theme.of(context).colorScheme.primary,
        size: 24,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: CustomIconWidget(
        iconName: 'arrow_forward_ios',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}

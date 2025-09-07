import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/note_card_widget.dart';
import './widgets/note_type_selector_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/tag_filter_widget.dart';

class NotesDashboard extends StatefulWidget {
  const NotesDashboard({Key? key}) : super(key: key);

  @override
  State<NotesDashboard> createState() => _NotesDashboardState();
}

class _NotesDashboardState extends State<NotesDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = false;
  bool _isSearchExpanded = false;

  // Mock data for notes
  final List<Map<String, dynamic>> _allNotes = [];

  List<Map<String, dynamic>> _filteredNotes = [];
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFilterSelected(String filter) {
    try {
      final notesService = context.read<NotesService>();
      notesService.setFilter(filter);
    } catch (e) {
      debugPrint('Error setting filter: $e');
    }
  }

  void _onSearchChanged(String query) {
    try {
      final notesService = context.read<NotesService>();
      notesService.setSearchQuery(query);
    } catch (e) {
      debugPrint('Error setting search query: $e');
    }
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

  void _createNote(String type) {
    // Navigate to note creation based on type
    switch (type) {
      case 'text':
        Navigator.pushNamed(context, '/note-creation-editor');
        break;
      case 'voice':
        Navigator.pushNamed(context, '/note-creation-editor');
        break;
      case 'drawing':
        Navigator.pushNamed(context, '/note-creation-editor');
        break;
      case 'template':
        Navigator.pushNamed(context, '/note-creation-editor');
        break;
    }
  }

  void _onNoteAction(int noteId, String action) {
    try {
      final notesService = context.read<NotesService>();
      
      switch (action) {
        case 'pin':
          notesService.togglePin(noteId);
          break;
        case 'delete':
          notesService.deleteNote(noteId);
          break;
        case 'duplicate':
          notesService.duplicateNote(noteId);
          break;
        case 'share':
          _shareNote(noteId);
          break;
        default:
          debugPrint('Unknown note action: $action');
      }
    } catch (e) {
      debugPrint('Error performing note action $action: $e');
    }
  }
  
  Future<void> _shareNote(int noteId) async {
    try {
      final notesService = context.read<NotesService>();
      await notesService.shareNote(noteId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showTagManagement() {
    // TODO: Implement tag management dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tag Management'),
        content: const Text('Tag management feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                                .withOpacity(0.1),
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
              Consumer<NotesService>(
                builder: (context, notesService, child) {
                  final filterCounts = notesService.filterCounts;
                  final selectedFilter = notesService.selectedFilter;
                  
                  return Container(
                    height: 6.h,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      children: filterCounts.entries.map((entry) {
                        return FilterChipWidget(
                          label: entry.key,
                          count: entry.value,
                          isSelected: selectedFilter == entry.key,
                          onTap: () => _onFilterSelected(entry.key),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              
              // Tag filter row
              Consumer<NotesService>(
                builder: (context, notesService, child) {
                  return TagFilterWidget(
                    availableTags: notesService.availableTags,
                    selectedTag: notesService.selectedTag,
                    onTagSelected: (tag) => notesService.setTagFilter(tag),
                    onManageTags: _showTagManagement,
                  );
                },
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
    return Consumer<NotesService>(
      builder: (context, notesService, child) {
        final filteredNotes = notesService.filteredNotes;
        
        if (filteredNotes.isEmpty) {
          return EmptyStateWidget(
            onCreateNote: _showNoteTypeSelector,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Simulate cloud sync
            await Future.delayed(const Duration(seconds: 1));
            // In a real app, you would trigger sync here
          },
          child: _isGridView 
              ? _buildGridView(filteredNotes) 
              : _buildListView(filteredNotes),
        );
      },
    );
  }

  Widget _buildListView(List<Note> notes) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 10.h),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCardWidget(
          note: note.toMap(), // Convert back to map for compatibility
          onTap: () {
            Navigator.pushNamed(context, '/note-creation-editor');
          },
          onPin: () => _onNoteAction(note.id, 'pin'),
          onShare: () => _onNoteAction(note.id, 'share'),
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

  Widget _buildGridView(List<Note> notes) {
    return GridView.builder(
      padding: EdgeInsets.all(4.w).copyWith(bottom: 10.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCardWidget(
          note: note.toMap(), // Convert back to map for compatibility
          onTap: () {
            Navigator.pushNamed(context, '/note-creation-editor');
          },
          onPin: () => _onNoteAction(note.id, 'pin'),
          onShare: () => _onNoteAction(note.id, 'share'),
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
                    .withOpacity(0.8),
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
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.upgradeScreen);
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
                        Navigator.pushNamed(context, AppRoutes.upgradeScreen);
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
          title: 'Cloud Sync',
          subtitle: 'Sync across devices',
          onTap: () {},
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

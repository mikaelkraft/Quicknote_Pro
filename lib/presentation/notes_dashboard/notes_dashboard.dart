import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

  // Mock data for notes
  final List<Map<String, dynamic>> _allNotes = [
    {
      "id": 1,
      "title": "Meeting Notes - Q4 Planning",
      "content":
          "Discussed quarterly goals, budget allocation, and team expansion plans. Key decisions made regarding product roadmap and marketing strategy.",
      "preview":
          "Discussed quarterly goals, budget allocation, and team expansion plans...",
      "type": "text",
      "folder": "Work",
      "createdAt": "2025-01-28T10:30:00Z",
      "isPinned": true,
      "hasReminder": true,
    },
    {
      "id": 2,
      "title": "Voice Memo - Grocery List",
      "content":
          "Milk, eggs, bread, apples, chicken breast, pasta, tomatoes, cheese",
      "preview": "Milk, eggs, bread, apples, chicken breast, pasta...",
      "type": "voice",
      "folder": "Personal",
      "createdAt": "2025-01-27T15:45:00Z",
      "isPinned": false,
      "hasReminder": false,
    },
    {
      "id": 3,
      "title": "App UI Wireframe",
      "content": "Initial sketches for the new mobile app interface design",
      "preview": "Initial sketches for the new mobile app interface design",
      "type": "drawing",
      "folder": "Work",
      "createdAt": "2025-01-26T09:15:00Z",
      "isPinned": false,
      "hasReminder": false,
    },
    {
      "id": 4,
      "title": "Book Ideas",
      "content":
          "Collection of interesting plot concepts and character development notes for future writing projects.",
      "preview":
          "Collection of interesting plot concepts and character development...",
      "type": "text",
      "folder": "Personal",
      "createdAt": "2025-01-25T20:30:00Z",
      "isPinned": false,
      "hasReminder": true,
    },
    {
      "id": 5,
      "title": "Travel Checklist",
      "content":
          "Passport, tickets, hotel confirmation, travel insurance, medications, chargers, camera",
      "preview": "Passport, tickets, hotel confirmation, travel insurance...",
      "type": "template",
      "folder": null,
      "createdAt": "2025-01-24T14:20:00Z",
      "isPinned": true,
      "hasReminder": false,
    },
  ];

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
    _filteredNotes = List.from(_allNotes);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _filterNotes() {
    setState(() {
      _filteredNotes = _allNotes.where((note) {
        bool matchesFilter = _selectedFilter == 'All' ||
            note['folder'] == _selectedFilter ||
            (_selectedFilter == 'Pinned' && note['isPinned'] == true) ||
            (_selectedFilter == 'Reminders' && note['hasReminder'] == true);

        bool matchesSearch = _searchQuery.isEmpty ||
            (note['title'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (note['content'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

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
    setState(() {
      final noteIndex = _allNotes.indexWhere((note) => note['id'] == noteId);
      if (noteIndex != -1) {
        switch (action) {
          case 'pin':
            _allNotes[noteIndex]['isPinned'] =
                !(_allNotes[noteIndex]['isPinned'] ?? false);
            break;
          case 'delete':
            _allNotes.removeAt(noteIndex);
            break;
          case 'duplicate':
            final originalNote = _allNotes[noteIndex];
            final duplicatedNote = Map<String, dynamic>.from(originalNote);
            duplicatedNote['id'] = DateTime.now().millisecondsSinceEpoch;
            duplicatedNote['title'] = '${originalNote['title']} (Copy)';
            duplicatedNote['createdAt'] = DateTime.now().toIso8601String();
            _allNotes.insert(noteIndex + 1, duplicatedNote);
            break;
        }
      }
    });
    _filterNotes();
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
                          .where((note) => note['folder'] == 'Work')
                          .length,
                      isSelected: _selectedFilter == 'Work',
                      onTap: () => _onFilterSelected('Work'),
                    ),
                    FilterChipWidget(
                      label: 'Personal',
                      count: _allNotes
                          .where((note) => note['folder'] == 'Personal')
                          .length,
                      isSelected: _selectedFilter == 'Personal',
                      onTap: () => _onFilterSelected('Personal'),
                    ),
                    FilterChipWidget(
                      label: 'Pinned',
                      count: _allNotes
                          .where((note) => note['isPinned'] == true)
                          .length,
                      isSelected: _selectedFilter == 'Pinned',
                      onTap: () => _onFilterSelected('Pinned'),
                    ),
                    FilterChipWidget(
                      label: 'Reminders',
                      count: _allNotes
                          .where((note) => note['hasReminder'] == true)
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
        // Simulate cloud sync
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          // Refresh data
        });
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
          note: note,
          onTap: () {
            Navigator.pushNamed(context, '/note-creation-editor');
          },
          onPin: () => _onNoteAction(note['id'], 'pin'),
          onShare: () {
            // Implement share functionality
          },
          onMove: () {
            Navigator.pushNamed(context, '/folder-organization');
          },
          onDelete: () => _onNoteAction(note['id'], 'delete'),
          onDuplicate: () => _onNoteAction(note['id'], 'duplicate'),
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
          note: note,
          onTap: () {
            Navigator.pushNamed(context, '/note-creation-editor');
          },
          onPin: () => _onNoteAction(note['id'], 'pin'),
          onShare: () {
            // Implement share functionality
          },
          onMove: () {
            Navigator.pushNamed(context, '/folder-organization');
          },
          onDelete: () => _onNoteAction(note['id'], 'delete'),
          onDuplicate: () => _onNoteAction(note['id'], 'duplicate'),
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

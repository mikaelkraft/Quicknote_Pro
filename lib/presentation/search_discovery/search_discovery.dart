import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/recent_searches_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/search_filters_widget.dart';
import './widgets/search_results_widget.dart';
import './widgets/voice_search_widget.dart';

class SearchDiscovery extends StatefulWidget {
  const SearchDiscovery({Key? key}) : super(key: key);

  @override
  State<SearchDiscovery> createState() => _SearchDiscoveryState();
}

class _SearchDiscoveryState extends State<SearchDiscovery>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Search state
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [
    'meeting notes',
    'project ideas',
    'shopping list',
    'voice memo',
    'drawing sketch',
    'work tasks'
  ];

  bool _isSearching = false;
  bool _isVoiceSearching = false;
  String _transcribedText = '';
  bool _isPremium = false; // Mock premium status

  // Filter state
  Map<String, bool> _selectedFilters = {
    'text': false,
    'voice': false,
    'drawing': false,
    'image': false,
    'ocr': false,
    'handwriting': false,
    'semantic': false,
  };
  DateTimeRange? _dateRange;
  List<String> _selectedFolders = [];

  // Mock search results data
  final List<Map<String, dynamic>> _mockNotes = [
    {
      "id": 1,
      "title": "Weekly Team Meeting Notes",
      "content":
          "Discussed project timeline, budget allocation, and upcoming deadlines. Sarah presented the new marketing strategy.",
      "type": "text",
      "folder": "Work",
      "createdAt": DateTime.now().subtract(const Duration(days: 2)),
      "matchingSnippet":
          "Discussed project timeline and budget allocation for Q4 planning session",
      "relevanceScore": 0.95,
      "tags": ["#meeting", "#work", "#planning"]
    },
    {
      "id": 2,
      "title": "Voice Memo - Project Ideas",
      "content":
          "Recorded brainstorming session about mobile app features and user experience improvements",
      "type": "voice",
      "folder": "Ideas",
      "createdAt": DateTime.now().subtract(const Duration(days: 1)),
      "matchingSnippet":
          "Mobile app features including voice search and AI-powered note organization",
      "relevanceScore": 0.88,
      "tags": ["#ideas", "#mobile", "#features"]
    },
    {
      "id": 3,
      "title": "Shopping List - Groceries",
      "content":
          "Milk, bread, eggs, chicken, vegetables, fruits, yogurt, cheese",
      "type": "text",
      "folder": "Personal",
      "createdAt": DateTime.now().subtract(const Duration(hours: 6)),
      "matchingSnippet":
          "Weekly grocery shopping including organic vegetables and dairy products",
      "relevanceScore": 0.76,
      "tags": ["#shopping", "#groceries", "#personal"]
    },
    {
      "id": 4,
      "title": "UI Design Sketch",
      "content":
          "Hand-drawn wireframes for the new dashboard layout with navigation improvements",
      "type": "drawing",
      "folder": "Projects",
      "createdAt": DateTime.now().subtract(const Duration(days: 3)),
      "matchingSnippet":
          "Dashboard wireframes showing improved navigation and user interface elements",
      "relevanceScore": 0.82,
      "tags": ["#design", "#wireframes", "#ui"]
    },
    {
      "id": 5,
      "title": "Meeting Photo - Whiteboard",
      "content":
          "Photo of whiteboard from strategy meeting with action items and timelines",
      "type": "image",
      "folder": "Work",
      "createdAt": DateTime.now().subtract(const Duration(days: 4)),
      "matchingSnippet":
          "Strategy meeting whiteboard with Q4 action items and project timelines",
      "relevanceScore": 0.71,
      "tags": ["#meeting", "#strategy", "#actionitems"]
    },
    {
      "id": 6,
      "title": "Book Notes - Productivity",
      "content":
          "Key insights from 'Getting Things Done' methodology and time management techniques",
      "type": "text",
      "folder": "Personal",
      "createdAt": DateTime.now().subtract(const Duration(days: 7)),
      "matchingSnippet":
          "Productivity methodology focusing on task organization and time management systems",
      "relevanceScore": 0.69,
      "tags": ["#productivity", "#books", "#learning"]
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    final results = _mockNotes.where((note) {
      final titleMatch =
          (note['title'] as String).toLowerCase().contains(query.toLowerCase());
      final contentMatch = (note['content'] as String)
          .toLowerCase()
          .contains(query.toLowerCase());
      final tagsMatch = (note['tags'] as List).any(
          (tag) => tag.toString().toLowerCase().contains(query.toLowerCase()));

      // Apply filters
      if (_selectedFilters.values.any((selected) => selected)) {
        final typeMatch = _selectedFilters[note['type']] ?? false;
        if (!typeMatch) return false;
      }

      // Apply folder filter
      if (_selectedFolders.isNotEmpty) {
        if (!_selectedFolders.contains(note['folder'])) return false;
      }

      // Apply date range filter
      if (_dateRange != null) {
        final noteDate = note['createdAt'] as DateTime;
        if (noteDate.isBefore(_dateRange!.start) ||
            noteDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      return titleMatch || contentMatch || tagsMatch;
    }).toList();

    // Sort by relevance score
    results.sort((a, b) => (b['relevanceScore'] as double)
        .compareTo(a['relevanceScore'] as double));

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    // Add to recent searches if not empty and not already present
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      });
    }
  }

  void _onRecentSearchTap(String search) {
    _searchController.text = search;
    _performSearch(search);
  }

  void _onClearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFiltersWidget(
        selectedFilters: _selectedFilters,
        dateRange: _dateRange,
        selectedFolders: _selectedFolders,
        isPremium: _isPremium,
        onFiltersChanged: (filters) {
          setState(() {
            _selectedFilters = filters;
          });
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
        onDateRangeChanged: (dateRange) {
          setState(() {
            _dateRange = dateRange;
          });
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
        onFoldersChanged: (folders) {
          setState(() {
            _selectedFolders = folders;
          });
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
      ),
    );
  }

  void _showVoiceSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceSearchWidget(
        isListening: _isVoiceSearching,
        transcribedText: _transcribedText,
        onStartListening: _startVoiceSearch,
        onStopListening: _stopVoiceSearch,
        onTranscriptionComplete: (text) {
          _searchController.text = text;
          _performSearch(text);
        },
      ),
    );
  }

  void _startVoiceSearch() {
    setState(() {
      _isVoiceSearching = true;
      _transcribedText = '';
    });

    // Simulate voice recognition
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isVoiceSearching) {
        setState(() {
          _transcribedText = 'Find my meeting notes from yesterday';
        });
      }
    });
  }

  void _stopVoiceSearch() {
    setState(() {
      _isVoiceSearching = false;
    });
  }

  void _onNoteTap(Map<String, dynamic> note) {
    // Navigate to note details
    Navigator.pushNamed(context, '/note-creation-editor');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Discovery'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: Theme.of(context).colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults.clear();
                });
              },
              icon: CustomIconWidget(
                iconName: 'clear',
                color: Theme.of(context).colorScheme.onSurface,
                size: 6.w,
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Recent'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          SearchBarWidget(
            controller: _searchController,
            onVoiceSearch: _showVoiceSearchBottomSheet,
            onFilterTap: _showFilterBottomSheet,
            isVoiceSearching: _isVoiceSearching,
          ),

          // Active Filters Indicator
          if (_selectedFilters.values.any((selected) => selected) ||
              _selectedFolders.isNotEmpty ||
              _dateRange != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'filter_list',
                    color: Theme.of(context).colorScheme.primary,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Filters active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilters = Map.fromIterable(
                          _selectedFilters.keys,
                          value: (_) => false,
                        );
                        _selectedFolders.clear();
                        _dateRange = null;
                      });
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Tab
                _buildSearchContent(),

                // Recent Tab
                _buildRecentContent(),

                // Favorites Tab
                _buildFavoritesContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_searchController.text.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),

            // Recent Searches
            RecentSearchesWidget(
              recentSearches: _recentSearches,
              onSearchTap: _onRecentSearchTap,
              onClearAll: _onClearRecentSearches,
            ),

            SizedBox(height: 3.h),

            // Native ad in search suggestions
            const SimpleNativeAd(
              placementId: AdsConfig.placementSearch,
              template: NativeAdTemplate.medium,
            ),
            SizedBox(height: 3.h),

            // Search Suggestions
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Suggestions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 2.h),
                  _buildSuggestionCard(
                    context,
                    'Find notes by content',
                    'Search within your note text and descriptions',
                    Icons.text_fields,
                    () => _searchController.text = 'project',
                  ),
                  _buildSuggestionCard(
                    context,
                    'Search by hashtags',
                    'Use #tags to find categorized notes',
                    Icons.tag,
                    () => _searchController.text = '#meeting',
                  ),
                  _buildSuggestionCard(
                    context,
                    'Voice and drawing search',
                    'Find multimedia content in your notes',
                    Icons.multitrack_audio,
                    () => _searchController.text = 'voice memo',
                  ),
                  if (_isPremium)
                    _buildSuggestionCard(
                      context,
                      'AI-powered search',
                      'Use natural language to find notes',
                      Icons.psychology,
                      () => _searchController.text =
                          'show me notes about productivity',
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SearchResultsWidget(
      searchResults: _searchResults,
      searchQuery: _searchController.text,
      isLoading: _isSearching,
      onNoteTap: _onNoteTap,
    );
  }

  Widget _buildRecentContent() {
    final recentNotes = _mockNotes.take(3).toList();
    return SearchResultsWidget(
      searchResults: recentNotes,
      searchQuery: '',
      onNoteTap: _onNoteTap,
    );
  }

  Widget _buildFavoritesContent() {
    final favoriteNotes = _mockNotes
        .where((note) => (note['relevanceScore'] as double) > 0.8)
        .toList();
    return SearchResultsWidget(
      searchResults: favoriteNotes,
      searchQuery: '',
      onNoteTap: _onNoteTap,
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: icon.toString().split('.').last,
                  color: Theme.of(context).colorScheme.primary,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'arrow_forward_ios',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 4.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

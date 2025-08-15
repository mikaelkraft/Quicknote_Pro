## Example: Integrating Monetization into Notes Dashboard

Here's a simple example showing how to add monetization features to the existing notes dashboard without major restructuring:

### Step 1: Add Tier Status Badge to Header

In `notes_dashboard.dart`, add the tier status badge to the header row:

```dart
// App title and actions
Row(
  children: [
    Text(
      'QuickNote Pro',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
      ),
    ),
    const Spacer(),
    
    // Add tier status badge
    const TierStatusBadge(),
    SizedBox(width: 3.w),
    
    GestureDetector(
      onTap: () {
        setState(() {
          _isGridView = !_isGridView;
        });
      },
      child: Container(
        // existing grid/list toggle button
      ),
    ),
  ],
),
```

### Step 2: Add Usage Dashboard Above Content

Add usage tracking above the notes content:

```dart
Column(
  children: [
    // Header (existing)
    Container(
      // existing header content
    ),
    
    // Add usage dashboard
    const UsageDashboard(),
    
    // Existing content
    Expanded(
      child: _filteredNotes.isEmpty
          ? const EmptyStateWidget()
          : _buildNotesContent(),
    ),
  ],
)
```

### Step 3: Add Feature Gate to FAB

Modify the floating action button to check note creation limits:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => _checkAndCreateNote(context),
  child: const Icon(Icons.add),
),

// Add this method
void _checkAndCreateNote(BuildContext context) async {
  final canCreate = await context.monetization.checkFeatureAccess(
    context,
    featureType: FeatureType.noteCreation,
    featureContext: 'notes_dashboard_fab',
  );
  
  if (canCreate) {
    await context.monetization.recordFeatureUsage(FeatureType.noteCreation);
    _showNoteTypeSelector();
    
    // Show interstitial ad occasionally
    await context.monetization.showSmartInterstitial(
      context,
      AdPlacement.noteCreationInterstitial,
    );
  }
}
```

### Step 4: Add Banner Ads to Notes List

Modify the notes list to include banner ads every 5 notes:

```dart
ListView.builder(
  itemCount: _getItemCount(), // Calculate total items including ads
  itemBuilder: (context, index) {
    // Check if this should be an ad
    final noteIndex = _getActualNoteIndex(index);
    final isAdPosition = (noteIndex + 1) % 5 == 0 && noteIndex < _filteredNotes.length - 1;
    
    if (isAdPosition) {
      return const SimpleBannerAd(
        placement: AdPlacement.noteListBanner,
      );
    }
    
    // Regular note card
    final actualIndex = _getActualNoteIndex(index);
    if (actualIndex >= _filteredNotes.length) return const SizedBox.shrink();
    
    return NoteCardWidget(
      // existing note card parameters
    );
  },
)

// Helper methods
int _getItemCount() {
  final noteCount = _filteredNotes.length;
  final adCount = (noteCount / 5).floor();
  return noteCount + adCount;
}

int _getActualNoteIndex(int listIndex) {
  final adsBeforeIndex = (listIndex / 6).floor(); // 5 notes + 1 ad = 6 items per cycle
  return listIndex - adsBeforeIndex;
}
```

### Step 5: Track Analytics

Add analytics tracking to existing methods:

```dart
void _createNote(String type) {
  // Existing navigation logic
  switch (type) {
    case 'text':
      context.analyticsService.trackEngagementEvent(
        EngagementEvent.noteCreated(),
      );
      Navigator.pushNamed(context, '/note-creation-editor');
      break;
    // ... other cases
  }
}

void _onNoteAction(int noteId, String action) {
  // Existing note action logic
  
  // Add analytics tracking
  context.analyticsService.trackFeatureEvent(
    FeatureEvent('note', action, {'note_id': noteId}),
  );
  
  setState(() {
    // existing state update logic
  });
}
```

### Complete Modified Header Example

```dart
// In the header section of notes_dashboard.dart
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
      // App title and actions with tier badge
      Row(
        children: [
          Text(
            'QuickNote Pro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            ),
          ),
          const Spacer(),
          
          // Monetization: Tier status badge
          const TierStatusBadge(),
          SizedBox(width: 3.w),
          
          // Existing grid/list toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: _isGridView ? 'view_list' : 'view_module',
                color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 2.h),

      // Existing search bar
      SearchBarWidget(
        hintText: 'Search notes...',
        onChanged: _onSearchChanged,
        onTap: () {
          setState(() {
            _isSearchExpanded = !_isSearchExpanded;
          });
        },
      ),
      
      // Existing filters
      if (_isSearchExpanded) ...[
        SizedBox(height: 2.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChipWidget(
                label: 'All',
                isSelected: _selectedFilter == 'All',
                onSelected: () => _onFilterChanged('All'),
              ),
              // ... other filter chips
            ],
          ),
        ),
      ],
    ],
  ),
),

// Add usage dashboard after header
const UsageDashboard(),
```

This approach adds monetization features incrementally without breaking existing functionality. The key is to:

1. **Start small**: Add tier badge and usage dashboard first
2. **Gate premium features**: Wrap existing functionality with feature gates
3. **Add ads strategically**: Insert banner ads at natural break points
4. **Track everything**: Add analytics to existing user actions
5. **Test thoroughly**: Use the monetization demo screen to validate features

The monetization system is designed to be non-intrusive and additive, so existing code continues to work while gaining new revenue opportunities.
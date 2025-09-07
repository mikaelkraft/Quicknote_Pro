import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/note.dart';

/// Service to manage notes with pin/sort/tag/share functionality
class NotesService extends ChangeNotifier {
  final List<Note> _notes = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<String> _availableTags = [];
  String? _selectedTag;
  bool _isInitialized = false;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;
  
  // Mock data - in a real app this would come from a database
  static final List<Map<String, dynamic>> _mockNotes = [
    {
      "id": 1,
      "title": "Meeting Notes - Q4 Planning",
      "content": "Discussed quarterly goals, budget allocation, and team expansion plans. Key decisions made regarding product roadmap and marketing strategy.",
      "preview": "Discussed quarterly goals, budget allocation, and team expansion plans...",
      "type": "text",
      "folder": "Work",
      "createdAt": "2025-01-28T10:30:00Z",
      "updatedAt": "2025-01-28T10:30:00Z",
      "isPinned": true,
      "hasReminder": true,
      "tags": ["work", "planning", "important"]
    },
    {
      "id": 2,
      "title": "Voice Memo - Grocery List",
      "content": "Milk, eggs, bread, apples, chicken breast, pasta, tomatoes, cheese",
      "preview": "Milk, eggs, bread, apples, chicken breast, pasta...",
      "type": "voice",
      "folder": "Personal",
      "createdAt": "2025-01-27T15:45:00Z",
      "updatedAt": "2025-01-27T15:45:00Z",
      "isPinned": false,
      "hasReminder": false,
      "tags": ["shopping", "groceries"]
    },
    {
      "id": 3,
      "title": "App UI Wireframe",
      "content": "Initial sketches for the new mobile app interface design",
      "preview": "Initial sketches for the new mobile app interface design",
      "type": "drawing",
      "folder": "Work",
      "createdAt": "2025-01-26T09:15:00Z",
      "updatedAt": "2025-01-26T09:15:00Z",
      "isPinned": false,
      "hasReminder": false,
      "tags": ["design", "ui", "wireframe"]
    },
    {
      "id": 4,
      "title": "Book Ideas",
      "content": "Collection of interesting plot concepts and character development notes for future writing projects.",
      "preview": "Collection of interesting plot concepts and character development...",
      "type": "text",
      "folder": "Personal",
      "createdAt": "2025-01-25T20:30:00Z",
      "updatedAt": "2025-01-25T20:30:00Z",
      "isPinned": false,
      "hasReminder": true,
      "tags": ["creative", "writing", "ideas"]
    },
    {
      "id": 5,
      "title": "Travel Checklist",
      "content": "Passport, tickets, hotel confirmation, travel insurance, medications, chargers, camera",
      "preview": "Passport, tickets, hotel confirmation, travel insurance...",
      "type": "template",
      "folder": null,
      "createdAt": "2025-01-24T14:20:00Z",
      "updatedAt": "2025-01-24T14:20:00Z",
      "isPinned": true,
      "hasReminder": false,
      "tags": ["travel", "checklist", "vacation"]
    },
  ];

  /// Initialize the service with mock data
  void initialize() {
    if (_isInitialized) return;
    
    try {
      _notes.clear();
      _notes.addAll(_mockNotes.map((map) => Note.fromMap(map)));
      _updateAvailableTags();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize notes service: $e');
      _isInitialized = true; // Still mark as initialized to prevent infinite retry
    }
  }

  /// Get all notes
  List<Note> get notes => List.unmodifiable(_notes);

  /// Get filtered and sorted notes
  List<Note> get filteredNotes {
    var filtered = _notes.where((note) {
      // Filter by search query
      if (_searchQuery.isNotEmpty && !note.matches(_searchQuery)) {
        return false;
      }

      // Filter by selected filter
      switch (_selectedFilter) {
        case 'Work':
          return note.folder == 'Work';
        case 'Personal':
          return note.folder == 'Personal';
        case 'Pinned':
          return note.isPinned;
        case 'Reminders':
          return note.hasReminder;
        case 'All':
        default:
          // Check tag filter
          if (_selectedTag != null) {
            return note.tags.contains(_selectedTag);
          }
          return true;
      }
    }).toList();

    // Sort: pinned first, then by updatedAt (most recent first)
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }

  /// Get available filter options with counts
  Map<String, int> get filterCounts {
    return {
      'All': _notes.length,
      'Work': _notes.where((n) => n.folder == 'Work').length,
      'Personal': _notes.where((n) => n.folder == 'Personal').length,
      'Pinned': _notes.where((n) => n.isPinned).length,
      'Reminders': _notes.where((n) => n.hasReminder).length,
    };
  }

  /// Get available tags
  List<String> get availableTags => List.unmodifiable(_availableTags);

  /// Get selected filter
  String get selectedFilter => _selectedFilter;

  /// Get selected tag
  String? get selectedTag => _selectedTag;

  /// Get search query
  String get searchQuery => _searchQuery;

  /// Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    _selectedTag = null; // Clear tag filter when changing main filter
    notifyListeners();
  }

  /// Set tag filter
  void setTagFilter(String? tag) {
    _selectedTag = tag;
    _selectedFilter = 'All'; // Reset main filter when using tag filter
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Toggle pin status of a note
  void togglePin(int noteId) {
    try {
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = _notes[index].copyWith(
          isPinned: !_notes[index].isPinned,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to toggle pin for note $noteId: $e');
    }
  }

  /// Delete a note
  void deleteNote(int noteId) {
    try {
      final removed = _notes.removeWhere((note) => note.id == noteId);
      if (removed > 0) {
        _updateAvailableTags();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to delete note $noteId: $e');
    }
  }

  /// Duplicate a note
  void duplicateNote(int noteId) {
    try {
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        final original = _notes[index];
        final duplicate = original.copyWith(
          id: DateTime.now().millisecondsSinceEpoch,
          title: '${original.title} (Copy)',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isPinned: false, // Duplicates are not pinned by default
        );
        _notes.insert(index + 1, duplicate);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to duplicate note $noteId: $e');
    }
  }

  /// Add or remove tag from note
  void updateNoteTags(int noteId, List<String> newTags) {
    try {
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = _notes[index].copyWith(
          tags: newTags,
          updatedAt: DateTime.now(),
        );
        _updateAvailableTags();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update tags for note $noteId: $e');
    }
  }

  /// Share a note
  Future<void> shareNote(int noteId) async {
    try {
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex == -1) {
        throw ArgumentError('Note with id $noteId not found');
      }
      
      final note = _notes[noteIndex];
      await Share.share(
        note.shareableContent,
        subject: note.title,
      );
    } catch (e) {
      debugPrint('Share failed for note $noteId: $e');
      rethrow;
    }
  }

  /// Update available tags from all notes
  void _updateAvailableTags() {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    _availableTags = tags.toList()..sort();
  }

  /// Create a new tag
  void createTag(String tag) {
    if (!_availableTags.contains(tag)) {
      _availableTags.add(tag);
      _availableTags.sort();
      notifyListeners();
    }
  }

  /// Get notes by folder
  List<Note> getNotesByFolder(String? folder) {
    return _notes.where((note) => note.folder == folder).toList();
  }

  /// Get pinned notes
  List<Note> get pinnedNotes => _notes.where((note) => note.isPinned).toList();

  /// Get notes with reminders
  List<Note> get notesWithReminders => _notes.where((note) => note.hasReminder).toList();

  /// Get recent notes (last 7 days)
  List<Note> get recentNotes {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _notes.where((note) => note.updatedAt.isAfter(weekAgo)).toList();
  }
}
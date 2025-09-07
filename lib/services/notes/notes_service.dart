import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/note_model.dart';
import '../../repositories/notes_repository.dart';
import '../widget/home_screen_widget_service.dart';

/// Service for managing notes with business logic and caching
class NotesService extends ChangeNotifier {
  final NotesRepository _repository;
  
  List<Note> _notes = [];
  Note? _currentNote;
  bool _isLoading = false;
  String? _error;
  Timer? _autoSaveTimer;
  
  NotesService(this._repository);
  
  // Getters
  List<Note> get notes => List.unmodifiable(_notes);
  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasNotes => _notes.isNotEmpty;
  
  /// Initialize the service
  Future<void> initialize() async {
    await _repository.initialize();
    await loadNotes();
  }
  
  /// Load all notes from repository
  Future<void> loadNotes() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _notes = await _repository.getAllNotes();
      await _updateHomeScreenWidget();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notes: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Create a new note
  Future<Note> createNote({
    String title = '',
    String content = '',
    String folder = 'General',
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _generateNoteId(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      folder: folder,
      tags: tags ?? [],
    );
    
    await saveNote(note);
    return note;
  }
  
  /// Save a note
  Future<void> saveNote(Note note) async {
    _setError(null);
    
    try {
      // Update timestamp
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      
      await _repository.saveNote(updatedNote);
      
      // Update local cache
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _notes[index] = updatedNote;
      } else {
        _notes.insert(0, updatedNote);
      }
      
      // Update current note if it matches
      if (_currentNote?.id == note.id) {
        _currentNote = updatedNote;
      }
      
      // Sort notes by updated date
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // Update home screen widget
      await _updateHomeScreenWidget();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to save note: $e');
      rethrow;
    }
  }
  
  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    _setError(null);
    
    try {
      await _repository.deleteNote(noteId);
      
      // Remove from local cache
      _notes.removeWhere((note) => note.id == noteId);
      
      // Clear current note if it was deleted
      if (_currentNote?.id == noteId) {
        _currentNote = null;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete note: $e');
      rethrow;
    }
  }
  
  /// Get a note by ID
  Future<Note?> getNoteById(String id) async {
    // Check cache first
    final cachedNote = _notes.firstWhere(
      (note) => note.id == id,
      orElse: () => throw StateError('Note not found'),
    );
    
    try {
      return cachedNote;
    } catch (e) {
      // Fall back to repository
      return await _repository.getNoteById(id);
    }
  }
  
  /// Set current note for editing
  void setCurrentNote(Note? note) {
    _currentNote = note;
    notifyListeners();
  }
  
  /// Add image to current note
  Future<void> addImageToCurrentNote(String imagePath) async {
    if (_currentNote == null) return;
    
    // Copy image to app directory
    final appImagePath = await _repository.copyFileToAppDirectory(
      imagePath,
      _currentNote!.id,
      'image',
    );
    
    if (appImagePath != null) {
      final updatedNote = _currentNote!.copyWith(
        imagePaths: [..._currentNote!.imagePaths, appImagePath],
      );
      
      await saveNote(updatedNote);
    }
  }
  
  /// Add attachment to current note
  Future<void> addAttachmentToCurrentNote(String filePath) async {
    if (_currentNote == null) return;
    
    // Copy file to app directory
    final appFilePath = await _repository.copyFileToAppDirectory(
      filePath,
      _currentNote!.id,
      'attachment',
    );
    
    if (appFilePath != null) {
      final updatedNote = _currentNote!.copyWith(
        attachmentPaths: [..._currentNote!.attachmentPaths, appFilePath],
      );
      
      await saveNote(updatedNote);
    }
  }
  
  /// Add voice note to current note
  Future<void> addVoiceNoteToCurrentNote(String voicePath) async {
    if (_currentNote == null) return;
    
    // Copy voice note to app directory
    final appVoicePath = await _repository.copyFileToAppDirectory(
      voicePath,
      _currentNote!.id,
      'voice',
    );
    
    if (appVoicePath != null) {
      final updatedNote = _currentNote!.copyWith(
        voiceNotePaths: [..._currentNote!.voiceNotePaths, appVoicePath],
      );
      
      await saveNote(updatedNote);
    }
  }
  
  /// Remove media from current note
  Future<void> removeMediaFromCurrentNote(String mediaPath, String mediaType) async {
    if (_currentNote == null) return;
    
    Note updatedNote;
    
    switch (mediaType) {
      case 'image':
        final newImages = _currentNote!.imagePaths.where((path) => path != mediaPath).toList();
        updatedNote = _currentNote!.copyWith(imagePaths: newImages);
        break;
      case 'attachment':
        final newAttachments = _currentNote!.attachmentPaths.where((path) => path != mediaPath).toList();
        updatedNote = _currentNote!.copyWith(attachmentPaths: newAttachments);
        break;
      case 'voice':
        final newVoiceNotes = _currentNote!.voiceNotePaths.where((path) => path != mediaPath).toList();
        updatedNote = _currentNote!.copyWith(voiceNotePaths: newVoiceNotes);
        break;
      case 'doodle':
        final newDoodles = _currentNote!.doodlePaths.where((path) => path != mediaPath).toList();
        updatedNote = _currentNote!.copyWith(doodlePaths: newDoodles);
        // Also delete the doodle file
        try {
          await _repository.deleteDoodleData(mediaPath);
        } catch (e) {
          _setError('Failed to delete doodle file: $e');
        }
        break;
      default:
        return;
    }
    
    await saveNote(updatedNote);
  }

  /// Add doodle to current note
  Future<String?> addDoodleToCurrentNote(String doodleJsonData) async {
    if (_currentNote == null) return null;
    
    try {
      // Save doodle JSON data to app directory
      final doodlePath = await _repository.saveDoodleData(
        _currentNote!.id,
        doodleJsonData,
      );
      
      if (doodlePath != null) {
        final updatedNote = _currentNote!.copyWith(
          doodlePaths: [..._currentNote!.doodlePaths, doodlePath],
        );
        
        await saveNote(updatedNote);
        return doodlePath;
      }
    } catch (e) {
      _setError('Failed to save doodle: $e');
    }
    
    return null;
  }

  /// Update existing doodle in current note
  Future<void> updateDoodleInCurrentNote(String doodlePath, String doodleJsonData) async {
    if (_currentNote == null) return;
    
    try {
      await _repository.updateDoodleData(doodlePath, doodleJsonData);
      // Note: No need to update the note model as the path remains the same
    } catch (e) {
      _setError('Failed to update doodle: $e');
    }
  }

  /// Load doodle data from path
  Future<String?> loadDoodleData(String doodlePath) async {
    try {
      return await _repository.loadDoodleData(doodlePath);
    } catch (e) {
      _setError('Failed to load doodle: $e');
      return null;
    }
  }
  
  /// Search notes
  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) return _notes;
    
    try {
      return await _repository.searchNotes(query);
    } catch (e) {
      _setError('Failed to search notes: $e');
      return [];
    }
  }
  
  /// Get notes by folder
  Future<List<Note>> getNotesByFolder(String folder) async {
    try {
      return await _repository.getNotesByFolder(folder);
    } catch (e) {
      _setError('Failed to get notes by folder: $e');
      return [];
    }
  }
  
  /// Get all notes (returns cached notes)
  Future<List<Note>> getAllNotes() async {
    return _notes;
  }
  
  /// Get all folders
  Future<List<String>> getAllFolders() async {
    try {
      return await _repository.getAllFolders();
    } catch (e) {
      _setError('Failed to get folders: $e');
      return [];
    }
  }
  
  /// Get all tags
  Future<List<String>> getAllTags() async {
    try {
      return await _repository.getAllTags();
    } catch (e) {
      _setError('Failed to get tags: $e');
      return [];
    }
  }
  
  /// Start auto-save for current note
  void startAutoSave(Note note, {Duration interval = const Duration(seconds: 30)}) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(interval, (_) {
      if (_currentNote?.id == note.id) {
        saveNote(_currentNote!);
      }
    });
  }
  
  /// Stop auto-save
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }
  
  /// Generate unique note ID
  String _generateNoteId() {
    return 'note_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }
  
  /// Clear error
  void clearError() {
    _setError(null);
  }
  
  /// Get absolute path for relative app path
  String? getAbsolutePath(String relativePath) {
    return _repository.getAbsolutePath(relativePath);
  }
  
  /// Export notes
  Future<Map<String, dynamic>> exportNotes() async {
    try {
      return await _repository.exportNotesAsJson();
    } catch (e) {
      _setError('Failed to export notes: $e');
      rethrow;
    }
  }
  
  /// Import notes
  Future<int> importNotes(Map<String, dynamic> data) async {
    try {
      final importedCount = await _repository.importNotesFromJson(data);
      await loadNotes(); // Refresh cache
      return importedCount;
    } catch (e) {
      _setError('Failed to import notes: $e');
      rethrow;
    }
  }
  
  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      return await _repository.getStorageStats();
    } catch (e) {
      _setError('Failed to get storage stats: $e');
      return {};
    }
  }
  
  /// Update home screen widget with latest note data
  Future<void> _updateHomeScreenWidget() async {
    try {
      if (_notes.isNotEmpty) {
        final recentNote = _notes.first;
        final truncatedContent = recentNote.content.length > 100 
            ? '${recentNote.content.substring(0, 97)}...' 
            : recentNote.content;
            
        await HomeScreenWidgetService().updateWidget(
          recentNoteTitle: recentNote.title.isEmpty ? 'Untitled Note' : recentNote.title,
          recentNoteContent: truncatedContent.isEmpty ? 'Empty note' : truncatedContent,
          totalNotesCount: _notes.length,
        );
      } else {
        await HomeScreenWidgetService().updateWidget(
          recentNoteTitle: 'No notes yet',
          recentNoteContent: 'Create your first note to get started',
          totalNotesCount: 0,
        );
      }
    } catch (e) {
      debugPrint('Failed to update home screen widget: $e');
    }
  }
  
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
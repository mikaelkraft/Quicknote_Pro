import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/note.dart';
import '../../models/attachment.dart';
import '../../repositories/structured_notes_repository.dart';
import 'note_model_adapter.dart';

/// Enhanced notes service for the new structured note models
/// Provides business logic, caching, and integration capabilities
class StructuredNotesService extends ChangeNotifier {
  final StructuredNotesRepository _repository;
  
  List<Note> _notes = [];
  Note? _currentNote;
  bool _isLoading = false;
  String? _error;
  Timer? _autoSaveTimer;
  Map<String, dynamic>? _storageStats;
  
  StructuredNotesService(this._repository);
  
  // Getters
  List<Note> get notes => List.unmodifiable(_notes);
  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasNotes => _notes.isNotEmpty;
  Map<String, dynamic>? get storageStats => _storageStats;
  
  /// Initialize the service
  Future<void> initialize() async {
    await _repository.initialize();
    await loadNotes();
    await _updateStorageStats();
  }
  
  /// Load all notes from repository
  Future<void> loadNotes() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _notes = await _repository.getAllNotes();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notes: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Create a new note with structured attachments
  Future<Note> createNote({
    String title = '',
    String content = '',
    String folder = 'General',
    List<String> tags = const [],
    List<Attachment> attachments = const [],
  }) async {
    try {
      final note = Note(
        id: _generateNoteId(),
        title: title,
        content: content,
        folder: folder,
        tags: List.from(tags),
        attachments: List.from(attachments),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _repository.saveNote(note);
      await loadNotes(); // Refresh list
      await _updateStorageStats();
      
      return note;
    } catch (e) {
      _setError('Failed to create note: $e');
      rethrow;
    }
  }
  
  /// Update an existing note
  Future<Note> updateNote(Note note, {
    String? title,
    String? content,
    String? folder,
    List<String>? tags,
    List<Attachment>? attachments,
  }) async {
    try {
      final updatedNote = note.copyWith(
        title: title,
        content: content,
        folder: folder,
        tags: tags,
        attachments: attachments,
        updatedAt: DateTime.now(),
      );
      
      await _repository.saveNote(updatedNote);
      
      if (_currentNote?.id == note.id) {
        _currentNote = updatedNote;
      }
      
      await loadNotes(); // Refresh list
      await _updateStorageStats();
      
      return updatedNote;
    } catch (e) {
      _setError('Failed to update note: $e');
      rethrow;
    }
  }
  
  /// Delete a note and clean up attachments
  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
      
      if (_currentNote?.id == noteId) {
        _currentNote = null;
      }
      
      await loadNotes(); // Refresh list
      await _updateStorageStats();
    } catch (e) {
      _setError('Failed to delete note: $e');
      rethrow;
    }
  }
  
  /// Get note by ID
  Future<Note?> getNoteById(String id) async {
    try {
      return await _repository.getNoteById(id);
    } catch (e) {
      _setError('Failed to get note: $e');
      return null;
    }
  }
  
  /// Set current note for editing
  void setCurrentNote(Note? note) {
    _currentNote = note;
    notifyListeners();
  }
  
  /// Add attachment to a note
  Future<Note> addAttachmentToNote(String noteId, Attachment attachment, String sourceFilePath) async {
    try {
      final note = await _repository.getNoteById(noteId);
      if (note == null) {
        throw Exception('Note not found');
      }
      
      // Save the attachment file
      final savedAttachment = await _repository.saveAttachment(attachment, sourceFilePath);
      
      // Update note with the new attachment
      final updatedNote = note.addAttachment(savedAttachment);
      await _repository.saveNote(updatedNote);
      
      if (_currentNote?.id == noteId) {
        _currentNote = updatedNote;
      }
      
      await loadNotes();
      await _updateStorageStats();
      
      return updatedNote;
    } catch (e) {
      _setError('Failed to add attachment: $e');
      rethrow;
    }
  }
  
  /// Remove attachment from a note
  Future<Note> removeAttachmentFromNote(String noteId, String attachmentId) async {
    try {
      final note = await _repository.getNoteById(noteId);
      if (note == null) {
        throw Exception('Note not found');
      }
      
      // Find the attachment to delete
      final attachment = note.attachments.firstWhere(
        (a) => a.id == attachmentId,
        orElse: () => throw Exception('Attachment not found'),
      );
      
      // Remove from note
      final updatedNote = note.removeAttachment(attachmentId);
      await _repository.saveNote(updatedNote);
      
      // Delete the file
      await _repository.deleteAttachment(attachment);
      
      if (_currentNote?.id == noteId) {
        _currentNote = updatedNote;
      }
      
      await loadNotes();
      await _updateStorageStats();
      
      return updatedNote;
    } catch (e) {
      _setError('Failed to remove attachment: $e');
      rethrow;
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
  
  /// Get notes by tag
  Future<List<Note>> getNotesByTag(String tag) async {
    try {
      return await _repository.getNotesByTag(tag);
    } catch (e) {
      _setError('Failed to get notes by tag: $e');
      return [];
    }
  }
  
  /// Search notes
  Future<List<Note>> searchNotes(String query) async {
    try {
      return await _repository.searchNotes(query);
    } catch (e) {
      _setError('Failed to search notes: $e');
      return [];
    }
  }
  
  /// Get all folders
  List<String> getAllFolders() {
    final folders = <String>{};
    for (final note in _notes) {
      folders.add(note.folder);
    }
    return folders.toList()..sort();
  }
  
  /// Get all tags
  List<String> getAllTags() {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }
  
  /// Add tag to note
  Future<Note> addTagToNote(String noteId, String tag) async {
    try {
      final note = await _repository.getNoteById(noteId);
      if (note == null) {
        throw Exception('Note not found');
      }
      
      final updatedNote = note.addTag(tag);
      await _repository.saveNote(updatedNote);
      
      if (_currentNote?.id == noteId) {
        _currentNote = updatedNote;
      }
      
      await loadNotes();
      return updatedNote;
    } catch (e) {
      _setError('Failed to add tag: $e');
      rethrow;
    }
  }
  
  /// Remove tag from note
  Future<Note> removeTagFromNote(String noteId, String tag) async {
    try {
      final note = await _repository.getNoteById(noteId);
      if (note == null) {
        throw Exception('Note not found');
      }
      
      final updatedNote = note.removeTag(tag);
      await _repository.saveNote(updatedNote);
      
      if (_currentNote?.id == noteId) {
        _currentNote = updatedNote;
      }
      
      await loadNotes();
      return updatedNote;
    } catch (e) {
      _setError('Failed to remove tag: $e');
      rethrow;
    }
  }
  
  /// Move note to folder
  Future<Note> moveNoteToFolder(String noteId, String folder) async {
    try {
      final note = await _repository.getNoteById(noteId);
      if (note == null) {
        throw Exception('Note not found');
      }
      
      final updatedNote = note.updateFolder(folder);
      await _repository.saveNote(updatedNote);
      
      if (_currentNote?.id == noteId) {
        _currentNote = updatedNote;
      }
      
      await loadNotes();
      return updatedNote;
    } catch (e) {
      _setError('Failed to move note: $e');
      rethrow;
    }
  }
  
  /// Auto-save current note
  void startAutoSave(Note note) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () async {
      try {
        await _repository.saveNote(note);
        await _updateStorageStats();
      } catch (e) {
        _setError('Auto-save failed: $e');
      }
    });
  }
  
  /// Stop auto-save
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }
  
  /// Export notes as backup
  Future<Map<String, dynamic>> exportNotes() async {
    try {
      return await _repository.exportNotes();
    } catch (e) {
      _setError('Failed to export notes: $e');
      rethrow;
    }
  }
  
  /// Import notes from backup
  Future<void> importNotes(Map<String, dynamic> backup, {bool overwrite = false}) async {
    try {
      await _repository.importNotes(backup, overwrite: overwrite);
      await loadNotes();
      await _updateStorageStats();
    } catch (e) {
      _setError('Failed to import notes: $e');
      rethrow;
    }
  }
  
  /// Convert from old note model for migration
  Future<Note> migrateFromOldNote(dynamic oldNote) async {
    try {
      final newNote = NoteModelAdapter.fromOldNote(oldNote);
      await _repository.saveNote(newNote);
      await loadNotes();
      await _updateStorageStats();
      return newNote;
    } catch (e) {
      _setError('Failed to migrate note: $e');
      rethrow;
    }
  }
  
  /// Get attachment file path
  String getAttachmentFilePath(Attachment attachment) {
    return _repository.getAttachmentFilePath(attachment);
  }
  
  /// Check if attachment file exists
  Future<bool> attachmentExists(Attachment attachment) async {
    return await _repository.attachmentExists(attachment);
  }
  
  /// Update storage statistics
  Future<void> _updateStorageStats() async {
    try {
      _storageStats = await _repository.getStorageStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update storage stats: $e');
    }
  }
  
  /// Generate unique note ID
  String _generateNoteId() {
    return 'note_${DateTime.now().millisecondsSinceEpoch}_${_notes.length}';
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
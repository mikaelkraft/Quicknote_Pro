import 'package:quicknote_pro/repositories/notes_repository.dart';
import 'package:quicknote_pro/models/note_model.dart';

/// Mock implementation of NotesRepository for testing
class MockNotesRepository extends NotesRepository {
  final List<Note> savedNotes = [];
  final List<String> deletedNoteIds = [];
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Future<void> initialize() async {
    // Mock initialization - no actual setup needed
  }

  @override
  Future<List<Note>> getAllNotes() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    return List.from(savedNotes);
  }

  @override
  Future<Note?> getNoteById(String id) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    try {
      return savedNotes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveNote(Note note) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    // Remove existing note with same ID
    savedNotes.removeWhere((existingNote) => existingNote.id == note.id);
    
    // Add the new/updated note
    savedNotes.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    savedNotes.removeWhere((note) => note.id == id);
    deletedNoteIds.add(id);
  }

  @override
  Future<List<Note>> searchNotes(String searchTerm) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    if (searchTerm.isEmpty) return getAllNotes();
    
    final lowerSearchTerm = searchTerm.toLowerCase();
    return savedNotes.where((note) {
      return note.title.toLowerCase().contains(lowerSearchTerm) ||
             note.content.toLowerCase().contains(lowerSearchTerm);
    }).toList();
  }

  @override
  Future<String?> copyFileToAppDirectory(String sourcePath, String noteId, String fileType) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    // Mock file copy - return a fake path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'media/${noteId}_${fileType}_$timestamp.jpg';
  }

  @override
  String? getAbsolutePath(String relativePath) {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    return '/mock/app/directory/$relativePath';
  }

  @override
  Future<bool> fileExists(String relativePath) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    // Mock file existence - assume all files exist
    return true;
  }

  @override
  Future<List<Note>> getNotesByFolder(String folder) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    return savedNotes.where((note) => note.folder == folder).toList();
  }

  @override
  Future<List<String>> getAllFolders() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    return savedNotes.map((note) => note.folder).toSet().toList();
  }

  @override
  Future<List<String>> getAllTags() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    final tags = <String>{};
    for (final note in savedNotes) {
      tags.addAll(note.tags);
    }
    return tags.toList();
  }

  @override
  Future<Map<String, dynamic>> exportNotesAsJson() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    return {
      'export_date': DateTime.now().toIso8601String(),
      'notes_count': savedNotes.length,
      'notes': savedNotes.map((note) => note.toJson()).toList(),
    };
  }

  @override
  Future<int> importNotesFromJson(Map<String, dynamic> jsonData) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    final notesData = jsonData['notes'] as List<dynamic>?;
    if (notesData == null) return 0;
    
    int importedCount = 0;
    for (final noteData in notesData) {
      try {
        final note = Note.fromJson(noteData as Map<String, dynamic>);
        await saveNote(note);
        importedCount++;
      } catch (e) {
        // Skip invalid notes
      }
    }
    
    return importedCount;
  }

  @override
  Future<void> clearAllNotes() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    savedNotes.clear();
    deletedNoteIds.clear();
  }

  @override
  Future<Map<String, dynamic>> getStorageStats() async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    
    return {
      'total_notes': savedNotes.length,
      'total_folders': await getAllFolders().then((folders) => folders.length),
      'total_tags': await getAllTags().then((tags) => tags.length),
      'total_images': savedNotes.fold(0, (sum, note) => sum + note.imagePaths.length),
      'total_attachments': savedNotes.fold(0, (sum, note) => sum + note.attachmentPaths.length),
      'total_voice_notes': savedNotes.fold(0, (sum, note) => sum + note.voiceNotePaths.length),
      'total_characters': savedNotes.fold(0, (sum, note) => sum + note.title.length + note.content.length),
    };
  }

  /// Test helper methods
  void reset() {
    savedNotes.clear();
    deletedNoteIds.clear();
    shouldThrowError = false;
    errorMessage = null;
  }

  void simulateError([String? message]) {
    shouldThrowError = true;
    errorMessage = message;
  }

  void stopSimulatingError() {
    shouldThrowError = false;
    errorMessage = null;
  }
}
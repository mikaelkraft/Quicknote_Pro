import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

/// Repository for managing note persistence using SharedPreferences and file system
class NotesRepository {
  static const String _notesKey = 'notes_data';
  static const String _noteIdsKey = 'note_ids';
  
  SharedPreferences? _prefs;
  Directory? _appDirectory;
  Directory? _notesDirectory;
  Directory? _mediaDirectory;
  
  /// Initialize the repository
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _initializeDirectories();
  }

  /// Initialize app directories for storing notes and media
  Future<void> _initializeDirectories() async {
    _appDirectory = await getApplicationDocumentsDirectory();
    
    // Create notes directory
    _notesDirectory = Directory('${_appDirectory!.path}/notes');
    if (!await _notesDirectory!.exists()) {
      await _notesDirectory!.create(recursive: true);
    }
    
    // Create media directory for attachments
    _mediaDirectory = Directory('${_appDirectory!.path}/media');
    if (!await _mediaDirectory!.exists()) {
      await _mediaDirectory!.create(recursive: true);
    }
  }

  /// Get all note IDs
  List<String> _getNoteIds() {
    return _prefs?.getStringList(_noteIdsKey) ?? [];
  }

  /// Save note IDs
  Future<void> _saveNoteIds(List<String> ids) async {
    await _prefs?.setStringList(_noteIdsKey, ids);
  }

  /// Get all notes
  Future<List<Note>> getAllNotes() async {
    final noteIds = _getNoteIds();
    final notes = <Note>[];
    
    for (final id in noteIds) {
      final note = await getNoteById(id);
      if (note != null) {
        notes.add(note);
      }
    }
    
    // Sort by updated date (most recent first)
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  /// Get note by ID
  Future<Note?> getNoteById(String id) async {
    final noteJson = _prefs?.getString('note_$id');
    if (noteJson != null) {
      try {
        return Note.fromJsonString(noteJson);
      } catch (e) {
        // Remove corrupted note data
        await deleteNote(id);
        return null;
      }
    }
    return null;
  }

  /// Save or update a note
  Future<void> saveNote(Note note) async {
    final noteIds = _getNoteIds();
    
    // Add ID to list if it's a new note
    if (!noteIds.contains(note.id)) {
      noteIds.add(note.id);
      await _saveNoteIds(noteIds);
    }
    
    // Save note data
    await _prefs?.setString('note_${note.id}', note.toJsonString());
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    // Remove from note IDs list
    final noteIds = _getNoteIds();
    noteIds.remove(id);
    await _saveNoteIds(noteIds);
    
    // Remove note data
    await _prefs?.remove('note_$id');
    
    // Clean up associated media files
    await _cleanupNoteMedia(id);
  }

  /// Clean up media files associated with a note
  Future<void> _cleanupNoteMedia(String noteId) async {
    try {
      if (_mediaDirectory != null && await _mediaDirectory!.exists()) {
        final files = await _mediaDirectory!.list().toList();
        for (final file in files) {
          if (file is File && file.path.contains(noteId)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Log error but don't throw - deletion should not fail due to media cleanup
      print('Error cleaning up media for note $noteId: $e');
    }
  }

  /// Copy a file to app media directory with unique name
  Future<String?> copyFileToAppDirectory(String sourcePath, String noteId, String fileType) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }
      
      await _initializeDirectories();
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = sourcePath.split('.').last;
      final fileName = '${noteId}_${fileType}_$timestamp.$extension';
      final targetPath = '${_mediaDirectory!.path}/$fileName';
      
      // Copy file
      await sourceFile.copy(targetPath);
      
      // Return relative path from app directory
      return 'media/$fileName';
    } catch (e) {
      print('Error copying file to app directory: $e');
      return null;
    }
  }

  /// Get absolute path for a relative app path
  String? getAbsolutePath(String relativePath) {
    if (_appDirectory == null) return null;
    return '${_appDirectory!.path}/$relativePath';
  }

  /// Check if a file exists in app storage
  Future<bool> fileExists(String relativePath) async {
    final absolutePath = getAbsolutePath(relativePath);
    if (absolutePath == null) return false;
    return await File(absolutePath).exists();
  }

  /// Get notes by folder
  Future<List<Note>> getNotesByFolder(String folder) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.folder == folder).toList();
  }

  /// Get notes containing search term
  Future<List<Note>> searchNotes(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return getAllNotes();
    
    final allNotes = await getAllNotes();
    final lowerSearchTerm = searchTerm.toLowerCase();
    
    return allNotes.where((note) {
      return note.title.toLowerCase().contains(lowerSearchTerm) ||
             note.content.toLowerCase().contains(lowerSearchTerm) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowerSearchTerm));
    }).toList();
  }

  /// Get all unique folders
  Future<List<String>> getAllFolders() async {
    final allNotes = await getAllNotes();
    final folders = allNotes.map((note) => note.folder).toSet().toList();
    folders.sort();
    return folders;
  }

  /// Get all unique tags
  Future<List<String>> getAllTags() async {
    final allNotes = await getAllNotes();
    final tags = <String>{};
    for (final note in allNotes) {
      tags.addAll(note.tags);
    }
    final tagList = tags.toList();
    tagList.sort();
    return tagList;
  }

  /// Export all notes as JSON
  Future<Map<String, dynamic>> exportNotesAsJson() async {
    final allNotes = await getAllNotes();
    return {
      'export_date': DateTime.now().toIso8601String(),
      'notes_count': allNotes.length,
      'notes': allNotes.map((note) => note.toJson()).toList(),
    };
  }

  /// Import notes from JSON (merges with existing notes)
  Future<int> importNotesFromJson(Map<String, dynamic> jsonData) async {
    final notesData = jsonData['notes'] as List<dynamic>?;
    if (notesData == null) return 0;
    
    int importedCount = 0;
    for (final noteData in notesData) {
      try {
        final note = Note.fromJson(noteData as Map<String, dynamic>);
        await saveNote(note);
        importedCount++;
      } catch (e) {
        print('Error importing note: $e');
      }
    }
    
    return importedCount;
  }

  /// Clear all notes (for testing or reset)
  Future<void> clearAllNotes() async {
    final noteIds = _getNoteIds();
    
    // Remove all note data
    for (final id in noteIds) {
      await _prefs?.remove('note_$id');
      await _cleanupNoteMedia(id);
    }
    
    // Clear note IDs list
    await _prefs?.remove(_noteIdsKey);
  }

  /// Save doodle data to app directory
  Future<String?> saveDoodleData(String noteId, String doodleJsonData) async {
    try {
      await _initializeDirectories();
      
      // Create doodles subdirectory if it doesn't exist
      final doodlesDirectory = Directory('${_mediaDirectory!.path}/doodles');
      if (!await doodlesDirectory.exists()) {
        await doodlesDirectory.create(recursive: true);
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${noteId}_doodle_$timestamp.json';
      final filePath = '${doodlesDirectory.path}/$fileName';
      
      // Write doodle data to file
      final file = File(filePath);
      await file.writeAsString(doodleJsonData);
      
      // Return relative path from app directory
      return 'media/doodles/$fileName';
    } catch (e) {
      print('Error saving doodle data: $e');
      return null;
    }
  }

  /// Update existing doodle data
  Future<void> updateDoodleData(String doodlePath, String doodleJsonData) async {
    try {
      final absolutePath = getAbsolutePath(doodlePath);
      if (absolutePath == null) {
        throw Exception('Invalid doodle path: $doodlePath');
      }
      
      final file = File(absolutePath);
      await file.writeAsString(doodleJsonData);
    } catch (e) {
      print('Error updating doodle data: $e');
      rethrow;
    }
  }

  /// Load doodle data from file
  Future<String?> loadDoodleData(String doodlePath) async {
    try {
      final absolutePath = getAbsolutePath(doodlePath);
      if (absolutePath == null) return null;
      
      final file = File(absolutePath);
      if (!await file.exists()) return null;
      
      return await file.readAsString();
    } catch (e) {
      print('Error loading doodle data: $e');
      return null;
    }
  }

  /// Delete doodle data file
  Future<void> deleteDoodleData(String doodlePath) async {
    try {
      final absolutePath = getAbsolutePath(doodlePath);
      if (absolutePath == null) return;
      
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting doodle data: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final allNotes = await getAllNotes();
    final folders = await getAllFolders();
    final tags = await getAllTags();
    
    int totalImages = 0;
    int totalAttachments = 0;
    int totalVoiceNotes = 0;
    int totalDoodles = 0;
    int totalCharacters = 0;
    
    for (final note in allNotes) {
      totalImages += note.imagePaths.length;
      totalAttachments += note.attachmentPaths.length;
      totalVoiceNotes += note.voiceNotePaths.length;
      totalDoodles += note.doodlePaths.length;
      totalCharacters += note.title.length + note.content.length;
    }
    
    return {
      'total_notes': allNotes.length,
      'total_folders': folders.length,
      'total_tags': tags.length,
      'total_images': totalImages,
      'total_attachments': totalAttachments,
      'total_voice_notes': totalVoiceNotes,
      'total_doodles': totalDoodles,
      'total_characters': totalCharacters,
    };
  }
}
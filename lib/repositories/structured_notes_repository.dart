import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/note.dart';
import '../../models/attachment.dart';

/// Enhanced repository for the new structured note and attachment models
/// Provides local storage, backup, and file management capabilities
class StructuredNotesRepository {
  static const String _notesKey = 'structured_notes_data';
  static const String _noteIdsKey = 'structured_note_ids';
  static const String _metadataKey = 'structured_notes_metadata';
  
  SharedPreferences? _prefs;
  Directory? _appDirectory;
  Directory? _notesDirectory;
  Directory? _attachmentsDirectory;
  
  /// Initialize the repository and set up directory structure
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _initializeDirectories();
  }
  
  /// Initialize app directories for storing notes and attachments
  Future<void> _initializeDirectories() async {
    _appDirectory = await getApplicationDocumentsDirectory();
    
    // Create notes directory
    _notesDirectory = Directory('${_appDirectory!.path}/structured_notes');
    if (!await _notesDirectory!.exists()) {
      await _notesDirectory!.create(recursive: true);
    }
    
    // Create attachments directory with subdirectories
    _attachmentsDirectory = Directory('${_appDirectory!.path}/attachments');
    if (!await _attachmentsDirectory!.exists()) {
      await _attachmentsDirectory!.create(recursive: true);
    }
    
    // Create subdirectories for different attachment types
    final subdirs = ['images', 'files', 'voice'];
    for (final subdir in subdirs) {
      final dir = Directory('${_attachmentsDirectory!.path}/$subdir');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
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
  
  /// Get all notes with full attachment metadata
  Future<List<Note>> getAllNotes() async {
    try {
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
    } catch (e) {
      throw Exception('Failed to load notes: $e');
    }
  }
  
  /// Get note by ID with attachment validation
  Future<Note?> getNoteById(String id) async {
    try {
      final noteFile = File('${_notesDirectory!.path}/$id.json');
      if (!await noteFile.exists()) {
        return null;
      }
      
      final jsonString = await noteFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final note = Note.fromJson(json);
      
      // Validate and update attachment file information
      final validatedAttachments = await _validateAttachments(note.attachments);
      
      if (validatedAttachments.length != note.attachments.length) {
        // Some attachments were invalid, update the note
        final updatedNote = note.copyWith(attachments: validatedAttachments);
        await saveNote(updatedNote);
        return updatedNote;
      }
      
      return note;
    } catch (e) {
      throw Exception('Failed to load note $id: $e');
    }
  }
  
  /// Validate attachments and update file size/metadata
  Future<List<Attachment>> _validateAttachments(List<Attachment> attachments) async {
    final validAttachments = <Attachment>[];
    
    for (final attachment in attachments) {
      final filePath = '${_attachmentsDirectory!.path}/${attachment.relativePath}';
      final file = File(filePath);
      
      if (await file.exists()) {
        // Update file size if not available
        final stat = await file.stat();
        final updatedAttachment = attachment.copyWith(
          sizeBytes: attachment.sizeBytes ?? stat.size,
        );
        validAttachments.add(updatedAttachment);
      }
      // Skip non-existent files
    }
    
    return validAttachments;
  }
  
  /// Save note with attachment management
  Future<void> saveNote(Note note) async {
    try {
      final noteFile = File('${_notesDirectory!.path}/${note.id}.json');
      await noteFile.writeAsString(note.toJsonString());
      
      // Update note IDs list
      final noteIds = _getNoteIds();
      if (!noteIds.contains(note.id)) {
        noteIds.add(note.id);
        await _saveNoteIds(noteIds);
      }
      
      // Update metadata
      await _updateMetadata();
    } catch (e) {
      throw Exception('Failed to save note ${note.id}: $e');
    }
  }
  
  /// Delete note and clean up orphaned attachments
  Future<void> deleteNote(String id) async {
    try {
      final note = await getNoteById(id);
      if (note == null) return;
      
      // Delete note file
      final noteFile = File('${_notesDirectory!.path}/$id.json');
      if (await noteFile.exists()) {
        await noteFile.delete();
      }
      
      // Remove from IDs list
      final noteIds = _getNoteIds();
      noteIds.remove(id);
      await _saveNoteIds(noteIds);
      
      // Clean up orphaned attachments
      await _cleanupOrphanedAttachments(note.attachments);
      
      // Update metadata
      await _updateMetadata();
    } catch (e) {
      throw Exception('Failed to delete note $id: $e');
    }
  }
  
  /// Copy attachment file and return updated attachment
  Future<Attachment> saveAttachment(Attachment attachment, String sourceFilePath) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourceFilePath');
      }
      
      // Determine target directory based on attachment type
      String subdir;
      switch (attachment.type) {
        case AttachmentType.image:
          subdir = 'images';
          break;
        case AttachmentType.voice:
          subdir = 'voice';
          break;
        case AttachmentType.file:
        default:
          subdir = 'files';
          break;
      }
      
      final targetPath = '$subdir/${attachment.name}';
      final targetFile = File('${_attachmentsDirectory!.path}/$targetPath');
      
      // Ensure target directory exists
      await targetFile.parent.create(recursive: true);
      
      // Copy file
      await sourceFile.copy(targetFile.path);
      
      // Get file statistics
      final stat = await targetFile.stat();
      
      return attachment.copyWith(
        relativePath: targetPath,
        sizeBytes: stat.size,
      );
    } catch (e) {
      throw Exception('Failed to save attachment ${attachment.id}: $e');
    }
  }
  
  /// Get attachment file path
  String getAttachmentFilePath(Attachment attachment) {
    return '${_attachmentsDirectory!.path}/${attachment.relativePath}';
  }
  
  /// Check if attachment file exists
  Future<bool> attachmentExists(Attachment attachment) async {
    final file = File(getAttachmentFilePath(attachment));
    return await file.exists();
  }
  
  /// Delete attachment file
  Future<void> deleteAttachment(Attachment attachment) async {
    try {
      final file = File(getAttachmentFilePath(attachment));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete attachment ${attachment.id}: $e');
    }
  }
  
  /// Clean up orphaned attachment files
  Future<void> _cleanupOrphanedAttachments(List<Attachment> attachmentsToCheck) async {
    // Get all notes to check which attachments are still in use
    final allNotes = await getAllNotes();
    final usedAttachmentPaths = <String>{};
    
    for (final note in allNotes) {
      for (final attachment in note.attachments) {
        usedAttachmentPaths.add(attachment.relativePath);
      }
    }
    
    // Delete attachments that are no longer used
    for (final attachment in attachmentsToCheck) {
      if (!usedAttachmentPaths.contains(attachment.relativePath)) {
        await deleteAttachment(attachment);
      }
    }
  }
  
  /// Get notes by folder
  Future<List<Note>> getNotesByFolder(String folder) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.folder == folder).toList();
  }
  
  /// Get notes by tag
  Future<List<Note>> getNotesByTag(String tag) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.hasTag(tag)).toList();
  }
  
  /// Search notes by content, title, or tags
  Future<List<Note>> searchNotes(String query) async {
    final allNotes = await getAllNotes();
    final lowerQuery = query.toLowerCase();
    
    return allNotes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
             note.content.toLowerCase().contains(lowerQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final metadata = await _getMetadata();
    final allNotes = await getAllNotes();
    
    int totalAttachments = 0;
    int totalSize = 0;
    int imageCount = 0;
    int fileCount = 0;
    int voiceCount = 0;
    
    for (final note in allNotes) {
      totalAttachments += note.attachments.length;
      totalSize += note.totalAttachmentSize;
      imageCount += note.imageAttachments.length;
      fileCount += note.fileAttachments.length;
      voiceCount += note.voiceAttachments.length;
    }
    
    return {
      'totalNotes': allNotes.length,
      'totalAttachments': totalAttachments,
      'totalSizeBytes': totalSize,
      'imageCount': imageCount,
      'fileCount': fileCount,
      'voiceCount': voiceCount,
      'lastBackup': metadata['lastBackup'],
      'repositoryVersion': metadata['version'] ?? '1.0.0',
    };
  }
  
  /// Export notes as JSON for backup
  Future<Map<String, dynamic>> exportNotes() async {
    final allNotes = await getAllNotes();
    final stats = await getStorageStats();
    
    return {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'statistics': stats,
      'notes': allNotes.map((note) => note.toJson()).toList(),
    };
  }
  
  /// Import notes from JSON backup
  Future<void> importNotes(Map<String, dynamic> backup, {bool overwrite = false}) async {
    try {
      final notes = (backup['notes'] as List<dynamic>)
          .map((noteJson) => Note.fromJson(noteJson as Map<String, dynamic>))
          .toList();
      
      for (final note in notes) {
        if (!overwrite) {
          final existing = await getNoteById(note.id);
          if (existing != null) {
            continue; // Skip existing notes
          }
        }
        await saveNote(note);
      }
      
      await _updateMetadata();
    } catch (e) {
      throw Exception('Failed to import notes: $e');
    }
  }
  
  /// Update repository metadata
  Future<void> _updateMetadata() async {
    final metadata = {
      'version': '1.0.0',
      'lastUpdated': DateTime.now().toIso8601String(),
      'totalNotes': _getNoteIds().length,
    };
    
    await _prefs?.setString(_metadataKey, jsonEncode(metadata));
  }
  
  /// Get repository metadata
  Future<Map<String, dynamic>> _getMetadata() async {
    final metadataString = _prefs?.getString(_metadataKey);
    if (metadataString == null) {
      return {
        'version': '1.0.0',
        'lastUpdated': DateTime.now().toIso8601String(),
        'totalNotes': 0,
      };
    }
    
    return jsonDecode(metadataString) as Map<String, dynamic>;
  }
  
  /// Clear all notes and attachments (for testing/reset)
  Future<void> clearAll() async {
    try {
      // Delete all note files
      if (await _notesDirectory!.exists()) {
        await _notesDirectory!.delete(recursive: true);
        await _notesDirectory!.create(recursive: true);
      }
      
      // Delete all attachment files
      if (await _attachmentsDirectory!.exists()) {
        await _attachmentsDirectory!.delete(recursive: true);
        await _initializeDirectories();
      }
      
      // Clear preferences
      await _prefs?.remove(_noteIdsKey);
      await _prefs?.remove(_metadataKey);
      
    } catch (e) {
      throw Exception('Failed to clear repository: $e');
    }
  }
}
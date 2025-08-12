import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

/// Result of an import operation with summary statistics.
class ImportResult {
  final int notesCreated;
  final int notesUpdated;
  final int notesSkipped;
  final int mediaFilesImported;
  final List<String> errors;
  final List<String> warnings;

  ImportResult({
    required this.notesCreated,
    required this.notesUpdated,
    required this.notesSkipped,
    required this.mediaFilesImported,
    required this.errors,
    required this.warnings,
  });

  /// Get a human-readable summary of the import operation.
  String getSummary() {
    final parts = <String>[];
    
    if (notesCreated > 0) parts.add('Created $notesCreated notes');
    if (notesUpdated > 0) parts.add('Updated $notesUpdated notes');
    if (notesSkipped > 0) parts.add('Skipped $notesSkipped notes');
    if (mediaFilesImported > 0) parts.add('Imported $mediaFilesImported media files');
    
    if (parts.isEmpty) {
      return 'No changes made';
    }
    
    String summary = parts.join(', ');
    
    if (warnings.isNotEmpty) {
      summary += '\n${warnings.length} warnings';
    }
    
    if (errors.isNotEmpty) {
      summary += '\n${errors.length} errors';
    }
    
    return summary;
  }
}

/// Service for importing notes and media from backup files.
/// 
/// Supports importing from ZIP archives or JSON files with merge strategies.
class ImportService {
  static const String _notesFileName = 'notes.json';
  static const String _mediaDirectoryName = 'media';

  /// Import notes from a ZIP backup file.
  /// 
  /// [filePath] - Path to the ZIP file to import
  /// [importAsCopies] - If true, create new IDs for all notes to avoid conflicts
  /// [mergeStrategy] - How to handle conflicts ('lastWriteWins', 'skipOlder', 'importAsCopies')
  Future<ImportResult> importFromZip({
    required String filePath,
    bool importAsCopies = false,
    String mergeStrategy = 'lastWriteWins',
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    try {
      // Read and extract ZIP file
      final zipFile = File(filePath);
      if (!await zipFile.exists()) {
        errors.add('Backup file not found');
        return ImportResult(
          notesCreated: 0,
          notesUpdated: 0,
          notesSkipped: 0,
          mediaFilesImported: 0,
          errors: errors,
          warnings: warnings,
        );
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find and extract notes.json
      List<Map<String, dynamic>> importedNotes = [];
      ArchiveFile? notesFile;
      
      for (final file in archive) {
        if (file.name == _notesFileName) {
          notesFile = file;
          break;
        }
      }
      
      if (notesFile == null) {
        errors.add('Notes data file not found in backup');
        return ImportResult(
          notesCreated: 0,
          notesUpdated: 0,
          notesSkipped: 0,
          mediaFilesImported: 0,
          errors: errors,
          warnings: warnings,
        );
      }
      
      // Parse notes JSON
      try {
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final notesData = jsonDecode(notesContent);
        
        if (notesData is List) {
          importedNotes = notesData.cast<Map<String, dynamic>>();
        } else {
          errors.add('Invalid notes data format');
          return ImportResult(
            notesCreated: 0,
            notesUpdated: 0,
            notesSkipped: 0,
            mediaFilesImported: 0,
            errors: errors,
            warnings: warnings,
          );
        }
      } catch (e) {
        errors.add('Failed to parse notes data: $e');
        return ImportResult(
          notesCreated: 0,
          notesUpdated: 0,
          notesSkipped: 0,
          mediaFilesImported: 0,
          errors: errors,
          warnings: warnings,
        );
      }
      
      // Extract and save media files
      final mediaFilesImported = await _extractMediaFiles(archive, warnings);
      
      // Import notes with merge strategy
      final notesResult = await _importNotes(
        importedNotes, 
        importAsCopies: importAsCopies,
        mergeStrategy: mergeStrategy,
        warnings: warnings,
      );
      
      return ImportResult(
        notesCreated: notesResult['created'] ?? 0,
        notesUpdated: notesResult['updated'] ?? 0,
        notesSkipped: notesResult['skipped'] ?? 0,
        mediaFilesImported: mediaFilesImported,
        errors: errors,
        warnings: warnings,
      );
      
    } catch (e) {
      errors.add('Failed to import backup: $e');
      return ImportResult(
        notesCreated: 0,
        notesUpdated: 0,
        notesSkipped: 0,
        mediaFilesImported: 0,
        errors: errors,
        warnings: warnings,
      );
    }
  }

  /// Import notes from a JSON file (notes only, no media).
  Future<ImportResult> importFromJson({
    required String filePath,
    bool importAsCopies = false,
    String mergeStrategy = 'lastWriteWins',
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    try {
      final jsonFile = File(filePath);
      if (!await jsonFile.exists()) {
        errors.add('JSON file not found');
        return ImportResult(
          notesCreated: 0,
          notesUpdated: 0,
          notesSkipped: 0,
          mediaFilesImported: 0,
          errors: errors,
          warnings: warnings,
        );
      }

      final jsonContent = await jsonFile.readAsString();
      final jsonData = jsonDecode(jsonContent);
      
      List<Map<String, dynamic>> importedNotes = [];
      
      if (jsonData is List) {
        importedNotes = jsonData.cast<Map<String, dynamic>>();
      } else if (jsonData is Map) {
        // Single note JSON
        importedNotes = [jsonData.cast<String, dynamic>()];
      } else {
        errors.add('Invalid JSON format');
        return ImportResult(
          notesCreated: 0,
          notesUpdated: 0,
          notesSkipped: 0,
          mediaFilesImported: 0,
          errors: errors,
          warnings: warnings,
        );
      }
      
      // Check for missing media references
      for (final note in importedNotes) {
        final images = note['images'] as List<dynamic>? ?? [];
        final voiceNotes = note['voiceNotes'] as List<dynamic>? ?? [];
        
        if (images.isNotEmpty || voiceNotes.isNotEmpty) {
          warnings.add('Note "${note['title']}" references media files that are not included in JSON import');
        }
      }
      
      final notesResult = await _importNotes(
        importedNotes,
        importAsCopies: importAsCopies,
        mergeStrategy: mergeStrategy,
        warnings: warnings,
      );
      
      return ImportResult(
        notesCreated: notesResult['created'] ?? 0,
        notesUpdated: notesResult['updated'] ?? 0,
        notesSkipped: notesResult['skipped'] ?? 0,
        mediaFilesImported: 0,
        errors: errors,
        warnings: warnings,
      );
      
    } catch (e) {
      errors.add('Failed to import JSON: $e');
      return ImportResult(
        notesCreated: 0,
        notesUpdated: 0,
        notesSkipped: 0,
        mediaFilesImported: 0,
        errors: errors,
        warnings: warnings,
      );
    }
  }

  /// Extract media files from archive to app media directory.
  Future<int> _extractMediaFiles(Archive archive, List<String> warnings) async {
    int mediaFilesImported = 0;
    
    try {
      // Get app documents directory for media storage
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');
      
      // Create media directory if it doesn't exist
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      
      // Extract media files
      for (final file in archive) {
        if (file.name.startsWith('$_mediaDirectoryName/') && file.isFile) {
          try {
            final fileName = file.name.substring(_mediaDirectoryName.length + 1);
            final mediaFile = File('${mediaDir.path}/$fileName');
            
            await mediaFile.writeAsBytes(file.content as List<int>);
            mediaFilesImported++;
          } catch (e) {
            warnings.add('Failed to extract media file ${file.name}: $e');
          }
        }
      }
    } catch (e) {
      warnings.add('Failed to extract media files: $e');
    }
    
    return mediaFilesImported;
  }

  /// Import notes with the specified merge strategy.
  Future<Map<String, int>> _importNotes(
    List<Map<String, dynamic>> importedNotes, {
    required bool importAsCopies,
    required String mergeStrategy,
    required List<String> warnings,
  }) async {
    int created = 0;
    int updated = 0;
    int skipped = 0;
    
    // Get existing notes (mock implementation)
    final existingNotes = _getExistingNotes();
    final existingNotesMap = {for (var note in existingNotes) note['id']: note};
    
    for (final importedNote in importedNotes) {
      try {
        // Validate note structure
        if (!_validateNoteStructure(importedNote)) {
          warnings.add('Skipping note with invalid structure: ${importedNote['title'] ?? 'Unknown'}');
          skipped++;
          continue;
        }
        
        final noteId = importedNote['id'];
        
        if (importAsCopies) {
          // Always create as new note with new ID
          final newNote = Map<String, dynamic>.from(importedNote);
          newNote['id'] = _generateNewNoteId();
          newNote['createdAt'] = DateTime.now().toIso8601String();
          newNote['updatedAt'] = DateTime.now().toIso8601String();
          
          await _saveNote(newNote);
          created++;
        } else {
          final existingNote = existingNotesMap[noteId];
          
          if (existingNote == null) {
            // New note
            await _saveNote(importedNote);
            created++;
          } else {
            // Handle merge strategy
            if (mergeStrategy == 'lastWriteWins') {
              final importedUpdatedAt = DateTime.tryParse(importedNote['updatedAt'] ?? '');
              final existingUpdatedAt = DateTime.tryParse(existingNote['updatedAt'] ?? '');
              
              if (importedUpdatedAt != null && existingUpdatedAt != null) {
                if (importedUpdatedAt.isAfter(existingUpdatedAt)) {
                  await _saveNote(importedNote);
                  updated++;
                } else {
                  skipped++;
                }
              } else {
                // Unable to compare dates, update anyway
                await _saveNote(importedNote);
                updated++;
              }
            } else if (mergeStrategy == 'skipOlder') {
              skipped++;
            }
          }
        }
      } catch (e) {
        warnings.add('Failed to import note "${importedNote['title'] ?? 'Unknown'}": $e');
        skipped++;
      }
    }
    
    return {
      'created': created,
      'updated': updated,
      'skipped': skipped,
    };
  }

  /// Validate that a note has the required structure.
  bool _validateNoteStructure(Map<String, dynamic> note) {
    // Check required fields
    if (note['id'] == null || note['title'] == null || note['content'] == null) {
      return false;
    }
    
    // Validate date fields if present
    if (note['createdAt'] != null && DateTime.tryParse(note['createdAt']) == null) {
      return false;
    }
    
    if (note['updatedAt'] != null && DateTime.tryParse(note['updatedAt']) == null) {
      return false;
    }
    
    return true;
  }

  /// Generate a new unique note ID.
  String _generateNewNoteId() {
    return 'note_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Save a note to storage (mock implementation).
  /// 
  /// In a real implementation, this would save to the actual data storage.
  Future<void> _saveNote(Map<String, dynamic> note) async {
    // Mock implementation - would save to database/storage
    await Future.delayed(const Duration(milliseconds: 10));
    print('Saved note: ${note['title']}');
  }

  /// Get existing notes from storage (mock implementation).
  /// 
  /// In a real implementation, this would fetch from the actual data storage.
  List<Map<String, dynamic>> _getExistingNotes() {
    // Mock implementation - would fetch from database/storage
    return [
      {
        'id': '1',
        'title': 'Existing Note',
        'content': 'This note already exists',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'folder': 'Personal',
        'tags': ['existing'],
        'images': [],
        'voiceNotes': [],
        'pinned': false,
      },
    ];
  }

  /// Validate backup file format and content.
  Future<Map<String, dynamic>> validateBackupFile(String filePath) async {
    final result = {
      'isValid': false,
      'fileType': 'unknown',
      'notesCount': 0,
      'mediaFilesCount': 0,
      'errors': <String>[],
      'warnings': <String>[],
    };

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        result['errors'] = ['File not found'];
        return result;
      }

      final fileName = filePath.split('/').last.toLowerCase();
      
      if (fileName.endsWith('.zip')) {
        result['fileType'] = 'zip';
        
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Check for notes.json
        ArchiveFile? notesFile;
        int mediaFiles = 0;
        
        for (final archiveFile in archive) {
          if (archiveFile.name == _notesFileName) {
            notesFile = archiveFile;
          } else if (archiveFile.name.startsWith('$_mediaDirectoryName/')) {
            mediaFiles++;
          }
        }
        
        if (notesFile != null) {
          try {
            final notesContent = utf8.decode(notesFile.content as List<int>);
            final notesData = jsonDecode(notesContent);
            
            if (notesData is List) {
              result['notesCount'] = notesData.length;
              result['mediaFilesCount'] = mediaFiles;
              result['isValid'] = true;
            } else {
              result['errors'] = ['Invalid notes data format in backup'];
            }
          } catch (e) {
            result['errors'] = ['Failed to parse notes data: $e'];
          }
        } else {
          result['errors'] = ['No notes data found in backup'];
        }
        
      } else if (fileName.endsWith('.json')) {
        result['fileType'] = 'json';
        
        try {
          final jsonContent = await file.readAsString();
          final jsonData = jsonDecode(jsonContent);
          
          if (jsonData is List) {
            result['notesCount'] = jsonData.length;
          } else if (jsonData is Map) {
            result['notesCount'] = 1;
          } else {
            result['errors'] = ['Invalid JSON format'];
            return result;
          }
          
          result['isValid'] = true;
          
        } catch (e) {
          result['errors'] = ['Failed to parse JSON file: $e'];
        }
        
      } else {
        result['errors'] = ['Unsupported file format. Please use .zip or .json files.'];
      }
      
    } catch (e) {
      result['errors'] = ['Failed to validate file: $e'];
    }

    return result;
  }
}
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for creating backups of notes and media files.
/// 
/// Creates ZIP archives containing notes.json and media files for export.
class BackupService {
  static const String _notesFileName = 'notes.json';
  static const String _mediaDirectoryName = 'media';

  /// Export all notes and media to a ZIP file.
  /// 
  /// Returns the path to the created ZIP file.
  Future<String> exportNotesToZip({
    required List<Map<String, dynamic>> notes,
    required List<String> mediaPaths,
    String? customFileName,
  }) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = customFileName ?? 'quicknote_backup_${timestamp.replaceAll('-', '').replaceAll('T', '_')}.zip';
    
    // Get temporary directory for creating the ZIP
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/$fileName';
    
    final archive = Archive();
    
    // Add notes.json to archive
    final notesJson = jsonEncode(notes);
    final notesFile = ArchiveFile(
      _notesFileName,
      notesJson.length,
      Uint8List.fromList(utf8.encode(notesJson)),
    );
    archive.addFile(notesFile);
    
    // Add media files to archive
    for (final mediaPath in mediaPaths) {
      final file = File(mediaPath);
      if (await file.exists()) {
        final fileName = file.path.split('/').last;
        final mediaBytes = await file.readAsBytes();
        final mediaFile = ArchiveFile(
          '$_mediaDirectoryName/$fileName',
          mediaBytes.length,
          mediaBytes,
        );
        archive.addFile(mediaFile);
      }
    }
    
    // Create ZIP file
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    
    if (zipBytes != null) {
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);
    }
    
    return zipPath;
  }

  /// Export a single note to JSON format.
  /// 
  /// Returns the path to the created JSON file.
  Future<String> exportSingleNoteToJson({
    required Map<String, dynamic> note,
    String? customFileName,
  }) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final noteTitle = note['title']?.toString().replaceAll(RegExp(r'[^\w\s-]'), '') ?? 'note';
    final fileName = customFileName ?? '${noteTitle}_${timestamp.replaceAll('-', '').replaceAll('T', '_')}.json';
    
    // Get temporary directory
    final tempDir = await getTemporaryDirectory();
    final jsonPath = '${tempDir.path}/$fileName';
    
    // Create JSON file
    final jsonContent = jsonEncode(note);
    final jsonFile = File(jsonPath);
    await jsonFile.writeAsString(jsonContent);
    
    return jsonPath;
  }

  /// Share the backup file using the system share dialog.
  /// 
  /// This allows users to save the backup anywhere without requiring storage permissions.
  Future<void> shareBackupFile(String filePath, {String? subject}) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'QuickNote Pro Backup',
        text: 'QuickNote Pro backup file',
      );
    }
  }

  /// Get sample notes data for testing purposes.
  /// 
  /// In a real implementation, this would fetch from the actual data storage.
  List<Map<String, dynamic>> getSampleNotesData() {
    return [
      {
        'id': '1',
        'title': 'Sample Note 1',
        'content': 'This is a sample note content with some text.',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'folder': 'Personal',
        'tags': ['sample', 'test'],
        'images': ['image1.jpg'],
        'voiceNotes': [],
        'pinned': false,
      },
      {
        'id': '2',
        'title': 'Another Note',
        'content': 'This note has voice recordings and images.',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'folder': 'Work',
        'tags': ['work', 'meeting'],
        'images': ['image2.jpg', 'image3.png'],
        'voiceNotes': ['voice1.m4a'],
        'pinned': true,
      },
    ];
  }

  /// Get sample media file paths for testing purposes.
  /// 
  /// In a real implementation, this would scan the actual media directories.
  List<String> getSampleMediaPaths() {
    return [
      '/data/user/0/com.example.quicknote_pro/app_flutter/media/image1.jpg',
      '/data/user/0/com.example.quicknote_pro/app_flutter/media/image2.jpg',
      '/data/user/0/com.example.quicknote_pro/app_flutter/media/image3.png',
      '/data/user/0/com.example.quicknote_pro/app_flutter/media/voice1.m4a',
    ];
  }

  /// Create a summary of what will be exported.
  Map<String, dynamic> createExportSummary(List<Map<String, dynamic>> notes, List<String> mediaPaths) {
    final mediaFiles = mediaPaths.where((path) => File(path).existsSync()).length;
    final totalSize = _calculateTotalSize(notes, mediaPaths);
    
    return {
      'notesCount': notes.length,
      'mediaFilesCount': mediaFiles,
      'estimatedSizeBytes': totalSize,
      'estimatedSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  int _calculateTotalSize(List<Map<String, dynamic>> notes, List<String> mediaPaths) {
    // Estimate JSON size
    final notesJson = jsonEncode(notes);
    int totalSize = utf8.encode(notesJson).length;
    
    // Add media file sizes (estimate if files don't exist)
    for (final path in mediaPaths) {
      final file = File(path);
      if (file.existsSync()) {
        totalSize += file.lengthSync();
      } else {
        // Estimate size for missing media files
        totalSize += 1024 * 1024; // 1MB estimate
      }
    }
    
    return totalSize;
  }
}
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive_io.dart';
import 'package:quicknote_pro/services/backup/import_service.dart';

void main() {
  group('ImportService Tests', () {
    late ImportService importService;
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      importService = ImportService();
      
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('import_test_');
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Backup File Validation Tests', () {
      test('should validate valid ZIP backup file', () async {
        // Arrange - Create a valid ZIP backup
        final notes = [
          {
            'id': '1',
            'title': 'Test Note',
            'content': 'Test content',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ];

        final zipPath = await _createTestZipBackup(notes, []);

        // Act
        final validation = await importService.validateBackupFile(zipPath);

        // Assert
        expect(validation['isValid'], isTrue);
        expect(validation['fileType'], equals('zip'));
        expect(validation['notesCount'], equals(1));
        expect(validation['mediaFilesCount'], equals(0));
        expect(validation['errors'], isEmpty);

        // Clean up
        await File(zipPath).delete();
      });

      test('should validate ZIP with media files', () async {
        // Arrange - Create ZIP with media
        final notes = [
          {
            'id': '1',
            'title': 'Note with media',
            'content': 'Has attachments',
            'images': ['test.jpg'],
          }
        ];

        final zipPath = await _createTestZipBackup(notes, [
          {'name': 'media/test.jpg', 'data': [1, 2, 3, 4, 5]},
          {'name': 'media/audio.m4a', 'data': [6, 7, 8, 9, 10]},
        ]);

        // Act
        final validation = await importService.validateBackupFile(zipPath);

        // Assert
        expect(validation['isValid'], isTrue);
        expect(validation['fileType'], equals('zip'));
        expect(validation['notesCount'], equals(1));
        expect(validation['mediaFilesCount'], equals(2));

        // Clean up
        await File(zipPath).delete();
      });

      test('should validate valid JSON file', () async {
        // Arrange - Create valid JSON file
        final notes = [
          {
            'id': '1',
            'title': 'JSON Note',
            'content': 'From JSON import',
            'createdAt': DateTime.now().toIso8601String(),
          }
        ];

        final jsonPath = '${tempDir.path}/test.json';
        final jsonFile = File(jsonPath);
        await jsonFile.writeAsString(jsonEncode(notes));

        // Act
        final validation = await importService.validateBackupFile(jsonPath);

        // Assert
        expect(validation['isValid'], isTrue);
        expect(validation['fileType'], equals('json'));
        expect(validation['notesCount'], equals(1));
        expect(validation['mediaFilesCount'], equals(0));

        // Clean up
        await jsonFile.delete();
      });

      test('should validate single note JSON object', () async {
        // Arrange - Create single note JSON
        final note = {
          'id': '1',
          'title': 'Single Note',
          'content': 'Single note content',
        };

        final jsonPath = '${tempDir.path}/single_note.json';
        final jsonFile = File(jsonPath);
        await jsonFile.writeAsString(jsonEncode(note));

        // Act
        final validation = await importService.validateBackupFile(jsonPath);

        // Assert
        expect(validation['isValid'], isTrue);
        expect(validation['fileType'], equals('json'));
        expect(validation['notesCount'], equals(1));

        // Clean up
        await jsonFile.delete();
      });

      test('should reject invalid file format', () async {
        // Arrange - Create invalid file
        final invalidPath = '${tempDir.path}/invalid.txt';
        final invalidFile = File(invalidPath);
        await invalidFile.writeAsString('This is not a backup file');

        // Act
        final validation = await importService.validateBackupFile(invalidPath);

        // Assert
        expect(validation['isValid'], isFalse);
        expect(validation['errors'], contains(predicate<String>((error) => 
          error.contains('Unsupported file format'))));

        // Clean up
        await invalidFile.delete();
      });

      test('should reject ZIP without notes.json', () async {
        // Arrange - Create ZIP without notes.json
        final archive = Archive();
        archive.addFile(ArchiveFile('readme.txt', 10, Uint8List.fromList(utf8.encode('No notes here'))));

        final zipPath = '${tempDir.path}/invalid.zip';
        final zipBytes = ZipEncoder().encode(archive);
        await File(zipPath).writeAsBytes(zipBytes!);

        // Act
        final validation = await importService.validateBackupFile(zipPath);

        // Assert
        expect(validation['isValid'], isFalse);
        expect(validation['errors'], contains(predicate<String>((error) => 
          error.contains('No notes data found'))));

        // Clean up
        await File(zipPath).delete();
      });

      test('should reject corrupt ZIP file', () async {
        // Arrange - Create corrupt ZIP
        final corruptZipPath = '${tempDir.path}/corrupt.zip';
        await File(corruptZipPath).writeAsBytes([1, 2, 3, 4, 5]); // Invalid ZIP

        // Act
        final validation = await importService.validateBackupFile(corruptZipPath);

        // Assert
        expect(validation['isValid'], isFalse);
        expect(validation['errors'], isNotEmpty);

        // Clean up
        await File(corruptZipPath).delete();
      });

      test('should reject invalid JSON format', () async {
        // Arrange - Create invalid JSON
        final invalidJsonPath = '${tempDir.path}/invalid.json';
        await File(invalidJsonPath).writeAsString('{ invalid json syntax');

        // Act
        final validation = await importService.validateBackupFile(invalidJsonPath);

        // Assert
        expect(validation['isValid'], isFalse);
        expect(validation['errors'], contains(predicate<String>((error) => 
          error.contains('Failed to parse JSON'))));

        // Clean up
        await File(invalidJsonPath).delete();
      });

      test('should reject non-existent file', () async {
        // Act
        final validation = await importService.validateBackupFile('/nonexistent/file.zip');

        // Assert
        expect(validation['isValid'], isFalse);
        expect(validation['errors'], contains('File not found'));
      });
    });

    group('ZIP Import Tests', () {
      test('should import notes from valid ZIP', () async {
        // Arrange
        final originalNotes = [
          {
            'id': '1',
            'title': 'Imported Note 1',
            'content': 'First imported note',
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'updatedAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          },
          {
            'id': '2',
            'title': 'Imported Note 2',
            'content': 'Second imported note',
            'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
            'updatedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          }
        ];

        final zipPath = await _createTestZipBackup(originalNotes, []);

        // Act
        final result = await importService.importFromZip(filePath: zipPath);

        // Assert
        expect(result.notesCreated, equals(1)); // One new note (existing note with id '1' will be updated)
        expect(result.notesUpdated, equals(1)); // One updated note
        expect(result.notesSkipped, equals(0));
        expect(result.mediaFilesImported, equals(0));
        expect(result.errors, isEmpty);

        // Clean up
        await File(zipPath).delete();
      });

      test('should import with "import as copies" option', () async {
        // Arrange
        final notes = [
          {
            'id': '1', // This conflicts with existing note
            'title': 'Conflicting Note',
            'content': 'This note has same ID as existing',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ];

        final zipPath = await _createTestZipBackup(notes, []);

        // Act
        final result = await importService.importFromZip(
          filePath: zipPath,
          importAsCopies: true,
        );

        // Assert
        expect(result.notesCreated, equals(1)); // Should create new note with new ID
        expect(result.notesUpdated, equals(0)); // No updates since creating copies
        expect(result.notesSkipped, equals(0));
        expect(result.errors, isEmpty);

        // Clean up
        await File(zipPath).delete();
      });

      test('should import media files from ZIP', () async {
        // Arrange
        final notes = [
          {
            'id': 'new_note',
            'title': 'Note with Media',
            'content': 'Has media attachments',
            'images': ['test_image.jpg'],
            'voiceNotes': ['test_audio.m4a'],
          }
        ];

        final mediaFiles = [
          {'name': 'media/test_image.jpg', 'data': List.filled(1024, 1)},
          {'name': 'media/test_audio.m4a', 'data': List.filled(2048, 2)},
        ];

        final zipPath = await _createTestZipBackup(notes, mediaFiles);

        // Act
        final result = await importService.importFromZip(filePath: zipPath);

        // Assert
        expect(result.mediaFilesImported, equals(2));
        expect(result.notesCreated, equals(1));
        expect(result.errors, isEmpty);

        // Clean up
        await File(zipPath).delete();
      });

      test('should handle large dataset import', () async {
        // Arrange - Create 500 notes
        final largeNotes = List.generate(500, (index) => {
          'id': 'large_note_$index',
          'title': 'Large Dataset Note $index',
          'content': 'Content for note $index ' * 20, // Larger content
          'createdAt': DateTime.now().subtract(Duration(minutes: index)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(Duration(minutes: index)).toIso8601String(),
          'folder': 'Folder ${index % 10}',
          'tags': ['bulk', 'import', 'test'],
        });

        final zipPath = await _createTestZipBackup(largeNotes, []);

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await importService.importFromZip(filePath: zipPath);
        stopwatch.stop();

        // Assert
        expect(result.notesCreated, equals(500));
        expect(result.errors, isEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds

        // Clean up
        await File(zipPath).delete();
      });

      test('should handle corrupt media files gracefully', () async {
        // Arrange
        final notes = [
          {
            'id': 'note_with_media',
            'title': 'Note with Corrupt Media',
            'content': 'Media files might be corrupt',
          }
        ];

        // Create ZIP with corrupt media file structure
        final archive = Archive();
        
        // Add valid notes.json
        final notesJson = jsonEncode(notes);
        archive.addFile(ArchiveFile(
          'notes.json',
          notesJson.length,
          Uint8List.fromList(utf8.encode(notesJson)),
        ));

        // Add invalid media file (wrong structure)
        archive.addFile(ArchiveFile(
          'media/',  // Directory without proper file
          0,
          Uint8List(0),
        ));

        final zipPath = '${tempDir.path}/corrupt_media.zip';
        final zipBytes = ZipEncoder().encode(archive);
        await File(zipPath).writeAsBytes(zipBytes!);

        // Act
        final result = await importService.importFromZip(filePath: zipPath);

        // Assert
        expect(result.notesCreated, equals(1)); // Notes should still import
        expect(result.mediaFilesImported, equals(0)); // No valid media files
        // Should have warnings but not fail completely

        // Clean up
        await File(zipPath).delete();
      });
    });

    group('JSON Import Tests', () {
      test('should import notes from JSON array', () async {
        // Arrange
        final notes = [
          {
            'id': 'json_note_1',
            'title': 'JSON Note 1',
            'content': 'From JSON import',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'json_note_2',
            'title': 'JSON Note 2',
            'content': 'Another JSON note',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ];

        final jsonPath = '${tempDir.path}/notes.json';
        await File(jsonPath).writeAsString(jsonEncode(notes));

        // Act
        final result = await importService.importFromJson(filePath: jsonPath);

        // Assert
        expect(result.notesCreated, equals(2));
        expect(result.notesUpdated, equals(0));
        expect(result.mediaFilesImported, equals(0));
        expect(result.errors, isEmpty);

        // Clean up
        await File(jsonPath).delete();
      });

      test('should import single note from JSON object', () async {
        // Arrange
        final note = {
          'id': 'single_json_note',
          'title': 'Single JSON Note',
          'content': 'Single note from JSON',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final jsonPath = '${tempDir.path}/single_note.json';
        await File(jsonPath).writeAsString(jsonEncode(note));

        // Act
        final result = await importService.importFromJson(filePath: jsonPath);

        // Assert
        expect(result.notesCreated, equals(1));
        expect(result.mediaFilesImported, equals(0));
        expect(result.errors, isEmpty);

        // Clean up
        await File(jsonPath).delete();
      });

      test('should warn about missing media references in JSON', () async {
        // Arrange
        final notes = [
          {
            'id': 'note_with_refs',
            'title': 'Note with Media References',
            'content': 'Has media but no files',
            'images': ['missing_image.jpg'],
            'voiceNotes': ['missing_audio.m4a'],
          }
        ];

        final jsonPath = '${tempDir.path}/notes_with_refs.json';
        await File(jsonPath).writeAsString(jsonEncode(notes));

        // Act
        final result = await importService.importFromJson(filePath: jsonPath);

        // Assert
        expect(result.notesCreated, equals(1));
        expect(result.warnings, isNotEmpty);
        expect(result.warnings.any((warning) => warning.contains('references media files')), isTrue);

        // Clean up
        await File(jsonPath).delete();
      });
    });

    group('Merge Strategy Tests', () {
      test('should use lastWriteWins strategy correctly', () async {
        // Arrange - Create note with newer timestamp than existing
        final notes = [
          {
            'id': '1', // Conflicts with existing note
            'title': 'Updated Note',
            'content': 'This is newer content',
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(), // Very recent
          }
        ];

        final zipPath = await _createTestZipBackup(notes, []);

        // Act
        final result = await importService.importFromZip(
          filePath: zipPath,
          mergeStrategy: 'lastWriteWins',
        );

        // Assert
        expect(result.notesUpdated, equals(1)); // Should update existing note
        expect(result.notesCreated, equals(0));
        expect(result.notesSkipped, equals(0));

        // Clean up
        await File(zipPath).delete();
      });

      test('should use skipOlder strategy correctly', () async {
        // Arrange - Create note with older timestamp
        final notes = [
          {
            'id': '1', // Conflicts with existing note
            'title': 'Older Note',
            'content': 'This is older content',
            'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
            'updatedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(), // Older
          }
        ];

        final zipPath = await _createTestZipBackup(notes, []);

        // Act
        final result = await importService.importFromZip(
          filePath: zipPath,
          mergeStrategy: 'skipOlder',
        );

        // Assert
        expect(result.notesSkipped, equals(1)); // Should skip older note
        expect(result.notesUpdated, equals(0));
        expect(result.notesCreated, equals(0));

        // Clean up
        await File(zipPath).delete();
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid note structure gracefully', () async {
        // Arrange - Create notes with invalid structure
        final invalidNotes = [
          {'title': 'Missing ID'}, // No ID
          {'id': null, 'title': 'Null ID'}, // Null ID
          {'id': '1'}, // Missing title and content
          {
            'id': '2',
            'title': 'Valid Note',
            'content': 'This one is valid',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ];

        final zipPath = await _createTestZipBackup(invalidNotes, []);

        // Act
        final result = await importService.importFromZip(filePath: zipPath);

        // Assert
        expect(result.notesCreated, equals(1)); // Only valid note
        expect(result.notesSkipped, equals(3)); // Invalid notes skipped
        expect(result.warnings, isNotEmpty);

        // Clean up
        await File(zipPath).delete();
      });

      test('should handle permission errors during import', () async {
        // Arrange
        final notes = [
          {
            'id': 'perm_test',
            'title': 'Permission Test',
            'content': 'Testing permissions',
          }
        ];

        final zipPath = await _createTestZipBackup(notes, []);

        // Act & Assert - Should not crash even with permission issues
        expect(() async => await importService.importFromZip(filePath: zipPath), 
               returnsNormally);

        // Clean up
        await File(zipPath).delete();
      });
    });

    group('Import Result Tests', () {
      test('should provide accurate import summary', () async {
        // Arrange
        final result = ImportResult(
          notesCreated: 5,
          notesUpdated: 3,
          notesSkipped: 2,
          mediaFilesImported: 4,
          errors: ['Error 1'],
          warnings: ['Warning 1', 'Warning 2'],
        );

        // Act
        final summary = result.getSummary();

        // Assert
        expect(summary, contains('Created 5 notes'));
        expect(summary, contains('Updated 3 notes'));
        expect(summary, contains('Skipped 2 notes'));
        expect(summary, contains('Imported 4 media files'));
        expect(summary, contains('1 errors'));
        expect(summary, contains('2 warnings'));
      });

      test('should handle empty result', () async {
        // Arrange
        final result = ImportResult(
          notesCreated: 0,
          notesUpdated: 0,
          notesSkipped: 0,
          mediaFilesImported: 0,
          errors: [],
          warnings: [],
        );

        // Act
        final summary = result.getSummary();

        // Assert
        expect(summary, equals('No changes made'));
      });
    });
  });

  // Helper method to create test ZIP backup
  Future<String> _createTestZipBackup(
    List<Map<String, dynamic>> notes,
    List<Map<String, dynamic>> mediaFiles,
  ) async {
    final archive = Archive();
    
    // Add notes.json
    final notesJson = jsonEncode(notes);
    archive.addFile(ArchiveFile(
      'notes.json',
      notesJson.length,
      Uint8List.fromList(utf8.encode(notesJson)),
    ));
    
    // Add media files
    for (final mediaFile in mediaFiles) {
      final name = mediaFile['name'] as String;
      final data = mediaFile['data'] as List<int>;
      archive.addFile(ArchiveFile(
        name,
        data.length,
        Uint8List.fromList(data),
      ));
    }
    
    // Create ZIP file
    final tempDir = await Directory.systemTemp.createTemp('test_backup_');
    final zipPath = '${tempDir.path}/test_backup.zip';
    final zipBytes = ZipEncoder().encode(archive);
    await File(zipPath).writeAsBytes(zipBytes!);
    
    return zipPath;
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive_io.dart';

// Import the services directly using relative paths to avoid import issues
import '../../../lib/services/backup/backup_service.dart';
import '../../../lib/services/backup/import_service.dart';

void main() {
  group('Basic Backup & Import Tests', () {
    late BackupService backupService;
    late ImportService importService;
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      backupService = BackupService();
      importService = ImportService();
      
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('basic_test_');
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('BackupService should create sample notes data', () {
      // Act
      final sampleNotes = backupService.getSampleNotesData();

      // Assert
      expect(sampleNotes, isNotEmpty);
      expect(sampleNotes.length, equals(2));
      
      // Check first note structure
      final firstNote = sampleNotes[0];
      expect(firstNote['id'], isNotNull);
      expect(firstNote['title'], isNotNull);
      expect(firstNote['content'], isNotNull);
      expect(firstNote['createdAt'], isNotNull);
      expect(firstNote['updatedAt'], isNotNull);
    });

    test('BackupService should create export summary', () {
      // Arrange
      final notes = [
        {'id': '1', 'title': 'Test Note', 'content': 'Test content'},
      ];
      final mediaPaths = <String>[];

      // Act
      final summary = backupService.createExportSummary(notes, mediaPaths);

      // Assert
      expect(summary['notesCount'], equals(1));
      expect(summary['mediaFilesCount'], equals(0));
      expect(summary['estimatedSizeBytes'], greaterThan(0));
      expect(summary['estimatedSizeMB'], isNotNull);
    });

    test('ImportService should validate JSON backup format', () async {
      // Arrange - Create a simple JSON file
      final notes = [
        {
          'id': 'test_1',
          'title': 'Test Note',
          'content': 'Test content',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      ];

      final jsonPath = '${tempDir.path}/test_backup.json';
      await File(jsonPath).writeAsString(jsonEncode(notes));

      // Act
      final validation = await importService.validateBackupFile(jsonPath);

      // Assert
      expect(validation['isValid'], isTrue);
      expect(validation['fileType'], equals('json'));
      expect(validation['notesCount'], equals(1));
      expect(validation['errors'], isEmpty);

      // Clean up
      await File(jsonPath).delete();
    });

    test('ImportService should reject invalid file format', () async {
      // Arrange - Create invalid file
      final invalidPath = '${tempDir.path}/invalid.txt';
      await File(invalidPath).writeAsString('This is not a backup file');

      // Act
      final validation = await importService.validateBackupFile(invalidPath);

      // Assert
      expect(validation['isValid'], isFalse);
      expect(validation['errors'], isNotEmpty);
      expect(validation['errors'].any((error) => 
        error.toString().contains('Unsupported file format')), isTrue);

      // Clean up
      await File(invalidPath).delete();
    });

    test('ImportService should handle non-existent file', () async {
      // Act
      final validation = await importService.validateBackupFile('/nonexistent/file.zip');

      // Assert
      expect(validation['isValid'], isFalse);
      expect(validation['errors'], contains('File not found'));
    });

    test('ImportResult should provide summary correctly', () {
      // Arrange
      final result = ImportResult(
        notesCreated: 3,
        notesUpdated: 2,
        notesSkipped: 1,
        mediaFilesImported: 4,
        errors: ['Error 1'],
        warnings: ['Warning 1', 'Warning 2'],
      );

      // Act
      final summary = result.getSummary();

      // Assert
      expect(summary, contains('Created 3 notes'));
      expect(summary, contains('Updated 2 notes'));
      expect(summary, contains('Skipped 1 notes'));
      expect(summary, contains('Imported 4 media files'));
      expect(summary, contains('1 errors'));
      expect(summary, contains('2 warnings'));
    });

    test('ImportResult should handle empty result', () {
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

    test('BackupService should handle empty notes list', () async {
      // Arrange
      final notes = <Map<String, dynamic>>[];
      final mediaPaths = <String>[];

      // Act
      final zipPath = await backupService.exportNotesToZip(
        notes: notes,
        mediaPaths: mediaPaths,
      );

      // Assert
      final zipFile = File(zipPath);
      expect(await zipFile.exists(), isTrue);

      // Clean up
      await zipFile.delete();
    });

    test('ImportService should handle corrupt JSON gracefully', () async {
      // Arrange - Create invalid JSON
      final invalidJsonPath = '${tempDir.path}/invalid.json';
      await File(invalidJsonPath).writeAsString('{ invalid json syntax');

      // Act
      final validation = await importService.validateBackupFile(invalidJsonPath);

      // Assert
      expect(validation['isValid'], isFalse);
      expect(validation['errors'], isNotEmpty);

      // Clean up
      await File(invalidJsonPath).delete();
    });
  });
}
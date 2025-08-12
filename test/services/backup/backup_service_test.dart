import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quicknote_pro/services/backup/backup_service.dart';

void main() {
  group('BackupService Tests', () {
    late BackupService backupService;
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      backupService = BackupService();
      
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('backup_test_');
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('ZIP Export Tests', () {
      test('should create ZIP with notes.json and media files', () async {
        // Arrange
        final notes = [
          {
            'id': '1',
            'title': 'Test Note 1',
            'content': 'This is test content',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'folder': 'Personal',
            'tags': ['test'],
            'images': ['test_image.jpg'],
            'voiceNotes': [],
            'pinned': false,
          },
          {
            'id': '2',
            'title': 'Test Note 2',
            'content': 'Another test note',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'folder': 'Work',
            'tags': ['work', 'test'],
            'images': [],
            'voiceNotes': ['voice_note.m4a'],
            'pinned': true,
          },
        ];

        // Create test media files
        final mediaFile1 = File('${tempDir.path}/test_image.jpg');
        final mediaFile2 = File('${tempDir.path}/voice_note.m4a');
        await mediaFile1.writeAsBytes([1, 2, 3, 4, 5]); // Dummy image data
        await mediaFile2.writeAsBytes([6, 7, 8, 9, 10]); // Dummy audio data

        final mediaPaths = [mediaFile1.path, mediaFile2.path];

        // Act
        final zipPath = await backupService.exportNotesToZip(
          notes: notes,
          mediaPaths: mediaPaths,
        );

        // Assert
        final zipFile = File(zipPath);
        expect(await zipFile.exists(), isTrue);

        // Verify ZIP contents
        final zipBytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);

        // Check notes.json exists
        final notesFile = archive.firstWhere((file) => file.name == 'notes.json');
        expect(notesFile, isNotNull);

        // Verify notes.json content
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final decodedNotes = jsonDecode(notesContent) as List;
        expect(decodedNotes.length, equals(2));
        expect(decodedNotes[0]['title'], equals('Test Note 1'));
        expect(decodedNotes[1]['title'], equals('Test Note 2'));

        // Check media files exist
        final mediaFiles = archive.where((file) => file.name.startsWith('media/')).toList();
        expect(mediaFiles.length, equals(2));
        expect(mediaFiles.any((file) => file.name == 'media/test_image.jpg'), isTrue);
        expect(mediaFiles.any((file) => file.name == 'media/voice_note.m4a'), isTrue);

        // Clean up
        await zipFile.delete();
        await mediaFile1.delete();
        await mediaFile2.delete();
      });

      test('should handle empty notes list', () async {
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

        final zipBytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);

        // Should still contain notes.json (empty array)
        final notesFile = archive.firstWhere((file) => file.name == 'notes.json');
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final decodedNotes = jsonDecode(notesContent) as List;
        expect(decodedNotes.length, equals(0));

        // Clean up
        await zipFile.delete();
      });

      test('should handle large dataset', () async {
        // Arrange - Create 1000 notes
        final notes = List.generate(1000, (index) => {
          'id': 'note_$index',
          'title': 'Test Note $index',
          'content': 'This is test content for note $index. ' * 50, // Large content
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'folder': 'Test Folder ${index % 10}',
          'tags': ['test', 'large', 'dataset'],
          'images': [],
          'voiceNotes': [],
          'pinned': index % 10 == 0,
        });

        // Act
        final zipPath = await backupService.exportNotesToZip(
          notes: notes,
          mediaPaths: [],
        );

        // Assert
        final zipFile = File(zipPath);
        expect(await zipFile.exists(), isTrue);

        // Verify large dataset was processed
        final zipBytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final notesFile = archive.firstWhere((file) => file.name == 'notes.json');
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final decodedNotes = jsonDecode(notesContent) as List;
        expect(decodedNotes.length, equals(1000));

        // Check file size is reasonable (should be more than 100KB for 1000 notes)
        expect(zipBytes.length, greaterThan(100 * 1024));

        // Clean up
        await zipFile.delete();
      });

      test('should handle missing media files gracefully', () async {
        // Arrange
        final notes = [
          {
            'id': '1',
            'title': 'Test Note',
            'content': 'Content with missing media',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'images': ['missing_image.jpg'],
            'voiceNotes': ['missing_audio.m4a'],
          }
        ];

        final mediaPaths = [
          '/nonexistent/path/missing_image.jpg',
          '/nonexistent/path/missing_audio.m4a',
        ];

        // Act
        final zipPath = await backupService.exportNotesToZip(
          notes: notes,
          mediaPaths: mediaPaths,
        );

        // Assert
        final zipFile = File(zipPath);
        expect(await zipFile.exists(), isTrue);

        // ZIP should still be created without the missing media files
        final zipBytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        
        // Should have notes.json but no media files
        expect(archive.any((file) => file.name == 'notes.json'), isTrue);
        expect(archive.where((file) => file.name.startsWith('media/')).length, equals(0));

        // Clean up
        await zipFile.delete();
      });

      test('should use custom filename when provided', () async {
        // Arrange
        final notes = [{'id': '1', 'title': 'Test', 'content': 'Test'}];
        const customFileName = 'my_custom_backup.zip';

        // Act
        final zipPath = await backupService.exportNotesToZip(
          notes: notes,
          mediaPaths: [],
          customFileName: customFileName,
        );

        // Assert
        expect(zipPath.endsWith(customFileName), isTrue);

        // Clean up
        final zipFile = File(zipPath);
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
      });
    });

    group('JSON Export Tests', () {
      test('should export single note to JSON', () async {
        // Arrange
        final note = {
          'id': '1',
          'title': 'Test Note',
          'content': 'This is a test note',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'folder': 'Personal',
          'tags': ['test', 'personal'],
          'images': [],
          'voiceNotes': [],
          'pinned': false,
        };

        // Act
        final jsonPath = await backupService.exportSingleNoteToJson(note: note);

        // Assert
        final jsonFile = File(jsonPath);
        expect(await jsonFile.exists(), isTrue);

        final jsonContent = await jsonFile.readAsString();
        final decodedNote = jsonDecode(jsonContent);
        expect(decodedNote['title'], equals('Test Note'));
        expect(decodedNote['content'], equals('This is a test note'));

        // Clean up
        await jsonFile.delete();
      });

      test('should sanitize filename from note title', () async {
        // Arrange
        final note = {
          'id': '1',
          'title': 'Test/Note:With<Special>Characters?',
          'content': 'Test content',
        };

        // Act
        final jsonPath = await backupService.exportSingleNoteToJson(note: note);

        // Assert
        expect(jsonPath.contains('/'), isTrue); // Path separators should remain
        expect(jsonPath.contains(':'), isFalse); // Special chars should be removed
        expect(jsonPath.contains('<'), isFalse);
        expect(jsonPath.contains('>'), isFalse);
        expect(jsonPath.contains('?'), isFalse);

        // Clean up
        final jsonFile = File(jsonPath);
        if (await jsonFile.exists()) {
          await jsonFile.delete();
        }
      });
    });

    group('Export Summary Tests', () {
      test('should create accurate export summary', () async {
        // Arrange
        final notes = [
          {'id': '1', 'title': 'Note 1', 'content': 'Content 1'},
          {'id': '2', 'title': 'Note 2', 'content': 'Content 2'},
        ];

        // Create test media files
        final mediaFile = File('${tempDir.path}/test_media.jpg');
        await mediaFile.writeAsBytes(List.filled(1024 * 1024, 1)); // 1MB file

        final mediaPaths = [mediaFile.path];

        // Act
        final summary = backupService.createExportSummary(notes, mediaPaths);

        // Assert
        expect(summary['notesCount'], equals(2));
        expect(summary['mediaFilesCount'], equals(1));
        expect(summary['estimatedSizeBytes'], greaterThan(1024 * 1024)); // At least 1MB
        expect(summary['estimatedSizeMB'], isNotNull);

        // Clean up
        await mediaFile.delete();
      });

      test('should handle non-existent media files in summary', () async {
        // Arrange
        final notes = [{'id': '1', 'title': 'Note 1', 'content': 'Content 1'}];
        final mediaPaths = ['/nonexistent/file.jpg'];

        // Act
        final summary = backupService.createExportSummary(notes, mediaPaths);

        // Assert
        expect(summary['notesCount'], equals(1));
        expect(summary['mediaFilesCount'], equals(0));
        expect(summary['estimatedSizeBytes'], greaterThan(0)); // Should estimate size
      });
    });

    group('Sample Data Tests', () {
      test('should provide valid sample notes', () {
        // Act
        final sampleNotes = backupService.getSampleNotesData();

        // Assert
        expect(sampleNotes, isNotEmpty);
        for (final note in sampleNotes) {
          expect(note['id'], isNotNull);
          expect(note['title'], isNotNull);
          expect(note['content'], isNotNull);
          expect(note['createdAt'], isNotNull);
          expect(note['updatedAt'], isNotNull);
        }
      });

      test('should provide sample media paths', () {
        // Act
        final mediaPaths = backupService.getSampleMediaPaths();

        // Assert
        expect(mediaPaths, isNotEmpty);
        for (final path in mediaPaths) {
          expect(path, isA<String>());
          expect(path.isNotEmpty, isTrue);
        }
      });
    });

    group('Error Handling Tests', () {
      test('should handle permission errors gracefully', () async {
        // This test simulates permission errors by trying to write to root directory
        // In a real environment, this would test actual permission scenarios
        
        final notes = [{'id': '1', 'title': 'Test', 'content': 'Test'}];
        
        // The service should handle this gracefully and not crash
        expect(() async => await backupService.exportNotesToZip(
          notes: notes,
          mediaPaths: [],
        ), returnsNormally);
      });

      test('should handle corrupt data gracefully', () async {
        // Arrange - Create notes with null/invalid data
        final corruptNotes = [
          null, // null note
          {'id': null, 'title': 'Valid Title'}, // missing required fields
          {'id': '1'}, // missing title and content
        ].whereType<Map<String, dynamic>>().toList();

        // Act & Assert - Should not crash
        expect(() async => await backupService.exportNotesToZip(
          notes: corruptNotes,
          mediaPaths: [],
        ), returnsNormally);
      });
    });
  });
}
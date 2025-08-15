import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive_io.dart';
import 'package:quicknote_pro/services/backup/backup_service.dart';
import 'package:quicknote_pro/services/backup/import_service.dart';

void main() {
  group('Backup & Import Integration Tests', () {
    late BackupService backupService;
    late ImportService importService;
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      backupService = BackupService();
      importService = ImportService();
      
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('integration_test_');
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Complete Backup & Import Workflow Tests', () {
      test('should export and import notes without data loss', () async {
        // Arrange - Create comprehensive test data
        final originalNotes = [
          {
            'id': 'note_1',
            'title': 'Personal Note',
            'content': 'This is my personal note with **markdown** and special characters: áéíóú',
            'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
            'updatedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'folder': 'Personal',
            'tags': ['personal', 'important', 'test'],
            'images': ['image1.jpg'],
            'voiceNotes': [],
            'pinned': true,
          },
          {
            'id': 'note_2',
            'title': 'Work Meeting Notes',
            'content': 'Meeting notes from today:\n- Point 1\n- Point 2\n- Action items',
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'updatedAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
            'folder': 'Work',
            'tags': ['work', 'meeting'],
            'images': [],
            'voiceNotes': ['meeting_audio.m4a'],
            'pinned': false,
          },
          {
            'id': 'note_3',
            'title': 'Shopping List',
            'content': 'Groceries needed:\n🥛 Milk\n🍞 Bread\n🍎 Apples\n🧀 Cheese',
            'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
            'updatedAt': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
            'folder': 'Lists',
            'tags': ['shopping', 'groceries'],
            'images': [],
            'voiceNotes': [],
            'pinned': false,
          },
        ];

        // Create test media files
        final imageFile = File('${tempDir.path}/image1.jpg');
        final audioFile = File('${tempDir.path}/meeting_audio.m4a');
        await imageFile.writeAsBytes(List.filled(2048, 1)); // Mock image data
        await audioFile.writeAsBytes(List.filled(4096, 2)); // Mock audio data

        final mediaPaths = [imageFile.path, audioFile.path];

        // Act - Export notes
        final zipPath = await backupService.exportNotesToZip(
          notes: originalNotes,
          mediaPaths: mediaPaths,
        );

        // Verify export was successful
        expect(File(zipPath).existsSync(), isTrue);

        // Act - Import notes back
        final importResult = await importService.importFromZip(filePath: zipPath);

        // Assert - Verify import results
        expect(importResult.errors, isEmpty);
        expect(importResult.notesCreated + importResult.notesUpdated, equals(3));
        expect(importResult.mediaFilesImported, equals(2));

        // Verify ZIP contents match original data
        final zipBytes = await File(zipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        
        // Check notes.json
        final notesFile = archive.firstWhere((file) => file.name == 'notes.json');
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final importedNotes = jsonDecode(notesContent) as List;
        
        expect(importedNotes.length, equals(3));
        
        // Verify specific note data
        final personalNote = importedNotes.firstWhere((note) => note['id'] == 'note_1');
        expect(personalNote['title'], equals('Personal Note'));
        expect(personalNote['content'], contains('**markdown**'));
        expect(personalNote['content'], contains('áéíóú')); // Unicode characters
        expect(personalNote['tags'], contains('important'));
        expect(personalNote['pinned'], isTrue);

        // Check media files
        final mediaFiles = archive.where((file) => file.name.startsWith('media/')).toList();
        expect(mediaFiles.length, equals(2));
        expect(mediaFiles.any((file) => file.name == 'media/image1.jpg'), isTrue);
        expect(mediaFiles.any((file) => file.name == 'media/meeting_audio.m4a'), isTrue);

        // Clean up
        await File(zipPath).delete();
        await imageFile.delete();
        await audioFile.delete();
      });

      test('should handle large dataset export/import cycle', () async {
        // Arrange - Create 500 notes with various data
        final largeDataset = List.generate(500, (index) => {
          'id': 'large_note_$index',
          'title': 'Large Dataset Note $index',
          'content': 'This is note number $index with substantial content. ' * 20, // Large content
          'createdAt': DateTime.now().subtract(Duration(minutes: index)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(Duration(minutes: index ~/ 2)).toIso8601String(),
          'folder': 'Folder ${index % 20}', // 20 different folders
          'tags': ['bulk', 'test', 'category_${index % 10}'], // Various tags
          'images': index % 5 == 0 ? ['image_$index.jpg'] : [], // Some with images
          'voiceNotes': index % 7 == 0 ? ['audio_$index.m4a'] : [], // Some with audio
          'pinned': index % 50 == 0, // Some pinned
        });

        // Act - Export large dataset
        final startTime = DateTime.now();
        final zipPath = await backupService.exportNotesToZip(
          notes: largeDataset,
          mediaPaths: [], // No actual media files for this test
        );
        final exportTime = DateTime.now().difference(startTime);

        // Verify export performance (should complete within reasonable time)
        expect(exportTime.inSeconds, lessThan(30)); // Should export within 30 seconds

        // Verify file size is reasonable
        final zipFile = File(zipPath);
        final fileSize = await zipFile.length();
        expect(fileSize, greaterThan(100 * 1024)); // At least 100KB for 500 notes
        expect(fileSize, lessThan(50 * 1024 * 1024)); // But less than 50MB

        // Act - Import large dataset
        final importStartTime = DateTime.now();
        final importResult = await importService.importFromZip(filePath: zipPath);
        final importTime = DateTime.now().difference(importStartTime);

        // Assert - Verify import performance and results
        expect(importTime.inSeconds, lessThan(45)); // Should import within 45 seconds
        expect(importResult.errors, isEmpty);
        expect(importResult.notesCreated, equals(500));
        expect(importResult.warnings, isEmpty);

        // Clean up
        await zipFile.delete();
      });

      test('should preserve data integrity with special characters and formats', () async {
        // Arrange - Create notes with various special content
        final specialNotes = [
          {
            'id': 'unicode_test',
            'title': 'Unicode Test: 🌟 ✨ 🎯',
            'content': '''Multi-line content with:
            
📝 Emojis: 😀 😃 😄 😁
🔤 Languages: Hëllö Wörld, Здравствуй мир, こんにちは世界
🔢 Numbers: 123.456 €, \$999.99, ¥1000
📊 Symbols: ± × ÷ √ ∞ ≈ ≠ ≤ ≥
🎨 Special chars: \\"quotes\\", <tags>, [brackets], {braces}
            
Code block:
```dart
void main() {
  print('Hello, World!');
}
```

Table:
| Column 1 | Column 2 |
|----------|----------|
| Data     | More     |
''',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'tags': ['unicode', 'special-chars', 'test'],
          },
          {
            'id': 'json_escape_test',
            'title': 'JSON Escape Test',
            'content': '''Content with JSON special characters:
            
"Double quotes"
'Single quotes'
\\Backslashes\\
\tTabs\t
\nNewlines\n
\rCarriage returns\r
/Forward slashes/
Control chars: \u0001\u0002\u0003
''',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ];

        // Act - Export and import
        final zipPath = await backupService.exportNotesToZip(
          notes: specialNotes,
          mediaPaths: [],
        );

        final importResult = await importService.importFromZip(filePath: zipPath);

        // Assert - Verify all special content is preserved
        expect(importResult.errors, isEmpty);
        expect(importResult.notesCreated, equals(2));

        // Verify content in the actual ZIP
        final zipBytes = await File(zipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final notesFile = archive.firstWhere((file) => file.name == 'notes.json');
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final importedNotes = jsonDecode(notesContent) as List;

        final unicodeNote = importedNotes.firstWhere((note) => note['id'] == 'unicode_test');
        expect(unicodeNote['title'], contains('🌟 ✨ 🎯'));
        expect(unicodeNote['content'], contains('😀 😃 😄 😁'));
        expect(unicodeNote['content'], contains('Hëllö Wörld'));
        expect(unicodeNote['content'], contains('Здравствуй мир'));
        expect(unicodeNote['content'], contains('こんにちは世界'));

        final escapeNote = importedNotes.firstWhere((note) => note['id'] == 'json_escape_test');
        expect(escapeNote['content'], contains('"Double quotes"'));
        expect(escapeNote['content'], contains("'Single quotes'"));
        expect(escapeNote['content'], contains('\\Backslashes\\'));

        // Clean up
        await File(zipPath).delete();
      });

      test('should handle encrypted backup simulation', () async {
        // Note: This simulates encrypted backup by adding metadata
        // In a real implementation, this would use actual encryption
        
        // Arrange - Create notes with encryption metadata
        final notes = [
          {
            'id': 'encrypted_note_1',
            'title': 'Sensitive Information',
            'content': 'This contains sensitive data that should be encrypted',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'encrypted': true,
            'encryptionVersion': '1.0',
          }
        ];

        // Act - Export with encryption metadata
        final zipPath = await backupService.exportNotesToZip(
          notes: notes,
          mediaPaths: [],
          customFileName: 'encrypted_backup.zip',
        );

        // Verify encryption metadata is preserved
        final zipBytes = await File(zipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final notesFile = archive.firstWhere((file) => file.name == 'notes.json');
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final importedNotes = jsonDecode(notesContent) as List;

        expect(importedNotes[0]['encrypted'], isTrue);
        expect(importedNotes[0]['encryptionVersion'], equals('1.0'));

        // Act - Import encrypted backup
        final importResult = await importService.importFromZip(filePath: zipPath);

        // Assert - Should import successfully
        expect(importResult.errors, isEmpty);
        expect(importResult.notesCreated, equals(1));

        // Clean up
        await File(zipPath).delete();
      });

      test('should handle partial corruption gracefully', () async {
        // Arrange - Create a backup with some corrupt entries
        final mixedNotes = [
          {
            'id': 'valid_note_1',
            'title': 'Valid Note 1',
            'content': 'This note is completely valid',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': null, // Invalid - null ID
            'title': 'Invalid Note',
            'content': 'This note has null ID',
          },
          {
            'id': 'valid_note_2',
            'title': 'Valid Note 2',
            'content': 'Another valid note',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'title': 'Missing ID', // Invalid - no ID field
            'content': 'This note has no ID',
          }
        ];

        // Act - Export mixed data
        final zipPath = await backupService.exportNotesToZip(
          notes: mixedNotes,
          mediaPaths: [],
        );

        // Act - Import mixed data
        final importResult = await importService.importFromZip(filePath: zipPath);

        // Assert - Should import valid notes and skip invalid ones
        expect(importResult.notesCreated, equals(2)); // Only valid notes
        expect(importResult.notesSkipped, equals(2)); // Invalid notes skipped
        expect(importResult.warnings, isNotEmpty); // Should have warnings
        expect(importResult.errors, isEmpty); // Should not error out completely

        // Clean up
        await File(zipPath).delete();
      });

      test('should handle merge conflicts correctly', () async {
        // Arrange - Create notes that conflict with existing data
        final conflictingNotes = [
          {
            'id': '1', // This ID exists in mock existing notes
            'title': 'Updated Existing Note',
            'content': 'This should update the existing note',
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(), // Very recent
            'folder': 'Updated',
          },
          {
            'id': 'new_unique_note',
            'title': 'Completely New Note',
            'content': 'This is a new note that should be created',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ];

        // Act - Import with lastWriteWins strategy
        final zipPath = await backupService.exportNotesToZip(
          notes: conflictingNotes,
          mediaPaths: [],
        );

        final importResult = await importService.importFromZip(
          filePath: zipPath,
          mergeStrategy: 'lastWriteWins',
        );

        // Assert - Should update existing and create new
        expect(importResult.notesUpdated, equals(1)); // Updated existing note
        expect(importResult.notesCreated, equals(1)); // Created new note
        expect(importResult.notesSkipped, equals(0));
        expect(importResult.errors, isEmpty);

        // Test with import as copies
        final copyResult = await importService.importFromZip(
          filePath: zipPath,
          importAsCopies: true,
        );

        // Assert - Should create copies of all notes
        expect(copyResult.notesCreated, equals(2)); // Both notes as copies
        expect(copyResult.notesUpdated, equals(0)); // No updates when copying
        expect(copyResult.errors, isEmpty);

        // Clean up
        await File(zipPath).delete();
      });
    });

    group('Cross-Format Compatibility Tests', () {
      test('should import JSON export as ZIP successfully', () async {
        // Arrange - Create JSON export first
        final note = {
          'id': 'json_to_zip_test',
          'title': 'JSON to ZIP Test',
          'content': 'This note was exported as JSON and imported as ZIP',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Export as single note JSON
        final jsonPath = await backupService.exportSingleNoteToJson(note: note);

        // Act - Import JSON
        final jsonImportResult = await importService.importFromJson(filePath: jsonPath);

        // Assert - JSON import should work
        expect(jsonImportResult.errors, isEmpty);
        expect(jsonImportResult.notesCreated, equals(1));
        expect(jsonImportResult.warnings, isEmpty);

        // Now test the same note in ZIP format
        final zipPath = await backupService.exportNotesToZip(
          notes: [note],
          mediaPaths: [],
        );

        final zipImportResult = await importService.importFromZip(filePath: zipPath);

        // Assert - ZIP import should also work
        expect(zipImportResult.errors, isEmpty);
        expect(zipImportResult.notesCreated + zipImportResult.notesUpdated, equals(1));

        // Clean up
        await File(jsonPath).delete();
        await File(zipPath).delete();
      });

      test('should maintain data consistency across formats', () async {
        // Arrange - Create note with comprehensive data
        final comprehensiveNote = {
          'id': 'comprehensive_test',
          'title': 'Comprehensive Data Test',
          'content': '''This note contains:
- Multiple lines
- Special characters: àáâãäåæçèéêë
- Numbers: 123456789
- Symbols: !@#\$%^&*()_+-={}[]|\\:";'<>?,./
- Unicode: 🎉🎊🎈🎁🎀''',
          'createdAt': DateTime(2023, 6, 15, 14, 30, 0).toIso8601String(),
          'updatedAt': DateTime(2023, 6, 16, 9, 45, 30).toIso8601String(),
          'folder': 'Test Folder with Spaces',
          'tags': ['tag1', 'tag-with-dash', 'tag_with_underscore', '标签'],
          'images': ['image1.jpg', 'image2.png'],
          'voiceNotes': ['audio1.m4a', 'audio2.wav'],
          'pinned': true,
        };

        // Act - Export as JSON
        final jsonPath = await backupService.exportSingleNoteToJson(note: comprehensiveNote);
        
        // Export as ZIP
        final zipPath = await backupService.exportNotesToZip(
          notes: [comprehensiveNote],
          mediaPaths: [],
        );

        // Import both formats
        final jsonImportResult = await importService.importFromJson(filePath: jsonPath);
        final zipImportResult = await importService.importFromZip(filePath: zipPath);

        // Assert - Both should import successfully
        expect(jsonImportResult.errors, isEmpty);
        expect(zipImportResult.errors, isEmpty);
        expect(jsonImportResult.notesCreated, equals(1));
        expect(zipImportResult.notesCreated + zipImportResult.notesUpdated, equals(1));

        // Verify data consistency by checking the ZIP contents
        final zipBytes = await File(zipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final notesFile = archive.firstWhere((file) => file.name == 'notes.json');
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final zipNote = (jsonDecode(notesContent) as List)[0];

        // Compare all fields
        expect(zipNote['id'], equals(comprehensiveNote['id']));
        expect(zipNote['title'], equals(comprehensiveNote['title']));
        expect(zipNote['content'], equals(comprehensiveNote['content']));
        expect(zipNote['createdAt'], equals(comprehensiveNote['createdAt']));
        expect(zipNote['updatedAt'], equals(comprehensiveNote['updatedAt']));
        expect(zipNote['folder'], equals(comprehensiveNote['folder']));
        expect(zipNote['tags'], equals(comprehensiveNote['tags']));
        expect(zipNote['pinned'], equals(comprehensiveNote['pinned']));

        // Clean up
        await File(jsonPath).delete();
        await File(zipPath).delete();
      });
    });

    group('Performance and Stress Tests', () {
      test('should handle rapid export/import cycles', () async {
        // Arrange - Create multiple small backups
        const cycleCount = 10;
        final notes = [
          {
            'id': 'cycle_test',
            'title': 'Cycle Test Note',
            'content': 'Testing rapid export/import cycles',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ];

        final zipPaths = <String>[];

        // Act - Perform multiple export/import cycles
        final startTime = DateTime.now();
        
        for (int i = 0; i < cycleCount; i++) {
          // Export
          final zipPath = await backupService.exportNotesToZip(
            notes: notes,
            mediaPaths: [],
            customFileName: 'cycle_test_$i.zip',
          );
          zipPaths.add(zipPath);

          // Import
          final importResult = await importService.importFromZip(filePath: zipPath);
          expect(importResult.errors, isEmpty);
        }

        final totalTime = DateTime.now().difference(startTime);

        // Assert - Should complete all cycles efficiently
        expect(totalTime.inSeconds, lessThan(60)); // Should complete within 1 minute
        expect(zipPaths.length, equals(cycleCount));

        // Clean up
        for (final path in zipPaths) {
          await File(path).delete();
        }
      });

      test('should handle memory efficiently with large content', () async {
        // Arrange - Create note with very large content
        const largeContentSize = 1024 * 1024; // 1MB of text
        final largeContent = 'A' * largeContentSize;
        
        final largeNote = {
          'id': 'memory_test',
          'title': 'Memory Test Note',
          'content': largeContent,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Act - Export and import large note
        final zipPath = await backupService.exportNotesToZip(
          notes: [largeNote],
          mediaPaths: [],
        );

        final importResult = await importService.importFromZip(filePath: zipPath);

        // Assert - Should handle large content without issues
        expect(importResult.errors, isEmpty);
        expect(importResult.notesCreated, equals(1));

        // Verify content size is preserved
        final zipBytes = await File(zipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final notesFile = archive.firstWhere((file) => file.name == 'notes.json');
        final notesContent = utf8.decode(notesFile.content as List<int>);
        final importedNote = (jsonDecode(notesContent) as List)[0];
        
        expect(importedNote['content'].length, equals(largeContentSize));

        // Clean up
        await File(zipPath).delete();
      });
    });
  });
}
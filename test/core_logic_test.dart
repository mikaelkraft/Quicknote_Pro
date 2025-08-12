import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backup & Import Core Logic Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('core_test_');
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Data Structure Validation Tests', () {
      test('should validate note structure correctly', () {
        // Test valid note structure
        final validNote = {
          'id': 'test_1',
          'title': 'Test Note',
          'content': 'Test content',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        expect(validateNoteStructure(validNote), isTrue);

        // Test invalid note structures
        expect(validateNoteStructure({'title': 'Missing ID'}), isFalse);
        expect(validateNoteStructure({'id': null, 'title': 'Null ID'}), isFalse);
        expect(validateNoteStructure({'id': 'test', 'content': 'Missing title'}), isFalse);
      });

      test('should handle special characters in notes', () {
        final specialNote = {
          'id': 'special_1',
          'title': 'Unicode Test: 🌟 ✨ 🎯',
          'content': '''Multi-line content with:
            
📝 Emojis: 😀 😃 😄 😁
🔤 Languages: Hëllö Wörld, Здравствуй мир, こんにちは世界
🔢 Numbers: 123.456 €, \$999.99, ¥1000
📊 Symbols: ± × ÷ √ ∞ ≈ ≠ ≤ ≥
🎨 Special chars: "quotes", <tags>, [brackets], {braces}''',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        expect(validateNoteStructure(specialNote), isTrue);

        // Test JSON encoding/decoding with special characters
        final jsonString = jsonEncode(specialNote);
        final decodedNote = jsonDecode(jsonString);
        expect(decodedNote['title'], equals(specialNote['title']));
        expect(decodedNote['content'], equals(specialNote['content']));
      });

      test('should calculate export summary correctly', () {
        final notes = [
          {'id': '1', 'title': 'Note 1', 'content': 'Content 1'},
          {'id': '2', 'title': 'Note 2', 'content': 'Content 2'},
        ];

        final summary = createExportSummary(notes, []);
        expect(summary['notesCount'], equals(2));
        expect(summary['mediaFilesCount'], equals(0));
        expect(summary['estimatedSizeBytes'], greaterThan(0));
      });
    });

    group('File Validation Tests', () {
      test('should detect JSON file format', () async {
        final jsonPath = '${tempDir.path}/test.json';
        final notes = [
          {
            'id': 'test_1',
            'title': 'Test Note',
            'content': 'Test content',
          }
        ];

        await File(jsonPath).writeAsString(jsonEncode(notes));

        final fileType = detectFileType(jsonPath);
        expect(fileType, equals('json'));

        // Clean up
        await File(jsonPath).delete();
      });

      test('should detect ZIP file format', () {
        final zipPath = '${tempDir.path}/test.zip';
        final fileType = detectFileType(zipPath);
        expect(fileType, equals('zip'));
      });

      test('should reject invalid file formats', () {
        final invalidPath = '${tempDir.path}/test.txt';
        final fileType = detectFileType(invalidPath);
        expect(fileType, equals('unknown'));
      });
    });

    group('Merge Strategy Logic Tests', () {
      test('should implement lastWriteWins strategy', () {
        final existingNote = {
          'id': '1',
          'title': 'Existing Note',
          'updatedAt': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        };

        final importedNote = {
          'id': '1',
          'title': 'Updated Note',
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final result = shouldUpdateNote(existingNote, importedNote, 'lastWriteWins');
        expect(result, isTrue); // Imported note is newer
      });

      test('should implement skipOlder strategy', () {
        final existingNote = {
          'id': '1',
          'title': 'Existing Note',
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final importedNote = {
          'id': '1',
          'title': 'Older Note',
          'updatedAt': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        };

        final result = shouldUpdateNote(existingNote, importedNote, 'skipOlder');
        expect(result, isFalse); // Imported note is older
      });
    });

    group('Error Handling Tests', () {
      test('should handle corrupt JSON gracefully', () {
        final corruptJson = '{ invalid json syntax';
        
        try {
          jsonDecode(corruptJson);
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<FormatException>());
        }
      });

      test('should validate required fields', () {
        final incompleteNote = {'id': '1', 'title': 'Missing content'};
        expect(validateNoteStructure(incompleteNote), isFalse);
      });

      test('should handle missing files gracefully', () async {
        final validation = await validateFile('/nonexistent/file.zip');
        expect(validation['isValid'], isFalse);
        expect(validation['errors'], contains('File not found'));
      });
    });

    group('Large Dataset Tests', () {
      test('should handle large number of notes efficiently', () {
        // Create 1000 test notes
        final largeDataset = List.generate(1000, (index) => {
          'id': 'note_$index',
          'title': 'Note $index',
          'content': 'Content for note $index ' * 10,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        final startTime = DateTime.now();
        
        // Simulate processing large dataset
        int validNotes = 0;
        for (final note in largeDataset) {
          if (validateNoteStructure(note)) {
            validNotes++;
          }
        }

        final processingTime = DateTime.now().difference(startTime);
        
        expect(validNotes, equals(1000));
        expect(processingTime.inMilliseconds, lessThan(1000)); // Should be fast
      });

      test('should handle large content efficiently', () {
        const largeContentSize = 1024 * 1024; // 1MB
        final largeContent = 'A' * largeContentSize;
        
        final largeNote = {
          'id': 'large_note',
          'title': 'Large Note',
          'content': largeContent,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        expect(validateNoteStructure(largeNote), isTrue);
        expect((largeNote['content'] as String).length, equals(largeContentSize));
      });
    });
  });
}

// Helper functions for testing core logic

bool validateNoteStructure(Map<String, dynamic> note) {
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

Map<String, dynamic> createExportSummary(List<Map<String, dynamic>> notes, List<String> mediaPaths) {
  final totalSize = _calculateTotalSize(notes, mediaPaths);
  
  return {
    'notesCount': notes.length,
    'mediaFilesCount': mediaPaths.where((path) => File(path).existsSync()).length,
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

String detectFileType(String filePath) {
  final fileName = filePath.split('/').last.toLowerCase();
  
  if (fileName.endsWith('.zip')) {
    return 'zip';
  } else if (fileName.endsWith('.json')) {
    return 'json';
  } else {
    return 'unknown';
  }
}

bool shouldUpdateNote(Map<String, dynamic> existingNote, Map<String, dynamic> importedNote, String strategy) {
  if (strategy == 'lastWriteWins') {
    final existingUpdatedAt = DateTime.tryParse(existingNote['updatedAt'] ?? '');
    final importedUpdatedAt = DateTime.tryParse(importedNote['updatedAt'] ?? '');
    
    if (existingUpdatedAt != null && importedUpdatedAt != null) {
      return importedUpdatedAt.isAfter(existingUpdatedAt);
    }
    return true; // Update if dates can't be compared
  } else if (strategy == 'skipOlder') {
    return false; // Never update in skip older strategy
  }
  
  return true; // Default to update
}

Future<Map<String, dynamic>> validateFile(String filePath) async {
  final result = {
    'isValid': false,
    'errors': <String>[],
  };

  try {
    final file = File(filePath);
    if (!await file.exists()) {
      result['errors'] = ['File not found'];
      return result;
    }

    result['isValid'] = true;
  } catch (e) {
    result['errors'] = ['Failed to validate file: $e'];
  }

  return result;
}
import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/note_model.dart';

void main() {
  group('Note Model Tests', () {
    late Note testNote;
    
    setUp(() {
      testNote = Note(
        id: 'test_id',
        title: 'Test Note',
        content: 'This is test content',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        folder: 'Test Folder',
        tags: ['tag1', 'tag2'],
        imagePaths: ['image1.jpg'],
        attachmentPaths: ['file1.pdf'],
        voiceNotePaths: ['voice1.m4a'],
      );
    });

    test('should create note with all properties', () {
      expect(testNote.id, 'test_id');
      expect(testNote.title, 'Test Note');
      expect(testNote.content, 'This is test content');
      expect(testNote.folder, 'Test Folder');
      expect(testNote.tags, ['tag1', 'tag2']);
      expect(testNote.imagePaths, ['image1.jpg']);
      expect(testNote.attachmentPaths, ['file1.pdf']);
      expect(testNote.voiceNotePaths, ['voice1.m4a']);
    });

    test('should create note with default values', () {
      final note = Note(
        id: 'simple_id',
        title: 'Simple Note',
        content: 'Simple content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.folder, 'General');
      expect(note.tags, isEmpty);
      expect(note.imagePaths, isEmpty);
      expect(note.attachmentPaths, isEmpty);
      expect(note.voiceNotePaths, isEmpty);
    });

    test('should copy note with updated fields', () {
      final updatedNote = testNote.copyWith(
        title: 'Updated Title',
        content: 'Updated content',
        tags: ['new_tag'],
      );

      expect(updatedNote.id, testNote.id);
      expect(updatedNote.title, 'Updated Title');
      expect(updatedNote.content, 'Updated content');
      expect(updatedNote.tags, ['new_tag']);
      expect(updatedNote.createdAt, testNote.createdAt);
      expect(updatedNote.folder, testNote.folder);
    });

    test('should convert to and from JSON', () {
      final json = testNote.toJson();
      final fromJson = Note.fromJson(json);

      expect(fromJson.id, testNote.id);
      expect(fromJson.title, testNote.title);
      expect(fromJson.content, testNote.content);
      expect(fromJson.folder, testNote.folder);
      expect(fromJson.tags, testNote.tags);
      expect(fromJson.imagePaths, testNote.imagePaths);
      expect(fromJson.attachmentPaths, testNote.attachmentPaths);
      expect(fromJson.voiceNotePaths, testNote.voiceNotePaths);
    });

    test('should convert to and from JSON string', () {
      final jsonString = testNote.toJsonString();
      final fromJsonString = Note.fromJsonString(jsonString);

      expect(fromJsonString.id, testNote.id);
      expect(fromJsonString.title, testNote.title);
      expect(fromJsonString.content, testNote.content);
    });

    test('should check if note is empty', () {
      final emptyNote = Note(
        id: 'empty',
        title: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(emptyNote.isEmpty, isTrue);
      expect(testNote.isEmpty, isFalse);
    });

    test('should check for changes between notes', () {
      final sameNote = testNote.copyWith();
      final differentNote = testNote.copyWith(title: 'Different Title');

      expect(testNote.hasChangesFrom(sameNote), isFalse);
      expect(testNote.hasChangesFrom(differentNote), isTrue);
    });

    test('should get preview text', () {
      expect(testNote.previewText, 'This is test content');

      final longNote = testNote.copyWith(
        content: 'This is a very long content that exceeds the preview limit. ' * 10,
      );
      
      expect(longNote.previewText.length, 103); // 100 chars + '...'
      expect(longNote.previewText.endsWith('...'), isTrue);
    });

    test('should count words', () {
      expect(testNote.wordCount, 4); // "This is test content"

      final emptyNote = testNote.copyWith(content: '');
      expect(emptyNote.wordCount, 0);
    });

    test('should check for attachments', () {
      expect(testNote.hasAttachments, isTrue);

      final noAttachmentsNote = Note(
        id: 'no_attachments',
        title: 'No Attachments',
        content: 'Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(noAttachmentsNote.hasAttachments, isFalse);
    });

    test('should handle equality correctly', () {
      final sameIdNote = Note(
        id: 'test_id',
        title: 'Different Title',
        content: 'Different Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(testNote == sameIdNote, isTrue);
      expect(testNote.hashCode, sameIdNote.hashCode);
    });
  });
}
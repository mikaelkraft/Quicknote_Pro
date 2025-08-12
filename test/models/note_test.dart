import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/note.dart';
import 'package:quicknote_pro/models/attachment.dart';

void main() {
  group('Note Model Tests', () {
    late Note testNote;
    late Attachment testImageAttachment;
    late Attachment testFileAttachment;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;
    
    setUp(() {
      testCreatedAt = DateTime(2024, 1, 1, 12, 0, 0);
      testUpdatedAt = DateTime(2024, 1, 2, 12, 0, 0);
      
      testImageAttachment = Attachment(
        id: 'img_1',
        name: 'image.jpg',
        relativePath: 'attachments/image.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1024000,
        type: AttachmentType.image,
        createdAt: testCreatedAt,
      );
      
      testFileAttachment = Attachment(
        id: 'file_1',
        name: 'document.pdf',
        relativePath: 'attachments/document.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2048000,
        type: AttachmentType.file,
        createdAt: testCreatedAt,
      );
      
      testNote = Note(
        id: 'test_note_id',
        title: 'Test Note',
        content: 'This is test content for the note',
        attachments: [testImageAttachment, testFileAttachment],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        folder: 'Work',
        tags: ['important', 'project'],
      );
    });

    test('should create note with all properties', () {
      expect(testNote.id, 'test_note_id');
      expect(testNote.title, 'Test Note');
      expect(testNote.content, 'This is test content for the note');
      expect(testNote.attachments.length, 2);
      expect(testNote.attachments[0], testImageAttachment);
      expect(testNote.attachments[1], testFileAttachment);
      expect(testNote.createdAt, testCreatedAt);
      expect(testNote.updatedAt, testUpdatedAt);
    });

    test('should create note with default empty attachments', () {
      final note = Note(
        id: 'simple_id',
        title: 'Simple Note',
        content: 'Simple content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.attachments, isEmpty);
    });

    test('should copy note with updated fields', () {
      final updatedNote = testNote.copyWith(
        title: 'Updated Title',
        content: 'Updated content',
        attachments: [testImageAttachment],
      );

      expect(updatedNote.id, testNote.id);
      expect(updatedNote.title, 'Updated Title');
      expect(updatedNote.content, 'Updated content');
      expect(updatedNote.attachments.length, 1);
      expect(updatedNote.attachments[0], testImageAttachment);
      expect(updatedNote.createdAt, testNote.createdAt);
      expect(updatedNote.updatedAt, testNote.updatedAt);
    });

    test('should convert to and from JSON', () {
      final json = testNote.toJson();
      final fromJson = Note.fromJson(json);

      expect(fromJson.id, testNote.id);
      expect(fromJson.title, testNote.title);
      expect(fromJson.content, testNote.content);
      expect(fromJson.attachments.length, testNote.attachments.length);
      expect(fromJson.attachments[0].id, testNote.attachments[0].id);
      expect(fromJson.attachments[1].id, testNote.attachments[1].id);
      expect(fromJson.createdAt, testNote.createdAt);
      expect(fromJson.updatedAt, testNote.updatedAt);
    });

    test('should convert to and from JSON string', () {
      final jsonString = testNote.toJsonString();
      final fromJsonString = Note.fromJsonString(jsonString);

      expect(fromJsonString.id, testNote.id);
      expect(fromJsonString.title, testNote.title);
      expect(fromJsonString.content, testNote.content);
      expect(fromJsonString.attachments.length, testNote.attachments.length);
    });

    test('should handle JSON with empty attachments', () {
      final noteWithoutAttachments = testNote.copyWith(attachments: []);
      final json = noteWithoutAttachments.toJson();
      final fromJson = Note.fromJson(json);

      expect(fromJson.attachments, isEmpty);
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

      final whitespaceNote = emptyNote.copyWith(
        title: '   ',
        content: '\n\t  ',
      );
      expect(whitespaceNote.isEmpty, isTrue);
    });

    test('should check for changes between notes', () {
      final sameNote = testNote.copyWith();
      final differentNote = testNote.copyWith(title: 'Different Title');
      final differentAttachmentsNote = testNote.copyWith(attachments: [testImageAttachment]);

      expect(testNote.hasChangesFrom(sameNote), isFalse);
      expect(testNote.hasChangesFrom(differentNote), isTrue);
      expect(testNote.hasChangesFrom(differentAttachmentsNote), isTrue);
    });

    test('should get preview text', () {
      expect(testNote.previewText, 'This is test content for the note');

      final longNote = testNote.copyWith(
        content: 'This is a very long content that exceeds the preview limit and should be truncated. ' * 10,
      );
      
      expect(longNote.previewText.length, 103); // 100 chars + '...'
      expect(longNote.previewText.endsWith('...'), isTrue);

      final emptyContentNote = testNote.copyWith(content: '');
      expect(emptyContentNote.previewText, 'No content');
    });

    test('should count words', () {
      expect(testNote.wordCount, 8); // "This is test content for the note"

      final emptyNote = testNote.copyWith(content: '');
      expect(emptyNote.wordCount, 0);

      final multiSpaceNote = testNote.copyWith(content: 'word1    word2\n\nword3');
      expect(multiSpaceNote.wordCount, 3);
    });

    test('should check for attachments', () {
      expect(testNote.hasAttachments, isTrue);

      final noAttachmentsNote = testNote.copyWith(attachments: []);
      expect(noAttachmentsNote.hasAttachments, isFalse);
    });

    test('should filter image attachments', () {
      final imageAttachments = testNote.imageAttachments;
      expect(imageAttachments.length, 1);
      expect(imageAttachments[0], testImageAttachment);
    });

    test('should filter file attachments', () {
      final fileAttachments = testNote.fileAttachments;
      expect(fileAttachments.length, 1);
      expect(fileAttachments[0], testFileAttachment);
    });

    test('should calculate total attachment size', () {
      final totalSize = testNote.totalAttachmentSize;
      expect(totalSize, 3072000); // 1024000 + 2048000

      final noSizeAttachment = testImageAttachment.copyWith(sizeBytes: null);
      final noteWithNullSize = testNote.copyWith(attachments: [noSizeAttachment, testFileAttachment]);
      expect(noteWithNullSize.totalAttachmentSize, 2048000); // Only counts non-null sizes
    });

    test('should add attachment', () {
      final newAttachment = Attachment(
        id: 'new_attachment',
        name: 'new_file.txt',
        relativePath: 'attachments/new_file.txt',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );

      final updatedNote = testNote.addAttachment(newAttachment);
      
      expect(updatedNote.attachments.length, 3);
      expect(updatedNote.attachments.last, newAttachment);
      expect(updatedNote.updatedAt.isAfter(testNote.updatedAt), isTrue);
    });

    test('should remove attachment', () {
      final updatedNote = testNote.removeAttachment('img_1');
      
      expect(updatedNote.attachments.length, 1);
      expect(updatedNote.attachments[0], testFileAttachment);
      expect(updatedNote.updatedAt.isAfter(testNote.updatedAt), isTrue);
    });

    test('should not change note when removing non-existent attachment', () {
      final updatedNote = testNote.removeAttachment('non_existent');
      
      expect(updatedNote.attachments.length, 2);
      expect(updatedNote.attachments, testNote.attachments);
    });

    test('should replace attachment', () {
      final newAttachment = Attachment(
        id: 'img_1',
        name: 'new_image.png',
        relativePath: 'attachments/new_image.png',
        type: AttachmentType.image,
        createdAt: DateTime.now(),
      );

      final updatedNote = testNote.replaceAttachment('img_1', newAttachment);
      
      expect(updatedNote.attachments.length, 2);
      expect(updatedNote.attachments[0], newAttachment);
      expect(updatedNote.attachments[1], testFileAttachment);
      expect(updatedNote.updatedAt.isAfter(testNote.updatedAt), isTrue);
    });

    test('should not change note when replacing non-existent attachment', () {
      final newAttachment = Attachment(
        id: 'non_existent',
        name: 'new_file.txt',
        relativePath: 'attachments/new_file.txt',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );

      final updatedNote = testNote.replaceAttachment('non_existent', newAttachment);
      
      expect(updatedNote.attachments.length, 2);
      expect(updatedNote.attachments, testNote.attachments);
    });

    test('should handle equality correctly', () {
      final sameIdNote = Note(
        id: 'test_note_id',
        title: 'Different Title',
        content: 'Different Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(testNote == sameIdNote, isTrue);
      expect(testNote.hashCode, sameIdNote.hashCode);
    });

    test('should generate string representation', () {
      final str = testNote.toString();
      expect(str, contains('test_note_id'));
      expect(str, contains('Test Note'));
      expect(str, contains('34 chars')); // content length
      expect(str, contains('attachments: 2'));
      expect(str, contains('folder: Work'));
      expect(str, contains('tags: [important, project]'));
    });

    // Tests for new features
    test('should create note with folder and tags', () {
      expect(testNote.folder, 'Work');
      expect(testNote.tags, ['important', 'project']);
    });

    test('should handle default values', () {
      final defaultNote = Note(
        id: 'default_id',
        title: 'Default Note',
        content: 'Content',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
      
      expect(defaultNote.folder, 'General');
      expect(defaultNote.tags, isEmpty);
      expect(defaultNote.attachments, isEmpty);
    });

    test('should add tags correctly', () {
      final noteWithNewTag = testNote.addTag('urgent');
      expect(noteWithNewTag.tags, contains('urgent'));
      expect(noteWithNewTag.tags.length, 3);
      
      // Should not add duplicate tags
      final duplicateTag = testNote.addTag('important');
      expect(duplicateTag.tags.length, 2);
    });

    test('should remove tags correctly', () {
      final noteWithoutTag = testNote.removeTag('important');
      expect(noteWithoutTag.tags, ['project']);
      expect(noteWithoutTag.tags.length, 1);
    });

    test('should update folder correctly', () {
      final noteWithNewFolder = testNote.updateFolder('Personal');
      expect(noteWithNewFolder.folder, 'Personal');
      expect(noteWithNewFolder.updatedAt, isNot(testNote.updatedAt));
    });

    test('should check for tags', () {
      expect(testNote.hasTag('important'), isTrue);
      expect(testNote.hasTag('urgent'), isFalse);
    });

    test('should handle voice attachments', () {
      final voiceAttachment = Attachment(
        id: 'voice_1',
        name: 'note.m4a',
        relativePath: 'attachments/note.m4a',
        mimeType: 'audio/mp4',
        type: AttachmentType.voice,
        createdAt: testCreatedAt,
        duration: Duration(minutes: 3, seconds: 45),
      );
      
      final noteWithVoice = testNote.addAttachment(voiceAttachment);
      expect(noteWithVoice.hasVoiceNotes, isTrue);
      expect(noteWithVoice.voiceAttachments.length, 1);
      expect(noteWithVoice.totalVoiceDuration, Duration(minutes: 3, seconds: 45));
    });

    test('should get attachments by type', () {
      final voiceAttachment = Attachment(
        id: 'voice_1',
        name: 'note.m4a',
        relativePath: 'attachments/note.m4a',
        type: AttachmentType.voice,
        createdAt: testCreatedAt,
      );
      
      final noteWithVoice = testNote.addAttachment(voiceAttachment);
      
      expect(noteWithVoice.getAttachmentsByType(AttachmentType.image).length, 1);
      expect(noteWithVoice.getAttachmentsByType(AttachmentType.file).length, 1);
      expect(noteWithVoice.getAttachmentsByType(AttachmentType.voice).length, 1);
    });

    test('should detect changes including new fields', () {
      final changedNote = testNote.copyWith(folder: 'Personal');
      expect(testNote.hasChangesFrom(changedNote), isTrue);
      
      final changedTags = testNote.copyWith(tags: ['different']);
      expect(testNote.hasChangesFrom(changedTags), isTrue);
    });

    test('should handle JSON serialization with new fields', () {
      final json = testNote.toJson();
      expect(json['folder'], 'Work');
      expect(json['tags'], ['important', 'project']);
      
      final fromJson = Note.fromJson(json);
      expect(fromJson.folder, 'Work');
      expect(fromJson.tags, ['important', 'project']);
    });

    test('should handle JSON deserialization with missing optional fields', () {
      final jsonWithoutOptionalFields = {
        'id': 'test_id',
        'title': 'Test',
        'content': 'Content',
        'attachments': [],
        'createdAt': testCreatedAt.toIso8601String(),
        'updatedAt': testUpdatedAt.toIso8601String(),
      };
      
      final note = Note.fromJson(jsonWithoutOptionalFields);
      expect(note.folder, 'General');
      expect(note.tags, isEmpty);
    });

    test('should handle copyWith with new fields', () {
      final updated = testNote.copyWith(
        folder: 'Personal',
        tags: ['new', 'tags'],
      );
      
      expect(updated.folder, 'Personal');
      expect(updated.tags, ['new', 'tags']);
      expect(updated.id, testNote.id); // Other fields unchanged
    });
  });
}
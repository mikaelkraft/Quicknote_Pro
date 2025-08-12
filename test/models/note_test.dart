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
      );
    });

    test('should create note using Note.create() factory', () {
      final createdNote = Note.create(
        title: 'Factory Note',
        content: 'Content from factory',
      );

      expect(createdNote.title, 'Factory Note');
      expect(createdNote.content, 'Content from factory');
      expect(createdNote.attachments, isEmpty);
      expect(createdNote.id, isNotEmpty);
      expect(createdNote.id, startsWith('note_'));
      expect(createdNote.createdAt, isA<DateTime>());
      expect(createdNote.updatedAt, isA<DateTime>());
      expect(createdNote.createdAt, equals(createdNote.updatedAt));
    });

    test('should create note with default empty values using Note.create()', () {
      final createdNote = Note.create();

      expect(createdNote.title, isEmpty);
      expect(createdNote.content, isEmpty);
      expect(createdNote.attachments, isEmpty);
      expect(createdNote.id, isNotEmpty);
    });

    test('should create note with attachments using Note.create()', () {
      final createdNote = Note.create(
        title: 'Note with attachments',
        content: 'Content',
        attachments: [testImageAttachment],
      );

      expect(createdNote.attachments.length, 1);
      expect(createdNote.attachments[0], testImageAttachment);
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
    });
  });
}
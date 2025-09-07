import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/note.dart';
import 'package:quicknote_pro/models/attachment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Note Attachment Integration Tests', () {
    test('should add and remove attachments from note', () {
      // Create a new note
      final note = Note.create(title: 'Test Note', content: 'Test content');
      expect(note.attachments, isEmpty);
      
      // Create test attachment
      final attachment = Attachment(
        id: 'test-attachment',
        name: 'test.jpg',
        relativePath: 'attachments/test.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1024,
        type: AttachmentType.image,
        createdAt: DateTime.now(),
      );
      
      // Add attachment to note
      final noteWithAttachment = note.addAttachment(attachment);
      expect(noteWithAttachment.attachments, hasLength(1));
      expect(noteWithAttachment.hasAttachments, isTrue);
      expect(noteWithAttachment.imageAttachments, hasLength(1));
      expect(noteWithAttachment.fileAttachments, isEmpty);
      
      // Remove attachment from note
      final noteWithoutAttachment = noteWithAttachment.removeAttachment(attachment.id);
      expect(noteWithoutAttachment.attachments, isEmpty);
      expect(noteWithoutAttachment.hasAttachments, isFalse);
    });
    
    test('should filter attachments by type', () {
      final note = Note.create(title: 'Test Note', content: 'Test content');
      
      final imageAttachment = Attachment(
        id: 'image-1',
        name: 'photo.jpg',
        relativePath: 'attachments/photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 2048,
        type: AttachmentType.image,
        createdAt: DateTime.now(),
      );
      
      final fileAttachment = Attachment(
        id: 'file-1',
        name: 'document.pdf',
        relativePath: 'attachments/document.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 4096,
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );
      
      final noteWithAttachments = note
          .addAttachment(imageAttachment)
          .addAttachment(fileAttachment);
      
      expect(noteWithAttachments.attachments, hasLength(2));
      expect(noteWithAttachments.imageAttachments, hasLength(1));
      expect(noteWithAttachments.fileAttachments, hasLength(1));
      expect(noteWithAttachments.totalAttachmentSize, equals(6144));
    });
    
    test('should serialize note with attachments to JSON and back', () {
      final originalNote = Note.create(title: 'Test Note', content: 'Test content');
      
      final attachment = Attachment(
        id: 'test-attachment',
        name: 'test.png',
        relativePath: 'attachments/test.png',
        mimeType: 'image/png',
        sizeBytes: 512,
        type: AttachmentType.image,
        createdAt: DateTime.now(),
      );
      
      final noteWithAttachment = originalNote.addAttachment(attachment);
      
      // Serialize to JSON
      final json = noteWithAttachment.toJson();
      expect(json['attachments'], isA<List>());
      expect(json['attachments'], hasLength(1));
      
      // Deserialize from JSON
      final deserializedNote = Note.fromJson(json);
      expect(deserializedNote.attachments, hasLength(1));
      expect(deserializedNote.attachments.first.id, equals(attachment.id));
      expect(deserializedNote.attachments.first.name, equals(attachment.name));
      expect(deserializedNote.attachments.first.type, equals(attachment.type));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/note.dart' as NewNote;
import 'package:quicknote_pro/models/attachment.dart';
import 'package:quicknote_pro/models/note_model.dart' as OldNote;
import 'package:quicknote_pro/services/notes/note_model_adapter.dart';

void main() {
  group('Note Model Adapter Tests', () {
    late OldNote.Note testOldNote;
    late NewNote.Note testNewNote;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;
    
    setUp(() {
      testCreatedAt = DateTime(2024, 1, 1, 12, 0, 0);
      testUpdatedAt = DateTime(2024, 1, 2, 12, 0, 0);
      
      testOldNote = OldNote.Note(
        id: 'test_id',
        title: 'Test Note',
        content: 'Test content',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        folder: 'Work',
        tags: ['important', 'project'],
        imagePaths: ['attachments/image1.jpg', 'attachments/image2.png'],
        attachmentPaths: ['attachments/document.pdf', 'attachments/file.txt'],
        voiceNotePaths: ['attachments/voice1.m4a', 'attachments/voice2.mp3'],
      );
      
      testNewNote = NewNote.Note(
        id: 'test_id',
        title: 'Test Note',
        content: 'Test content',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        folder: 'Work',
        tags: ['important', 'project'],
        attachments: [
          Attachment(
            id: 'img_test_id_0',
            name: 'image1.jpg',
            relativePath: 'attachments/image1.jpg',
            mimeType: 'image/jpeg',
            type: AttachmentType.image,
            createdAt: testCreatedAt,
          ),
          Attachment(
            id: 'file_test_id_0',
            name: 'document.pdf',
            relativePath: 'attachments/document.pdf',
            mimeType: 'application/pdf',
            type: AttachmentType.file,
            createdAt: testCreatedAt,
          ),
          Attachment(
            id: 'voice_test_id_0',
            name: 'voice1.m4a',
            relativePath: 'attachments/voice1.m4a',
            mimeType: 'audio/mp4',
            type: AttachmentType.voice,
            createdAt: testCreatedAt,
          ),
        ],
      );
    });

    test('should convert old note to new note format', () {
      final newNote = NoteModelAdapter.fromOldNote(testOldNote);
      
      expect(newNote.id, testOldNote.id);
      expect(newNote.title, testOldNote.title);
      expect(newNote.content, testOldNote.content);
      expect(newNote.createdAt, testOldNote.createdAt);
      expect(newNote.updatedAt, testOldNote.updatedAt);
      expect(newNote.folder, testOldNote.folder);
      expect(newNote.tags, testOldNote.tags);
      
      // Check attachments conversion
      expect(newNote.attachments.length, 5); // 2 images + 2 files + 2 voice
      
      // Check image attachments
      final imageAttachments = newNote.imageAttachments;
      expect(imageAttachments.length, 2);
      expect(imageAttachments[0].name, 'image1.jpg');
      expect(imageAttachments[0].relativePath, 'attachments/image1.jpg');
      expect(imageAttachments[0].type, AttachmentType.image);
      expect(imageAttachments[1].name, 'image2.png');
      expect(imageAttachments[1].mimeType, 'image/png');
      
      // Check file attachments
      final fileAttachments = newNote.fileAttachments;
      expect(fileAttachments.length, 2);
      expect(fileAttachments[0].name, 'document.pdf');
      expect(fileAttachments[0].mimeType, 'application/pdf');
      expect(fileAttachments[1].name, 'file.txt');
      expect(fileAttachments[1].mimeType, 'text/plain');
      
      // Check voice attachments
      final voiceAttachments = newNote.voiceAttachments;
      expect(voiceAttachments.length, 2);
      expect(voiceAttachments[0].name, 'voice1.m4a');
      expect(voiceAttachments[0].mimeType, 'audio/mp4');
      expect(voiceAttachments[1].name, 'voice2.mp3');
      expect(voiceAttachments[1].mimeType, 'audio/mpeg');
    });

    test('should convert new note to old note format', () {
      final oldNote = NoteModelAdapter.toOldNote(testNewNote);
      
      expect(oldNote.id, testNewNote.id);
      expect(oldNote.title, testNewNote.title);
      expect(oldNote.content, testNewNote.content);
      expect(oldNote.createdAt, testNewNote.createdAt);
      expect(oldNote.updatedAt, testNewNote.updatedAt);
      expect(oldNote.folder, testNewNote.folder);
      expect(oldNote.tags, testNewNote.tags);
      
      // Check path arrays
      expect(oldNote.imagePaths.length, 1);
      expect(oldNote.imagePaths[0], 'attachments/image1.jpg');
      
      expect(oldNote.attachmentPaths.length, 1);
      expect(oldNote.attachmentPaths[0], 'attachments/document.pdf');
      
      expect(oldNote.voiceNotePaths.length, 1);
      expect(oldNote.voiceNotePaths[0], 'attachments/voice1.m4a');
    });

    test('should handle round-trip conversion correctly', () {
      // Old -> New -> Old
      final newFromOld = NoteModelAdapter.fromOldNote(testOldNote);
      final backToOld = NoteModelAdapter.toOldNote(newFromOld);
      
      expect(backToOld.id, testOldNote.id);
      expect(backToOld.title, testOldNote.title);
      expect(backToOld.content, testOldNote.content);
      expect(backToOld.folder, testOldNote.folder);
      expect(backToOld.tags, testOldNote.tags);
      expect(backToOld.imagePaths, testOldNote.imagePaths);
      expect(backToOld.attachmentPaths, testOldNote.attachmentPaths);
      expect(backToOld.voiceNotePaths, testOldNote.voiceNotePaths);
    });

    test('should handle empty attachments', () {
      final emptyOldNote = OldNote.Note(
        id: 'empty_id',
        title: 'Empty Note',
        content: 'No attachments',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
      
      final newNote = NoteModelAdapter.fromOldNote(emptyOldNote);
      expect(newNote.attachments, isEmpty);
      expect(newNote.hasAttachments, isFalse);
      
      final backToOld = NoteModelAdapter.toOldNote(newNote);
      expect(backToOld.imagePaths, isEmpty);
      expect(backToOld.attachmentPaths, isEmpty);
      expect(backToOld.voiceNotePaths, isEmpty);
    });

    test('should extract filename correctly', () {
      final oldNote = OldNote.Note(
        id: 'test_id',
        title: 'Test',
        content: 'Test',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        imagePaths: ['path/to/some/deep/folder/image.jpg'],
      );
      
      final newNote = NoteModelAdapter.fromOldNote(oldNote);
      expect(newNote.imageAttachments[0].name, 'image.jpg');
    });

    test('should determine MIME types correctly', () {
      final oldNote = OldNote.Note(
        id: 'mime_test',
        title: 'MIME Test',
        content: 'Testing MIME types',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        imagePaths: ['test.jpg', 'test.png', 'test.gif', 'test.webp'],
        attachmentPaths: ['doc.pdf', 'file.docx', 'text.txt'],
        voiceNotePaths: ['audio.mp3', 'voice.wav'],
      );
      
      final newNote = NoteModelAdapter.fromOldNote(oldNote);
      
      // Check image MIME types
      final images = newNote.imageAttachments;
      expect(images[0].mimeType, 'image/jpeg'); // jpg
      expect(images[1].mimeType, 'image/png'); // png
      expect(images[2].mimeType, 'image/gif'); // gif
      expect(images[3].mimeType, 'image/webp'); // webp
      
      // Check file MIME types
      final files = newNote.fileAttachments;
      expect(files[0].mimeType, 'application/pdf'); // pdf
      expect(files[1].mimeType, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'); // docx
      expect(files[2].mimeType, 'text/plain'); // txt
      
      // Check voice MIME types
      final voices = newNote.voiceAttachments;
      expect(voices[0].mimeType, 'audio/mpeg'); // mp3
      expect(voices[1].mimeType, 'audio/wav'); // wav
    });

    test('should create compatible note', () {
      final result = NoteModelAdapter.createCompatibleNote(
        id: 'compatible_id',
        title: 'Compatible Note',
        content: 'This note works with both models',
        folder: 'Test',
        tags: ['compatible', 'test'],
        attachments: [
          Attachment(
            id: 'compat_img',
            name: 'image.jpg',
            relativePath: 'attachments/image.jpg',
            type: AttachmentType.image,
            createdAt: DateTime.now(),
          ),
        ],
      );
      
      expect(result['newModel'], isA<NewNote.Note>());
      expect(result['oldModel'], isA<OldNote.Note>());
      expect(result['json'], isA<Map<String, dynamic>>());
      
      final newNote = result['newModel'] as NewNote.Note;
      final oldNote = result['oldModel'] as OldNote.Note;
      
      expect(newNote.id, 'compatible_id');
      expect(oldNote.id, 'compatible_id');
      expect(newNote.title, oldNote.title);
      expect(newNote.content, oldNote.content);
      expect(newNote.folder, oldNote.folder);
      expect(newNote.tags, oldNote.tags);
    });

    test('should handle unknown file extensions', () {
      final oldNote = OldNote.Note(
        id: 'unknown_ext',
        title: 'Unknown Extension',
        content: 'Test unknown extensions',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        attachmentPaths: ['file.xyz', 'another.unknown'],
      );
      
      final newNote = NoteModelAdapter.fromOldNote(oldNote);
      final fileAttachments = newNote.fileAttachments;
      
      expect(fileAttachments[0].mimeType, isNull);
      expect(fileAttachments[1].mimeType, isNull);
    });
  });
}
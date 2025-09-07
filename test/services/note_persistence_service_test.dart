import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/note_persistence_service.dart';
import 'package:quicknote_pro/models/note.dart';
import 'package:quicknote_pro/models/attachment.dart';
import '../mocks/mock_notes_repository.dart';

void main() {
  group('NotePersistenceService Audio Tests', () {
    late NotePersistenceService service;
    late MockNotesRepository mockRepository;
    late Note testNote;
    late Attachment audioAttachment;

    setUp(() {
      mockRepository = MockNotesRepository();
      service = NotePersistenceService(mockRepository);
      
      audioAttachment = Attachment(
        id: 'audio_1',
        name: 'voice_note.m4a',
        relativePath: 'audio/voice_note.m4a',
        mimeType: 'audio/aac',
        sizeBytes: 512000,
        type: AttachmentType.audio,
        createdAt: DateTime.now(),
        durationSeconds: 120,
      );

      testNote = Note.create(
        title: 'Test Note',
        content: 'This is a test note',
        attachments: [audioAttachment],
      );
    });

    test('should add audio attachment to note', () async {
      const audioPath = '/path/to/voice_note.m4a';
      const durationSeconds = 180;
      const fileSizeBytes = 1024000;

      final updatedNote = await service.addAudioAttachment(
        testNote,
        audioPath,
        durationSeconds,
        fileSizeBytes: fileSizeBytes,
      );

      expect(updatedNote.audioAttachments.length, 2);
      
      final newAudio = updatedNote.audioAttachments.last;
      expect(newAudio.name, 'voice_note.m4a');
      expect(newAudio.relativePath, audioPath);
      expect(newAudio.durationSeconds, durationSeconds);
      expect(newAudio.sizeBytes, fileSizeBytes);
      expect(newAudio.mimeType, 'audio/aac');
      expect(newAudio.type, AttachmentType.audio);
    });

    test('should handle different audio file formats', () async {
      final testCases = [
        {'path': '/audio/voice.wav', 'expectedMime': 'audio/wav'},
        {'path': '/audio/voice.mp3', 'expectedMime': 'audio/mpeg'},
        {'path': '/audio/voice.aac', 'expectedMime': 'audio/aac'},
        {'path': '/audio/voice.unknown', 'expectedMime': null},
      ];

      for (final testCase in testCases) {
        final path = testCase['path'] as String;
        final expectedMime = testCase['expectedMime'] as String?;
        
        final updatedNote = await service.addAudioAttachment(
          testNote,
          path,
          60,
        );

        final newAudio = updatedNote.audioAttachments.last;
        expect(newAudio.mimeType, expectedMime);
      }
    });

    test('should remove audio attachment from note', () async {
      final updatedNote = await service.removeAttachment(testNote, 'audio_1');
      
      expect(updatedNote.audioAttachments.length, 0);
      expect(updatedNote.attachments.length, 0);
    });

    test('should generate unique IDs for audio attachments', () async {
      const audioPath = '/path/to/voice_note.m4a';
      
      final note1 = await service.addAudioAttachment(testNote, audioPath, 60);
      await Future.delayed(const Duration(milliseconds: 1)); // Ensure different timestamp
      final note2 = await service.addAudioAttachment(note1, audioPath, 60);

      expect(note2.audioAttachments.length, 3);
      
      final ids = note2.audioAttachments.map((a) => a.id).toSet();
      expect(ids.length, 3); // All IDs should be unique
    });

    test('should preserve other attachments when adding audio', () async {
      final imageAttachment = Attachment(
        id: 'img_1',
        name: 'image.jpg',
        relativePath: 'images/image.jpg',
        type: AttachmentType.image,
        createdAt: DateTime.now(),
      );

      final noteWithImage = testNote.addAttachment(imageAttachment);
      
      final updatedNote = await service.addAudioAttachment(
        noteWithImage,
        '/audio/new_voice.m4a',
        90,
      );

      expect(updatedNote.audioAttachments.length, 2);
      expect(updatedNote.imageAttachments.length, 1);
      expect(updatedNote.attachments.length, 3);
    });

    test('should format duration correctly in attachment', () async {
      const testCases = [
        {'duration': 30, 'expected': '00:30'},
        {'duration': 90, 'expected': '01:30'},
        {'duration': 3661, 'expected': '61:01'},
      ];

      for (final testCase in testCases) {
        final duration = testCase['duration'] as int;
        final expected = testCase['expected'] as String;
        
        final updatedNote = await service.addAudioAttachment(
          testNote,
          '/audio/test.m4a',
          duration,
        );

        final newAudio = updatedNote.audioAttachments.last;
        expect(newAudio.formattedDuration, expected);
      }
    });
  });
}
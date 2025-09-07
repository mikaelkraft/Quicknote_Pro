import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/attachment.dart';

void main() {
  group('AttachmentType Tests', () {
    test('should convert AttachmentType to string', () {
      expect(AttachmentType.image.value, 'image');
      expect(AttachmentType.file.value, 'file');
      expect(AttachmentType.doodle.value, 'doodle');
      expect(AttachmentType.audio.value, 'audio');
    });

    test('should create AttachmentType from string', () {
      expect(AttachmentTypeExtension.fromString('image'), AttachmentType.image);
      expect(AttachmentTypeExtension.fromString('file'), AttachmentType.file);
      expect(AttachmentTypeExtension.fromString('doodle'), AttachmentType.doodle);
      expect(AttachmentTypeExtension.fromString('audio'), AttachmentType.audio);
    });

    test('should throw error for invalid AttachmentType string', () {
      expect(
        () => AttachmentTypeExtension.fromString('invalid'),
        throwsArgumentError,
      );
    });
  });

  group('Attachment Model Tests', () {
    late Attachment testAttachment;
    late DateTime testCreatedAt;
    
    setUp(() {
      testCreatedAt = DateTime(2024, 1, 1, 12, 0, 0);
      testAttachment = Attachment(
        id: 'test_id',
        name: 'test_image.jpg',
        relativePath: 'attachments/test_image.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1024000,
        type: AttachmentType.image,
        createdAt: testCreatedAt,
      );
    });

    test('should create attachment with all properties', () {
      expect(testAttachment.id, 'test_id');
      expect(testAttachment.name, 'test_image.jpg');
      expect(testAttachment.relativePath, 'attachments/test_image.jpg');
      expect(testAttachment.mimeType, 'image/jpeg');
      expect(testAttachment.sizeBytes, 1024000);
      expect(testAttachment.type, AttachmentType.image);
      expect(testAttachment.createdAt, testCreatedAt);
    });

    test('should create attachment with optional null values', () {
      final attachment = Attachment(
        id: 'simple_id',
        name: 'simple_file.txt',
        relativePath: 'files/simple_file.txt',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );

      expect(attachment.mimeType, isNull);
      expect(attachment.sizeBytes, isNull);
    });

    test('should copy attachment with updated fields', () {
      final updatedAttachment = testAttachment.copyWith(
        name: 'updated_image.jpg',
        relativePath: 'updated/path/updated_image.jpg',
        sizeBytes: 2048000,
      );

      expect(updatedAttachment.id, testAttachment.id);
      expect(updatedAttachment.name, 'updated_image.jpg');
      expect(updatedAttachment.relativePath, 'updated/path/updated_image.jpg');
      expect(updatedAttachment.sizeBytes, 2048000);
      expect(updatedAttachment.mimeType, testAttachment.mimeType);
      expect(updatedAttachment.type, testAttachment.type);
      expect(updatedAttachment.createdAt, testAttachment.createdAt);
    });

    test('should convert to and from JSON', () {
      final json = testAttachment.toJson();
      final fromJson = Attachment.fromJson(json);

      expect(fromJson.id, testAttachment.id);
      expect(fromJson.name, testAttachment.name);
      expect(fromJson.relativePath, testAttachment.relativePath);
      expect(fromJson.mimeType, testAttachment.mimeType);
      expect(fromJson.sizeBytes, testAttachment.sizeBytes);
      expect(fromJson.type, testAttachment.type);
      expect(fromJson.createdAt, testAttachment.createdAt);
    });

    test('should convert to and from JSON string', () {
      final jsonString = testAttachment.toJsonString();
      final fromJsonString = Attachment.fromJsonString(jsonString);

      expect(fromJsonString.id, testAttachment.id);
      expect(fromJsonString.name, testAttachment.name);
      expect(fromJsonString.type, testAttachment.type);
    });

    test('should handle JSON with null optional fields', () {
      final attachment = Attachment(
        id: 'null_test',
        name: 'test.txt',
        relativePath: 'test.txt',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );

      final json = attachment.toJson();
      final fromJson = Attachment.fromJson(json);

      expect(fromJson.mimeType, isNull);
      expect(fromJson.sizeBytes, isNull);
    });

    test('should handle equality correctly', () {
      final sameIdAttachment = Attachment(
        id: 'test_id',
        name: 'different_name.jpg',
        relativePath: 'different/path.jpg',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );

      expect(testAttachment == sameIdAttachment, isTrue);
      expect(testAttachment.hashCode, sameIdAttachment.hashCode);
    });

    test('should format file size correctly', () {
      // Test the original attachment (1024000 bytes = 1000 KB)
      expect(testAttachment.fileSizeFormatted, '1000.0 KB');

      final bytesAttachment = testAttachment.copyWith(sizeBytes: 500);
      expect(bytesAttachment.fileSizeFormatted, '500 B');

      final kbAttachment = testAttachment.copyWith(sizeBytes: 1536); // 1.5 KB
      expect(kbAttachment.fileSizeFormatted, '1.5 KB');

      final mbAttachment = testAttachment.copyWith(sizeBytes: 1572864); // 1.5 MB
      expect(mbAttachment.fileSizeFormatted, '1.5 MB');

      final gbAttachment = testAttachment.copyWith(sizeBytes: 1610612736); // 1.5 GB
      expect(gbAttachment.fileSizeFormatted, '1.5 GB');

      // Test null size by creating new attachment without size
      final noSizeAttachment = Attachment(
        id: 'no_size_test',
        name: 'no_size.txt',
        relativePath: 'test/no_size.txt',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
        // No sizeBytes field - should be null
      );
      expect(noSizeAttachment.fileSizeFormatted, 'Unknown size');
    });

    test('should identify attachment types correctly', () {
      expect(testAttachment.isImage, isTrue);
      expect(testAttachment.isFile, isFalse);
      expect(testAttachment.isDoodle, isFalse);
      expect(testAttachment.isAudio, isFalse);

      final fileAttachment = testAttachment.copyWith(type: AttachmentType.file);
      expect(fileAttachment.isImage, isFalse);
      expect(fileAttachment.isFile, isTrue);
      expect(fileAttachment.isDoodle, isFalse);
      expect(fileAttachment.isAudio, isFalse);

      final doodleAttachment = testAttachment.copyWith(type: AttachmentType.doodle);
      expect(doodleAttachment.isImage, isFalse);
      expect(doodleAttachment.isFile, isFalse);
      expect(doodleAttachment.isDoodle, isTrue);
      expect(doodleAttachment.isAudio, isFalse);

      final audioAttachment = testAttachment.copyWith(type: AttachmentType.audio);
      expect(audioAttachment.isImage, isFalse);
      expect(audioAttachment.isFile, isFalse);
      expect(audioAttachment.isDoodle, isFalse);
      expect(audioAttachment.isAudio, isTrue);
    });

    test('should extract file extension correctly', () {
      expect(testAttachment.fileExtension, 'jpg');

      final pdfAttachment = testAttachment.copyWith(name: 'document.pdf');
      expect(pdfAttachment.fileExtension, 'pdf');

      final noExtensionAttachment = testAttachment.copyWith(name: 'noextension');
      expect(noExtensionAttachment.fileExtension, isNull);

      final dotEndAttachment = testAttachment.copyWith(name: 'file.');
      expect(dotEndAttachment.fileExtension, isNull);

      final multiDotAttachment = testAttachment.copyWith(name: 'file.backup.txt');
      expect(multiDotAttachment.fileExtension, 'txt');
    });

    test('should generate string representation', () {
      final str = testAttachment.toString();
      expect(str, contains('test_id'));
      expect(str, contains('test_image.jpg'));
      expect(str, contains('image/jpeg'));
      expect(str, contains('AttachmentType.image'));
    });
  });

  group('Audio Attachment Tests', () {
    late Attachment audioAttachment;
    late DateTime testCreatedAt;
    
    setUp(() {
      testCreatedAt = DateTime(2024, 1, 1, 12, 0, 0);
      audioAttachment = Attachment(
        id: 'audio_test_id',
        name: 'voice_note_001.m4a',
        relativePath: 'audio/voice_note_001.m4a',
        mimeType: 'audio/aac',
        sizeBytes: 1024000,
        type: AttachmentType.audio,
        createdAt: testCreatedAt,
        durationSeconds: 120,
      );
    });

    test('should create audio attachment with duration', () {
      expect(audioAttachment.id, 'audio_test_id');
      expect(audioAttachment.name, 'voice_note_001.m4a');
      expect(audioAttachment.type, AttachmentType.audio);
      expect(audioAttachment.durationSeconds, 120);
      expect(audioAttachment.isAudio, isTrue);
      expect(audioAttachment.isImage, isFalse);
      expect(audioAttachment.isFile, isFalse);
      expect(audioAttachment.isDoodle, isFalse);
    });

    test('should format duration correctly', () {
      final testCases = [
        {'seconds': 0, 'expected': '00:00'},
        {'seconds': 30, 'expected': '00:30'},
        {'seconds': 60, 'expected': '01:00'},
        {'seconds': 90, 'expected': '01:30'},
        {'seconds': 300, 'expected': '05:00'},
        {'seconds': 3661, 'expected': '61:01'}, // Over an hour
      ];

      for (final testCase in testCases) {
        final attachment = audioAttachment.copyWith(
          durationSeconds: testCase['seconds'] as int,
        );
        expect(attachment.formattedDuration, testCase['expected']);
      }
    });

    test('should handle null duration gracefully', () {
      final attachment = Attachment(
        id: 'audio_test_null',
        name: 'voice_note_no_duration.m4a',
        relativePath: 'audio/voice_note_no_duration.m4a',
        mimeType: 'audio/aac',
        type: AttachmentType.audio,
        createdAt: DateTime.now(),
        // No durationSeconds field - should be null
      );
      expect(attachment.formattedDuration, '');
    });

    test('should format non-audio attachment duration as empty', () {
      final imageAttachment = audioAttachment.copyWith(
        type: AttachmentType.image,
        durationSeconds: 120,
      );
      expect(imageAttachment.formattedDuration, '');
    });

    test('should serialize and deserialize audio attachment with duration', () {
      final json = audioAttachment.toJson();
      final fromJson = Attachment.fromJson(json);

      expect(fromJson.id, audioAttachment.id);
      expect(fromJson.name, audioAttachment.name);
      expect(fromJson.type, AttachmentType.audio);
      expect(fromJson.durationSeconds, 120);
      expect(fromJson.mimeType, 'audio/aac');
      expect(fromJson.formattedDuration, '02:00');
    });

    test('should copy audio attachment with updated duration', () {
      final updated = audioAttachment.copyWith(
        name: 'updated_voice.m4a',
        durationSeconds: 180,
      );

      expect(updated.id, audioAttachment.id);
      expect(updated.name, 'updated_voice.m4a');
      expect(updated.durationSeconds, 180);
      expect(updated.formattedDuration, '03:00');
      expect(updated.type, AttachmentType.audio);
    });

    test('should get correct file extension for audio files', () {
      expect(audioAttachment.fileExtension, 'm4a');

      final mp3Attachment = audioAttachment.copyWith(name: 'audio.mp3');
      expect(mp3Attachment.fileExtension, 'mp3');

      final wavAttachment = audioAttachment.copyWith(name: 'recording.wav');
      expect(wavAttachment.fileExtension, 'wav');
    });

    test('should include duration in string representation', () {
      final str = audioAttachment.toString();
      expect(str, contains('audio_test_id'));
      expect(str, contains('voice_note_001.m4a'));
      expect(str, contains('AttachmentType.audio'));
      expect(str, contains('durationSeconds: 120'));
    });
  });
}
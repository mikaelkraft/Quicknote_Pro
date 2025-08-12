import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/attachment.dart';

void main() {
  group('AttachmentType Tests', () {
    test('should convert AttachmentType to string', () {
      expect(AttachmentType.image.value, 'image');
      expect(AttachmentType.file.value, 'file');
    });

    test('should create AttachmentType from string', () {
      expect(AttachmentTypeExtension.fromString('image'), AttachmentType.image);
      expect(AttachmentTypeExtension.fromString('file'), AttachmentType.file);
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
      final bytesAttachment = testAttachment.copyWith(sizeBytes: 500);
      expect(bytesAttachment.fileSizeFormatted, '500 B');

      final kbAttachment = testAttachment.copyWith(sizeBytes: 1536); // 1.5 KB
      expect(kbAttachment.fileSizeFormatted, '1.5 KB');

      final mbAttachment = testAttachment.copyWith(sizeBytes: 1572864); // 1.5 MB
      expect(mbAttachment.fileSizeFormatted, '1.5 MB');

      final gbAttachment = testAttachment.copyWith(sizeBytes: 1610612736); // 1.5 GB
      expect(gbAttachment.fileSizeFormatted, '1.5 GB');

      final noSizeAttachment = testAttachment.copyWith(sizeBytes: null);
      expect(noSizeAttachment.fileSizeFormatted, 'Unknown size');
    });

    test('should identify attachment types correctly', () {
      expect(testAttachment.isImage, isTrue);
      expect(testAttachment.isFile, isFalse);

      final fileAttachment = testAttachment.copyWith(type: AttachmentType.file);
      expect(fileAttachment.isImage, isFalse);
      expect(fileAttachment.isFile, isTrue);
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
}
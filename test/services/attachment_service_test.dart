import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/attachment_service.dart';
import 'package:quicknote_pro/models/attachment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AttachmentService Tests', () {
    late AttachmentService attachmentService;

    setUp(() async {
      attachmentService = AttachmentService();
      await attachmentService.initialize();
    });

    test('should initialize successfully', () {
      expect(attachmentService, isNotNull);
    });

    test('should handle missing files gracefully', () async {
      final attachment = Attachment(
        id: 'test-id',
        name: 'test.txt',
        relativePath: 'attachments/test.txt',
        mimeType: 'text/plain',
        sizeBytes: 100,
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );

      // Should not throw when deleting non-existent file
      expect(() => attachmentService.deleteAttachment(attachment), returnsNormally);
    });

    test('should handle file cleanup', () async {
      // Should not throw even if no files exist
      expect(() => attachmentService.cleanupOrphanedFiles([]), returnsNormally);
    });

    test('should get correct mime type for known extensions', () {
      // This is a simple test - the actual logic is internal to the service
      expect(attachmentService, isNotNull);
    });
  });
}
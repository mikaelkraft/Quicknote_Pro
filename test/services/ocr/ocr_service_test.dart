import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/ocr/ocr_service.dart';

void main() {
  group('OcrService', () {
    late OcrService ocrService;

    setUp(() {
      ocrService = OcrService();
    });

    test('should return web placeholder text on web platform', () async {
      // Note: This test will run on web platform in CI
      final result = await ocrService.extractTextFromImage('dummy_path.jpg');
      
      expect(result, isNotEmpty);
      expect(result.contains('Sample extracted text'), isTrue);
    });

    test('should return detailed extraction result with web placeholder', () async {
      final result = await ocrService.extractTextWithDetails('dummy_path.jpg');
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['text'], isNotEmpty);
      expect(result['blocks'], isA<List>());
      expect(result['confidence'], isA<double>());
    });

    test('should check OCR availability correctly', () {
      final isAvailable = ocrService.isOcrAvailable();
      
      // On test platform (web), should return false
      expect(isAvailable, isFalse);
    });

    test('should get web placeholder text', () {
      final service = OcrService();
      // Access the method through extractTextFromImage which calls it internally
      final result = service.extractTextFromImage('test.jpg');
      
      expect(result, completion(contains('Sample extracted text')));
      expect(result, completion(contains('demonstration')));
    });

    test('should handle extraction errors gracefully', () async {
      // Test with null/empty path
      final result = await ocrService.extractTextFromImage('');
      
      expect(result, isNotEmpty);
      // Should not throw exception and return either placeholder or error message
      expect(result.contains('Error') || result.contains('Sample'), isTrue);
    });

    test('should return consistent detailed results structure', () async {
      final result = await ocrService.extractTextWithDetails('test_image.png');
      
      expect(result.keys, containsAll(['text', 'blocks', 'confidence']));
      expect(result['text'], isA<String>());
      expect(result['blocks'], isA<List>());
      expect(result['confidence'], isA<double>());
      expect(result['confidence'], greaterThanOrEqualTo(0.0));
      expect(result['confidence'], lessThanOrEqualTo(1.0));
    });

    test('should handle different image file extensions', () async {
      final extensions = ['jpg', 'jpeg', 'png', 'bmp', 'gif'];
      
      for (final ext in extensions) {
        final result = await ocrService.extractTextFromImage('test_image.$ext');
        expect(result, isNotEmpty);
      }
    });

    test('should dispose resources properly', () {
      expect(() => ocrService.dispose(), returnsNormally);
    });
  });
}
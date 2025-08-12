import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from an image file
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      if (kIsWeb) {
        // Web doesn't support ML Kit, return placeholder
        return _getWebPlaceholderText();
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return 'No text found in image.';
      }
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('OCR Error: $e');
      return 'Error extracting text from image.';
    }
  }

  /// Extract text with detailed block information
  Future<Map<String, dynamic>> extractTextWithDetails(String imagePath) async {
    try {
      if (kIsWeb) {
        return {
          'text': _getWebPlaceholderText(),
          'blocks': [],
          'confidence': 0.0,
        };
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      List<Map<String, dynamic>> blocks = [];
      double totalConfidence = 0.0;
      int elementCount = 0;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            blocks.add({
              'text': element.text,
              'confidence': element.confidence ?? 0.0,
              'boundingBox': {
                'left': element.boundingBox.left,
                'top': element.boundingBox.top,
                'right': element.boundingBox.right,
                'bottom': element.boundingBox.bottom,
              },
            });
            totalConfidence += (element.confidence ?? 0.0);
            elementCount++;
          }
        }
      }

      return {
        'text': recognizedText.text.isEmpty ? 'No text found in image.' : recognizedText.text,
        'blocks': blocks,
        'confidence': elementCount > 0 ? totalConfidence / elementCount : 0.0,
      };
    } catch (e) {
      debugPrint('OCR Error: $e');
      return {
        'text': 'Error extracting text from image.',
        'blocks': [],
        'confidence': 0.0,
      };
    }
  }

  /// Check if OCR is available on the current platform
  bool isOcrAvailable() {
    return !kIsWeb;
  }

  /// Get simulated text for web platform
  String _getWebPlaceholderText() {
    return '''Sample extracted text from image:

This is a demonstration of OCR functionality.
In the web version, actual text recognition
is not available due to platform limitations.

On mobile devices, this would contain
the actual text extracted from your image
using Google ML Kit Text Recognition.''';
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
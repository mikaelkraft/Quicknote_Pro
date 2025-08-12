import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/premium/feature_gate.dart';

void main() {
  group('FeatureGate Tests', () {
    group('Voice Note Features', () {
      test('should allow voice notes within free limit', () {
        expect(FeatureGate.canRecordVoiceNote(5, false), isTrue);
        expect(FeatureGate.canRecordVoiceNote(9, false), isTrue);
      });

      test('should block voice notes when free limit exceeded', () {
        expect(FeatureGate.canRecordVoiceNote(10, false), isFalse);
        expect(FeatureGate.canRecordVoiceNote(15, false), isFalse);
      });

      test('should allow unlimited voice notes for premium users', () {
        expect(FeatureGate.canRecordVoiceNote(50, true), isTrue);
        expect(FeatureGate.canRecordVoiceNote(100, true), isTrue);
      });

      test('should block transcription for free users', () {
        expect(FeatureGate.canTranscribeVoiceNote(false), isFalse);
      });

      test('should allow transcription for premium users', () {
        expect(FeatureGate.canTranscribeVoiceNote(true), isTrue);
      });

      test('should block background recording for free users', () {
        expect(FeatureGate.canUseBackgroundRecording(false), isFalse);
      });

      test('should allow background recording for premium users', () {
        expect(FeatureGate.canUseBackgroundRecording(true), isTrue);
      });

      test('should return correct max recording length', () {
        expect(
          FeatureGate.getMaxRecordingLength(false),
          equals(const Duration(minutes: 2)),
        );
        expect(
          FeatureGate.getMaxRecordingLength(true),
          equals(const Duration(hours: 1)),
        );
      });
    });

    group('Drawing Features', () {
      test('should block advanced drawing tools for free users', () {
        expect(FeatureGate.canUseAdvancedDrawingTools(false), isFalse);
      });

      test('should allow advanced drawing tools for premium users', () {
        expect(FeatureGate.canUseAdvancedDrawingTools(true), isTrue);
      });

      test('should allow only 1 layer for free users', () {
        expect(FeatureGate.canUseLayers(1, false), isTrue);
        expect(FeatureGate.canUseLayers(2, false), isFalse);
      });

      test('should allow multiple layers for premium users', () {
        expect(FeatureGate.canUseLayers(5, true), isTrue);
        expect(FeatureGate.canUseLayers(10, true), isTrue);
        expect(FeatureGate.canUseLayers(11, true), isFalse);
      });

      test('should return correct max layers', () {
        expect(FeatureGate.getMaxLayers(false), equals(1));
        expect(FeatureGate.getMaxLayers(true), equals(10));
      });
    });

    group('Export Features', () {
      test('should allow only txt export for free users', () {
        expect(FeatureGate.canUseExportFormat('txt', false), isTrue);
        expect(FeatureGate.canUseExportFormat('pdf', false), isFalse);
        expect(FeatureGate.canUseExportFormat('docx', false), isFalse);
        expect(FeatureGate.canUseExportFormat('md', false), isFalse);
      });

      test('should allow all export formats for premium users', () {
        expect(FeatureGate.canUseExportFormat('txt', true), isTrue);
        expect(FeatureGate.canUseExportFormat('pdf', true), isTrue);
        expect(FeatureGate.canUseExportFormat('docx', true), isTrue);
        expect(FeatureGate.canUseExportFormat('md', true), isTrue);
      });

      test('should return correct available export formats', () {
        expect(
          FeatureGate.getAvailableExportFormats(false),
          equals(['txt']),
        );
        expect(
          FeatureGate.getAvailableExportFormats(true),
          equals(['txt', 'pdf', 'docx', 'md']),
        );
      });
    });

    group('Cloud Features', () {
      test('should block cloud sync for free users', () {
        expect(FeatureGate.canUseCloudSync(false), isFalse);
      });

      test('should allow cloud sync for premium users', () {
        expect(FeatureGate.canUseCloudSync(true), isTrue);
      });

      test('should respect cloud storage limits', () {
        // Free user: 100MB limit
        expect(FeatureGate.canUploadToCloud(50, false), isTrue);
        expect(FeatureGate.canUploadToCloud(99, false), isTrue);
        expect(FeatureGate.canUploadToCloud(100, false), isFalse);

        // Premium user: 10GB limit
        expect(FeatureGate.canUploadToCloud(5000, true), isTrue);
        expect(FeatureGate.canUploadToCloud(10239, true), isTrue);
        expect(FeatureGate.canUploadToCloud(10240, true), isFalse);
      });

      test('should return correct max cloud storage', () {
        expect(FeatureGate.getMaxCloudStorageMB(false), equals(100));
        expect(FeatureGate.getMaxCloudStorageMB(true), equals(10240));
      });
    });

    group('Ad Features', () {
      test('should show ads for free users', () {
        expect(FeatureGate.shouldShowAds(false), isTrue);
      });

      test('should hide ads for premium users', () {
        expect(FeatureGate.shouldShowAds(true), isFalse);
      });
    });

    group('Other Premium Features', () {
      test('should block advanced OCR for free users', () {
        expect(FeatureGate.canUseAdvancedOCR(false), isFalse);
      });

      test('should allow advanced OCR for premium users', () {
        expect(FeatureGate.canUseAdvancedOCR(true), isTrue);
      });

      test('should block note templates for free users', () {
        expect(FeatureGate.canUseNoteTemplates(false), isFalse);
      });

      test('should allow note templates for premium users', () {
        expect(FeatureGate.canUseNoteTemplates(true), isTrue);
      });

      test('should block note encryption for free users', () {
        expect(FeatureGate.canUseNoteEncryption(false), isFalse);
      });

      test('should allow note encryption for premium users', () {
        expect(FeatureGate.canUseNoteEncryption(true), isTrue);
      });

      test('should block collaborative editing for free users', () {
        expect(FeatureGate.canUseCollaborativeEditing(false), isFalse);
      });

      test('should allow collaborative editing for premium users', () {
        expect(FeatureGate.canUseCollaborativeEditing(true), isTrue);
      });
    });

    group('Messaging Features', () {
      test('should return appropriate lock messages', () {
        final message = FeatureGate.getFeatureLockMessage('Voice Notes');
        expect(message, contains('Upgrade to Premium'));
        expect(message, contains('Voice Notes'));
      });

      test('should return context-specific upgrade messages', () {
        expect(
          FeatureGate.getUpgradeMessage('voice notes'),
          contains('unlimited voice notes'),
        );
        expect(
          FeatureGate.getUpgradeMessage('drawing tools'),
          contains('advanced drawing tools'),
        );
        expect(
          FeatureGate.getUpgradeMessage('cloud sync'),
          contains('sync notes across'),
        );
        expect(
          FeatureGate.getUpgradeMessage('export'),
          contains('PDF, DOCX'),
        );
        expect(
          FeatureGate.getUpgradeMessage('unknown feature'),
          contains('unlock this feature'),
        );
      });
    });
  });
}
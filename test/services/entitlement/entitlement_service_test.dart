import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/entitlement/entitlement_service.dart';
import 'package:quicknote_pro/services/billing/billing_service.dart';

@GenerateMocks([BillingService])
import 'entitlement_service_test.mocks.dart';

void main() {
  group('EntitlementService Tests', () {
    late EntitlementService entitlementService;
    late MockBillingService mockBillingService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      mockBillingService = MockBillingService();
      when(mockBillingService.isPremiumUser).thenReturn(false);
      
      entitlementService = EntitlementService(mockBillingService);
    });

    tearDown(() {
      entitlementService.dispose();
    });

    test('should initialize with correct default state', () {
      expect(entitlementService.isInitialized, isFalse);
      expect(entitlementService.isPremiumUser, isFalse);
    });

    test('should initialize and load cached entitlements', () async {
      await entitlementService.initialize();
      
      expect(entitlementService.isInitialized, isTrue);
    });

    test('should deny premium features for free users', () async {
      when(mockBillingService.isPremiumUser).thenReturn(false);
      await entitlementService.initialize();

      expect(entitlementService.hasFeature(PremiumFeature.voiceNoteTranscription), isFalse);
      expect(entitlementService.hasFeature(PremiumFeature.advancedDrawingTools), isFalse);
      expect(entitlementService.hasFeature(PremiumFeature.drawingLayers), isFalse);
      expect(entitlementService.hasFeature(PremiumFeature.exportFormats), isFalse);
    });

    test('should grant premium features for premium users', () async {
      when(mockBillingService.isPremiumUser).thenReturn(true);
      await entitlementService.initialize();

      expect(entitlementService.hasFeature(PremiumFeature.voiceNoteTranscription), isTrue);
      expect(entitlementService.hasFeature(PremiumFeature.advancedDrawingTools), isTrue);
      expect(entitlementService.hasFeature(PremiumFeature.drawingLayers), isTrue);
      expect(entitlementService.hasFeature(PremiumFeature.exportFormats), isTrue);
    });

    group('Feature limits', () {
      test('should enforce limits for free users', () async {
        when(mockBillingService.isPremiumUser).thenReturn(false);
        await entitlementService.initialize();

        // Voice transcription limit
        expect(entitlementService.hasReachedLimit(
          PremiumFeature.voiceNoteTranscription, 10), isTrue);
        expect(entitlementService.hasReachedLimit(
          PremiumFeature.voiceNoteTranscription, 5), isFalse);

        // Recording length limit
        expect(entitlementService.hasReachedLimit(
          PremiumFeature.longerRecordings, 60), isTrue);
        expect(entitlementService.hasReachedLimit(
          PremiumFeature.longerRecordings, 30), isFalse);

        // Notes limit
        expect(entitlementService.hasReachedLimit(
          PremiumFeature.unlimitedNotes, 100), isTrue);
        expect(entitlementService.hasReachedLimit(
          PremiumFeature.unlimitedNotes, 50), isFalse);
      });

      test('should not enforce limits for premium users', () async {
        when(mockBillingService.isPremiumUser).thenReturn(true);
        await entitlementService.initialize();

        expect(entitlementService.hasReachedLimit(
          PremiumFeature.voiceNoteTranscription, 1000), isFalse);
        expect(entitlementService.hasReachedLimit(
          PremiumFeature.longerRecordings, 3600), isFalse);
        expect(entitlementService.hasReachedLimit(
          PremiumFeature.unlimitedNotes, 10000), isFalse);
      });

      test('should return correct feature limits', () async {
        when(mockBillingService.isPremiumUser).thenReturn(false);
        await entitlementService.initialize();

        expect(entitlementService.getFeatureLimit(PremiumFeature.voiceNoteTranscription), 10);
        expect(entitlementService.getFeatureLimit(PremiumFeature.longerRecordings), 60);
        expect(entitlementService.getFeatureLimit(PremiumFeature.unlimitedNotes), 100);
      });

      test('should return null limits for premium users', () async {
        when(mockBillingService.isPremiumUser).thenReturn(true);
        await entitlementService.initialize();

        expect(entitlementService.getFeatureLimit(PremiumFeature.voiceNoteTranscription), isNull);
        expect(entitlementService.getFeatureLimit(PremiumFeature.longerRecordings), isNull);
        expect(entitlementService.getFeatureLimit(PremiumFeature.unlimitedNotes), isNull);
      });

      test('should calculate remaining usage correctly', () async {
        when(mockBillingService.isPremiumUser).thenReturn(false);
        await entitlementService.initialize();

        expect(entitlementService.getRemainingUsage(
          PremiumFeature.voiceNoteTranscription, 5), 5);
        expect(entitlementService.getRemainingUsage(
          PremiumFeature.voiceNoteTranscription, 8), 2);
        expect(entitlementService.getRemainingUsage(
          PremiumFeature.voiceNoteTranscription, 15), 0); // Over limit
      });
    });

    group('Feature metadata', () {
      test('should identify premium features correctly', () {
        expect(entitlementService.isFeaturePremium(PremiumFeature.voiceNoteTranscription), isTrue);
        expect(entitlementService.isFeaturePremium(PremiumFeature.advancedDrawingTools), isTrue);
        expect(entitlementService.isFeaturePremium(PremiumFeature.drawingLayers), isTrue);
        expect(entitlementService.isFeaturePremium(PremiumFeature.exportFormats), isTrue);
        expect(entitlementService.isFeaturePremium(PremiumFeature.cloudSync), isTrue);
        expect(entitlementService.isFeaturePremium(PremiumFeature.unlimitedNotes), isFalse); // Has free limit
      });

      test('should return correct feature names', () {
        expect(entitlementService.getFeatureName(PremiumFeature.voiceNoteTranscription), 
               'Voice Note Transcription');
        expect(entitlementService.getFeatureName(PremiumFeature.advancedDrawingTools), 
               'Advanced Drawing Tools');
        expect(entitlementService.getFeatureName(PremiumFeature.drawingLayers), 
               'Drawing Layers');
      });

      test('should return feature descriptions', () {
        final description = entitlementService.getFeatureDescription(PremiumFeature.voiceNoteTranscription);
        expect(description, isNotEmpty);
        expect(description, contains('transcribe'));
      });
    });

    group('Billing service integration', () {
      test('should update entitlements when billing state changes', () async {
        when(mockBillingService.isPremiumUser).thenReturn(false);
        await entitlementService.initialize();

        expect(entitlementService.hasFeature(PremiumFeature.voiceNoteTranscription), isFalse);

        // Simulate premium purchase
        when(mockBillingService.isPremiumUser).thenReturn(true);
        
        // Manually trigger billing state change (in real implementation, this would be automatic)
        await entitlementService.refresh();

        expect(entitlementService.hasFeature(PremiumFeature.voiceNoteTranscription), isTrue);
      });
    });

    group('Caching', () {
      test('should cache entitlements to SharedPreferences', () async {
        when(mockBillingService.isPremiumUser).thenReturn(true);
        await entitlementService.initialize();

        // Verify that entitlements are cached
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('entitlement_voiceNoteTranscription'), isTrue);
      });

      test('should load cached entitlements on initialization', () async {
        // Pre-populate cache
        SharedPreferences.setMockInitialValues({
          'entitlement_voiceNoteTranscription': true,
          'entitlement_advancedDrawingTools': true,
        });

        when(mockBillingService.isPremiumUser).thenReturn(false);
        await entitlementService.initialize();

        // Should load from cache initially, then update based on billing state
        expect(entitlementService.isInitialized, isTrue);
      });
    });

    test('should handle refresh correctly', () async {
      await entitlementService.initialize();
      
      expect(() => entitlementService.refresh(), returnsNormally);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/ab_testing_service.dart';
import 'package:quicknote_pro/services/analytics/analytics_service.dart';

void main() {
  group('ABTestingService', () {
    late ABTestingService abTestingService;
    late AnalyticsService mockAnalytics;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockAnalytics = AnalyticsService();
      abTestingService = ABTestingService(mockAnalytics);
    });

    test('should initialize with default experiments', () async {
      await abTestingService.initialize();
      
      expect(abTestingService.isEnabled, isTrue);
      expect(abTestingService.activeExperiments.length, greaterThan(0));
      
      // Check for expected default experiments
      expect(abTestingService.activeExperiments, contains('paywall_headline'));
      expect(abTestingService.activeExperiments, contains('ad_timing'));
      expect(abTestingService.activeExperiments, contains('trial_duration'));
      expect(abTestingService.activeExperiments, contains('pricing_display'));
    });

    test('should assign users to variants consistently', () async {
      await abTestingService.initialize();
      
      const userId = 'test_user_123';
      const experimentId = 'paywall_headline';
      
      // Get variant multiple times - should be consistent
      final variant1 = abTestingService.getVariant(experimentId, userId: userId);
      final variant2 = abTestingService.getVariant(experimentId, userId: userId);
      final variant3 = abTestingService.getVariant(experimentId, userId: userId);
      
      expect(variant1, equals(variant2));
      expect(variant2, equals(variant3));
      
      // Should be a valid variant
      final experiment = abTestingService.activeExperiments[experimentId]!;
      expect(experiment.variants.keys, contains(variant1));
    });

    test('should return control for non-existent experiments', () async {
      await abTestingService.initialize();
      
      final variant = abTestingService.getVariant('non_existent_experiment');
      expect(variant, equals('control'));
    });

    test('should track conversions correctly', () async {
      await abTestingService.initialize();
      
      const experimentId = 'paywall_headline';
      const userId = 'test_user_456';
      
      // Get user's variant first
      final variant = abTestingService.getVariant(experimentId, userId: userId);
      
      // Track conversion - should not throw
      expect(() {
        abTestingService.trackConversion(
          experimentId, 
          'upgrade_completed',
          userId: userId,
          properties: {'tier': 'premium'},
        );
      }, returnsNormally);
    });

    test('should handle variant parameters correctly', () async {
      await abTestingService.initialize();
      
      const experimentId = 'paywall_headline';
      const userId = 'test_user_789';
      
      final parameters = abTestingService.getVariantParameters(experimentId, userId: userId);
      
      expect(parameters, isA<Map<String, dynamic>>());
      
      // Should contain expected parameters for paywall experiment
      if (parameters.isNotEmpty) {
        expect(parameters, anyOf([
          containsPair('headline', isA<String>()),
          containsPair('subtitle', isA<String>()),
        ]));
      }
    });

    test('should force variants in debug mode', () async {
      await abTestingService.initialize();
      
      const experimentId = 'paywall_headline';
      const forcedVariant = 'benefit_focused';
      
      // Force user into specific variant
      abTestingService.forceVariant(experimentId, forcedVariant);
      
      // Verify forced assignment
      final variant = abTestingService.getVariant(experimentId);
      expect(variant, equals(forcedVariant));
    });

    test('should provide experiment status for debugging', () async {
      await abTestingService.initialize();
      
      final status = abTestingService.getExperimentStatus();
      
      expect(status, isA<Map<String, dynamic>>());
      expect(status, containsPair('enabled', isA<bool>()));
      expect(status, containsPair('active_experiments', isA<int>()));
      expect(status, containsPair('experiments', isA<Map>()));
      
      final experiments = status['experiments'] as Map;
      expect(experiments.length, greaterThan(0));
    });

    test('should reset experiments correctly', () async {
      await abTestingService.initialize();
      
      // Get a variant to create user group assignment
      abTestingService.getVariant('paywall_headline', userId: 'test_user');
      
      // Verify user has assignment
      expect(abTestingService.userGroups.length, greaterThan(0));
      
      // Reset experiments
      await abTestingService.resetExperiments();
      
      // Verify reset worked
      expect(abTestingService.userGroups.length, equals(0));
    });

    test('should handle traffic allocation correctly', () async {
      await abTestingService.initialize();
      
      const experimentId = 'trial_duration';
      final experiment = abTestingService.activeExperiments[experimentId]!;
      
      // Verify traffic allocation adds up to 100%
      int totalAllocation = 0;
      for (final variant in experiment.variants.values) {
        totalAllocation += variant.trafficAllocation;
      }
      expect(totalAllocation, equals(100));
      
      // Test multiple assignments to ensure distribution
      final assignments = <String, int>{};
      for (int i = 0; i < 100; i++) {
        final variant = abTestingService.getVariant(experimentId, userId: 'user_$i');
        assignments[variant] = (assignments[variant] ?? 0) + 1;
      }
      
      // Should have assignments to multiple variants
      expect(assignments.length, greaterThan(1));
    });

    test('should handle experiment expiration', () async {
      await abTestingService.initialize();
      
      // All default experiments should be active and running
      for (final experiment in abTestingService.activeExperiments.values) {
        expect(experiment.isActive, isTrue);
        expect(experiment.isRunning, isTrue);
      }
    });
  });
}
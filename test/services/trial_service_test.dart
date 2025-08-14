import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/monetization/trial_service.dart';
import '../../lib/services/monetization/monetization_service.dart';

void main() {
  late TrialService trialService;

  setUpEach(() async {
    SharedPreferences.setMockInitialValues({});
    trialService = TrialService();
    await trialService.initialize();
  });

  group('TrialService', () {
    test('should initialize without errors', () async {
      expect(trialService, isNotNull);
      expect(trialService.hasActiveTrial, isFalse);
      expect(trialService.isTrialAboutToExpire, isFalse);
    });

    test('should start a trial successfully', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
        type: TrialType.standard,
      );
      
      final success = await trialService.startTrial(config);
      
      expect(success, isTrue);
      expect(trialService.hasActiveTrial, isTrue);
      expect(trialService.currentTrial?.tier, equals(UserTier.premium));
      expect(trialService.currentTrial?.originalDurationDays, equals(7));
      expect(trialService.currentTrial?.state, equals(TrialState.active));
    });

    test('should not start trial if already has active trial', () async {
      final config1 = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      final config2 = TrialConfig(
        tier: UserTier.pro,
        durationDays: 14,
      );
      
      // Start first trial
      final success1 = await trialService.startTrial(config1);
      expect(success1, isTrue);
      
      // Try to start second trial
      final success2 = await trialService.startTrial(config2);
      expect(success2, isFalse);
      expect(trialService.currentTrial?.tier, equals(UserTier.premium));
    });

    test('should not start trial if not eligible', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      // Start and complete first trial
      await trialService.startTrial(config);
      await trialService.convertTrial(UserTier.premium);
      
      // Try to start another trial for same tier
      final success = await trialService.startTrial(config);
      expect(success, isFalse);
    });

    test('should extend trial correctly', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      await trialService.startTrial(config);
      
      final originalExpiry = trialService.currentTrial!.expiresAt;
      final extensionResult = await trialService.extendTrial(3, reason: 'promotion');
      
      expect(extensionResult, isTrue);
      expect(trialService.currentTrial?.extensionDays, equals(3));
      expect(trialService.currentTrial?.totalDurationDays, equals(10));
      expect(trialService.currentTrial?.state, equals(TrialState.extended));
      expect(trialService.currentTrial?.expiresAt.isAfter(originalExpiry), isTrue);
    });

    test('should convert trial to paid subscription', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      await trialService.startTrial(config);
      final conversionResult = await trialService.convertTrial(UserTier.premium);
      
      expect(conversionResult, isTrue);
      expect(trialService.hasActiveTrial, isFalse);
      expect(trialService.currentTrial, isNull);
      expect(trialService.trialHistory.length, equals(1));
      
      final historicalTrial = trialService.trialHistory.first;
      expect(historicalTrial.state, equals(TrialState.converted));
      expect(historicalTrial.tier, equals(UserTier.premium));
    });

    test('should cancel trial', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      await trialService.startTrial(config);
      final cancellationResult = await trialService.cancelTrial(reason: 'user_request');
      
      expect(cancellationResult, isTrue);
      expect(trialService.hasActiveTrial, isFalse);
      expect(trialService.currentTrial, isNull);
      expect(trialService.trialHistory.length, equals(1));
      
      final historicalTrial = trialService.trialHistory.first;
      expect(historicalTrial.state, equals(TrialState.cancelled));
    });

    test('should get available trials for user', () {
      final availableTrials = trialService.getAvailableTrials();
      
      expect(availableTrials.isNotEmpty, isTrue);
      
      // Should have standard trials for Premium and Pro
      final premiumTrial = availableTrials.firstWhere(
        (t) => t.tier == UserTier.premium && t.type == TrialType.standard,
      );
      expect(premiumTrial.durationDays, equals(7));
      
      final proTrial = availableTrials.firstWhere(
        (t) => t.tier == UserTier.pro && t.type == TrialType.standard,
      );
      expect(proTrial.durationDays, equals(14));
    });

    test('should get promotional trials after conversion attempts', () async {
      // Record multiple conversion attempts
      await trialService.recordConversionAttempt(context: 'pricing_page');
      await trialService.recordConversionAttempt(context: 'upgrade_prompt');
      
      final availableTrials = trialService.getAvailableTrials();
      
      // Should now include promotional trial
      final promoTrial = availableTrials.firstWhere(
        (t) => t.type == TrialType.promotional,
        orElse: () => throw Exception('Promo trial not found'),
      );
      
      expect(promoTrial.durationDays, equals(14)); // Extended promotional trial
      expect(promoTrial.promoCode, equals('TRYEXTENDED'));
    });

    test('should get win-back trials for users with expired trials', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      // Start trial, let it expire (simulate)
      await trialService.startTrial(config);
      
      // Manually set trial as expired for testing
      if (trialService.currentTrial != null) {
        final expiredTrial = trialService.currentTrial!.copyWith(
          state: TrialState.expired,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        trialService.trialHistory.add(expiredTrial);
        // Clear current trial to simulate expiry
        await trialService.cancelTrial();
      }
      
      // Record conversion attempt to trigger win-back offer
      await trialService.recordConversionAttempt(context: 'reactivation');
      
      final availableTrials = trialService.getAvailableTrials();
      
      // Should include win-back trial
      final winbackTrial = availableTrials.firstWhere(
        (t) => t.type == TrialType.winback,
        orElse: () => throw Exception('Win-back trial not found'),
      );
      
      expect(winbackTrial.durationDays, equals(10));
      expect(winbackTrial.promoCode, equals('WELCOMEBACK'));
    });

    test('should provide conversion recommendations', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      await trialService.startTrial(config);
      
      final recommendations = trialService.getConversionRecommendations();
      expect(recommendations.isNotEmpty, isTrue);
      
      // Should include trial progress information
      final progressRec = recommendations.firstWhere(
        (r) => r.contains('using'),
        orElse: () => '',
      );
      expect(progressRec.isNotEmpty, isTrue);
    });

    test('should handle trial expiration detection', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      await trialService.startTrial(config);
      
      // Manually set trial to expire soon for testing
      final soonToExpireTrial = trialService.currentTrial!.copyWith(
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      
      expect(soonToExpireTrial.isAboutToExpire, isTrue);
      expect(soonToExpireTrial.daysRemaining, equals(1));
    });

    test('should track conversion attempts', () async {
      expect(trialService.conversionAttempts, equals(0));
      
      await trialService.recordConversionAttempt(context: 'pricing_page');
      expect(trialService.conversionAttempts, equals(1));
      
      await trialService.recordConversionAttempt(context: 'upgrade_prompt');
      expect(trialService.conversionAttempts, equals(2));
    });

    test('should provide analytics data', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
      );
      
      await trialService.startTrial(config);
      
      final analytics = trialService.getAnalyticsData();
      
      expect(analytics, isA<Map<String, dynamic>>());
      expect(analytics['has_active_trial'], isTrue);
      expect(analytics['current_trial_tier'], equals('premium'));
      expect(analytics['current_trial_days_remaining'], isA<int>());
      expect(analytics['total_trials_started'], equals(1));
      expect(analytics['conversion_rate'], isA<String>());
    });

    test('should calculate progress percentage correctly', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 10,
      );
      
      await trialService.startTrial(config);
      
      // For a fresh trial, progress should be close to 0
      final progress = trialService.currentTrial!.progressPercentage;
      expect(progress, lessThan(10)); // Should be very low for fresh trial
    });

    test('should handle different trial types correctly', () {
      // Standard trial
      final standardConfig = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
        type: TrialType.standard,
      );
      expect(standardConfig.displayName, equals('7-Day PREMIUM Trial'));
      expect(standardConfig.description, contains('Try all premium features'));
      
      // Promotional trial
      final promoConfig = TrialConfig(
        tier: UserTier.pro,
        durationDays: 14,
        type: TrialType.promotional,
      );
      expect(promoConfig.displayName, equals('Special 14-Day PRO Trial'));
      expect(promoConfig.description, contains('Limited time offer'));
      
      // Win-back trial
      final winbackConfig = TrialConfig(
        tier: UserTier.premium,
        durationDays: 10,
        type: TrialType.winback,
      );
      expect(winbackConfig.displayName, equals('Welcome Back - 10 Days Free'));
      expect(winbackConfig.description, contains('We miss you'));
    });

    test('should serialize and deserialize trial info', () async {
      final config = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
        type: TrialType.standard,
        promoCode: 'TEST123',
      );
      
      await trialService.startTrial(config);
      
      final originalTrial = trialService.currentTrial!;
      final json = originalTrial.toJson();
      final deserializedTrial = TrialInfo.fromJson(json);
      
      expect(deserializedTrial.tier, equals(originalTrial.tier));
      expect(deserializedTrial.type, equals(originalTrial.type));
      expect(deserializedTrial.originalDurationDays, equals(originalTrial.originalDurationDays));
      expect(deserializedTrial.promoCode, equals(originalTrial.promoCode));
      expect(deserializedTrial.state, equals(originalTrial.state));
    });
  });

  group('TrialConfig', () {
    test('should validate trial configs', () {
      final validConfig = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
        validUntil: DateTime.now().add(const Duration(days: 1)),
      );
      expect(validConfig.isValid, isTrue);
      
      final expiredConfig = TrialConfig(
        tier: UserTier.premium,
        durationDays: 7,
        validUntil: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredConfig.isValid, isFalse);
    });
  });

  group('TrialInfo', () {
    test('should calculate days remaining correctly', () {
      final trialInfo = TrialInfo(
        tier: UserTier.premium,
        type: TrialType.standard,
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        originalDurationDays: 7,
      );
      
      expect(trialInfo.daysRemaining, equals(6)); // 5 + 1 (current day)
      expect(trialInfo.isActive, isTrue);
      expect(trialInfo.isExpired, isFalse);
    });

    test('should handle expired trials', () {
      final expiredTrial = TrialInfo(
        tier: UserTier.premium,
        type: TrialType.standard,
        startedAt: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        originalDurationDays: 7,
      );
      
      expect(expiredTrial.daysRemaining, equals(0));
      expect(expiredTrial.isExpired, isTrue);
      expect(expiredTrial.isActive, isFalse);
    });

    test('should copy with updated values', () {
      final originalTrial = TrialInfo(
        tier: UserTier.premium,
        type: TrialType.standard,
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        originalDurationDays: 7,
        state: TrialState.active,
      );
      
      final updatedTrial = originalTrial.copyWith(
        state: TrialState.extended,
        extensionDays: 3,
      );
      
      expect(updatedTrial.state, equals(TrialState.extended));
      expect(updatedTrial.extensionDays, equals(3));
      expect(updatedTrial.tier, equals(originalTrial.tier)); // Unchanged
    });
  });
}
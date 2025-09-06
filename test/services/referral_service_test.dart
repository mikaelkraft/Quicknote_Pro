import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/monetization/referral_service.dart';
import '../../lib/services/monetization/monetization_service.dart';

void main() {
  late ReferralService referralService;

  setUpEach(() async {
    SharedPreferences.setMockInitialValues({});
    referralService = ReferralService();
    await referralService.initialize();
  });

  group('ReferralService', () {
    test('should initialize without errors', () async {
      expect(referralService, isNotNull);
      expect(referralService.hasReferralCode, isFalse);
      expect(referralService.wasReferred, isFalse);
    });

    test('should generate unique referral code', () async {
      const userId = 'test_user_123';
      final code1 = await referralService.generateReferralCode(userId: userId);
      final code2 = await referralService.generateReferralCode(userId: userId);
      
      expect(code1, isNotEmpty);
      expect(code1, startsWith('QN'));
      expect(code1.length, equals(8));
      expect(code1, equals(code2)); // Should return same code for same user
      expect(referralService.hasReferralCode, isTrue);
    });

    test('should validate referral code format', () async {
      // Test valid codes
      expect(await referralService.applyReferralCode('QNABC123', newUserId: 'user2'), isTrue);
      
      // Test invalid codes
      expect(await referralService.applyReferralCode('INVALID', newUserId: 'user3'), isFalse);
      expect(await referralService.applyReferralCode('QN12', newUserId: 'user4'), isFalse);
      expect(await referralService.applyReferralCode('', newUserId: 'user5'), isFalse);
    });

    test('should apply referral code and add welcome reward', () async {
      const referralCode = 'QNTEST12';
      const newUserId = 'new_user_123';
      
      final result = await referralService.applyReferralCode(referralCode, newUserId: newUserId);
      
      expect(result, isTrue);
      expect(referralService.wasReferred, isTrue);
      expect(referralService.referredBy, equals(referralCode));
      expect(referralService.pendingRewards.length, equals(1));
      
      final reward = referralService.pendingRewards.first;
      expect(reward.type, equals(ReferralRewardType.extendedTrial));
      expect(reward.config['trial_days'], equals(14));
      expect(reward.config['tier'], equals('premium'));
    });

    test('should not apply referral code twice', () async {
      const referralCode1 = 'QNTEST12';
      const referralCode2 = 'QNTEST34';
      const newUserId = 'new_user_123';
      
      // Apply first code
      final result1 = await referralService.applyReferralCode(referralCode1, newUserId: newUserId);
      expect(result1, isTrue);
      
      // Try to apply second code
      final result2 = await referralService.applyReferralCode(referralCode2, newUserId: newUserId);
      expect(result2, isFalse);
      expect(referralService.referredBy, equals(referralCode1));
    });

    test('should record referral conversion and add referrer reward', () async {
      const userId = 'referrer_123';
      const convertedUserId = 'converted_user_456';
      
      // Generate referral code first
      final referralCode = await referralService.generateReferralCode(userId: userId);
      
      // Record conversion
      await referralService.recordReferralConversion(
        referralCode: referralCode,
        convertedUserId: convertedUserId,
        subscribedTier: UserTier.premium,
      );
      
      expect(referralService.referralData?.successfulReferrals, equals(1));
      expect(referralService.referralData?.rewards.length, equals(1));
      
      final reward = referralService.referralData!.rewards.first;
      expect(reward.type, equals(ReferralRewardType.freeMonth));
      expect(reward.config['tier'], equals('premium'));
    });

    test('should claim pending rewards', () async {
      const referralCode = 'QNTEST12';
      const newUserId = 'new_user_123';
      
      // Apply referral code to get pending reward
      await referralService.applyReferralCode(referralCode, newUserId: newUserId);
      
      final reward = referralService.pendingRewards.first;
      final claimResult = await referralService.claimReward(reward);
      
      expect(claimResult, isTrue);
      expect(referralService.pendingRewards.length, equals(0));
    });

    test('should not claim expired rewards', () async {
      // Create expired reward
      final expiredReward = ReferralReward.extendedTrial(
        days: 7,
        tier: UserTier.premium,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      
      // Manually add expired reward for testing
      referralService.pendingRewards.add(expiredReward);
      
      final claimResult = await referralService.claimReward(expiredReward);
      expect(claimResult, isFalse);
    });

    test('should get referral statistics', () async {
      const userId = 'referrer_123';
      
      // Generate referral code
      final referralCode = await referralService.generateReferralCode(userId: userId);
      
      final stats = referralService.getReferralStats();
      
      expect(stats['referral_code'], equals(referralCode));
      expect(stats['total_referrals'], equals(0));
      expect(stats['successful_referrals'], equals(0));
      expect(stats['conversion_rate'], equals('0.0'));
      expect(stats['was_referred'], isFalse);
    });

    test('should create different reward types', () {
      // Test extended trial reward
      final trialReward = ReferralReward.extendedTrial(
        days: 14,
        tier: UserTier.pro,
      );
      expect(trialReward.type, equals(ReferralRewardType.extendedTrial));
      expect(trialReward.displayName, contains('14-Day PRO Trial'));
      
      // Test discount coupon reward
      final discountReward = ReferralReward.discountCoupon(
        discount: 25,
        isPercentage: true,
      );
      expect(discountReward.type, equals(ReferralRewardType.discountCoupon));
      expect(discountReward.displayName, contains('25% off'));
      
      // Test free month reward
      final freeMonthReward = ReferralReward.freeMonth(
        tier: UserTier.premium,
      );
      expect(freeMonthReward.type, equals(ReferralRewardType.freeMonth));
      expect(freeMonthReward.displayName, contains('Free Month of PREMIUM'));
    });

    test('should handle analytics data correctly', () {
      final analytics = referralService.getAnalyticsData();
      
      expect(analytics, isA<Map<String, dynamic>>());
      expect(analytics['has_referral_code'], isFalse);
      expect(analytics['was_referred'], isFalse);
      expect(analytics['pending_rewards_count'], equals(0));
      expect(analytics['active_rewards_count'], equals(0));
    });
  });

  group('ReferralReward', () {
    test('should check if reward is expired', () {
      final validReward = ReferralReward.extendedTrial(
        days: 7,
        tier: UserTier.premium,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(validReward.isExpired, isFalse);
      expect(validReward.isValid, isTrue);
      
      final expiredReward = ReferralReward.extendedTrial(
        days: 7,
        tier: UserTier.premium,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredReward.isExpired, isTrue);
      expect(expiredReward.isValid, isFalse);
    });

    test('should create proper display names and descriptions', () {
      final reward = ReferralReward.discountCoupon(
        discount: 50,
        isPercentage: false,
      );
      
      expect(reward.displayName, equals('\$50.00 off Subscription'));
      expect(reward.description, contains('Get \$50.00 off your next subscription'));
    });
  });
}
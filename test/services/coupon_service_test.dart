import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/monetization/coupon_service.dart';
import '../../lib/services/monetization/monetization_service.dart';
import '../../lib/services/monetization/pricing_models.dart';

void main() {
  late CouponService couponService;

  setUpEach(() async {
    SharedPreferences.setMockInitialValues({});
    couponService = CouponService();
    await couponService.initialize();
  });

  group('CouponService', () {
    test('should initialize with default coupons', () async {
      expect(couponService.availableCoupons.isNotEmpty, isTrue);
      expect(couponService.availableCoupons.containsKey('WELCOME25'), isTrue);
      expect(couponService.availableCoupons.containsKey('STUDENT20'), isTrue);
      expect(couponService.availableCoupons.containsKey('HOLIDAY50'), isTrue);
    });

    test('should validate coupon successfully', () async {
      const userId = 'test_user_123';
      const originalPrice = 20.0;
      
      final validation = await couponService.validateCoupon(
        code: 'WELCOME25',
        tier: UserTier.premium,
        term: PlanTerm.monthly,
        originalPrice: originalPrice,
        userId: userId,
        currentTier: UserTier.free,
      );
      
      expect(validation.isValid, isTrue);
      expect(validation.coupon?.code, equals('WELCOME25'));
      expect(validation.discountAmount, equals(5.0)); // 25% of $20
    });

    test('should reject invalid coupon code', () async {
      const userId = 'test_user_123';
      const originalPrice = 20.0;
      
      final validation = await couponService.validateCoupon(
        code: 'INVALID_CODE',
        tier: UserTier.premium,
        term: PlanTerm.monthly,
        originalPrice: originalPrice,
        userId: userId,
        currentTier: UserTier.free,
      );
      
      expect(validation.isValid, isFalse);
      expect(validation.errorMessage, equals('Invalid coupon code'));
    });

    test('should respect minimum purchase requirements', () async {
      const userId = 'test_user_123';
      const lowPrice = 10.0; // Below minimum for HOLIDAY50 ($15)
      
      final validation = await couponService.validateCoupon(
        code: 'HOLIDAY50',
        tier: UserTier.premium,
        term: PlanTerm.annual,
        originalPrice: lowPrice,
        userId: userId,
        currentTier: UserTier.free,
      );
      
      expect(validation.isValid, isFalse);
      expect(validation.errorMessage, contains('Minimum purchase'));
    });

    test('should apply coupon successfully', () async {
      const userId = 'test_user_123';
      const originalPrice = 20.0;
      
      final success = await couponService.applyCoupon(
        code: 'WELCOME25',
        tier: UserTier.premium,
        term: PlanTerm.monthly,
        originalPrice: originalPrice,
        userId: userId,
      );
      
      expect(success, isTrue);
      expect(couponService.appliedCoupons.containsKey('WELCOME25'), isTrue);
      expect(couponService.usageHistory.length, equals(1));
      
      final usage = couponService.usageHistory.first;
      expect(usage.couponCode, equals('WELCOME25'));
      expect(usage.userId, equals(userId));
      expect(usage.discountAmount, equals(5.0));
    });

    test('should calculate total discount correctly', () async {
      const userId = 'test_user_123';
      const originalPrice = 20.0;
      
      // Apply percentage discount
      await couponService.applyCoupon(
        code: 'WELCOME25',
        tier: UserTier.premium,
        term: PlanTerm.monthly,
        originalPrice: originalPrice,
        userId: userId,
      );
      
      final totalDiscount = couponService.calculateTotalDiscount(originalPrice);
      expect(totalDiscount, equals(5.0)); // 25% of $20
    });

    test('should remove applied coupons', () async {
      const userId = 'test_user_123';
      const originalPrice = 20.0;
      
      // Apply coupon first
      await couponService.applyCoupon(
        code: 'WELCOME25',
        tier: UserTier.premium,
        term: PlanTerm.monthly,
        originalPrice: originalPrice,
        userId: userId,
      );
      
      expect(couponService.appliedCoupons.isNotEmpty, isTrue);
      
      // Remove coupon
      await couponService.removeCoupon('WELCOME25');
      expect(couponService.appliedCoupons.isEmpty, isTrue);
    });

    test('should get applicable coupons for user', () {
      const userId = 'test_user_123';
      
      final applicableCoupons = couponService.getApplicableCoupons(
        currentTier: UserTier.free,
        targetTier: UserTier.premium,
        term: PlanTerm.monthly,
        userId: userId,
      );
      
      expect(applicableCoupons.isNotEmpty, isTrue);
      
      // Should include welcome coupon for new users
      final welcomeCoupon = applicableCoupons.firstWhere(
        (c) => c.code == 'WELCOME25',
        orElse: () => throw Exception('Welcome coupon not found'),
      );
      expect(welcomeCoupon.eligibility, equals(CouponEligibility.newUsersOnly));
    });

    test('should respect usage limits', () async {
      const userId = 'test_user_123';
      const originalPrice = 20.0;
      
      // Apply coupon first time (should succeed)
      final success1 = await couponService.applyCoupon(
        code: 'WELCOME25',
        tier: UserTier.premium,
        term: PlanTerm.monthly,
        originalPrice: originalPrice,
        userId: userId,
      );
      expect(success1, isTrue);
      
      // Try to apply same coupon again (should fail due to maxUsesPerUser: 1)
      final validation2 = await couponService.validateCoupon(
        code: 'WELCOME25',
        tier: UserTier.premium,
        term: PlanTerm.monthly,
        originalPrice: originalPrice,
        userId: userId,
        currentTier: UserTier.free,
      );
      expect(validation2.isValid, isFalse);
      expect(validation2.errorMessage, equals('Coupon usage limit reached'));
    });

    test('should handle expired coupons', () {
      // Create expired coupon config
      final expiredCoupon = CouponConfig(
        code: 'EXPIRED10',
        displayName: 'Expired Coupon',
        description: 'This coupon has expired',
        discountType: CouponDiscountType.percentage,
        discountValue: 10,
        startsAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      
      expect(expiredCoupon.isValid, isFalse);
      expect(expiredCoupon.isExpired, isTrue);
    });

    test('should handle different discount types', () {
      // Percentage discount
      final percentageCoupon = CouponConfig(
        code: 'PERCENT20',
        displayName: '20% Off',
        description: '20% discount',
        discountType: CouponDiscountType.percentage,
        discountValue: 20,
        startsAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(percentageCoupon.calculateDiscount(100), equals(20));
      expect(percentageCoupon.discountDisplayText, equals('20% off'));
      
      // Fixed amount discount
      final fixedCoupon = CouponConfig(
        code: 'FIXED5',
        displayName: '\$5 Off',
        description: '\$5 fixed discount',
        discountType: CouponDiscountType.fixedAmount,
        discountValue: 5,
        startsAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(fixedCoupon.calculateDiscount(100), equals(5));
      expect(fixedCoupon.discountDisplayText, equals('\$5.00 off'));
      
      // Free months
      final freeMonthsCoupon = CouponConfig(
        code: 'FREE2MONTHS',
        displayName: '2 Months Free',
        description: '2 free months',
        discountType: CouponDiscountType.freeMonths,
        discountValue: 2,
        startsAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(freeMonthsCoupon.calculateDiscount(100), equals(100));
      expect(freeMonthsCoupon.discountDisplayText, equals('2 months free'));
      
      // Free trial extension
      final trialCoupon = CouponConfig(
        code: 'TRIAL7',
        displayName: 'Extended Trial',
        description: '7 extra trial days',
        discountType: CouponDiscountType.freeTrial,
        discountValue: 7,
        startsAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(trialCoupon.calculateDiscount(100), equals(0));
      expect(trialCoupon.discountDisplayText, equals('+7 trial days'));
    });

    test('should provide analytics data', () {
      final analytics = couponService.getAnalyticsData();
      
      expect(analytics, isA<Map<String, dynamic>>());
      expect(analytics['available_coupons_count'], greaterThan(0));
      expect(analytics['applied_coupons_count'], equals(0));
      expect(analytics['total_usage_count'], equals(0));
      expect(analytics['total_discount_given'], equals(0));
    });

    test('should handle coupon eligibility correctly', () {
      // Test new users only
      final newUserCoupons = couponService.getApplicableCoupons(
        currentTier: UserTier.free,
        targetTier: UserTier.premium,
        term: PlanTerm.monthly,
        userId: 'new_user',
      );
      
      final welcomeCoupon = newUserCoupons.any((c) => c.code == 'WELCOME25');
      expect(welcomeCoupon, isTrue);
      
      // Test existing users
      final existingUserCoupons = couponService.getApplicableCoupons(
        currentTier: UserTier.premium,
        targetTier: UserTier.pro,
        term: PlanTerm.monthly,
        userId: 'existing_user',
      );
      
      final comebackCoupon = existingUserCoupons.any((c) => c.code == 'COMEBACK30');
      expect(comebackCoupon, isTrue);
    });

    test('should serialize and deserialize coupon configs', () {
      final originalCoupon = CouponConfig(
        code: 'TEST123',
        displayName: 'Test Coupon',
        description: 'Test description',
        discountType: CouponDiscountType.percentage,
        discountValue: 15,
        eligibility: CouponEligibility.newUsersOnly,
        applicableTiers: [UserTier.premium, UserTier.pro],
        applicableTerms: [PlanTerm.monthly],
        startsAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        maxUsesPerUser: 1,
        metadata: {'test': 'value'},
      );
      
      final json = originalCoupon.toJson();
      final deserializedCoupon = CouponConfig.fromJson(json);
      
      expect(deserializedCoupon.code, equals(originalCoupon.code));
      expect(deserializedCoupon.discountType, equals(originalCoupon.discountType));
      expect(deserializedCoupon.discountValue, equals(originalCoupon.discountValue));
      expect(deserializedCoupon.eligibility, equals(originalCoupon.eligibility));
      expect(deserializedCoupon.maxUsesPerUser, equals(originalCoupon.maxUsesPerUser));
    });
  });

  group('CouponValidationResult', () {
    test('should create success result', () {
      final coupon = CouponConfig(
        code: 'TEST',
        displayName: 'Test',
        description: 'Test',
        discountType: CouponDiscountType.percentage,
        discountValue: 10,
        startsAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      
      final result = CouponValidationResult.success(
        coupon: coupon,
        discountAmount: 5.0,
      );
      
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.coupon, equals(coupon));
      expect(result.discountAmount, equals(5.0));
    });

    test('should create failure result', () {
      final result = CouponValidationResult.failure('Test error');
      
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Test error'));
      expect(result.coupon, isNull);
      expect(result.discountAmount, isNull);
    });
  });
}
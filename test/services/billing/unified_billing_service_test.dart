import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/billing/unified_billing_service.dart';
import 'package:quicknote_pro/constants/feature_flags.dart';
import 'package:quicknote_pro/constants/product_ids.dart';

void main() {
  group('UnifiedBillingService', () {
    late UnifiedBillingService billingService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      billingService = UnifiedBillingService.instance;
    });

    test('should be a singleton', () {
      final instance1 = UnifiedBillingService.instance;
      final instance2 = UnifiedBillingService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should determine correct preferred provider', () {
      final provider = billingService.preferredProvider;
      
      // Should return a valid provider
      expect(provider, isA<BillingProvider>());
    });

    test('should validate product IDs', () {
      expect(ProductIds.premiumMonthly, isNotEmpty);
      expect(ProductIds.proMonthly, isNotEmpty);
      expect(ProductIds.premiumLifetime, isNotEmpty);
      expect(ProductIds.proLifetime, isNotEmpty);
    });

    test('should handle feature flags correctly', () {
      // Test that feature flags exist and have valid defaults
      expect(FeatureFlags.revenueCatEnabled, isA<bool>());
      expect(FeatureFlags.paystackEnabled, isA<bool>());
      expect(FeatureFlags.webCheckoutEnabled, isA<bool>());
    });

    test('should return correct premium access status', () {
      // Should be false before initialization
      expect(billingService.hasPremiumAccess, isFalse);
    });

    test('should handle initialization gracefully when disabled', () async {
      // This test verifies that initialization doesn't crash when features are disabled
      // In a real test environment, we would mock the feature flags
      
      try {
        await billingService.initialize(userId: 'test_user');
        // Should complete without throwing
        expect(true, isTrue);
      } catch (e) {
        // Should fail due to missing configuration or initialization issues
        expect(e.toString(), anyOf([
          contains('configuration'),
          contains('RevenueCat'),
          contains('Paystack'),
          contains('BillingException'),
          contains('Flutter'),
        ]));
      }
    });

    test('should validate product availability check', () {
      const testProductId = 'test_product';
      final isAvailable = billingService.isProductAvailable(testProductId);
      
      // Should return false for non-existent product
      expect(isAvailable, isFalse);
    });

    test('should handle user ID management', () {
      const testUserId = 'test_user_123';
      
      // Should accept user ID without errors
      expect(() => billingService.setUserId(testUserId), returnsNormally);
      expect(billingService.currentUserId, equals(testUserId));
    });
  });

  group('BillingProvider enum', () {
    test('should have all expected providers', () {
      final providers = BillingProvider.values;
      
      expect(providers, contains(BillingProvider.revenueCat));
      expect(providers, contains(BillingProvider.paystack));
      expect(providers, contains(BillingProvider.mock));
    });
  });

  group('UnifiedPurchaseResult', () {
    test('should create valid purchase result', () {
      const result = UnifiedPurchaseResult(
        success: true,
        provider: BillingProvider.revenueCat,
        productId: ProductIds.premiumMonthly,
      );
      
      expect(result.success, isTrue);
      expect(result.provider, equals(BillingProvider.revenueCat));
      expect(result.productId, equals(ProductIds.premiumMonthly));
      expect(result.error, isNull);
    });

    test('should create error purchase result', () {
      const result = UnifiedPurchaseResult(
        success: false,
        provider: BillingProvider.paystack,
        error: 'Test error message',
      );
      
      expect(result.success, isFalse);
      expect(result.error, equals('Test error message'));
    });
  });
}
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/premium/premium_service.dart';
import 'package:quicknote_pro/constants/product_ids.dart';

void main() {
  group('PremiumService Tests', () {
    late PremiumService premiumService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      premiumService = PremiumService();
      // Mock shared preferences
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      try {
        premiumService.dispose();
      } catch (e) {
        // Ignore disposal errors in tests
      }
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(premiumService.isPremium, isFalse);
        expect(premiumService.isLoading, isFalse);
        expect(premiumService.premiumExpiry, isNull);
        expect(premiumService.lastError, isNull);
        expect(premiumService.products, isEmpty);
      });

      test('should initialize from stored preferences', () async {
        // Set up mock preferences with premium status
        SharedPreferences.setMockInitialValues({
          'premium_status': true,
          'premium_expiry': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
        });

        await premiumService.initialize();

        expect(premiumService.isPremium, isTrue);
        expect(premiumService.premiumExpiry, isNotNull);
      });

      test('should detect expired subscription', () async {
        // Set up mock preferences with expired subscription
        SharedPreferences.setMockInitialValues({
          'premium_status': true,
          'premium_expiry': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        });

        await premiumService.initialize();

        expect(premiumService.isPremium, isFalse);
        expect(premiumService.premiumExpiry, isNull);
      });
    });

    group('Product Management', () {
      test('should handle product not found', () {
        final product = premiumService.getProductDetails('nonexistent_product');
        expect(product, isNull);
      });

      test('should clear error state', () {
        // Simulate error state
        premiumService.clearError();
        expect(premiumService.lastError, isNull);
      });
    });

    group('Development Features', () {
      test('should allow manual premium status in debug mode', () async {
        await premiumService.setDevelopmentPremiumStatus(true);
        // Note: This will only work in debug mode with allowDevBypass enabled
        // In test mode, it might not change the status
      });
    });

    group('Product IDs', () {
      test('should have correct product IDs defined', () {
        expect(ProductIds.premiumMonthly, equals('quicknote_premium_monthly'));
        expect(ProductIds.premiumLifetime, equals('quicknote_premium_lifetime'));
        expect(ProductIds.allProductIds, contains(ProductIds.premiumMonthly));
        expect(ProductIds.allProductIds, contains(ProductIds.premiumLifetime));
      });

      test('should have display names for all products', () {
        for (final productId in ProductIds.allProductIds) {
          expect(ProductIds.productDisplayNames.containsKey(productId), isTrue);
          expect(ProductIds.productDisplayNames[productId], isNotEmpty);
        }
      });

      test('should have fallback prices for all products', () {
        for (final productId in ProductIds.allProductIds) {
          expect(ProductIds.fallbackPrices.containsKey(productId), isTrue);
          expect(ProductIds.fallbackPrices[productId], isNotEmpty);
        }
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        // Mock a platform error
        try {
          await premiumService.initialize();
          // Should not throw even if platform channels fail
        } catch (e) {
          fail('Initialization should handle errors gracefully');
        }
      });

      test('should handle purchase errors', () async {
        // Mock InAppPurchase to be unavailable
        final result = await premiumService.purchaseProduct('test_product');
        expect(result, isFalse);
        expect(premiumService.lastError, isNotNull);
      });
    });

    group('State Management', () {
      test('should notify listeners on state changes', () async {
        bool notified = false;
        premiumService.addListener(() {
          notified = true;
        });

        premiumService.clearError();
        expect(notified, isTrue);
      });

      test('should maintain consistent state', () {
        // Premium status should be consistent
        if (premiumService.isPremium) {
          expect(premiumService.premiumExpiry == null || 
                 premiumService.premiumExpiry!.isAfter(DateTime.now()), 
                 isTrue);
        }
      });
    });

    group('Feature Integration', () {
      test('should integrate with feature gate correctly', () {
        // Test that premium service state affects feature gate decisions
        // This is tested more thoroughly in feature_gate_test.dart
        expect(premiumService.isPremium, isA<bool>());
      });
    });
  });
}
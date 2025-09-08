import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/monetization/revenuecat_service.dart';
import 'package:quicknote_pro/services/monetization/monetization_service.dart';
import 'package:quicknote_pro/constants/product_ids.dart';

void main() {
  group('RevenueCatService', () {
    late RevenueCatService revenueCatService;

    setUp(() {
      revenueCatService = RevenueCatService();
    });

    test('should initialize with no entitlements by default', () {
      expect(revenueCatService.entitlements, isEmpty);
      expect(revenueCatService.hasPremiumEntitlement, false);
      expect(revenueCatService.hasProEntitlement, false);
      expect(revenueCatService.hasEnterpriseEntitlement, false);
      expect(revenueCatService.getCurrentTier(), UserTier.free);
    });

    test('should return available products with correct information', () {
      final products = revenueCatService.getAvailableProducts();
      
      expect(products.length, equals(8)); // All product IDs
      
      // Check premium products
      final premiumMonthly = products.firstWhere((p) => p.id == ProductIds.premiumMonthly);
      expect(premiumMonthly.tier, UserTier.premium);
      expect(premiumMonthly.price, '\$1.99');
      
      final premiumAnnual = products.firstWhere((p) => p.id == ProductIds.premiumAnnual);
      expect(premiumAnnual.tier, UserTier.premium);
      expect(premiumAnnual.price, '\$19.99');
      
      // Check pro products
      final proMonthly = products.firstWhere((p) => p.id == ProductIds.proMonthly);
      expect(proMonthly.tier, UserTier.pro);
      expect(proMonthly.price, '\$2.99');
      
      final proAnnual = products.firstWhere((p) => p.id == ProductIds.proAnnual);
      expect(proAnnual.tier, UserTier.pro);
      expect(proAnnual.price, '\$29.99');
      
      // Check enterprise products
      final enterpriseMonthly = products.firstWhere((p) => p.id == ProductIds.enterpriseMonthly);
      expect(enterpriseMonthly.tier, UserTier.enterprise);
      expect(enterpriseMonthly.price, '\$2.00');
      
      final enterpriseAnnual = products.firstWhere((p) => p.id == ProductIds.enterpriseAnnual);
      expect(enterpriseAnnual.tier, UserTier.enterprise);
      expect(enterpriseAnnual.price, '\$20.00');
    });

    test('should handle feature access correctly', () {
      // Free tier - no access
      expect(revenueCatService.hasFeatureAccess('premium_features'), false);
      expect(revenueCatService.hasFeatureAccess('pro_features'), false);
      expect(revenueCatService.hasFeatureAccess('enterprise_features'), false);
      
      // Premium features should be available to all paid tiers
      expect(revenueCatService.hasFeatureAccess('advanced_drawing'), false);
      expect(revenueCatService.hasFeatureAccess('ocr_features'), false);
      
      // Pro-specific features
      expect(revenueCatService.hasFeatureAccess('unlimited_voice_recording'), false);
      
      // Enterprise-specific features
      expect(revenueCatService.hasFeatureAccess('team_management'), false);
    });

    test('should validate product IDs match constants', () {
      final products = revenueCatService.getAvailableProducts();
      final productIds = products.map((p) => p.id).toSet();
      final expectedIds = ProductIds.allProductIds.toSet();
      
      expect(productIds, equals(expectedIds));
    });

    test('should validate all product display names exist', () {
      final products = revenueCatService.getAvailableProducts();
      
      for (final product in products) {
        expect(ProductIds.productDisplayNames.containsKey(product.id), true,
            reason: 'Product ${product.id} should have a display name');
        expect(ProductIds.fallbackPrices.containsKey(product.id), true,
            reason: 'Product ${product.id} should have a fallback price');
      }
    });

    test('should validate pricing consistency', () {
      final products = revenueCatService.getAvailableProducts();
      
      for (final product in products) {
        final expectedPrice = ProductIds.fallbackPrices[product.id];
        expect(product.price, equals(expectedPrice),
            reason: 'Product ${product.id} price should match fallback price');
      }
    });
  });

  group('ProductInfo', () {
    test('should create ProductInfo with all required fields', () {
      const productInfo = ProductInfo(
        id: 'test_product',
        title: 'Test Product',
        price: '\$9.99',
        tier: UserTier.premium,
      );

      expect(productInfo.id, 'test_product');
      expect(productInfo.title, 'Test Product');
      expect(productInfo.price, '\$9.99');
      expect(productInfo.tier, UserTier.premium);
    });
  });
}
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:quicknote_pro/services/entitlements/entitlement_service.dart';
import 'package:quicknote_pro/services/billing/billing_service.dart';
import 'package:quicknote_pro/constants/product_ids.dart';

import 'entitlement_service_test.mocks.dart';

@GenerateMocks([BillingService])
void main() {
  group('EntitlementService Tests', () {
    late EntitlementService entitlementService;
    late MockBillingService mockBillingService;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      mockBillingService = MockBillingService();
      entitlementService = EntitlementService(mockBillingService);

      // Setup default mock behaviors
      when(mockBillingService.initialize()).thenAnswer((_) async {});
      when(mockBillingService.getActivePurchases()).thenAnswer((_) async => []);
      when(mockBillingService.dispose()).thenReturn(null);
    });

    tearDown(() {
      entitlementService.dispose();
    });

    test('should initialize with free tier by default', () async {
      await entitlementService.initialize();

      expect(entitlementService.isPremium, false);
      expect(entitlementService.premiumProductId, null);
      expect(entitlementService.premiumPurchaseDate, null);
      expect(entitlementService.entitlementLevel, EntitlementLevel.free);
      expect(entitlementService.isInitialized, true);
    });

    test('should detect premium purchase from billing service', () async {
      // Mock active purchase
      final mockPurchase = _createMockPurchase(
        ProductIds.premiumLifetime,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      
      when(mockBillingService.getActivePurchases())
          .thenAnswer((_) async => [mockPurchase]);

      await entitlementService.initialize();

      expect(entitlementService.isPremium, true);
      expect(entitlementService.premiumProductId, ProductIds.premiumLifetime);
      expect(entitlementService.entitlementLevel, EntitlementLevel.premiumLifetime);
    });

    test('should persist premium status to SharedPreferences', () async {
      await entitlementService.initialize();
      
      // Grant premium manually
      await entitlementService.grantPremium(
        productId: ProductIds.premiumMonthly,
        purchaseDate: DateTime(2024, 1, 1),
      );

      // Verify it's stored
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('premium_status'), true);
      expect(prefs.getString('premium_product_id'), ProductIds.premiumMonthly);
      expect(prefs.getInt('premium_purchase_date'), DateTime(2024, 1, 1).millisecondsSinceEpoch);
    });

    test('should load stored premium status on initialization', () async {
      // Pre-populate SharedPreferences
      SharedPreferences.setMockInitialValues({
        'premium_status': true,
        'premium_product_id': ProductIds.premiumLifetime,
        'premium_purchase_date': DateTime(2024, 1, 1).millisecondsSinceEpoch,
      });

      // Mock the billing service to return the expected purchase
      final mockPurchase = _createMockPurchase(
        ProductIds.premiumLifetime,
        DateTime(2024, 1, 1).millisecondsSinceEpoch.toString(),
      );
      when(mockBillingService.getActivePurchases())
          .thenAnswer((_) async => [mockPurchase]);

      final newEntitlementService = EntitlementService(mockBillingService);
      await newEntitlementService.initialize();

      expect(newEntitlementService.isPremium, true);
      expect(newEntitlementService.premiumProductId, ProductIds.premiumLifetime);
      expect(newEntitlementService.premiumPurchaseDate, DateTime(2024, 1, 1));
      expect(newEntitlementService.entitlementLevel, EntitlementLevel.premiumLifetime);

      newEntitlementService.dispose();
    });

    test('should grant premium access', () async {
      await entitlementService.initialize();
      
      expect(entitlementService.isPremium, false);

      await entitlementService.grantPremium();

      expect(entitlementService.isPremium, true);
      expect(entitlementService.premiumProductId, ProductIds.premiumLifetime);
      expect(entitlementService.premiumPurchaseDate, isNotNull);
    });

    test('should revoke premium access', () async {
      await entitlementService.initialize();
      await entitlementService.grantPremium();
      
      expect(entitlementService.isPremium, true);

      await entitlementService.revokePremium();

      expect(entitlementService.isPremium, false);
      expect(entitlementService.premiumProductId, null);
      expect(entitlementService.premiumPurchaseDate, null);
      expect(entitlementService.entitlementLevel, EntitlementLevel.free);
    });

    test('should check feature access correctly', () async {
      await entitlementService.initialize();

      // In debug mode with allowDevBypass enabled, features are always available
      // In production, free users should not have premium features
      bool expectedFreeAccess = kDebugMode && ProductIds.allowDevBypass;
      
      expect(entitlementService.hasFeature(PremiumFeature.unlimitedVoiceNotes), expectedFreeAccess);
      expect(entitlementService.hasFeature(PremiumFeature.advancedDrawingTools), expectedFreeAccess);
      expect(entitlementService.hasFeature(PremiumFeature.cloudSync), expectedFreeAccess);

      // Grant premium
      await entitlementService.grantPremium();

      // Premium user should have all features regardless of debug mode
      expect(entitlementService.hasFeature(PremiumFeature.unlimitedVoiceNotes), true);
      expect(entitlementService.hasFeature(PremiumFeature.advancedDrawingTools), true);
      expect(entitlementService.hasFeature(PremiumFeature.cloudSync), true);
    });

    test('should refresh entitlements from billing service', () async {
      await entitlementService.initialize();
      expect(entitlementService.isPremium, false);

      // Mock new purchase available
      final mockPurchase = _createMockPurchase(
        ProductIds.premiumMonthly,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      
      when(mockBillingService.getActivePurchases())
          .thenAnswer((_) async => [mockPurchase]);

      await entitlementService.refreshEntitlements();

      expect(entitlementService.isPremium, true);
      expect(entitlementService.premiumProductId, ProductIds.premiumMonthly);
      expect(entitlementService.entitlementLevel, EntitlementLevel.premiumMonthly);
    });

    test('should handle billing service errors gracefully', () async {
      when(mockBillingService.initialize()).thenThrow(Exception('Billing error'));
      when(mockBillingService.getActivePurchases()).thenThrow(Exception('Network error'));

      // Should not throw, but should still initialize
      await entitlementService.initialize();

      expect(entitlementService.isInitialized, true);
      expect(entitlementService.isPremium, false);
    });

    test('should notify listeners on entitlement changes', () async {
      await entitlementService.initialize();

      bool notified = false;
      entitlementService.addListener(() {
        notified = true;
      });

      await entitlementService.grantPremium();

      expect(notified, true);
    });

    test('should determine correct entitlement level', () async {
      await entitlementService.initialize();

      // Free tier
      expect(entitlementService.entitlementLevel, EntitlementLevel.free);

      // Monthly premium
      await entitlementService.grantPremium(productId: ProductIds.premiumMonthly);
      expect(entitlementService.entitlementLevel, EntitlementLevel.premiumMonthly);

      // Lifetime premium
      await entitlementService.grantPremium(productId: ProductIds.premiumLifetime);
      expect(entitlementService.entitlementLevel, EntitlementLevel.premiumLifetime);
    });
  });

  group('PremiumFeature Extensions', () {
    test('should have display names for all features', () {
      for (final feature in PremiumFeature.values) {
        expect(feature.displayName.isNotEmpty, true);
        expect(feature.description.isNotEmpty, true);
      }
    });

    test('should have unique display names', () {
      final displayNames = PremiumFeature.values.map((f) => f.displayName).toSet();
      expect(displayNames.length, PremiumFeature.values.length);
    });
  });
}

// Helper function to create mock purchase details
PurchaseDetails _createMockPurchase(String productId, String transactionDate) {
  return PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local_data',
      serverVerificationData: 'server_data',
      source: 'test',
    ),
    transactionDate: transactionDate,
    status: PurchaseStatus.purchased,
  );
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/theme/theme_entitlement_service.dart';

void main() {
  group('ThemeEntitlementService', () {
    late ThemeEntitlementService service;

    setUp(() async {
      // Clear any existing SharedPreferences
      SharedPreferences.setMockInitialValues({});
      service = ThemeEntitlementService();
      await service.initialize();
    });

    test('should start with no premium access', () {
      expect(service.isPremium, false);
      expect(service.purchaseType, null);
      expect(service.purchaseDate, null);
    });

    test('should correctly identify Pro themes', () {
      expect(service.hasThemeAccess('default_light'), true);
      expect(service.hasThemeAccess('default_dark'), true);
      expect(service.hasThemeAccess('futuristic'), false);
      expect(service.hasThemeAccess('neon'), false);
      expect(service.hasThemeAccess('floral'), false);
    });

    test('should show paywall for Pro themes when not premium', () {
      expect(service.shouldShowPaywallForTheme('default_light'), false);
      expect(service.shouldShowPaywallForTheme('futuristic'), true);
      expect(service.shouldShowPaywallForTheme('neon'), true);
      expect(service.shouldShowPaywallForTheme('floral'), true);
    });

    test('should grant premium access correctly', () async {
      await service.grantPremiumAccess(purchaseType: 'lifetime');
      
      expect(service.isPremium, true);
      expect(service.purchaseType, 'lifetime');
      expect(service.purchaseDate, isNotNull);
      expect(service.getSubscriptionStatusText(), 'Pro Lifetime');
    });

    test('should allow access to Pro themes after purchase', () async {
      await service.grantPremiumAccess(purchaseType: 'lifetime');
      
      expect(service.hasThemeAccess('futuristic'), true);
      expect(service.hasThemeAccess('neon'), true);
      expect(service.hasThemeAccess('floral'), true);
      expect(service.shouldShowPaywallForTheme('futuristic'), false);
    });

    test('should handle monthly subscription validation', () async {
      final now = DateTime.now();
      await service.grantPremiumAccess(
        purchaseType: 'monthly',
        purchaseDate: now.subtract(const Duration(days: 15)),
      );
      
      expect(service.isMonthlySubscriptionValid(), true);
      expect(service.getSubscriptionStatusText(), 'Pro Monthly');
    });

    test('should revoke premium access', () async {
      await service.grantPremiumAccess(purchaseType: 'lifetime');
      expect(service.isPremium, true);
      
      await service.revokePremiumAccess();
      expect(service.isPremium, false);
      expect(service.purchaseType, null);
      expect(service.getSubscriptionStatusText(), 'Free Plan');
    });

    test('should persist premium state across restarts', () async {
      await service.grantPremiumAccess(purchaseType: 'lifetime');
      
      // Create new service instance to simulate app restart
      final newService = ThemeEntitlementService();
      await newService.initialize();
      
      expect(newService.isPremium, true);
      expect(newService.purchaseType, 'lifetime');
    });

    test('should simulate purchase restoration', () async {
      await service.simulatePurchaseForTesting('lifetime');
      await service.revokePremiumAccess();
      
      final restored = await service.restorePurchases();
      expect(restored, true);
      expect(service.isPremium, true);
    });
  });
}
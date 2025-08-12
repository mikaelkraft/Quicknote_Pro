import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/entitlement/entitlement_service.dart';
import 'package:quicknote_pro/models/entitlement_status.dart';

void main() {
  group('EntitlementService', () {
    late EntitlementService entitlementService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      entitlementService = EntitlementService();
    });

    test('should initialize with free status by default', () async {
      await entitlementService.initialize();
      
      expect(entitlementService.hasProAccess, false);
      expect(entitlementService.isFreeUser, true);
      expect(entitlementService.currentStatus.subscriptionType, SubscriptionType.free);
    });

    test('should grant monthly Pro access correctly', () async {
      await entitlementService.initialize();
      
      final expirationDate = DateTime.now().add(const Duration(days: 30));
      await entitlementService.grantMonthlyPro(expirationDate: expirationDate);
      
      expect(entitlementService.hasProAccess, true);
      expect(entitlementService.isFreeUser, false);
      expect(entitlementService.currentStatus.subscriptionType, SubscriptionType.monthly);
      expect(entitlementService.currentStatus.expirationDate, expirationDate);
    });

    test('should grant lifetime Pro access correctly', () async {
      await entitlementService.initialize();
      
      await entitlementService.grantLifetimePro();
      
      expect(entitlementService.hasProAccess, true);
      expect(entitlementService.isFreeUser, false);
      expect(entitlementService.currentStatus.subscriptionType, SubscriptionType.lifetime);
      expect(entitlementService.currentStatus.expirationDate, null);
    });

    test('should revoke Pro access correctly', () async {
      await entitlementService.initialize();
      
      // First grant Pro access
      await entitlementService.grantLifetimePro();
      expect(entitlementService.hasProAccess, true);
      
      // Then revoke it
      await entitlementService.revokeProAccess();
      expect(entitlementService.hasProAccess, false);
      expect(entitlementService.isFreeUser, true);
      expect(entitlementService.currentStatus.subscriptionType, SubscriptionType.free);
    });

    test('should check premium feature access correctly', () async {
      await entitlementService.initialize();
      
      expect(entitlementService.canAccessPremiumFeature('themes'), false);
      
      await entitlementService.grantLifetimePro();
      expect(entitlementService.canAccessPremiumFeature('themes'), true);
    });

    test('should detect expiring subscription', () async {
      await entitlementService.initialize();
      
      // Grant subscription expiring in 5 days
      final nearExpiration = DateTime.now().add(const Duration(days: 5));
      await entitlementService.grantMonthlyPro(expirationDate: nearExpiration);
      
      expect(entitlementService.isExpiringSoon, true);
      
      // Grant subscription expiring in 10 days
      final farExpiration = DateTime.now().add(const Duration(days: 10));
      await entitlementService.grantMonthlyPro(expirationDate: farExpiration);
      
      expect(entitlementService.isExpiringSoon, false);
    });

    test('should simulate purchase correctly', () async {
      await entitlementService.initialize();
      
      // Test lifetime purchase
      final lifetimeResult = await entitlementService.simulatePurchase(isLifetime: true);
      expect(lifetimeResult, true);
      expect(entitlementService.currentStatus.subscriptionType, SubscriptionType.lifetime);
      
      // Reset to free
      await entitlementService.revokeProAccess();
      
      // Test monthly purchase
      final monthlyResult = await entitlementService.simulatePurchase(isLifetime: false);
      expect(monthlyResult, true);
      expect(entitlementService.currentStatus.subscriptionType, SubscriptionType.monthly);
    });

    test('should persist and restore status across sessions', () async {
      // First session - grant Pro access
      await entitlementService.initialize();
      await entitlementService.grantLifetimePro();
      
      // Create new service instance to simulate app restart
      final newService = EntitlementService();
      await newService.initialize();
      
      expect(newService.hasProAccess, true);
      expect(newService.currentStatus.subscriptionType, SubscriptionType.lifetime);
    });

    test('should handle expired subscription on initialization', () async {
      await entitlementService.initialize();
      
      // Grant subscription that's already expired
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      await entitlementService.grantMonthlyPro(expirationDate: pastDate);
      
      // Create new service instance to simulate app restart
      final newService = EntitlementService();
      await newService.initialize();
      
      expect(newService.hasProAccess, false);
      expect(newService.currentStatus.subscriptionType, SubscriptionType.free);
    });

    test('should clear cache correctly', () async {
      await entitlementService.initialize();
      await entitlementService.grantLifetimePro();
      
      expect(entitlementService.hasProAccess, true);
      
      await entitlementService.clearCache();
      
      expect(entitlementService.hasProAccess, false);
      expect(entitlementService.currentStatus.subscriptionType, SubscriptionType.free);
    });
  });
}
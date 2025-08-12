import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/entitlement_status.dart';

void main() {
  group('EntitlementStatus', () {
    test('should create free user status correctly', () {
      final status = EntitlementStatus.free();
      
      expect(status.subscriptionType, SubscriptionType.free);
      expect(status.hasProAccess, false);
      expect(status.expirationDate, null);
      expect(status.isOfflineCache, false);
    });

    test('should create monthly Pro status correctly', () {
      final expirationDate = DateTime.now().add(const Duration(days: 30));
      final status = EntitlementStatus.monthlyPro(expirationDate: expirationDate);
      
      expect(status.subscriptionType, SubscriptionType.monthly);
      expect(status.hasProAccess, true);
      expect(status.expirationDate, expirationDate);
      expect(status.isExpired, false);
    });

    test('should create lifetime Pro status correctly', () {
      final status = EntitlementStatus.lifetimePro();
      
      expect(status.subscriptionType, SubscriptionType.lifetime);
      expect(status.hasProAccess, true);
      expect(status.expirationDate, null);
      expect(status.isExpired, false);
    });

    test('should detect expired monthly subscription', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final status = EntitlementStatus.monthlyPro(expirationDate: pastDate);
      
      expect(status.isExpired, true);
      expect(status.hasProAccess, false); // Should be false due to expiration check in the actual usage
    });

    test('should calculate days until expiration correctly', () {
      final futureDate = DateTime.now().add(const Duration(days: 15));
      final status = EntitlementStatus.monthlyPro(expirationDate: futureDate);
      
      expect(status.daysUntilExpiration, 15);
    });

    test('should detect stale cache correctly', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 2));
      final status = EntitlementStatus.free().copyWith(lastVerified: oldDate);
      
      expect(status.isStale, true);
    });

    test('should serialize to and from JSON correctly', () {
      final originalStatus = EntitlementStatus.monthlyPro(
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        isOfflineCache: true,
      );
      
      final json = originalStatus.toJson();
      final deserializedStatus = EntitlementStatus.fromJson(json);
      
      expect(deserializedStatus.subscriptionType, originalStatus.subscriptionType);
      expect(deserializedStatus.hasProAccess, originalStatus.hasProAccess);
      expect(deserializedStatus.isOfflineCache, originalStatus.isOfflineCache);
    });
  });

  group('SubscriptionType', () {
    test('should identify Pro subscriptions correctly', () {
      expect(SubscriptionType.free.isPro, false);
      expect(SubscriptionType.monthly.isPro, true);
      expect(SubscriptionType.lifetime.isPro, true);
    });

    test('should provide correct display names', () {
      expect(SubscriptionType.free.displayName, 'Free');
      expect(SubscriptionType.monthly.displayName, 'Monthly Pro');
      expect(SubscriptionType.lifetime.displayName, 'Lifetime Pro');
    });
  });
}
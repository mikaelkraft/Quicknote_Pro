import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../models/entitlement_status.dart';

/// Service to manage user entitlement and subscription status
/// 
/// Handles subscription verification, offline caching, and Pro access control.
/// Treats users as free when status is unknown for security.
class EntitlementService extends ChangeNotifier {
  static const String _entitlementKey = 'user_entitlement_status';
  static const String _lastVerificationKey = 'last_entitlement_verification';
  
  EntitlementStatus _currentStatus = EntitlementStatus.free();
  SharedPreferences? _prefs;

  /// Current entitlement status
  EntitlementStatus get currentStatus => _currentStatus;

  /// Whether user has active Pro access
  bool get hasProAccess => _currentStatus.hasProAccess && !_currentStatus.isExpired;

  /// Whether user is on free plan
  bool get isFreeUser => !hasProAccess;

  /// Whether current status is from offline cache
  bool get isOfflineCache => _currentStatus.isOfflineCache;

  /// Whether cached status is stale and needs refresh
  bool get needsRefresh => _currentStatus.isStale;

  /// Initialize the entitlement service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedStatus();
    
    // Attempt to refresh status if we're online and it's stale
    if (needsRefresh) {
      unawaited(_refreshEntitlementStatus());
    }
  }

  /// Load entitlement status from local cache
  Future<void> _loadCachedStatus() async {
    if (_prefs == null) return;

    try {
      final statusJson = _prefs!.getString(_entitlementKey);
      if (statusJson != null) {
        final statusMap = json.decode(statusJson) as Map<String, dynamic>;
        _currentStatus = EntitlementStatus.fromJson(statusMap).copyWith(
          isOfflineCache: true,
        );
        
        // Check if monthly subscription has expired
        if (_currentStatus.isExpired) {
          _currentStatus = EntitlementStatus.free();
          await _saveStatusToCache(_currentStatus);
        }
      }
    } catch (e) {
      debugPrint('Error loading cached entitlement status: $e');
      _currentStatus = EntitlementStatus.free();
    }
    
    notifyListeners();
  }

  /// Save entitlement status to local cache
  Future<void> _saveStatusToCache(EntitlementStatus status) async {
    if (_prefs == null) return;

    try {
      final statusJson = json.encode(status.toJson());
      await _prefs!.setString(_entitlementKey, statusJson);
      await _prefs!.setInt(_lastVerificationKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving entitlement status to cache: $e');
    }
  }

  /// Refresh entitlement status from server
  /// 
  /// In a real implementation, this would make an API call to verify
  /// the user's subscription status. For now, it simulates the process.
  Future<void> _refreshEntitlementStatus() async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, this would call your backend to verify subscription
      // For demo purposes, we'll maintain the current status but update verification time
      _currentStatus = _currentStatus.copyWith(
        lastVerified: DateTime.now(),
        isOfflineCache: false,
      );
      
      await _saveStatusToCache(_currentStatus);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing entitlement status: $e');
      // Keep current cached status if refresh fails
    }
  }

  /// Update entitlement status (called after successful purchase)
  Future<void> updateEntitlementStatus(EntitlementStatus newStatus) async {
    _currentStatus = newStatus.copyWith(
      lastVerified: DateTime.now(),
      isOfflineCache: false,
    );
    
    await _saveStatusToCache(_currentStatus);
    notifyListeners();
  }

  /// Grant monthly Pro access
  Future<void> grantMonthlyPro({required DateTime expirationDate}) async {
    final status = EntitlementStatus.monthlyPro(
      expirationDate: expirationDate,
    );
    await updateEntitlementStatus(status);
  }

  /// Grant lifetime Pro access
  Future<void> grantLifetimePro() async {
    final status = EntitlementStatus.lifetimePro();
    await updateEntitlementStatus(status);
  }

  /// Revoke Pro access (subscription cancelled or expired)
  Future<void> revokeProAccess() async {
    final status = EntitlementStatus.free();
    await updateEntitlementStatus(status);
  }

  /// Check if user can access a specific premium feature
  bool canAccessPremiumFeature(String featureId) {
    return hasProAccess;
  }

  /// Get remaining days for monthly subscription
  int? getRemainingDays() {
    return _currentStatus.daysUntilExpiration;
  }

  /// Check if subscription will expire soon (within 7 days)
  bool get isExpiringSoon {
    final remainingDays = getRemainingDays();
    return remainingDays != null && remainingDays <= 7;
  }

  /// Force refresh entitlement status
  Future<void> forceRefresh() async {
    await _refreshEntitlementStatus();
  }

  /// Clear all cached entitlement data
  Future<void> clearCache() async {
    if (_prefs == null) return;
    
    await _prefs!.remove(_entitlementKey);
    await _prefs!.remove(_lastVerificationKey);
    _currentStatus = EntitlementStatus.free();
    notifyListeners();
  }

  /// Simulate purchase flow for testing
  Future<bool> simulatePurchase({required bool isLifetime}) async {
    try {
      // Simulate purchase processing
      await Future.delayed(const Duration(seconds: 2));
      
      if (isLifetime) {
        await grantLifetimePro();
      } else {
        // Grant 1 month of Pro access
        final expirationDate = DateTime.now().add(const Duration(days: 30));
        await grantMonthlyPro(expirationDate: expirationDate);
      }
      
      return true;
    } catch (e) {
      debugPrint('Purchase simulation failed: $e');
      return false;
    }
  }

  /// Helper method to handle unawaited futures
  void unawaited(Future<void> future) {
    future.catchError((error) {
      debugPrint('Unawaited future error: $error');
    });
  }
}
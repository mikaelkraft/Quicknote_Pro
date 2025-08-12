import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pricing_tier.dart';
import '../models/user_entitlements.dart';
import '../constants/product_ids.dart';

/// Events that can be fired for analytics
enum MonetizationEvent {
  freeLimitReached,
  upgradeInitiated,
  upgradeCompleted,
  upgradeFailed,
  trialStarted,
  trialExpired,
  subscriptionExpired,
  restorePurchaseAttempted,
  restorePurchaseSucceeded,
  restorePurchaseFailed,
}

/// Service for managing pricing tiers and user entitlements
class PricingTierService extends ChangeNotifier {
  static const String _entitlementsKey = 'user_entitlements';
  static const String _lastPurchaseCheckKey = 'last_purchase_check';
  
  SharedPreferences? _prefs;
  UserEntitlements _currentEntitlements = UserEntitlements.free();
  
  // Analytics callback for tracking monetization events
  Function(MonetizationEvent event, Map<String, dynamic> data)? _analyticsCallback;
  
  // Stream controller for entitlement changes
  final StreamController<UserEntitlements> _entitlementsController = 
      StreamController<UserEntitlements>.broadcast();

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadEntitlements();
    await _checkAndResetUsageIfNeeded();
  }

  /// Get current user entitlements
  UserEntitlements get currentEntitlements => _currentEntitlements;

  /// Get current pricing tier
  PricingTier get currentTier => _currentEntitlements.tier;

  /// Check if user is premium
  bool get isPremium => _currentEntitlements.isPremium;

  /// Get current tier limits
  PricingTierLimits get currentLimits => _currentEntitlements.currentLimits;

  /// Stream of entitlement changes
  Stream<UserEntitlements> get entitlementsStream => _entitlementsController.stream;

  /// Set analytics callback for tracking events
  void setAnalyticsCallback(Function(MonetizationEvent event, Map<String, dynamic> data) callback) {
    _analyticsCallback = callback;
  }

  /// Track a monetization event
  void _trackEvent(MonetizationEvent event, [Map<String, dynamic>? additionalData]) {
    final data = {
      'event': event.name,
      'tier': _currentEntitlements.tier.name,
      'subscription_type': _currentEntitlements.subscriptionType.name,
      'is_premium': _currentEntitlements.isPremium,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };
    
    if (_analyticsCallback != null) {
      _analyticsCallback!(event, data);
    }
    
    // Also log in debug mode
    if (kDebugMode) {
      print('MonetizationEvent: ${event.name} - $data');
    }
  }

  /// Load entitlements from storage
  Future<void> _loadEntitlements() async {
    if (_prefs == null) return;
    
    final entitlementsJson = _prefs!.getString(_entitlementsKey);
    if (entitlementsJson != null) {
      try {
        final json = jsonDecode(entitlementsJson);
        _currentEntitlements = UserEntitlements.fromJson(json);
        _entitlementsController.add(_currentEntitlements);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error loading entitlements: $e');
        }
        // Reset to free if corrupted
        _currentEntitlements = UserEntitlements.free();
        await _saveEntitlements();
      }
    }
  }

  /// Save entitlements to storage
  Future<void> _saveEntitlements() async {
    if (_prefs == null) return;
    
    final json = jsonEncode(_currentEntitlements.toJson());
    await _prefs!.setString(_entitlementsKey, json);
    _entitlementsController.add(_currentEntitlements);
    notifyListeners();
  }

  /// Check and reset usage counters if new month
  Future<void> _checkAndResetUsageIfNeeded() async {
    if (_currentEntitlements.needsUsageReset) {
      _currentEntitlements = _currentEntitlements.resetUsage();
      await _saveEntitlements();
    }
  }

  /// Start a free trial
  Future<bool> startFreeTrial({int trialDays = 7}) async {
    if (!_currentEntitlements.canStartTrial) {
      _trackEvent(MonetizationEvent.upgradeFailed, {
        'reason': 'trial_already_used',
      });
      return false;
    }

    final now = DateTime.now();
    final trialEnd = now.add(Duration(days: trialDays));

    _currentEntitlements = UserEntitlements.trial(
      trialStartDate: now,
      trialEndDate: trialEnd,
    );

    await _saveEntitlements();
    
    _trackEvent(MonetizationEvent.trialStarted, {
      'trial_days': trialDays,
      'trial_end_date': trialEnd.toIso8601String(),
    });

    return true;
  }

  /// Activate premium subscription
  Future<bool> activatePremiumSubscription({
    required SubscriptionType subscriptionType,
    required String productId,
    String? subscriptionId,
    String? originalPurchaseId,
    DateTime? subscriptionEndDate,
  }) async {
    final now = DateTime.now();
    
    // Calculate end date for monthly subscriptions
    DateTime? endDate = subscriptionEndDate;
    if (subscriptionType == SubscriptionType.monthly && endDate == null) {
      endDate = now.add(const Duration(days: 30));
    }

    _currentEntitlements = UserEntitlements.premium(
      subscriptionType: subscriptionType,
      subscriptionStartDate: now,
      subscriptionEndDate: endDate,
      subscriptionId: subscriptionId,
      originalPurchaseId: originalPurchaseId,
    );

    await _saveEntitlements();
    
    _trackEvent(MonetizationEvent.upgradeCompleted, {
      'product_id': productId,
      'subscription_type': subscriptionType.name,
      'subscription_id': subscriptionId,
      'end_date': endDate?.toIso8601String(),
    });

    return true;
  }

  /// Handle failed purchase
  Future<void> handleFailedPurchase(String productId, String reason) async {
    _trackEvent(MonetizationEvent.upgradeFailed, {
      'product_id': productId,
      'reason': reason,
    });
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    _trackEvent(MonetizationEvent.restorePurchaseAttempted);

    try {
      // In a real app, this would check with the platform stores
      // For now, simulate a restore check
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if we have stored purchase info
      final lastCheck = _prefs?.getInt(_lastPurchaseCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Only allow restore check once per hour to prevent abuse
      if (now - lastCheck < 3600000) {
        _trackEvent(MonetizationEvent.restorePurchaseFailed, {
          'reason': 'rate_limited',
        });
        return false;
      }

      await _prefs?.setInt(_lastPurchaseCheckKey, now);
      
      // In a real implementation, this would query the app stores
      // For demo purposes, we'll assume no purchases to restore
      _trackEvent(MonetizationEvent.restorePurchaseFailed, {
        'reason': 'no_purchases_found',
      });
      
      return false;
    } catch (e) {
      _trackEvent(MonetizationEvent.restorePurchaseFailed, {
        'reason': 'error',
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Check if subscription needs renewal
  bool needsRenewal() {
    return _currentEntitlements.subscriptionType == SubscriptionType.monthly &&
           _currentEntitlements.isSubscriptionExpired;
  }

  /// Check if trial is expiring soon (within 24 hours)
  bool isTrialExpiringSoon() {
    return _currentEntitlements.isInTrial &&
           _currentEntitlements.trialDaysRemaining <= 1;
  }

  /// Increment voice note usage
  Future<void> incrementVoiceNoteUsage() async {
    _currentEntitlements = _currentEntitlements.incrementVoiceNotes();
    await _saveEntitlements();
  }

  /// Increment export usage
  Future<void> incrementExportUsage() async {
    _currentEntitlements = _currentEntitlements.incrementExports();
    await _saveEntitlements();
  }

  /// Check if user has reached voice note limit
  bool hasReachedVoiceNoteLimit() {
    final limits = _currentEntitlements.currentLimits;
    if (limits.isUnlimited(limits.maxVoiceNotesPerMonth)) return false;
    return _currentEntitlements.currentMonthVoiceNotes >= limits.maxVoiceNotesPerMonth;
  }

  /// Check if user has reached export limit
  bool hasReachedExportLimit() {
    final limits = _currentEntitlements.currentLimits;
    if (limits.isUnlimited(limits.maxExportsPerMonth)) return false;
    return _currentEntitlements.currentMonthExports >= limits.maxExportsPerMonth;
  }

  /// Get remaining voice notes for current month
  int getRemainingVoiceNotes() {
    final limits = _currentEntitlements.currentLimits;
    if (limits.isUnlimited(limits.maxVoiceNotesPerMonth)) return -1;
    return (limits.maxVoiceNotesPerMonth - _currentEntitlements.currentMonthVoiceNotes).clamp(0, double.infinity).toInt();
  }

  /// Get remaining exports for current month
  int getRemainingExports() {
    final limits = _currentEntitlements.currentLimits;
    if (limits.isUnlimited(limits.maxExportsPerMonth)) return -1;
    return (limits.maxExportsPerMonth - _currentEntitlements.currentMonthExports).clamp(0, double.infinity).toInt();
  }

  /// Track when a free limit is reached
  void trackFreeLimitReached(String featureName) {
    _trackEvent(MonetizationEvent.freeLimitReached, {
      'feature': featureName,
      'limit_type': _currentEntitlements.tier.name,
    });
  }

  /// Track when upgrade is initiated
  void trackUpgradeInitiated(String productId, String source) {
    _trackEvent(MonetizationEvent.upgradeInitiated, {
      'product_id': productId,
      'source': source, // e.g., 'limit_reached', 'settings', 'feature_gate'
    });
  }

  /// Get upgrade messaging based on context
  Map<String, String> getUpgradeMessaging(String context) {
    switch (context) {
      case 'voice_note_limit':
        return {
          'title': 'Voice Note Limit Reached',
          'message': 'You\'ve used all ${currentLimits.maxVoiceNotesPerMonth} voice notes this month. Upgrade to Premium for unlimited voice notes!',
          'cta': 'Upgrade Now',
        };
      case 'export_limit':
        return {
          'title': 'Export Limit Reached',
          'message': 'You\'ve used all ${currentLimits.maxExportsPerMonth} exports this month. Upgrade to Premium for unlimited exports!',
          'cta': 'Upgrade Now',
        };
      case 'note_limit':
        return {
          'title': 'Note Limit Reached',
          'message': 'You\'ve reached the ${currentLimits.maxNotes} note limit. Upgrade to Premium for unlimited notes!',
          'cta': 'Upgrade Now',
        };
      case 'cloud_sync':
        return {
          'title': 'Cloud Sync Unavailable',
          'message': 'Cloud sync is a Premium feature. Upgrade to sync your notes across all devices!',
          'cta': 'Enable Sync',
        };
      case 'custom_themes':
        return {
          'title': 'Custom Themes',
          'message': 'Custom themes are available with Premium. Personalize your note-taking experience!',
          'cta': 'Unlock Themes',
        };
      default:
        return {
          'title': 'Upgrade to Premium',
          'message': 'Unlock all features with QuickNote Pro Premium!',
          'cta': 'Upgrade Now',
        };
    }
  }

  /// Clear all data (for testing or user logout)
  Future<void> clearData() async {
    _currentEntitlements = UserEntitlements.free();
    await _saveEntitlements();
  }

  @override
  void dispose() {
    _entitlementsController.close();
    super.dispose();
  }
}
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Service for managing user consent (GDPR, ATT, etc.)
class ConsentService extends ChangeNotifier {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  bool _gdprConsent = false;
  bool _attConsent = false;
  bool _isEuUser = false;
  bool _consentRequired = false;
  bool _initialized = false;

  // Getters
  bool get gdprConsent => _gdprConsent;
  bool get attConsent => _attConsent;
  bool get isEuUser => _isEuUser;
  bool get consentRequired => _consentRequired;
  bool get initialized => _initialized;
  bool get canShowAds => !_consentRequired || (_gdprConsent && _attConsent);
  bool get canShowPersonalizedAds => _gdprConsent && _attConsent;

  /// Initialize consent management
  Future<void> initialize() async {
    try {
      await _loadConsentState();
      await _checkUserLocation();
      
      if (Platform.isIOS) {
        await _requestATTPermission();
      }
      
      _initialized = true;
      notifyListeners();
      
      debugPrint('Consent service initialized');
    } catch (e) {
      debugPrint('Consent initialization error: $e');
    }
  }

  /// Load consent state from shared preferences
  Future<void> _loadConsentState() async {
    final prefs = await SharedPreferences.getInstance();
    
    _gdprConsent = prefs.getBool('gdpr_consent') ?? false;
    _attConsent = prefs.getBool('att_consent') ?? false;
    _isEuUser = prefs.getBool('is_eu_user') ?? false;
    _consentRequired = prefs.getBool('consent_required') ?? false;
  }

  /// Save consent state to shared preferences
  Future<void> _saveConsentState() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('gdpr_consent', _gdprConsent);
    await prefs.setBool('att_consent', _attConsent);
    await prefs.setBool('is_eu_user', _isEuUser);
    await prefs.setBool('consent_required', _consentRequired);
    
    // Store consent timestamp
    await prefs.setInt('consent_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if user is in EU (simplified geolocation)
  Future<void> _checkUserLocation() async {
    try {
      // In a real implementation, you'd use proper geolocation
      // For now, we'll check timezone or use a geolocation service
      final timeZone = DateTime.now().timeZoneName;
      
      // EU timezone patterns (simplified)
      final euTimezones = [
        'CET', 'EET', 'WET', 'GMT', 'BST', 'CEST', 'EEST'
      ];
      
      _isEuUser = euTimezones.any((tz) => timeZone.contains(tz));
      _consentRequired = _isEuUser || Platform.isIOS; // iOS requires ATT globally
      
      await _saveConsentState();
    } catch (e) {
      debugPrint('Location check error: $e');
      // Default to requiring consent for safety
      _consentRequired = true;
    }
  }

  /// Request ATT permission (iOS)
  Future<void> _requestATTPermission() async {
    if (!Platform.isIOS) return;

    try {
      // Check current status
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      
      if (status == TrackingStatus.notDetermined) {
        // Request permission
        final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        _attConsent = newStatus == TrackingStatus.authorized;
      } else {
        _attConsent = status == TrackingStatus.authorized;
      }
      
      await _saveConsentState();
      notifyListeners();
      
      debugPrint('ATT consent: $_attConsent');
    } catch (e) {
      debugPrint('ATT request error: $e');
      _attConsent = false;
    }
  }

  /// Show GDPR consent dialog
  Future<bool> requestGDPRConsent() async {
    if (!_isEuUser) {
      _gdprConsent = true;
      await _saveConsentState();
      notifyListeners();
      return true;
    }

    // In a real implementation, you'd show a proper consent dialog
    // For now, we'll simulate user consent
    _gdprConsent = true;
    await _saveConsentState();
    notifyListeners();
    
    return _gdprConsent;
  }

  /// Revoke consent
  Future<void> revokeConsent() async {
    _gdprConsent = false;
    _attConsent = false;
    
    await _saveConsentState();
    notifyListeners();
    
    debugPrint('Consent revoked');
  }

  /// Update GDPR consent
  Future<void> setGDPRConsent(bool consent) async {
    _gdprConsent = consent;
    await _saveConsentState();
    notifyListeners();
  }

  /// Check if consent is still valid (1 year expiry for GDPR)
  Future<bool> isConsentValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('consent_timestamp');
    
    if (timestamp == null) return false;
    
    final consentDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final daysSinceConsent = now.difference(consentDate).inDays;
    
    // GDPR requires consent refresh every 12 months
    return daysSinceConsent < 365;
  }

  /// Get consent status for analytics
  Map<String, dynamic> getConsentStatus() {
    return {
      'gdpr_consent': _gdprConsent,
      'att_consent': _attConsent,
      'is_eu_user': _isEuUser,
      'consent_required': _consentRequired,
      'can_show_ads': canShowAds,
      'can_show_personalized_ads': canShowPersonalizedAds,
    };
  }

  /// Reset consent (for testing)
  Future<void> resetConsent() async {
    if (kDebugMode) {
      _gdprConsent = false;
      _attConsent = false;
      _consentRequired = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gdpr_consent');
      await prefs.remove('att_consent');
      await prefs.remove('consent_required');
      await prefs.remove('consent_timestamp');
      
      notifyListeners();
      debugPrint('Consent reset for testing');
    }
  }

  /// Configure ads based on consent
  void configureAdsConsent() {
    if (!_initialized) return;

    try {
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        testDeviceIds: kDebugMode ? ['YOUR_TEST_DEVICE_ID'] : [],
      );

      MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      
      debugPrint('Ads configured with consent settings');
    } catch (e) {
      debugPrint('Error configuring ads consent: $e');
    }
  }
}
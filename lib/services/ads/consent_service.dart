import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Service to manage consent for ads tracking compliance.
/// 
/// Handles ATT (iOS) and GDPR/UMP (Android/EU) consent flows
/// to ensure compliance with privacy regulations.
class ConsentService extends ChangeNotifier {
  static const String _consentStatusKey = 'consent_status';
  static const String _attStatusKey = 'att_status';
  static const String _lastConsentRequestKey = 'last_consent_request';
  static const String _gdprAppliesKey = 'gdpr_applies';

  ConsentStatus _consentStatus = ConsentStatus.unknown;
  TrackingStatus _attStatus = TrackingStatus.notDetermined;
  bool? _gdprApplies;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Current consent status for personalized ads
  ConsentStatus get consentStatus => _consentStatus;

  /// Current ATT status (iOS only)
  TrackingStatus get attStatus => _attStatus;

  /// Whether GDPR applies to this user
  bool? get gdprApplies => _gdprApplies;

  /// Whether consent service is initialized
  bool get isInitialized => _isInitialized;

  /// Whether we can show personalized ads
  bool get canShowPersonalizedAds {
    return _consentStatus == ConsentStatus.obtained;
  }

  /// Whether we can show any ads (personalized or non-personalized)
  bool get canShowAds {
    // On iOS, we need ATT permission for tracking
    if (Platform.isIOS) {
      return _attStatus == TrackingStatus.authorized || 
             _attStatus == TrackingStatus.denied; // Can still show non-personalized
    }
    
    // On Android, respect UMP consent
    return _consentStatus == ConsentStatus.obtained || 
           _consentStatus == ConsentStatus.notRequired;
  }

  /// Initialize the consent service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadConsentState();
      
      if (Platform.isIOS) {
        await _initializeATT();
      }
      
      await _initializeUMP();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing consent service: $e');
      _isInitialized = true;
    }
  }

  /// Load consent state from local storage
  Future<void> _loadConsentState() async {
    if (_prefs == null) return;

    final consentIndex = _prefs!.getInt(_consentStatusKey) ?? 0;
    _consentStatus = ConsentStatus.values[consentIndex];
    
    final attIndex = _prefs!.getInt(_attStatusKey) ?? 0;
    _attStatus = TrackingStatus.values[attIndex];
    
    _gdprApplies = _prefs!.getBool(_gdprAppliesKey);
  }

  /// Initialize App Tracking Transparency (iOS)
  Future<void> _initializeATT() async {
    if (!Platform.isIOS) return;

    try {
      // Get current status
      _attStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
      await _saveATTStatus();
      
      // If not determined, we'll request permission when needed
      debugPrint('ATT Status: $_attStatus');
    } catch (e) {
      debugPrint('Error initializing ATT: $e');
    }
  }

  /// Initialize User Messaging Platform (UMP) for GDPR
  Future<void> _initializeUMP() async {
    try {
      // Initialize the consent form
      final consentInfo = await ConsentInformation.instance.reset();
      
      // Check if consent is required
      await ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
      );
      
      final status = await ConsentInformation.instance.getConsentStatus();
      _consentStatus = status;
      await _saveConsentStatus();
      
      _gdprApplies = await ConsentInformation.instance.isConsentFormAvailable();
      await _saveGDPRStatus();
      
      debugPrint('UMP Consent Status: $_consentStatus');
      debugPrint('GDPR Applies: $_gdprApplies');
      
    } catch (e) {
      debugPrint('Error initializing UMP: $e');
    }
  }

  /// Request consent if required
  Future<bool> requestConsentIfRequired() async {
    bool consentRequired = false;
    
    // Request ATT permission on iOS
    if (Platform.isIOS && _attStatus == TrackingStatus.notDetermined) {
      consentRequired = true;
      await _requestATTPermission();
    }
    
    // Request UMP consent if required
    if (_consentStatus == ConsentStatus.required) {
      consentRequired = true;
      await _requestUMPConsent();
    }
    
    // Update last request timestamp
    if (consentRequired && _prefs != null) {
      await _prefs!.setInt(_lastConsentRequestKey, DateTime.now().millisecondsSinceEpoch);
    }
    
    return consentRequired;
  }

  /// Request ATT permission (iOS)
  Future<void> _requestATTPermission() async {
    if (!Platform.isIOS) return;

    try {
      _attStatus = await AppTrackingTransparency.requestTrackingAuthorization();
      await _saveATTStatus();
      notifyListeners();
      
      debugPrint('ATT Permission Result: $_attStatus');
    } catch (e) {
      debugPrint('Error requesting ATT permission: $e');
    }
  }

  /// Request UMP consent (Android/GDPR)
  Future<void> _requestUMPConsent() async {
    try {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        await ConsentForm.loadAndShowConsentFormIfRequired();
        
        _consentStatus = await ConsentInformation.instance.getConsentStatus();
        await _saveConsentStatus();
        notifyListeners();
        
        debugPrint('UMP Consent Result: $_consentStatus');
      }
    } catch (e) {
      debugPrint('Error requesting UMP consent: $e');
    }
  }

  /// Save consent status to storage
  Future<void> _saveConsentStatus() async {
    if (_prefs != null) {
      await _prefs!.setInt(_consentStatusKey, _consentStatus.index);
    }
  }

  /// Save ATT status to storage
  Future<void> _saveATTStatus() async {
    if (_prefs != null) {
      await _prefs!.setInt(_attStatusKey, _attStatus.index);
    }
  }

  /// Save GDPR status to storage
  Future<void> _saveGDPRStatus() async {
    if (_prefs != null && _gdprApplies != null) {
      await _prefs!.setBool(_gdprAppliesKey, _gdprApplies!);
    }
  }

  /// Check if we should request consent (not too frequently)
  bool shouldRequestConsent() {
    if (_prefs == null) return true;
    
    final lastRequest = _prefs!.getInt(_lastConsentRequestKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dayInMs = 24 * 60 * 60 * 1000;
    
    // Don't request more than once per day
    return (now - lastRequest) > dayInMs;
  }

  /// Reset consent (for testing or user request)
  Future<void> resetConsent() async {
    try {
      if (Platform.isAndroid) {
        await ConsentInformation.instance.reset();
      }
      
      _consentStatus = ConsentStatus.unknown;
      _attStatus = TrackingStatus.notDetermined;
      _gdprApplies = null;
      
      if (_prefs != null) {
        await _prefs!.remove(_consentStatusKey);
        await _prefs!.remove(_attStatusKey);
        await _prefs!.remove(_gdprAppliesKey);
        await _prefs!.remove(_lastConsentRequestKey);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting consent: $e');
    }
  }

  /// Get consent status display text
  String get statusText {
    if (Platform.isIOS) {
      switch (_attStatus) {
        case TrackingStatus.authorized:
          return 'Tracking Authorized';
        case TrackingStatus.denied:
          return 'Tracking Denied';
        case TrackingStatus.restricted:
          return 'Tracking Restricted';
        case TrackingStatus.notDetermined:
          return 'Permission Pending';
      }
    } else {
      switch (_consentStatus) {
        case ConsentStatus.obtained:
          return 'Consent Obtained';
        case ConsentStatus.required:
          return 'Consent Required';
        case ConsentStatus.notRequired:
          return 'Consent Not Required';
        case ConsentStatus.unknown:
          return 'Unknown';
      }
    }
  }
}
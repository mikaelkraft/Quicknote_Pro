import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../billing/billing_service.dart';
import '../../constants/product_ids.dart';

/// Features that can be gated behind premium entitlements
enum PremiumFeature {
  voiceNoteTranscription,
  longerRecordings,
  backgroundRecording,
  advancedDrawingTools,
  drawingLayers,
  exportFormats,
  cloudSync,
  unlimitedNotes,
  advancedSearch,
  customThemes,
}

/// Service for managing premium entitlements and feature gating
class EntitlementService extends ChangeNotifier {
  final BillingService _billingService;
  SharedPreferences? _prefs;
  
  bool _isInitialized = false;
  Map<PremiumFeature, bool> _cachedEntitlements = {};
  
  // Feature limits for free users
  static const Map<PremiumFeature, int> _freeLimits = {
    PremiumFeature.voiceNoteTranscription: 10, // 10 per month
    PremiumFeature.longerRecordings: 60, // 60 seconds max
    PremiumFeature.unlimitedNotes: 100, // 100 notes max
  };
  
  EntitlementService(this._billingService) {
    _billingService.addListener(_onBillingStateChanged);
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPremiumUser => _billingService.isPremiumUser || _getDeveloperOverride();
  
  /// Initialize the entitlement service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    
    // Load cached entitlements
    await _loadCachedEntitlements();
    
    // Update entitlements based on current billing state
    await _updateAllEntitlements();
    
    notifyListeners();
  }
  
  /// Check if user has access to a specific premium feature
  bool hasFeature(PremiumFeature feature) {
    if (!_isInitialized) return false;
    
    // Always allow in debug mode if developer override is enabled
    if (_getDeveloperOverride()) return true;
    
    // Check cached entitlement first
    if (_cachedEntitlements.containsKey(feature)) {
      return _cachedEntitlements[feature]!;
    }
    
    // Fallback to billing service check
    return _billingService.isPremiumUser;
  }
  
  /// Check if user has reached the limit for a feature
  bool hasReachedLimit(PremiumFeature feature, int currentUsage) {
    if (hasFeature(feature)) {
      return false; // Premium users have no limits
    }
    
    final limit = _freeLimits[feature];
    if (limit == null) {
      return false; // No limit defined
    }
    
    return currentUsage >= limit;
  }
  
  /// Get the limit for a feature
  int? getFeatureLimit(PremiumFeature feature) {
    if (hasFeature(feature)) {
      return null; // No limit for premium users
    }
    
    return _freeLimits[feature];
  }
  
  /// Get remaining usage for a feature
  int? getRemainingUsage(PremiumFeature feature, int currentUsage) {
    final limit = getFeatureLimit(feature);
    if (limit == null) {
      return null; // No limit
    }
    
    return (limit - currentUsage).clamp(0, limit);
  }
  
  /// Check if feature requires premium (for UI display)
  bool isFeaturePremium(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.voiceNoteTranscription:
      case PremiumFeature.longerRecordings:
      case PremiumFeature.backgroundRecording:
      case PremiumFeature.advancedDrawingTools:
      case PremiumFeature.drawingLayers:
      case PremiumFeature.exportFormats:
      case PremiumFeature.cloudSync:
      case PremiumFeature.advancedSearch:
      case PremiumFeature.customThemes:
        return true;
      case PremiumFeature.unlimitedNotes:
        return false; // Has free limit, not strictly premium-only
    }
  }
  
  /// Get user-friendly feature name
  String getFeatureName(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.voiceNoteTranscription:
        return 'Voice Note Transcription';
      case PremiumFeature.longerRecordings:
        return 'Longer Recordings';
      case PremiumFeature.backgroundRecording:
        return 'Background Recording';
      case PremiumFeature.advancedDrawingTools:
        return 'Advanced Drawing Tools';
      case PremiumFeature.drawingLayers:
        return 'Drawing Layers';
      case PremiumFeature.exportFormats:
        return 'Export Formats';
      case PremiumFeature.cloudSync:
        return 'Cloud Sync';
      case PremiumFeature.unlimitedNotes:
        return 'Unlimited Notes';
      case PremiumFeature.advancedSearch:
        return 'Advanced Search';
      case PremiumFeature.customThemes:
        return 'Custom Themes';
    }
  }
  
  /// Get feature description for upsell
  String getFeatureDescription(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.voiceNoteTranscription:
        return 'Automatically transcribe your voice notes with AI';
      case PremiumFeature.longerRecordings:
        return 'Record voice notes longer than 60 seconds';
      case PremiumFeature.backgroundRecording:
        return 'Continue recording when app is in background';
      case PremiumFeature.advancedDrawingTools:
        return 'Access professional drawing and annotation tools';
      case PremiumFeature.drawingLayers:
        return 'Create complex drawings with multiple layers';
      case PremiumFeature.exportFormats:
        return 'Export notes in PDF, Word, and other formats';
      case PremiumFeature.cloudSync:
        return 'Sync your notes across all devices';
      case PremiumFeature.unlimitedNotes:
        return 'Create unlimited notes without restrictions';
      case PremiumFeature.advancedSearch:
        return 'Search with filters, tags, and advanced queries';
      case PremiumFeature.customThemes:
        return 'Personalize with custom colors and themes';
    }
  }
  
  /// Handle billing service state changes
  void _onBillingStateChanged() {
    _updateAllEntitlements();
  }
  
  /// Update all entitlements based on current state
  Future<void> _updateAllEntitlements() async {
    if (!_isInitialized) return;
    
    final isPremium = _billingService.isPremiumUser || _getDeveloperOverride();
    
    // Update all features
    for (final feature in PremiumFeature.values) {
      _cachedEntitlements[feature] = isPremium;
    }
    
    // Save to cache
    await _saveCachedEntitlements();
    notifyListeners();
  }
  
  /// Load cached entitlements from local storage
  Future<void> _loadCachedEntitlements() async {
    if (_prefs == null) return;
    
    for (final feature in PremiumFeature.values) {
      final key = 'entitlement_${feature.name}';
      final cached = _prefs!.getBool(key) ?? false;
      _cachedEntitlements[feature] = cached;
    }
  }
  
  /// Save cached entitlements to local storage
  Future<void> _saveCachedEntitlements() async {
    if (_prefs == null) return;
    
    for (final entry in _cachedEntitlements.entries) {
      final key = 'entitlement_${entry.key.name}';
      await _prefs!.setBool(key, entry.value);
    }
  }
  
  /// Get developer override setting (debug builds only)
  bool _getDeveloperOverride() {
    if (!kDebugMode) return false;
    if (!ProductIds.allowDevBypass) return false;
    if (_prefs == null) return false;
    
    return _prefs!.getBool('dev_premium_override') ?? false;
  }
  
  /// Set developer override (debug builds only)
  Future<void> setDeveloperOverride(bool enabled) async {
    if (!kDebugMode) return;
    if (!ProductIds.allowDevBypass) return;
    if (_prefs == null) return;
    
    await _prefs!.setBool('dev_premium_override', enabled);
    await _updateAllEntitlements();
  }
  
  /// Refresh entitlements from billing service
  Future<void> refresh() async {
    await _updateAllEntitlements();
  }
  
  @override
  void dispose() {
    _billingService.removeListener(_onBillingStateChanged);
    super.dispose();
  }
}
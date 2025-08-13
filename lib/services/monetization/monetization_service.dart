import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_service.dart';
import '../ads/ad_service.dart';
import '../../constants/product_ids.dart';
import '../../models/analytics_event.dart';

/// Service for managing monetization features including premium status, feature gating, and usage limits
class MonetizationService {
  static final MonetizationService _instance = MonetizationService._internal();
  factory MonetizationService() => _instance;
  MonetizationService._internal();

  SharedPreferences? _prefs;
  final AnalyticsService _analytics = AnalyticsService();
  final AdService _adService = AdService();
  bool _isInitialized = false;
  bool _isPremiumUser = false;

  /// Initialize the monetization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _isPremiumUser = _prefs!.getBool('is_premium_user') ?? false;
    
    await _analytics.initialize();
    await _adService.initialize(isPremiumUser: _isPremiumUser);
    
    _isInitialized = true;

    // Track app launch
    await _analytics.trackActivation(AnalyticsEvents.appLaunched);
  }

  /// Check if user has premium access
  bool get isPremiumUser => _isPremiumUser;

  /// Get current user tier
  String get userTier => _isPremiumUser ? 'premium' : 'free';

  /// Update premium status
  Future<void> updatePremiumStatus(bool isPremium) async {
    _isPremiumUser = isPremium;
    await _prefs?.setBool('is_premium_user', isPremium);
    _adService.updatePremiumStatus(isPremium);
  }

  /// Check if a premium feature is available to the user
  bool isFeatureAvailable(String featureName) {
    if (_isPremiumUser) return true;

    // Define which features are available in free tier
    final freeFeatures = [
      'basic_notes',
      'basic_editing',
      'basic_search',
      'basic_folders',
    ];

    return freeFeatures.contains(featureName);
  }

  /// Check usage limits for free tier users
  Future<bool> canUseFeature(String featureName) async {
    if (_isPremiumUser) return true;

    switch (featureName) {
      case 'create_note':
        return await _checkNoteLimit();
      case 'voice_note':
        return await _checkVoiceNoteLimit();
      case 'add_attachment':
        return await _checkAttachmentLimit();
      case 'cloud_sync':
        return false; // Premium only
      case 'advanced_drawing':
        return false; // Premium only
      case 'export_formats':
        return false; // Premium only
      case 'ocr':
        return false; // Premium only
      default:
        return true;
    }
  }

  /// Track when a user hits a free tier limit
  Future<void> trackFeatureBlocked(String featureName, {String? reason}) async {
    await _analytics.trackPremiumBlock(featureName);
    
    // Show upgrade suggestion after multiple blocks
    final blockCount = await _getFeatureBlockCount(featureName);
    if (blockCount >= 3) {
      await _suggestUpgrade(featureName);
    }
  }

  /// Track premium screen views and conversion funnel
  Future<void> trackPremiumScreenView({String? source}) async {
    await _analytics.trackConversion(
      AnalyticsEvents.premiumScreenViewed,
      properties: {
        'source': source ?? 'unknown',
      },
    );
  }

  /// Track upgrade button interactions
  Future<void> trackUpgradeAttempt(String planType, {String? source}) async {
    await _analytics.trackConversion(
      AnalyticsEvents.upgradeButtonTapped,
      properties: {
        'plan_type': planType,
        'source': source ?? 'unknown',
      },
    );
  }

  /// Track purchase events
  Future<void> trackPurchaseEvent(String eventName, {
    String? planType,
    String? price,
    String? currency,
    String? errorCode,
    String? errorMessage,
  }) async {
    await _analytics.trackPurchaseEvent(
      eventName,
      subscriptionType: planType,
      price: price,
      currency: currency,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  /// Get usage statistics for display in UI
  Future<Map<String, dynamic>> getUsageStats() async {
    final notesCount = await _getNotesCount();
    final voiceNotesCount = await _getVoiceNotesCount();
    final attachmentsCount = await _getAttachmentsCount();

    return {
      'notes_count': notesCount,
      'notes_limit': ProductIds.freeNotesLimit,
      'notes_percentage': _isPremiumUser ? 100.0 : (notesCount / ProductIds.freeNotesLimit * 100).clamp(0.0, 100.0),
      'voice_notes_count': voiceNotesCount,
      'voice_notes_limit': ProductIds.freeVoiceNotesLimit,
      'voice_notes_percentage': _isPremiumUser ? 100.0 : (voiceNotesCount / ProductIds.freeVoiceNotesLimit * 100).clamp(0.0, 100.0),
      'attachments_count': attachmentsCount,
      'attachments_limit': ProductIds.freeAttachmentsLimit,
      'attachments_percentage': _isPremiumUser ? 100.0 : (attachmentsCount / ProductIds.freeAttachmentsLimit * 100).clamp(0.0, 100.0),
      'is_premium': _isPremiumUser,
      'tier': userTier,
    };
  }

  /// Get monetization insights for analytics
  Future<Map<String, dynamic>> getMonetizationInsights() async {
    final userMetrics = await _analytics.getUserMetrics();
    final adMetrics = await _adService.getAdMetrics();
    final usageStats = await getUsageStats();

    return {
      'user_metrics': userMetrics,
      'ad_metrics': adMetrics,
      'usage_stats': usageStats,
      'conversion_funnel': await _getConversionFunnel(),
    };
  }

  /// Show upgrade suggestion to user
  Future<void> _suggestUpgrade(String blockedFeature) async {
    // In a real implementation, this would show an upgrade dialog or navigate to premium screen
    await _analytics.trackConversion(
      AnalyticsEvents.premiumScreenViewed,
      properties: {
        'source': 'feature_blocked',
        'blocked_feature': blockedFeature,
      },
    );
  }

  // Private helper methods for checking limits
  Future<bool> _checkNoteLimit() async {
    final notesCount = await _getNotesCount();
    return notesCount < ProductIds.freeNotesLimit;
  }

  Future<bool> _checkVoiceNoteLimit() async {
    final voiceNotesCount = await _getVoiceNotesCount();
    return voiceNotesCount < ProductIds.freeVoiceNotesLimit;
  }

  Future<bool> _checkAttachmentLimit() async {
    final attachmentsCount = await _getAttachmentsCount();
    return attachmentsCount < ProductIds.freeAttachmentsLimit;
  }

  Future<int> _getNotesCount() async {
    // In real implementation, get from notes service
    return _prefs?.getInt('notes_count') ?? 0;
  }

  Future<int> _getVoiceNotesCount() async {
    // In real implementation, get from notes service
    return _prefs?.getInt('voice_notes_count') ?? 0;
  }

  Future<int> _getAttachmentsCount() async {
    // In real implementation, get from notes service
    return _prefs?.getInt('attachments_count') ?? 0;
  }

  Future<int> _getFeatureBlockCount(String featureName) async {
    final key = 'feature_block_count_$featureName';
    final count = _prefs?.getInt(key) ?? 0;
    await _prefs?.setInt(key, count + 1);
    return count + 1;
  }

  Future<Map<String, dynamic>> _getConversionFunnel() async {
    final events = await _analytics.getUserMetrics();
    
    // Calculate conversion funnel metrics
    return {
      'premium_views': events['premium_blocks_count'] ?? 0,
      'upgrade_attempts': events['upgrade_attempts'] ?? 0,
      'conversions': _isPremiumUser ? 1 : 0,
    };
  }

  /// Increment usage counters (to be called by other services)
  Future<void> incrementNotesCount() async {
    final current = await _getNotesCount();
    await _prefs?.setInt('notes_count', current + 1);
  }

  Future<void> incrementVoiceNotesCount() async {
    final current = await _getVoiceNotesCount();
    await _prefs?.setInt('voice_notes_count', current + 1);
  }

  Future<void> incrementAttachmentsCount() async {
    final current = await _getAttachmentsCount();
    await _prefs?.setInt('attachments_count', current + 1);
  }
}
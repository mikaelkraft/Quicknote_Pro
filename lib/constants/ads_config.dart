/// Centralized ads configuration for consistent usage across the app.
/// 
/// This configuration defines ad placements, formats, frequency caps,
/// and analytics tracking for the free tier experience.
class AdsConfig {
  AdsConfig._(); // Private constructor to prevent instantiation

  /// Ad placement identifiers
  static const String placementHome = 'home_screen';
  static const String placementNoteList = 'note_list';
  static const String placementNoteDetails = 'note_details';
  static const String placementSettings = 'settings';
  static const String placementSearch = 'search_results';
  static const String placementFolders = 'folder_organization';

  /// List of all ad placements for easy iteration
  static const List<String> allPlacements = [
    placementHome,
    placementNoteList,
    placementNoteDetails,
    placementSettings,
    placementSearch,
    placementFolders,
  ];

  /// Ad format types
  static const String formatBanner = 'banner';
  static const String formatInterstitial = 'interstitial';
  static const String formatNative = 'native';
  static const String formatRewardedVideo = 'rewarded_video';

  /// List of supported ad formats
  static const List<String> supportedFormats = [
    formatBanner,
    formatInterstitial,
    formatNative,
    formatRewardedVideo,
  ];

  /// Frequency caps (in minutes) for different ad types
  static const Map<String, int> frequencyCaps = {
    formatBanner: 0, // No cap for banner ads
    formatInterstitial: 30, // 30 minutes between interstitials
    formatNative: 5, // 5 minutes between native ads
    formatRewardedVideo: 15, // 15 minutes between rewarded videos
  };

  /// Maximum ads per session for each placement
  static const Map<String, int> sessionLimits = {
    placementHome: 10,
    placementNoteList: 15,
    placementNoteDetails: 8,
    placementSettings: 5,
    placementSearch: 12,
    placementFolders: 6,
  };

  /// Default ad configuration for each placement
  static const Map<String, Map<String, dynamic>> placementConfig = {
    placementHome: {
      'formats': [formatBanner, formatNative],
      'priority': [formatNative, formatBanner],
      'sessionLimit': 10,
      'abTestEnabled': true,
    },
    placementNoteList: {
      'formats': [formatBanner, formatNative, formatInterstitial],
      'priority': [formatBanner, formatNative, formatInterstitial],
      'sessionLimit': 15,
      'abTestEnabled': true,
    },
    placementNoteDetails: {
      'formats': [formatBanner, formatNative],
      'priority': [formatNative, formatBanner],
      'sessionLimit': 8,
      'abTestEnabled': false,
    },
    placementSettings: {
      'formats': [formatBanner, formatNative],
      'priority': [formatBanner, formatNative],
      'sessionLimit': 5,
      'abTestEnabled': false,
    },
    placementSearch: {
      'formats': [formatBanner, formatNative],
      'priority': [formatNative, formatBanner],
      'sessionLimit': 12,
      'abTestEnabled': true,
    },
    placementFolders: {
      'formats': [formatBanner, formatNative],
      'priority': [formatNative, formatBanner],
      'sessionLimit': 6,
      'abTestEnabled': false,
    },
  };

  /// A/B testing configuration
  static const Map<String, List<String>> abTestVariants = {
    'home_ad_position': ['top', 'bottom', 'middle'],
    'note_list_ad_frequency': ['every_5', 'every_10', 'every_15'],
    'ad_format_preference': ['banner_first', 'native_first', 'mixed'],
  };

  /// Analytics event names
  static const String eventAdImpression = 'ad_impression';
  static const String eventAdClick = 'ad_click';
  static const String eventAdDismiss = 'ad_dismiss';
  static const String eventAdBlocked = 'ad_blocked';
  static const String eventAdConversion = 'ad_conversion';
  static const String eventAdLoadFailure = 'ad_load_failure';
  static const String eventAdFrequencyCapped = 'ad_frequency_capped';

  /// List of all analytics events
  static const List<String> allAnalyticsEvents = [
    eventAdImpression,
    eventAdClick,
    eventAdDismiss,
    eventAdBlocked,
    eventAdConversion,
    eventAdLoadFailure,
    eventAdFrequencyCapped,
  ];

  /// Feature flags for ads functionality
  static const bool adsEnabled = true; // Master switch for ads
  static const bool abTestingEnabled = true; // A/B testing enabled
  static const bool analyticsEnabled = true; // Analytics tracking enabled
  static const bool frequencyCappingEnabled = true; // Frequency capping enabled
  static const bool allowAdBlocking = false; // Whether to respect ad blockers

  /// Fallback configuration for failed ad loads
  static const int maxRetryAttempts = 3;
  static const int retryDelayMs = 2000; // 2 seconds
  static const bool showFallbackContent = true;
  static const String fallbackContentText = 'Support QuickNote Pro by upgrading to Premium!';

  /// Ad loading timeouts (in milliseconds)
  static const int bannerLoadTimeout = 10000; // 10 seconds
  static const int interstitialLoadTimeout = 15000; // 15 seconds
  static const int nativeLoadTimeout = 12000; // 12 seconds
  static const int rewardedVideoLoadTimeout = 20000; // 20 seconds

  /// Gets the timeout for a specific ad format
  static int getTimeoutForFormat(String format) {
    switch (format) {
      case formatBanner:
        return bannerLoadTimeout;
      case formatInterstitial:
        return interstitialLoadTimeout;
      case formatNative:
        return nativeLoadTimeout;
      case formatRewardedVideo:
        return rewardedVideoLoadTimeout;
      default:
        return bannerLoadTimeout;
    }
  }

  /// Gets the frequency cap for a specific ad format
  static int getFrequencyCapForFormat(String format) {
    return frequencyCaps[format] ?? 0;
  }

  /// Gets the session limit for a specific placement
  static int getSessionLimitForPlacement(String placement) {
    return sessionLimits[placement] ?? 10;
  }

  /// Gets the supported formats for a placement
  static List<String> getFormatsForPlacement(String placement) {
    final config = placementConfig[placement];
    return config != null ? List<String>.from(config['formats']) : [formatBanner];
  }

  /// Gets the priority order of formats for a placement
  static List<String> getPriorityForPlacement(String placement) {
    final config = placementConfig[placement];
    return config != null ? List<String>.from(config['priority']) : [formatBanner];
  }

  /// Checks if A/B testing is enabled for a placement
  static bool isAbTestEnabledForPlacement(String placement) {
    final config = placementConfig[placement];
    return config != null ? config['abTestEnabled'] ?? false : false;
  }
}
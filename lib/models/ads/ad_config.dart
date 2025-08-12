import 'dart:io';

/// Configuration class for ad unit IDs with secure rotation support.
/// 
/// Manages ad unit IDs for different platforms and ad types,
/// with rotation capability for security and performance.
class AdConfig {
  AdConfig._();

  /// Test ad unit IDs (used in debug builds)
  static const Map<String, String> _testAdUnits = {
    'banner_android': 'ca-app-pub-3940256099942544/6300978111',
    'banner_ios': 'ca-app-pub-3940256099942544/2934735716',
    'interstitial_android': 'ca-app-pub-3940256099942544/1033173712',
    'interstitial_ios': 'ca-app-pub-3940256099942544/4411468910',
    'rewarded_android': 'ca-app-pub-3940256099942544/5224354917',
    'rewarded_ios': 'ca-app-pub-3940256099942544/1712485313',
  };

  /// Production ad unit IDs (replace with your actual AdMob IDs)
  static const Map<String, List<String>> _productionAdUnits = {
    'banner_android': [
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Primary banner unit
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Secondary banner unit
    ],
    'banner_ios': [
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Primary banner unit
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Secondary banner unit
    ],
    'interstitial_android': [
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Primary interstitial unit
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Secondary interstitial unit
    ],
    'interstitial_ios': [
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Primary interstitial unit
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Secondary interstitial unit
    ],
    'rewarded_android': [
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Primary rewarded unit
    ],
    'rewarded_ios': [
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Primary rewarded unit
    ],
  };

  /// Rotation index for ad unit selection
  static int _rotationIndex = 0;

  /// Get banner ad unit ID
  static String get bannerAdUnitId {
    return _getAdUnitId('banner');
  }

  /// Get interstitial ad unit ID
  static String get interstitialAdUnitId {
    return _getAdUnitId('interstitial');
  }

  /// Get rewarded ad unit ID
  static String get rewardedAdUnitId {
    return _getAdUnitId('rewarded');
  }

  /// Get ad unit ID with platform detection and rotation
  static String _getAdUnitId(String adType) {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final key = '${adType}_$platform';

    // Use test ads in debug mode
    if (_isDebugMode()) {
      return _testAdUnits[key] ?? '';
    }

    // Get production ad units
    final adUnits = _productionAdUnits[key] ?? [];
    if (adUnits.isEmpty) {
      // Fallback to test ads if production IDs not configured
      return _testAdUnits[key] ?? '';
    }

    // Rotate through available ad units
    final index = _rotationIndex % adUnits.length;
    return adUnits[index];
  }

  /// Check if we're in debug mode
  static bool _isDebugMode() {
    bool debugMode = false;
    assert(debugMode = true); // This will only execute in debug mode
    return debugMode;
  }

  /// Rotate to next ad unit (call after failed ad load)
  static void rotateAdUnit() {
    _rotationIndex++;
  }

  /// Reset rotation index
  static void resetRotation() {
    _rotationIndex = 0;
  }

  /// Ad refresh intervals (in seconds)
  static const Duration bannerRefreshInterval = Duration(minutes: 5);
  static const Duration interstitialCooldown = Duration(minutes: 3);
  static const Duration rewardedCooldown = Duration(minutes: 10);

  /// Ad display constraints
  static const int maxInterstitialsPerSession = 3;
  static const int maxInterstitialsPerHour = 6;
  static const Duration minSessionTimeBeforeAds = Duration(seconds: 30);

  /// Regional restrictions (countries where ads are disabled)
  static const List<String> restrictedCountries = [
    'CN', // China
    // Add other restricted countries as needed
  ];

  /// Check if ads are allowed in the current region
  static bool isRegionAllowed(String? countryCode) {
    if (countryCode == null) return true;
    return !restrictedCountries.contains(countryCode.toUpperCase());
  }

  /// Ad size configurations
  static const bannerAdSize = 'BANNER'; // 320x50
  static const largeBannerAdSize = 'LARGE_BANNER'; // 320x100
  static const mediumRectangleAdSize = 'MEDIUM_RECTANGLE'; // 300x250

  /// Get appropriate banner size based on screen width
  static String getBannerSize(double screenWidth) {
    if (screenWidth >= 728) {
      return 'LEADERBOARD'; // 728x90 for tablets
    } else if (screenWidth >= 320) {
      return bannerAdSize; // 320x50 for phones
    }
    return bannerAdSize; // Default
  }
}
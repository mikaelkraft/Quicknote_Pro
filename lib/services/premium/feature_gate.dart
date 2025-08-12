import 'package:flutter/foundation.dart';

/// Feature flags and gating logic for premium functionality.
/// Provides a centralized way to check if premium features are available.
class FeatureGate {
  FeatureGate._(); // Private constructor to prevent instantiation

  /// Voice note related features
  static const int maxFreeVoiceNotes = 10;
  static const Duration maxFreeRecordingLength = Duration(minutes: 2);
  static const Duration maxPremiumRecordingLength = Duration(hours: 1);

  /// Drawing/doodle related features
  static const int maxFreeLayers = 1;
  static const int maxPremiumLayers = 10;

  /// Note export formats
  static const List<String> freeExportFormats = ['txt'];
  static const List<String> premiumExportFormats = ['txt', 'pdf', 'docx', 'md'];

  /// Storage limits
  static const int freeCloudStorageMB = 100;
  static const int premiumCloudStorageMB = 10240; // 10GB

  /// Check if voice note recording is allowed
  /// [currentCount] - number of voice notes already created this month
  /// [isPremium] - whether user has premium subscription
  static bool canRecordVoiceNote(int currentCount, bool isPremium) {
    if (isPremium) return true;
    return currentCount < maxFreeVoiceNotes;
  }

  /// Check if voice note transcription is available
  /// Only available for premium users
  static bool canTranscribeVoiceNote(bool isPremium) {
    return isPremium;
  }

  /// Check if background recording is allowed
  /// Only available for premium users
  static bool canUseBackgroundRecording(bool isPremium) {
    return isPremium;
  }

  /// Get maximum recording length based on premium status
  static Duration getMaxRecordingLength(bool isPremium) {
    return isPremium ? maxPremiumRecordingLength : maxFreeRecordingLength;
  }

  /// Check if advanced drawing tools are available
  /// Only available for premium users
  static bool canUseAdvancedDrawingTools(bool isPremium) {
    return isPremium;
  }

  /// Check if layers are available for drawing
  /// [requestedLayers] - number of layers requested
  /// [isPremium] - whether user has premium subscription
  static bool canUseLayers(int requestedLayers, bool isPremium) {
    final maxLayers = isPremium ? maxPremiumLayers : maxFreeLayers;
    return requestedLayers <= maxLayers;
  }

  /// Get maximum number of layers allowed
  static int getMaxLayers(bool isPremium) {
    return isPremium ? maxPremiumLayers : maxFreeLayers;
  }

  /// Check if export format is available
  /// [format] - export format (e.g., 'pdf', 'docx')
  /// [isPremium] - whether user has premium subscription
  static bool canUseExportFormat(String format, bool isPremium) {
    if (isPremium) {
      return premiumExportFormats.contains(format.toLowerCase());
    }
    return freeExportFormats.contains(format.toLowerCase());
  }

  /// Get available export formats based on premium status
  static List<String> getAvailableExportFormats(bool isPremium) {
    return isPremium ? premiumExportFormats : freeExportFormats;
  }

  /// Check if cloud sync is available
  /// Only available for premium users
  static bool canUseCloudSync(bool isPremium) {
    return isPremium;
  }

  /// Check if cloud storage limit allows upload
  /// [currentUsageMB] - current storage usage in MB
  /// [isPremium] - whether user has premium subscription
  static bool canUploadToCloud(double currentUsageMB, bool isPremium) {
    final maxStorage = isPremium ? premiumCloudStorageMB : freeCloudStorageMB;
    return currentUsageMB < maxStorage;
  }

  /// Get maximum cloud storage in MB
  static int getMaxCloudStorageMB(bool isPremium) {
    return isPremium ? premiumCloudStorageMB : freeCloudStorageMB;
  }

  /// Check if ads should be shown
  /// Ads are hidden for premium users
  static bool shouldShowAds(bool isPremium) {
    return !isPremium;
  }

  /// Check if OCR (text recognition) is available
  /// Basic OCR is free, advanced OCR is premium
  static bool canUseAdvancedOCR(bool isPremium) {
    return isPremium;
  }

  /// Check if note templates are available
  /// Only available for premium users
  static bool canUseNoteTemplates(bool isPremium) {
    return isPremium;
  }

  /// Check if note encryption is available
  /// Only available for premium users
  static bool canUseNoteEncryption(bool isPremium) {
    return isPremium;
  }

  /// Check if collaborative editing is available
  /// Only available for premium users
  static bool canUseCollaborativeEditing(bool isPremium) {
    return isPremium;
  }

  /// Get a user-friendly message for why a feature is locked
  /// [featureName] - name of the locked feature
  static String getFeatureLockMessage(String featureName) {
    return 'Upgrade to Premium to unlock $featureName and more advanced features.';
  }

  /// Get upgrade CTA message based on feature context
  /// [featureName] - name of the feature user tried to access
  static String getUpgradeMessage(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'voice notes':
        return 'Upgrade to Premium for unlimited voice notes with AI transcription.';
      case 'drawing tools':
        return 'Upgrade to Premium for advanced drawing tools and layers.';
      case 'cloud sync':
        return 'Upgrade to Premium to sync notes across all your devices.';
      case 'export':
        return 'Upgrade to Premium to export notes in PDF, DOCX, and more formats.';
      case 'background recording':
        return 'Upgrade to Premium to record voice notes in the background.';
      default:
        return 'Upgrade to Premium to unlock this feature and many more.';
    }
  }

  /// Development/testing helper to bypass feature gates
  static bool bypassFeatureGates() {
    return kDebugMode && const bool.fromEnvironment('BYPASS_PREMIUM', defaultValue: false);
  }

  /// Check any premium feature with bypass for development
  static bool checkFeature(bool Function() featureCheck) {
    if (bypassFeatureGates()) return true;
    return featureCheck();
  }
}
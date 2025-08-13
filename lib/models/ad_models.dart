/// Model representing an ad placement configuration
class AdPlacement {
  final String id;
  final String name;
  final AdFormat format;
  final String location;
  final int maxDailyImpressions;
  final int minIntervalMinutes;
  final bool isDismissible;

  const AdPlacement({
    required this.id,
    required this.name,
    required this.format,
    required this.location,
    required this.maxDailyImpressions,
    required this.minIntervalMinutes,
    this.isDismissible = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'format': format.name,
      'location': location,
      'maxDailyImpressions': maxDailyImpressions,
      'minIntervalMinutes': minIntervalMinutes,
      'isDismissible': isDismissible,
    };
  }

  factory AdPlacement.fromJson(Map<String, dynamic> json) {
    return AdPlacement(
      id: json['id'] as String,
      name: json['name'] as String,
      format: AdFormat.values.firstWhere((f) => f.name == json['format']),
      location: json['location'] as String,
      maxDailyImpressions: json['maxDailyImpressions'] as int,
      minIntervalMinutes: json['minIntervalMinutes'] as int,
      isDismissible: json['isDismissible'] as bool? ?? true,
    );
  }
}

/// Ad format types
enum AdFormat {
  banner,
  interstitial,
  native,
  rewarded,
}

/// Model representing an ad impression
class AdImpression {
  final String id;
  final String placementId;
  final AdFormat format;
  final DateTime timestamp;
  final String? adProvider;
  final bool wasClicked;
  final bool wasDismissed;

  const AdImpression({
    required this.id,
    required this.placementId,
    required this.format,
    required this.timestamp,
    this.adProvider,
    this.wasClicked = false,
    this.wasDismissed = false,
  });

  AdImpression copyWith({
    bool? wasClicked,
    bool? wasDismissed,
  }) {
    return AdImpression(
      id: id,
      placementId: placementId,
      format: format,
      timestamp: timestamp,
      adProvider: adProvider,
      wasClicked: wasClicked ?? this.wasClicked,
      wasDismissed: wasDismissed ?? this.wasDismissed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placementId': placementId,
      'format': format.name,
      'timestamp': timestamp.toIso8601String(),
      'adProvider': adProvider,
      'wasClicked': wasClicked,
      'wasDismissed': wasDismissed,
    };
  }

  factory AdImpression.fromJson(Map<String, dynamic> json) {
    return AdImpression(
      id: json['id'] as String,
      placementId: json['placementId'] as String,
      format: AdFormat.values.firstWhere((f) => f.name == json['format']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      adProvider: json['adProvider'] as String?,
      wasClicked: json['wasClicked'] as bool? ?? false,
      wasDismissed: json['wasDismissed'] as bool? ?? false,
    );
  }
}

/// Predefined ad placements for the app
class AdPlacements {
  AdPlacements._();

  static const AdPlacement noteListBanner = AdPlacement(
    id: 'note_list_banner',
    name: 'Note List Banner',
    format: AdFormat.banner,
    location: 'notes_dashboard',
    maxDailyImpressions: 10,
    minIntervalMinutes: 30,
    isDismissible: true,
  );

  static const AdPlacement editingInterstitial = AdPlacement(
    id: 'editing_interstitial',
    name: 'Editing Interstitial',
    format: AdFormat.interstitial,
    location: 'note_editor',
    maxDailyImpressions: 3,
    minIntervalMinutes: 60,
    isDismissible: false,
  );

  static const AdPlacement premiumNative = AdPlacement(
    id: 'premium_native',
    name: 'Premium Native',
    format: AdFormat.native,
    location: 'premium_screen',
    maxDailyImpressions: 5,
    minIntervalMinutes: 15,
    isDismissible: true,
  );

  static const AdPlacement rewardedUpgrade = AdPlacement(
    id: 'rewarded_upgrade',
    name: 'Rewarded Upgrade',
    format: AdFormat.rewarded,
    location: 'premium_blocked',
    maxDailyImpressions: 3,
    minIntervalMinutes: 120,
    isDismissible: false,
  );

  /// Get all predefined ad placements
  static List<AdPlacement> get allPlacements => [
    noteListBanner,
    editingInterstitial,
    premiumNative,
    rewardedUpgrade,
  ];

  /// Get placement by ID
  static AdPlacement? getById(String id) {
    try {
      return allPlacements.firstWhere((placement) => placement.id == id);
    } catch (e) {
      return null;
    }
  }
}
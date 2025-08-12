/// Represents an ad placement within the app.
/// 
/// This model defines where, when, and how ads should be displayed
/// in different parts of the QuickNote Pro interface.
class AdPlacement {
  final String id;
  final String name;
  final String screenLocation;
  final List<String> supportedFormats;
  final List<String> formatPriority;
  final int sessionLimit;
  final bool abTestEnabled;
  final Map<String, dynamic> metadata;

  const AdPlacement({
    required this.id,
    required this.name,
    required this.screenLocation,
    required this.supportedFormats,
    required this.formatPriority,
    required this.sessionLimit,
    this.abTestEnabled = false,
    this.metadata = const {},
  });

  /// Creates an AdPlacement from JSON configuration
  factory AdPlacement.fromJson(Map<String, dynamic> json) {
    return AdPlacement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      screenLocation: json['screenLocation'] ?? '',
      supportedFormats: List<String>.from(json['supportedFormats'] ?? []),
      formatPriority: List<String>.from(json['formatPriority'] ?? []),
      sessionLimit: json['sessionLimit'] ?? 10,
      abTestEnabled: json['abTestEnabled'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converts the AdPlacement to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'screenLocation': screenLocation,
      'supportedFormats': supportedFormats,
      'formatPriority': formatPriority,
      'sessionLimit': sessionLimit,
      'abTestEnabled': abTestEnabled,
      'metadata': metadata,
    };
  }

  /// Creates a copy of the AdPlacement with optional parameter overrides
  AdPlacement copyWith({
    String? id,
    String? name,
    String? screenLocation,
    List<String>? supportedFormats,
    List<String>? formatPriority,
    int? sessionLimit,
    bool? abTestEnabled,
    Map<String, dynamic>? metadata,
  }) {
    return AdPlacement(
      id: id ?? this.id,
      name: name ?? this.name,
      screenLocation: screenLocation ?? this.screenLocation,
      supportedFormats: supportedFormats ?? this.supportedFormats,
      formatPriority: formatPriority ?? this.formatPriority,
      sessionLimit: sessionLimit ?? this.sessionLimit,
      abTestEnabled: abTestEnabled ?? this.abTestEnabled,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdPlacement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AdPlacement(id: $id, name: $name, location: $screenLocation)';
  }
}

/// Represents different ad formats supported by the app.
enum AdFormat {
  banner,
  interstitial,
  native,
  rewardedVideo;

  /// Converts the enum to a string representation
  String get value {
    switch (this) {
      case AdFormat.banner:
        return 'banner';
      case AdFormat.interstitial:
        return 'interstitial';
      case AdFormat.native:
        return 'native';
      case AdFormat.rewardedVideo:
        return 'rewarded_video';
    }
  }

  /// Creates an AdFormat from a string value
  static AdFormat fromString(String value) {
    switch (value.toLowerCase()) {
      case 'banner':
        return AdFormat.banner;
      case 'interstitial':
        return AdFormat.interstitial;
      case 'native':
        return AdFormat.native;
      case 'rewarded_video':
      case 'rewarded':
        return AdFormat.rewardedVideo;
      default:
        return AdFormat.banner;
    }
  }

  /// Gets the display name for the ad format
  String get displayName {
    switch (this) {
      case AdFormat.banner:
        return 'Banner Ad';
      case AdFormat.interstitial:
        return 'Interstitial Ad';
      case AdFormat.native:
        return 'Native Ad';
      case AdFormat.rewardedVideo:
        return 'Rewarded Video';
    }
  }
}

/// Represents the state of an ad.
enum AdState {
  idle,
  loading,
  loaded,
  shown,
  clicked,
  dismissed,
  failed;

  /// Gets the display name for the ad state
  String get displayName {
    switch (this) {
      case AdState.idle:
        return 'Idle';
      case AdState.loading:
        return 'Loading';
      case AdState.loaded:
        return 'Loaded';
      case AdState.shown:
        return 'Shown';
      case AdState.clicked:
        return 'Clicked';
      case AdState.dismissed:
        return 'Dismissed';
      case AdState.failed:
        return 'Failed';
    }
  }
}

/// Represents an individual ad instance.
class AdInstance {
  final String id;
  final String placementId;
  final AdFormat format;
  final AdState state;
  final DateTime? loadedAt;
  final DateTime? shownAt;
  final DateTime? clickedAt;
  final DateTime? dismissedAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const AdInstance({
    required this.id,
    required this.placementId,
    required this.format,
    required this.state,
    this.loadedAt,
    this.shownAt,
    this.clickedAt,
    this.dismissedAt,
    this.errorMessage,
    this.metadata = const {},
  });

  /// Creates an AdInstance from JSON
  factory AdInstance.fromJson(Map<String, dynamic> json) {
    return AdInstance(
      id: json['id'] ?? '',
      placementId: json['placementId'] ?? '',
      format: AdFormat.fromString(json['format'] ?? 'banner'),
      state: AdState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => AdState.idle,
      ),
      loadedAt: json['loadedAt'] != null ? DateTime.parse(json['loadedAt']) : null,
      shownAt: json['shownAt'] != null ? DateTime.parse(json['shownAt']) : null,
      clickedAt: json['clickedAt'] != null ? DateTime.parse(json['clickedAt']) : null,
      dismissedAt: json['dismissedAt'] != null ? DateTime.parse(json['dismissedAt']) : null,
      errorMessage: json['errorMessage'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converts the AdInstance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placementId': placementId,
      'format': format.value,
      'state': state.name,
      'loadedAt': loadedAt?.toIso8601String(),
      'shownAt': shownAt?.toIso8601String(),
      'clickedAt': clickedAt?.toIso8601String(),
      'dismissedAt': dismissedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  /// Creates a copy of the AdInstance with optional parameter overrides
  AdInstance copyWith({
    String? id,
    String? placementId,
    AdFormat? format,
    AdState? state,
    DateTime? loadedAt,
    DateTime? shownAt,
    DateTime? clickedAt,
    DateTime? dismissedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return AdInstance(
      id: id ?? this.id,
      placementId: placementId ?? this.placementId,
      format: format ?? this.format,
      state: state ?? this.state,
      loadedAt: loadedAt ?? this.loadedAt,
      shownAt: shownAt ?? this.shownAt,
      clickedAt: clickedAt ?? this.clickedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Checks if the ad is in a displayable state
  bool get isDisplayable => state == AdState.loaded;

  /// Checks if the ad has been interacted with
  bool get hasBeenInteractedWith => clickedAt != null || dismissedAt != null;

  /// Gets the duration the ad was displayed (if it was shown)
  Duration? get displayDuration {
    if (shownAt == null) return null;
    final endTime = dismissedAt ?? clickedAt ?? DateTime.now();
    return endTime.difference(shownAt!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdInstance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AdInstance(id: $id, placement: $placementId, format: ${format.value}, state: ${state.name})';
  }
}
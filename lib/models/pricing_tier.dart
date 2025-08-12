/// Enum representing different pricing tiers
enum PricingTier {
  free,
  premium,
}

/// Model representing feature limits for each pricing tier
class PricingTierLimits {
  final PricingTier tier;
  final int maxNotes;
  final int maxVoiceNotesPerMonth;
  final int maxExportsPerMonth;
  final int maxSyncDevices;
  final bool hasCloudSync;
  final bool hasAdvancedDrawingTools;
  final bool isAdFree;
  final bool hasCustomThemes;
  final bool hasUnlimitedBackups;
  final bool hasOcrTextRecognition;
  final int maxAttachmentsPerNote;
  final int maxAttachmentSizeMB;

  const PricingTierLimits({
    required this.tier,
    required this.maxNotes,
    required this.maxVoiceNotesPerMonth,
    required this.maxExportsPerMonth,
    required this.maxSyncDevices,
    required this.hasCloudSync,
    required this.hasAdvancedDrawingTools,
    required this.isAdFree,
    required this.hasCustomThemes,
    required this.hasUnlimitedBackups,
    required this.hasOcrTextRecognition,
    required this.maxAttachmentsPerNote,
    required this.maxAttachmentSizeMB,
  });

  /// Predefined limits for free tier
  static const PricingTierLimits free = PricingTierLimits(
    tier: PricingTier.free,
    maxNotes: 100,
    maxVoiceNotesPerMonth: 10,
    maxExportsPerMonth: 5,
    maxSyncDevices: 0, // No cloud sync
    hasCloudSync: false,
    hasAdvancedDrawingTools: false,
    isAdFree: false,
    hasCustomThemes: false,
    hasUnlimitedBackups: false,
    hasOcrTextRecognition: false,
    maxAttachmentsPerNote: 3,
    maxAttachmentSizeMB: 5,
  );

  /// Predefined limits for premium tier
  static const PricingTierLimits premium = PricingTierLimits(
    tier: PricingTier.premium,
    maxNotes: -1, // Unlimited
    maxVoiceNotesPerMonth: -1, // Unlimited
    maxExportsPerMonth: -1, // Unlimited
    maxSyncDevices: -1, // Unlimited
    hasCloudSync: true,
    hasAdvancedDrawingTools: true,
    isAdFree: true,
    hasCustomThemes: true,
    hasUnlimitedBackups: true,
    hasOcrTextRecognition: true,
    maxAttachmentsPerNote: -1, // Unlimited
    maxAttachmentSizeMB: 100,
  );

  /// Get limits for a specific tier
  static PricingTierLimits forTier(PricingTier tier) {
    switch (tier) {
      case PricingTier.free:
        return free;
      case PricingTier.premium:
        return premium;
    }
  }

  /// Check if a feature is unlimited (-1 indicates unlimited)
  bool isUnlimited(int value) => value == -1;

  /// Get display text for a limit value
  String getLimitDisplay(int value) {
    return isUnlimited(value) ? 'Unlimited' : value.toString();
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'maxNotes': maxNotes,
      'maxVoiceNotesPerMonth': maxVoiceNotesPerMonth,
      'maxExportsPerMonth': maxExportsPerMonth,
      'maxSyncDevices': maxSyncDevices,
      'hasCloudSync': hasCloudSync,
      'hasAdvancedDrawingTools': hasAdvancedDrawingTools,
      'isAdFree': isAdFree,
      'hasCustomThemes': hasCustomThemes,
      'hasUnlimitedBackups': hasUnlimitedBackups,
      'hasOcrTextRecognition': hasOcrTextRecognition,
      'maxAttachmentsPerNote': maxAttachmentsPerNote,
      'maxAttachmentSizeMB': maxAttachmentSizeMB,
    };
  }

  /// Create from JSON
  factory PricingTierLimits.fromJson(Map<String, dynamic> json) {
    return PricingTierLimits(
      tier: PricingTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => PricingTier.free,
      ),
      maxNotes: json['maxNotes'] ?? 0,
      maxVoiceNotesPerMonth: json['maxVoiceNotesPerMonth'] ?? 0,
      maxExportsPerMonth: json['maxExportsPerMonth'] ?? 0,
      maxSyncDevices: json['maxSyncDevices'] ?? 0,
      hasCloudSync: json['hasCloudSync'] ?? false,
      hasAdvancedDrawingTools: json['hasAdvancedDrawingTools'] ?? false,
      isAdFree: json['isAdFree'] ?? false,
      hasCustomThemes: json['hasCustomThemes'] ?? false,
      hasUnlimitedBackups: json['hasUnlimitedBackups'] ?? false,
      hasOcrTextRecognition: json['hasOcrTextRecognition'] ?? false,
      maxAttachmentsPerNote: json['maxAttachmentsPerNote'] ?? 0,
      maxAttachmentSizeMB: json['maxAttachmentSizeMB'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'PricingTierLimits(tier: $tier, maxNotes: ${getLimitDisplay(maxNotes)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PricingTierLimits &&
        other.tier == tier &&
        other.maxNotes == maxNotes &&
        other.maxVoiceNotesPerMonth == maxVoiceNotesPerMonth &&
        other.maxExportsPerMonth == maxExportsPerMonth &&
        other.maxSyncDevices == maxSyncDevices &&
        other.hasCloudSync == hasCloudSync &&
        other.hasAdvancedDrawingTools == hasAdvancedDrawingTools &&
        other.isAdFree == isAdFree &&
        other.hasCustomThemes == hasCustomThemes &&
        other.hasUnlimitedBackups == hasUnlimitedBackups &&
        other.hasOcrTextRecognition == hasOcrTextRecognition &&
        other.maxAttachmentsPerNote == maxAttachmentsPerNote &&
        other.maxAttachmentSizeMB == maxAttachmentSizeMB;
  }

  @override
  int get hashCode {
    return Object.hash(
      tier,
      maxNotes,
      maxVoiceNotesPerMonth,
      maxExportsPerMonth,
      maxSyncDevices,
      hasCloudSync,
      hasAdvancedDrawingTools,
      isAdFree,
      hasCustomThemes,
      hasUnlimitedBackups,
      hasOcrTextRecognition,
      maxAttachmentsPerNote,
      maxAttachmentSizeMB,
    );
  }
}
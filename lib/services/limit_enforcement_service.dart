import 'dart:async';
import 'package:flutter/material.dart';

import '../models/pricing_tier.dart';
import '../models/user_entitlements.dart';
import '../services/pricing_tier_service.dart';

/// Result of a limit check operation
class LimitCheckResult {
  final bool allowed;
  final String? limitMessage;
  final String? upgradeMessage;
  final VoidCallback? upgradeAction;

  const LimitCheckResult({
    required this.allowed,
    this.limitMessage,
    this.upgradeMessage,
    this.upgradeAction,
  });

  /// Create a result that allows the action
  factory LimitCheckResult.allowed() {
    return const LimitCheckResult(allowed: true);
  }

  /// Create a result that blocks the action
  factory LimitCheckResult.blocked({
    required String limitMessage,
    String? upgradeMessage,
    VoidCallback? upgradeAction,
  }) {
    return LimitCheckResult(
      allowed: false,
      limitMessage: limitMessage,
      upgradeMessage: upgradeMessage,
      upgradeAction: upgradeAction,
    );
  }
}

/// Service for enforcing feature limits based on pricing tiers
class LimitEnforcementService {
  final PricingTierService _pricingService;
  
  LimitEnforcementService(this._pricingService);

  /// Check if user can create a new note
  Future<LimitCheckResult> canCreateNote(int currentNoteCount) async {
    final limits = _pricingService.currentLimits;
    
    if (limits.isUnlimited(limits.maxNotes)) {
      return LimitCheckResult.allowed();
    }
    
    if (currentNoteCount >= limits.maxNotes) {
      _pricingService.trackFreeLimitReached('note_creation');
      
      final messaging = _pricingService.getUpgradeMessaging('note_limit');
      return LimitCheckResult.blocked(
        limitMessage: 'You\'ve reached the ${limits.maxNotes} note limit for free users.',
        upgradeMessage: messaging['message'],
        upgradeAction: () => _pricingService.trackUpgradeInitiated('note_limit', 'limit_reached'),
      );
    }
    
    return LimitCheckResult.allowed();
  }

  /// Check if user can record a voice note
  Future<LimitCheckResult> canRecordVoiceNote() async {
    final limits = _pricingService.currentLimits;
    
    if (limits.isUnlimited(limits.maxVoiceNotesPerMonth)) {
      return LimitCheckResult.allowed();
    }
    
    if (_pricingService.hasReachedVoiceNoteLimit()) {
      _pricingService.trackFreeLimitReached('voice_note');
      
      final messaging = _pricingService.getUpgradeMessaging('voice_note_limit');
      return LimitCheckResult.blocked(
        limitMessage: 'You\'ve used all ${limits.maxVoiceNotesPerMonth} voice notes this month.',
        upgradeMessage: messaging['message'],
        upgradeAction: () => _pricingService.trackUpgradeInitiated('voice_note_limit', 'limit_reached'),
      );
    }
    
    return LimitCheckResult.allowed();
  }

  /// Check if user can export notes
  Future<LimitCheckResult> canExportNotes() async {
    final limits = _pricingService.currentLimits;
    
    if (limits.isUnlimited(limits.maxExportsPerMonth)) {
      return LimitCheckResult.allowed();
    }
    
    if (_pricingService.hasReachedExportLimit()) {
      _pricingService.trackFreeLimitReached('export');
      
      final messaging = _pricingService.getUpgradeMessaging('export_limit');
      return LimitCheckResult.blocked(
        limitMessage: 'You\'ve used all ${limits.maxExportsPerMonth} exports this month.',
        upgradeMessage: messaging['message'],
        upgradeAction: () => _pricingService.trackUpgradeInitiated('export_limit', 'limit_reached'),
      );
    }
    
    return LimitCheckResult.allowed();
  }

  /// Check if user can access cloud sync
  LimitCheckResult canAccessCloudSync() {
    final limits = _pricingService.currentLimits;
    
    if (limits.hasCloudSync) {
      return LimitCheckResult.allowed();
    }
    
    _pricingService.trackFreeLimitReached('cloud_sync');
    
    final messaging = _pricingService.getUpgradeMessaging('cloud_sync');
    return LimitCheckResult.blocked(
      limitMessage: 'Cloud sync is a Premium feature.',
      upgradeMessage: messaging['message'],
      upgradeAction: () => _pricingService.trackUpgradeInitiated('cloud_sync', 'feature_gate'),
    );
  }

  /// Check if user can access advanced drawing tools
  LimitCheckResult canAccessAdvancedDrawingTools() {
    final limits = _pricingService.currentLimits;
    
    if (limits.hasAdvancedDrawingTools) {
      return LimitCheckResult.allowed();
    }
    
    _pricingService.trackFreeLimitReached('advanced_drawing');
    
    return LimitCheckResult.blocked(
      limitMessage: 'Advanced drawing tools are a Premium feature.',
      upgradeMessage: 'Upgrade to Premium for professional drawing tools with layers and effects!',
      upgradeAction: () => _pricingService.trackUpgradeInitiated('advanced_drawing', 'feature_gate'),
    );
  }

  /// Check if user can access custom themes
  LimitCheckResult canAccessCustomThemes() {
    final limits = _pricingService.currentLimits;
    
    if (limits.hasCustomThemes) {
      return LimitCheckResult.allowed();
    }
    
    _pricingService.trackFreeLimitReached('custom_themes');
    
    final messaging = _pricingService.getUpgradeMessaging('custom_themes');
    return LimitCheckResult.blocked(
      limitMessage: 'Custom themes are a Premium feature.',
      upgradeMessage: messaging['message'],
      upgradeAction: () => _pricingService.trackUpgradeInitiated('custom_themes', 'feature_gate'),
    );
  }

  /// Check if user can access OCR text recognition
  LimitCheckResult canAccessOCR() {
    final limits = _pricingService.currentLimits;
    
    if (limits.hasOcrTextRecognition) {
      return LimitCheckResult.allowed();
    }
    
    _pricingService.trackFreeLimitReached('ocr');
    
    return LimitCheckResult.blocked(
      limitMessage: 'OCR text recognition is a Premium feature.',
      upgradeMessage: 'Upgrade to Premium to extract text from images automatically!',
      upgradeAction: () => _pricingService.trackUpgradeInitiated('ocr', 'feature_gate'),
    );
  }

  /// Check if user can add more attachments to a note
  LimitCheckResult canAddAttachment(int currentAttachmentCount) {
    final limits = _pricingService.currentLimits;
    
    if (limits.isUnlimited(limits.maxAttachmentsPerNote)) {
      return LimitCheckResult.allowed();
    }
    
    if (currentAttachmentCount >= limits.maxAttachmentsPerNote) {
      _pricingService.trackFreeLimitReached('attachments');
      
      return LimitCheckResult.blocked(
        limitMessage: 'You can only add ${limits.maxAttachmentsPerNote} attachments per note on the free plan.',
        upgradeMessage: 'Upgrade to Premium for unlimited attachments per note!',
        upgradeAction: () => _pricingService.trackUpgradeInitiated('attachments', 'limit_reached'),
      );
    }
    
    return LimitCheckResult.allowed();
  }

  /// Check if attachment size is within limits
  LimitCheckResult canAddAttachmentSize(double fileSizeMB) {
    final limits = _pricingService.currentLimits;
    
    if (fileSizeMB <= limits.maxAttachmentSizeMB) {
      return LimitCheckResult.allowed();
    }
    
    _pricingService.trackFreeLimitReached('attachment_size');
    
    return LimitCheckResult.blocked(
      limitMessage: 'File size exceeds ${limits.maxAttachmentSizeMB}MB limit for free users.',
      upgradeMessage: 'Upgrade to Premium for larger file attachments (up to ${PricingTierLimits.premium.maxAttachmentSizeMB}MB)!',
      upgradeAction: () => _pricingService.trackUpgradeInitiated('attachment_size', 'limit_reached'),
    );
  }

  /// Check if user can access unlimited backups
  LimitCheckResult canAccessUnlimitedBackups() {
    final limits = _pricingService.currentLimits;
    
    if (limits.hasUnlimitedBackups) {
      return LimitCheckResult.allowed();
    }
    
    _pricingService.trackFreeLimitReached('unlimited_backups');
    
    return LimitCheckResult.blocked(
      limitMessage: 'Unlimited backups are a Premium feature.',
      upgradeMessage: 'Upgrade to Premium for unlimited cloud backups and restore points!',
      upgradeAction: () => _pricingService.trackUpgradeInitiated('unlimited_backups', 'feature_gate'),
    );
  }

  /// Check if ads should be shown
  bool shouldShowAds() {
    return !_pricingService.currentLimits.isAdFree;
  }

  /// Get usage summary for display in UI
  Map<String, dynamic> getUsageSummary() {
    final entitlements = _pricingService.currentEntitlements;
    final limits = _pricingService.currentLimits;
    
    return {
      'tier': entitlements.tier.name,
      'isPremium': entitlements.isPremium,
      'voiceNotes': {
        'used': entitlements.currentMonthVoiceNotes,
        'limit': limits.maxVoiceNotesPerMonth,
        'unlimited': limits.isUnlimited(limits.maxVoiceNotesPerMonth),
        'remaining': _pricingService.getRemainingVoiceNotes(),
      },
      'exports': {
        'used': entitlements.currentMonthExports,
        'limit': limits.maxExportsPerMonth,
        'unlimited': limits.isUnlimited(limits.maxExportsPerMonth),
        'remaining': _pricingService.getRemainingExports(),
      },
      'features': {
        'cloudSync': limits.hasCloudSync,
        'advancedDrawing': limits.hasAdvancedDrawingTools,
        'customThemes': limits.hasCustomThemes,
        'adFree': limits.isAdFree,
        'unlimitedBackups': limits.hasUnlimitedBackups,
        'ocr': limits.hasOcrTextRecognition,
      },
      'trial': {
        'isInTrial': entitlements.isInTrial,
        'daysRemaining': entitlements.trialDaysRemaining,
        'canStartTrial': entitlements.canStartTrial,
      },
    };
  }

  /// Get a user-friendly description of current limits
  List<String> getCurrentLimitDescriptions() {
    final limits = _pricingService.currentLimits;
    final descriptions = <String>[];
    
    if (limits.tier == PricingTier.free) {
      descriptions.add('📝 Up to ${limits.maxNotes} notes');
      descriptions.add('🎤 ${limits.maxVoiceNotesPerMonth} voice notes per month');
      descriptions.add('💾 ${limits.maxExportsPerMonth} exports per month');
      descriptions.add('📎 Up to ${limits.maxAttachmentsPerNote} attachments per note');
      descriptions.add('📁 Files up to ${limits.maxAttachmentSizeMB}MB');
      descriptions.add('📱 Local storage only');
      descriptions.add('🎨 Standard themes only');
      descriptions.add('📢 Includes ads');
    } else {
      descriptions.add('📝 Unlimited notes');
      descriptions.add('🎤 Unlimited voice notes');
      descriptions.add('💾 Unlimited exports');
      descriptions.add('📎 Unlimited attachments');
      descriptions.add('📁 Files up to ${limits.maxAttachmentSizeMB}MB');
      descriptions.add('☁️ Cloud sync across devices');
      descriptions.add('🎨 Custom themes & advanced drawing');
      descriptions.add('🚫 Ad-free experience');
      descriptions.add('🔍 OCR text recognition');
    }
    
    return descriptions;
  }

  /// Get premium feature highlights for upgrade prompts
  List<String> getPremiumFeatureHighlights() {
    return [
      '🚀 Unlimited everything - notes, voice recordings, exports',
      '☁️ Sync across all your devices seamlessly',
      '🎨 Advanced drawing tools with layers and effects',
      '🔍 OCR text recognition from images',
      '🎭 Custom themes and personalization',
      '🚫 Ad-free, distraction-free experience',
      '💾 Unlimited cloud backups and restore points',
      '📁 Larger file attachments (up to 100MB)',
    ];
  }
}
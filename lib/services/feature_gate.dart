import 'package:flutter/material.dart';
import '../services/monetization/monetization_service.dart';
import '../widgets/feature_blocked_dialog.dart';
import '../constants/product_ids.dart';

/// Helper service for checking feature availability and showing upgrade prompts
class FeatureGate {
  static final MonetizationService _monetization = MonetizationService();

  /// Check if user can create a note, show blocking dialog if not
  static Future<bool> checkCreateNote(BuildContext context) async {
    final canUse = await _monetization.canUseFeature('create_note');
    
    if (!canUse) {
      await _monetization.trackFeatureBlocked('create_note');
      
      final result = await FeatureBlockedDialog.show(
        context,
        featureName: 'note creation',
        description: 'Create unlimited notes with premium access.',
        currentLimit: '${ProductIds.freeNotesLimit} notes maximum',
      );
      
      return result ?? false;
    }
    
    return true;
  }

  /// Check if user can create a voice note, show blocking dialog if not
  static Future<bool> checkVoiceNote(BuildContext context) async {
    final canUse = await _monetization.canUseFeature('voice_note');
    
    if (!canUse) {
      await _monetization.trackFeatureBlocked('voice_note');
      
      final result = await FeatureBlockedDialog.show(
        context,
        featureName: 'voice notes',
        description: 'Record unlimited voice notes with premium access.',
        currentLimit: '${ProductIds.freeVoiceNotesLimit} per month',
      );
      
      return result ?? false;
    }
    
    return true;
  }

  /// Check if user can add attachments, show blocking dialog if not
  static Future<bool> checkAddAttachment(BuildContext context) async {
    final canUse = await _monetization.canUseFeature('add_attachment');
    
    if (!canUse) {
      await _monetization.trackFeatureBlocked('add_attachment');
      
      final result = await FeatureBlockedDialog.show(
        context,
        featureName: 'attachments',
        description: 'Add unlimited photos and files with premium access.',
        currentLimit: '${ProductIds.freeAttachmentsLimit} attachments maximum',
      );
      
      return result ?? false;
    }
    
    return true;
  }

  /// Check if user can use cloud sync, show blocking dialog if not
  static Future<bool> checkCloudSync(BuildContext context) async {
    final canUse = await _monetization.canUseFeature('cloud_sync');
    
    if (!canUse) {
      await _monetization.trackFeatureBlocked('cloud_sync');
      
      final result = await FeatureBlockedDialog.show(
        context,
        featureName: 'cloud sync',
        description: 'Sync your notes across all devices with premium access.',
        currentLimit: 'Premium feature only',
      );
      
      return result ?? false;
    }
    
    return true;
  }

  /// Check if user can use advanced drawing tools, show blocking dialog if not
  static Future<bool> checkAdvancedDrawing(BuildContext context) async {
    final canUse = await _monetization.canUseFeature('advanced_drawing');
    
    if (!canUse) {
      await _monetization.trackFeatureBlocked('advanced_drawing');
      
      final result = await FeatureBlockedDialog.show(
        context,
        featureName: 'advanced drawing',
        description: 'Access professional drawing tools and layers with premium.',
        currentLimit: 'Premium feature only',
      );
      
      return result ?? false;
    }
    
    return true;
  }

  /// Check if user can use OCR, show blocking dialog if not
  static Future<bool> checkOCR(BuildContext context) async {
    final canUse = await _monetization.canUseFeature('ocr');
    
    if (!canUse) {
      await _monetization.trackFeatureBlocked('ocr');
      
      final result = await FeatureBlockedDialog.show(
        context,
        featureName: 'text recognition (OCR)',
        description: 'Extract text from images with premium access.',
        currentLimit: 'Premium feature only',
      );
      
      return result ?? false;
    }
    
    return true;
  }

  /// Check if user can export in premium formats, show blocking dialog if not
  static Future<bool> checkPremiumExport(BuildContext context) async {
    final canUse = await _monetization.canUseFeature('export_formats');
    
    if (!canUse) {
      await _monetization.trackFeatureBlocked('export_formats');
      
      final result = await FeatureBlockedDialog.show(
        context,
        featureName: 'premium export formats',
        description: 'Export to PDF, Word, and more formats with premium access.',
        currentLimit: 'Text export only',
      );
      
      return result ?? false;
    }
    
    return true;
  }

  /// Show a general premium upsell dialog
  static Future<bool> showUpgradePrompt(
    BuildContext context, {
    String title = 'Upgrade to Premium',
    String description = 'Unlock all features and remove limits.',
  }) async {
    final result = await FeatureBlockedDialog.show(
      context,
      featureName: 'premium features',
      description: description,
      currentLimit: 'Free tier',
    );
    
    return result ?? false;
  }

  /// Check premium status and return immediately for premium users
  static Future<bool> isPremiumUser() async {
    return _monetization.isPremiumUser;
  }

  /// Track feature usage for analytics
  static Future<void> trackFeatureUsage(String featureName) async {
    await _monetization.incrementNotesCount(); // This would be more specific in real implementation
  }
}
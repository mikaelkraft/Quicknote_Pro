import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/entitlements/entitlement_service.dart';
import '../../core/app_export.dart';

/// Dialog that shows upsell messaging for premium features
class UpsellDialog extends StatelessWidget {
  final PremiumFeature feature;
  final String? title;
  final String? message;
  final VoidCallback onUpgrade;
  final VoidCallback? onCancel;

  const UpsellDialog({
    Key? key,
    required this.feature,
    this.title,
    this.message,
    required this.onUpgrade,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Feature icon with gradient background
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                gradient: _getFeatureGradient(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  _getFeatureIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            
            SizedBox(height: 3.h),
            
            // Title
            Text(
              title ?? 'Unlock ${feature.displayName}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 2.h),
            
            // Description
            Text(
              message ?? feature.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 1.h),
            
            // Benefits list
            ..._buildFeatureBenefits(context),
            
            SizedBox(height: 4.h),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 3.w),
                
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 18),
                        SizedBox(width: 1.w),
                        Text(
                          'Upgrade Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureBenefits(BuildContext context) {
    final benefits = _getFeatureBenefits();
    if (benefits.isEmpty) return [];

    return [
      SizedBox(height: 2.h),
      ...benefits.map((benefit) => Padding(
        padding: EdgeInsets.only(bottom: 1.h),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                benefit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    ];
  }

  IconData _getFeatureIcon() {
    switch (feature) {
      case PremiumFeature.unlimitedVoiceNotes:
      case PremiumFeature.voiceTranscription:
      case PremiumFeature.longerRecordings:
      case PremiumFeature.backgroundRecording:
        return Icons.mic;
      case PremiumFeature.advancedDrawingTools:
      case PremiumFeature.layersSupport:
        return Icons.brush;
      case PremiumFeature.exportFormats:
        return Icons.file_download;
      case PremiumFeature.cloudSync:
        return Icons.cloud_sync;
      case PremiumFeature.adFree:
        return Icons.block;
      case PremiumFeature.prioritySupport:
        return Icons.support_agent;
    }
  }

  LinearGradient _getFeatureGradient() {
    switch (feature) {
      case PremiumFeature.unlimitedVoiceNotes:
      case PremiumFeature.voiceTranscription:
      case PremiumFeature.longerRecordings:
      case PremiumFeature.backgroundRecording:
        return LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PremiumFeature.advancedDrawingTools:
      case PremiumFeature.layersSupport:
        return LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF67E8F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PremiumFeature.exportFormats:
        return LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PremiumFeature.cloudSync:
        return LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PremiumFeature.adFree:
        return LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PremiumFeature.prioritySupport:
        return LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  List<String> _getFeatureBenefits() {
    switch (feature) {
      case PremiumFeature.unlimitedVoiceNotes:
        return [
          'Record unlimited voice memos',
          'No monthly limits or restrictions',
          'Perfect for meetings and lectures',
        ];
      case PremiumFeature.voiceTranscription:
        return [
          'Automatic speech-to-text conversion',
          'Search through your voice notes',
          'Edit and annotate transcripts',
        ];
      case PremiumFeature.longerRecordings:
        return [
          'Record up to 1 hour per session',
          'Perfect for long meetings',
          'High-quality audio preservation',
        ];
      case PremiumFeature.backgroundRecording:
        return [
          'Continue recording when app is minimized',
          'Multitask while recording',
          'Never miss important moments',
        ];
      case PremiumFeature.advancedDrawingTools:
        return [
          'Professional drawing brushes',
          'Pressure sensitivity support',
          'Custom brush creation',
        ];
      case PremiumFeature.layersSupport:
        return [
          'Work with multiple drawing layers',
          'Non-destructive editing',
          'Professional illustration workflow',
        ];
      case PremiumFeature.exportFormats:
        return [
          'Export to PDF, Word, and more',
          'High-resolution image exports',
          'Batch export multiple notes',
        ];
      case PremiumFeature.cloudSync:
        return [
          'Sync across all your devices',
          'Automatic backup and restore',
          'Access notes anywhere',
        ];
      case PremiumFeature.adFree:
        return [
          'Clean, distraction-free interface',
          'No interruptions while working',
          'Better focus and productivity',
        ];
      case PremiumFeature.prioritySupport:
        return [
          'Faster response times',
          'Direct access to support team',
          'Priority bug fixes and features',
        ];
    }
  }
}
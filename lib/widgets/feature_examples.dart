import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Example widget showing how to implement feature gating and contextual upsells.
/// This demonstrates the pattern that should be used throughout the app.
class FeatureGatedVoiceNote extends StatefulWidget {
  final Function(String) onTranscriptionComplete;

  const FeatureGatedVoiceNote({
    Key? key,
    required this.onTranscriptionComplete,
  }) : super(key: key);

  @override
  State<FeatureGatedVoiceNote> createState() => _FeatureGatedVoiceNoteState();
}

class _FeatureGatedVoiceNoteState extends State<FeatureGatedVoiceNote> {
  int _voiceNotesThisMonth = 8; // Mock: get from user data
  bool _showUpsell = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final bool canRecord = FeatureGate.canRecordVoiceNote(
          _voiceNotesThisMonth,
          premiumService.isPremium,
        );

        if (!canRecord && !_showUpsell) {
          // Show the limit reached message with upsell option
          return _buildLimitReachedWidget(premiumService);
        }

        if (_showUpsell) {
          return _buildUpsellWidget();
        }

        return _buildVoiceNoteInterface(premiumService);
      },
    );
  }

  Widget _buildLimitReachedWidget(PremiumService premiumService) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_off,
            size: 48,
            color: Colors.orange.shade700,
          ),
          SizedBox(height: 2.h),
          Text(
            'Voice Note Limit Reached',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'You\'ve used ${FeatureGate.maxFreeVoiceNotes} of ${FeatureGate.maxFreeVoiceNotes} free voice notes this month.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showUpsell = false),
                  child: const Text('Maybe Later'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showUpsell = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Upgrade Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpsellWidget() {
    return UpsellWidgets.voiceNotes(
      onDismiss: () => setState(() => _showUpsell = false),
    );
  }

  Widget _buildVoiceNoteInterface(PremiumService premiumService) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 2.w),
              Text(
                'Voice Note',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!premiumService.isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_voiceNotesThisMonth}/${FeatureGate.maxFreeVoiceNotes}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Recording interface
          Container(
            height: 15.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Tap to record',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Feature availability indicators
          _buildFeatureIndicators(premiumService),
          
          SizedBox(height: 2.h),
          
          ElevatedButton.icon(
            onPressed: () => _startRecording(),
            icon: const Icon(Icons.mic),
            label: const Text('Start Recording'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIndicators(PremiumService premiumService) {
    final features = [
      {
        'name': 'Transcription',
        'available': FeatureGate.canTranscribeVoiceNote(premiumService.isPremium),
        'icon': Icons.transcribe,
      },
      {
        'name': 'Background Recording',
        'available': FeatureGate.canUseBackgroundRecording(premiumService.isPremium),
        'icon': Icons.record_voice_over,
      },
      {
        'name': 'Long Recordings',
        'available': premiumService.isPremium,
        'icon': Icons.schedule,
      },
    ];

    return Column(
      children: features.map((feature) {
        final bool available = feature['available'] as bool;
        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Row(
            children: [
              Icon(
                feature['icon'] as IconData,
                size: 16,
                color: available 
                  ? Colors.green 
                  : Theme.of(context).disabledColor,
              ),
              SizedBox(width: 2.w),
              Text(
                feature['name'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: available 
                    ? Theme.of(context).textTheme.bodySmall?.color
                    : Theme.of(context).disabledColor,
                ),
              ),
              const Spacer(),
              if (!available)
                InkWell(
                  onTap: () => _showFeatureUpsell(feature['name'] as String),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PRO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _startRecording() {
    // Check recording length limit
    final premiumService = context.read<PremiumService>();
    final maxLength = FeatureGate.getMaxRecordingLength(premiumService.isPremium);
    
    // Show recording length notice for free users
    if (!premiumService.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Free recordings limited to ${maxLength.inMinutes} minutes'),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.premiumUpgrade),
          ),
        ),
      );
    }

    // Start actual recording logic here
    widget.onTranscriptionComplete('Mock transcription: Hello world!');
  }

  void _showFeatureUpsell(String featureName) {
    String title, description;
    IconData icon;

    switch (featureName) {
      case 'Transcription':
        title = 'AI Transcription';
        description = 'Automatically convert your voice recordings to text with advanced AI.';
        icon = Icons.transcribe;
        break;
      case 'Background Recording':
        title = 'Background Recording';
        description = 'Record voice notes even when the app is in the background.';
        icon = Icons.record_voice_over;
        break;
      case 'Long Recordings':
        title = 'Extended Recordings';
        description = 'Record voice notes up to 1 hour long with premium.';
        icon = Icons.schedule;
        break;
      default:
        return;
    }

    showFeatureUpsellDialog(
      context,
      featureName: featureName.toLowerCase(),
      title: title,
      description: description,
      icon: icon,
    );
  }
}

/// Example widget showing how to gate drawing features
class FeatureGatedDrawingCanvas extends StatelessWidget {
  final int requestedLayers;

  const FeatureGatedDrawingCanvas({
    Key? key,
    required this.requestedLayers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final bool canUseLayers = FeatureGate.canUseLayers(
          requestedLayers,
          premiumService.isPremium,
        );

        if (!canUseLayers) {
          return PremiumFeatureBanner(
            message: 'Unlock ${FeatureGate.getMaxLayers(true)} layers with Premium',
            onTap: () => showFeatureUpsellDialog(
              context,
              featureName: 'drawing tools',
              title: 'Advanced Drawing Tools',
              description: 'Get access to multiple layers, advanced brushes, and professional drawing tools.',
              icon: Icons.layers,
            ),
          );
        }

        return _buildDrawingCanvas(premiumService);
      },
    );
  }

  Widget _buildDrawingCanvas(PremiumService premiumService) {
    final maxLayers = FeatureGate.getMaxLayers(premiumService.isPremium);
    
    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.layers),
                SizedBox(width: 2.w),
                Text('Drawing Canvas'),
                const Spacer(),
                if (!premiumService.isPremium)
                  Text(
                    '$requestedLayers/$maxLayers layers',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              height: 30.h,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Drawing Canvas Area'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onTranscriptionComplete;

  const VoiceInputWidget({
    Key? key,
    required this.onTranscriptionComplete,
  }) : super(key: key);

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasPermission = false;
  int _recordingDuration = 0;
  String _recordingPath = '';
  late AnimationController _waveformController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _checkPermissions();
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) {
      setState(() => _hasPermission = true);
      return;
    }

    final status = await Permission.microphone.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
    } else {
      final result = await Permission.microphone.request();
      setState(() => _hasPermission = result.isGranted);
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      _showPermissionDialog();
      return;
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        if (kIsWeb) {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.wav),
            path: 'recording_${DateTime.now().millisecondsSinceEpoch}.wav',
          );
        } else {
          await _audioRecorder.start(
            const RecordConfig(),
            path: 'recording_${DateTime.now().millisecondsSinceEpoch}.wav',
          );
        }

        setState(() => _isRecording = true);
        _waveformController.repeat();
        _pulseController.repeat();
        _startTimer();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path ?? '';
        _recordingDuration = 0;
      });

      _waveformController.stop();
      _pulseController.stop();

      // Simulate transcription for demo purposes
      _simulateTranscription();
    } catch (e) {
      _showErrorSnackBar('Failed to stop recording');
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;

      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecording) {
        setState(() => _recordingDuration++);

        // Check entitlement for longer recordings
        final entitlementService = context.read<EntitlementService>();
        if (entitlementService.hasReachedLimit(PremiumFeature.longerRecordings, _recordingDuration)) {
          await _stopRecording();
          _showUpgradeDialog();
          return false;
        }
      }
      return _isRecording;
    });
  }

  void _simulateTranscription() {
    final entitlementService = context.read<EntitlementService>();
    
    // Check if transcription feature is available
    if (!entitlementService.hasFeature(PremiumFeature.voiceNoteTranscription)) {
      _showTranscriptionUpgradeDialog();
      return;
    }
    
    // Simulate real transcription with realistic delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      final transcriptions = [
        "This is a sample transcription of your voice note.",
        "Meeting notes: Discuss project timeline and deliverables.",
        "Remember to buy groceries and pick up dry cleaning.",
        "Ideas for the presentation: focus on user experience and data insights.",
        "Call mom about dinner plans this weekend.",
      ];
      final randomText =
          transcriptions[DateTime.now().millisecond % transcriptions.length];
      widget.onTranscriptionComplete(randomText);
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Microphone Permission Required',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Please grant microphone permission to use voice input feature.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPermissions();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    final entitlementService = context.read<EntitlementService>();
    final limit = entitlementService.getFeatureLimit(PremiumFeature.longerRecordings);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Recording Limit Reached',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'workspace_premium',
              size: 12.w,
              color: Colors.amber,
            ),
            SizedBox(height: 2.h),
            Text(
              'Free users are limited to ${limit ?? 60}-second voice recordings. Upgrade to Premium for unlimited recording time.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Upgrade Now', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showTranscriptionUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Premium Feature',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'workspace_premium',
              size: 12.w,
              color: Colors.amber,
            ),
            SizedBox(height: 2.h),
            Text(
              'Voice-to-text transcription is a premium feature. Upgrade to automatically convert your voice recordings to text.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Upgrade Now', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12.h,
      right: 4.w,
      child: Column(
        children: [
          if (_isRecording) _buildRecordingIndicator(),
          SizedBox(height: 2.h),
          _buildVoiceButton(),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _waveformController,
            builder: (context, child) {
              return Row(
                children: List.generate(4, (index) {
                  final delay = index * 0.2;
                  final animation = Tween<double>(begin: 0.3, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _waveformController,
                      curve:
                          Interval(delay, delay + 0.4, curve: Curves.easeInOut),
                    ),
                  );
                  return Container(
                    width: 1.w,
                    height: 4.h * animation.value,
                    margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            },
          ),
          SizedBox(width: 3.w),
          Text(
            '${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (!widget.isPremiumUser && _recordingDuration > 45) ...[
            SizedBox(width: 2.w),
            CustomIconWidget(
              iconName: 'warning',
              size: 4.w,
              color: AppTheme.getWarningColor(
                  Theme.of(context).brightness == Brightness.light),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRecording ? 1.0 + (_pulseController.value * 0.1) : 1.0,
          child: FloatingActionButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            backgroundColor: _isRecording
                ? AppTheme.lightTheme.colorScheme.error
                : AppTheme.lightTheme.primaryColor,
            child: CustomIconWidget(
              iconName: _isRecording ? 'stop' : 'mic',
              size: 6.w,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
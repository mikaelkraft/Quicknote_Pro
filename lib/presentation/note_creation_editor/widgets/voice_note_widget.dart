import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/app_export.dart';

class VoiceNoteWidget extends StatefulWidget {
  final Function(String audioPath, int durationSeconds) onAudioRecorded;
  final bool isPremiumUser;

  const VoiceNoteWidget({
    Key? key,
    required this.onAudioRecorded,
    required this.isPremiumUser,
  }) : super(key: key);

  @override
  State<VoiceNoteWidget> createState() => _VoiceNoteWidgetState();
}

class _VoiceNoteWidgetState extends State<VoiceNoteWidget>
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
      
      if (!result.isGranted) {
        _showPermissionDialog();
      }
    }
  }

  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return '${audioDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _checkPermissions();
      return;
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        final path = await _getRecordingPath();
        
        if (kIsWeb) {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.wav),
            path: path,
          );
        } else {
          // Use AAC format for mobile platforms
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );
        }

        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _recordingDuration = 0;
        });
        
        _waveformController.repeat();
        _pulseController.repeat();
        _startTimer();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() => _isRecording = false);

      _waveformController.stop();
      _pulseController.stop();

      if (_recordingPath.isNotEmpty && _recordingDuration > 0) {
        // Check if file exists
        final file = File(_recordingPath);
        if (await file.exists()) {
          widget.onAudioRecorded(_recordingPath, _recordingDuration);
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice note recorded successfully')),
            );
          }
        } else {
          _showErrorSnackBar('Recording file not found');
        }
      } else {
        _showErrorSnackBar('Recording too short or invalid');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  void _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
        _recordingPath = '';
      });

      _waveformController.stop();
      _pulseController.stop();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to cancel recording: $e');
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;

      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecording) {
        setState(() => _recordingDuration++);

        // Free tier limit check (5 minutes for free users)
        if (!widget.isPremiumUser && _recordingDuration >= 300) {
          await _stopRecording();
          _showUpgradeDialog();
          return false;
        }
        
        // Maximum recording limit (30 minutes for premium users)
        if (widget.isPremiumUser && _recordingDuration >= 1800) {
          await _stopRecording();
          _showMaxLimitDialog();
          return false;
        }
      }
      return _isRecording;
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
          'Please grant microphone permission to record voice notes.',
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
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upgrade to Premium',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'star',
              size: 12.w,
              color: AppTheme.getWarningColor(
                  Theme.of(context).brightness == Brightness.light),
            ),
            SizedBox(height: 2.h),
            Text(
              'Free users are limited to 5-minute voice notes. Upgrade to Premium for longer recordings up to 30 minutes.',
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
              // Navigate to premium upgrade screen
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showMaxLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Recording Limit Reached',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Maximum recording length is 30 minutes. Your voice note has been saved.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Record Voice Note',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 4.h),
          
          if (_isRecording) _buildRecordingIndicator(),
          
          SizedBox(height: 4.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_isRecording) ...[
                // Cancel button
                FloatingActionButton(
                  heroTag: 'cancel',
                  onPressed: _cancelRecording,
                  backgroundColor: Colors.grey[600],
                  child: CustomIconWidget(
                    iconName: 'close',
                    size: 6.w,
                    color: Colors.white,
                  ),
                ),
                
                // Stop button
                FloatingActionButton(
                  heroTag: 'stop',
                  onPressed: _stopRecording,
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                  child: CustomIconWidget(
                    iconName: 'stop',
                    size: 6.w,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                // Start recording button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return FloatingActionButton(
                      heroTag: 'record',
                      onPressed: _hasPermission ? _startRecording : _checkPermissions,
                      backgroundColor: AppTheme.lightTheme.primaryColor,
                      child: CustomIconWidget(
                        iconName: 'mic',
                        size: 6.w,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          
          SizedBox(height: 3.h),
          
          if (!_isRecording) ...[
            Text(
              widget.isPremiumUser 
                  ? 'Tap to record (up to 30 minutes)'
                  : 'Tap to record (up to 5 minutes)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (!widget.isPremiumUser) ...[
              SizedBox(height: 1.h),
              Text(
                'Upgrade to Premium for longer recordings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getWarningColor(
                      Theme.of(context).brightness == Brightness.light),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Waveform animation
          AnimatedBuilder(
            animation: _waveformController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(8, (index) {
                  final delay = index * 0.1;
                  final animation = Tween<double>(begin: 0.3, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _waveformController,
                      curve: Interval(delay, delay + 0.3, curve: Curves.easeInOut),
                    ),
                  );
                  return Container(
                    width: 1.5.w,
                    height: 6.h * animation.value,
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
          
          SizedBox(height: 2.h),
          
          // Timer
          Text(
            '${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),
          
          SizedBox(height: 1.h),
          
          // Status text
          Text(
            'Recording...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          // Warning for free users approaching limit
          if (!widget.isPremiumUser && _recordingDuration > 240) ...[
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'warning',
                  size: 4.w,
                  color: AppTheme.getWarningColor(
                      Theme.of(context).brightness == Brightness.light),
                ),
                SizedBox(width: 2.w),
                Text(
                  '${300 - _recordingDuration}s remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.getWarningColor(
                        Theme.of(context).brightness == Brightness.light),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
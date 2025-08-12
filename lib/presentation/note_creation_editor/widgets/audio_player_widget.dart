import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/attachment.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Attachment audioAttachment;
  final VoidCallback? onDelete;

  const AudioPlayerWidget({
    Key? key,
    required this.audioAttachment,
    this.onDelete,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _playPause() async {
    setState(() => _isLoading = true);

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        final file = File(widget.audioAttachment.relativePath);
        if (await file.exists()) {
          await _audioPlayer.play(DeviceFileSource(file.path));
        } else {
          _showErrorSnackBar('Audio file not found');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to play audio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stop() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to stop audio: $e');
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _showErrorSnackBar('Failed to seek: $e');
    }
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Voice Note',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete this voice note? This action cannot be undone.',
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
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and delete button
          Row(
            children: [
              CustomIconWidget(
                iconName: 'audio_file',
                size: 5.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Note',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.audioAttachment.fileSizeFormatted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                IconButton(
                  onPressed: _showDeleteConfirmation,
                  icon: CustomIconWidget(
                    iconName: 'delete',
                    size: 5.w,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),

          SizedBox(height: 2.h),

          // Progress bar
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: _totalDuration.inMilliseconds > 0
                        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                        : 0.0,
                    onChanged: (value) {
                      final position = Duration(
                        milliseconds: (value * _totalDuration.inMilliseconds).round(),
                      );
                      _seek(position);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                _totalDuration.inMilliseconds > 0
                    ? _formatDuration(_totalDuration)
                    : widget.audioAttachment.formattedDuration,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _stop,
                icon: CustomIconWidget(
                  iconName: 'stop',
                  size: 6.w,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _playPause,
                  icon: _isLoading
                      ? SizedBox(
                          width: 5.w,
                          height: 5.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : CustomIconWidget(
                          iconName: _isPlaying ? 'pause' : 'play_arrow',
                          size: 6.w,
                          color: Colors.white,
                        ),
                ),
              ),
              SizedBox(width: 4.w),
              IconButton(
                onPressed: () => _seek(_totalDuration),
                icon: CustomIconWidget(
                  iconName: 'skip_next',
                  size: 6.w,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),

          // Metadata
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'schedule',
                size: 3.w,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: 1.w),
              Text(
                'Created ${_formatDate(widget.audioAttachment.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
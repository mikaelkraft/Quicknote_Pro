import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class VoiceSearchWidget extends StatefulWidget {
  final bool isListening;
  final String transcribedText;
  final VoidCallback? onStartListening;
  final VoidCallback? onStopListening;
  final Function(String)? onTranscriptionComplete;

  const VoiceSearchWidget({
    Key? key,
    required this.isListening,
    required this.transcribedText,
    this.onStartListening,
    this.onStopListening,
    this.onTranscriptionComplete,
  }) : super(key: key);

  @override
  State<VoiceSearchWidget> createState() => _VoiceSearchWidgetState();
}

class _VoiceSearchWidgetState extends State<VoiceSearchWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(VoiceSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _startAnimations();
    } else if (!widget.isListening && oldWidget.isListening) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
    _pulseController.reset();
    _waveController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice Search',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 6.w,
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Voice Animation
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer wave circles
                  if (widget.isListening) ...[
                    _buildWaveCircle(context, 25.w, 0.1),
                    _buildWaveCircle(context, 20.w, 0.2),
                    _buildWaveCircle(context, 15.w, 0.3),
                  ],

                  // Main microphone button
                  Transform.scale(
                    scale: widget.isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: widget.isListening
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: widget.isListening
                            ? widget.onStopListening
                            : widget.onStartListening,
                        borderRadius: BorderRadius.circular(10.w),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: widget.isListening ? 'stop' : 'mic',
                            color: Colors.white,
                            size: 8.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 4.h),

          // Status Text
          Text(
            widget.isListening ? 'Listening...' : 'Tap to start voice search',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: widget.isListening
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),

          SizedBox(height: 2.h),

          // Transcribed Text
          if (widget.transcribedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transcribed:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    widget.transcribedText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onTranscriptionComplete
                          ?.call(widget.transcribedText);
                      Navigator.pop(context);
                    },
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 2.h),

          // Voice Search Tips
          if (!widget.isListening && widget.transcribedText.isEmpty)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Search Tips:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 1.h),
                  _buildVoiceTip(context, '• Speak clearly and naturally'),
                  _buildVoiceTip(
                      context, '• Try "Find my meeting notes from yesterday"'),
                  _buildVoiceTip(context, '• Say "Search for shopping list"'),
                  _buildVoiceTip(
                      context, '• Use "Show me drawings about project"'),
                ],
              ),
            ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildWaveCircle(BuildContext context, double size, double opacity) {
    return Container(
      width: size * _waveAnimation.value,
      height: size * _waveAnimation.value,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: opacity * (1 - _waveAnimation.value)),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildVoiceTip(BuildContext context, String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Text(
        tip,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

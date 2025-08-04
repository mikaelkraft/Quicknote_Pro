import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class SaveStatusIndicatorWidget extends StatefulWidget {
  final bool isSaving;
  final bool hasUnsavedChanges;
  final DateTime? lastSaved;

  const SaveStatusIndicatorWidget({
    Key? key,
    required this.isSaving,
    required this.hasUnsavedChanges,
    this.lastSaved,
  }) : super(key: key);

  @override
  State<SaveStatusIndicatorWidget> createState() =>
      _SaveStatusIndicatorWidgetState();
}

class _SaveStatusIndicatorWidgetState extends State<SaveStatusIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SaveStatusIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSaving != oldWidget.isSaving ||
        widget.hasUnsavedChanges != oldWidget.hasUnsavedChanges) {
      _animationController.forward().then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _animationController.reverse();
          }
        });
      });
    }
  }

  String _getStatusText() {
    if (widget.isSaving) {
      return 'Saving...';
    } else if (widget.hasUnsavedChanges) {
      return 'Unsaved changes';
    } else if (widget.lastSaved != null) {
      final now = DateTime.now();
      final difference = now.difference(widget.lastSaved!);

      if (difference.inMinutes < 1) {
        return 'Saved just now';
      } else if (difference.inMinutes < 60) {
        return 'Saved ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Saved ${difference.inHours}h ago';
      } else {
        return 'Saved ${difference.inDays}d ago';
      }
    }
    return 'Draft';
  }

  Color _getStatusColor() {
    if (widget.isSaving) {
      return AppTheme.lightTheme.primaryColor;
    } else if (widget.hasUnsavedChanges) {
      return AppTheme.getWarningColor(
          Theme.of(context).brightness == Brightness.light);
    } else {
      return AppTheme.getSuccessColor(
          Theme.of(context).brightness == Brightness.light);
    }
  }

  IconData _getStatusIcon() {
    if (widget.isSaving) {
      return Icons.sync;
    } else if (widget.hasUnsavedChanges) {
      return Icons.edit;
    } else {
      return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor().withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.isSaving
                    ? SizedBox(
                        width: 3.w,
                        height: 3.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_getStatusColor()),
                        ),
                      )
                    : CustomIconWidget(
                        iconName: _getStatusIcon().toString().split('.').last,
                        size: 3.w,
                        color: _getStatusColor(),
                      ),
                SizedBox(width: 2.w),
                Text(
                  _getStatusText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

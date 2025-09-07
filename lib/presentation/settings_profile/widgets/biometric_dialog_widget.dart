import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BiometricDialogWidget extends StatefulWidget {
  final String action;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BiometricDialogWidget({
    Key? key,
    required this.action,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<BiometricDialogWidget> createState() => _BiometricDialogWidgetState();
}

class _BiometricDialogWidgetState extends State<BiometricDialogWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAuthenticating = false;
  bool _authenticationFailed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _authenticateWithBiometric() async {
    setState(() {
      _isAuthenticating = true;
      _authenticationFailed = false;
    });

    // Simulate biometric authentication
    await Future.delayed(const Duration(seconds: 2));

    // Simulate random success/failure for demo
    final isSuccess = DateTime.now().millisecondsSinceEpoch % 3 != 0;

    if (mounted) {
      if (isSuccess) {
        widget.onConfirm();
      } else {
        setState(() {
          _isAuthenticating = false;
          _authenticationFailed = true;
        });

        // Reset after showing error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _authenticationFailed = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Authenticate to ${widget.action}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 3.h),

            // Biometric icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _authenticationFailed
                            ? [
                                isDark
                                    ? AppTheme.errorDark
                                    : AppTheme.errorLight,
                                (isDark
                                        ? AppTheme.errorDark
                                        : AppTheme.errorLight)
                                    .withOpacity(0.8),
                              ]
                            : [
                                isDark
                                    ? AppTheme.primaryDark
                                    : AppTheme.primaryLight,
                                (isDark
                                        ? AppTheme.primaryDark
                                        : AppTheme.primaryLight)
                                    .withOpacity(0.8),
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_authenticationFailed
                                  ? (isDark
                                      ? AppTheme.errorDark
                                      : AppTheme.errorLight)
                                  : (isDark
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight))
                              .withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isAuthenticating
                          ? SizedBox(
                              width: 8.w,
                              height: 8.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : CustomIconWidget(
                              iconName: _authenticationFailed
                                  ? 'error'
                                  : 'fingerprint',
                              color: Colors.white,
                              size: 10.w,
                            ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 3.h),

            // Status text
            Text(
              _isAuthenticating
                  ? 'Authenticating...'
                  : _authenticationFailed
                      ? 'Authentication failed. Try again.'
                      : 'Touch the fingerprint sensor or use Face ID',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _authenticationFailed
                        ? (isDark ? AppTheme.errorDark : AppTheme.errorLight)
                        : (isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight),
                  ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isAuthenticating ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isAuthenticating ? null : _authenticateWithBiometric,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authenticationFailed
                          ? (isDark ? AppTheme.errorDark : AppTheme.errorLight)
                          : null,
                    ),
                    child: Text(
                      _authenticationFailed ? 'Retry' : 'Authenticate',
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Alternative authentication
            TextButton(
              onPressed: _isAuthenticating
                  ? null
                  : () {
                      // Show password input or other alternatives
                      _showPasswordDialog();
                    },
              child: Text(
                'Use Password Instead',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

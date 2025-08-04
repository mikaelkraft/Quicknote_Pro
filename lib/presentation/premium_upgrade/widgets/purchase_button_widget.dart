import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PurchaseButtonWidget extends StatefulWidget {
  final bool isLoading;
  final String selectedPlan;
  final VoidCallback onStartTrial;
  final VoidCallback onRestore;

  const PurchaseButtonWidget({
    Key? key,
    required this.isLoading,
    required this.selectedPlan,
    required this.onStartTrial,
    required this.onRestore,
  }) : super(key: key);

  @override
  State<PurchaseButtonWidget> createState() => _PurchaseButtonWidgetState();
}

class _PurchaseButtonWidgetState extends State<PurchaseButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Primary button
        GestureDetector(
          onTap: widget.isLoading ? null : widget.onStartTrial,
          child: Container(
            width: double.infinity,
            height: 7.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                  (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                      .withValues(alpha: 0.8),
                  isDark ? AppTheme.accentDark : AppTheme.accentLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                      .withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Shimmer effect
                  if (!widget.isLoading)
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Positioned(
                          left: _shimmerAnimation.value * 100.w,
                          top: 0,
                          child: Container(
                            width: 20.w,
                            height: 7.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Button content
                  Center(
                    child: widget.isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 5.w,
                                height: 5.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'Processing...',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'rocket_launch',
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                widget.selectedPlan == 'lifetime'
                                    ? 'Get Lifetime Access'
                                    : 'Start Free Trial',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Secondary button
        GestureDetector(
          onTap: widget.isLoading ? null : widget.onRestore,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'restore',
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  size: 18,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Restore Purchases',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 1.h),

        // Terms text
        Text(
          'Terms of Service • Privacy Policy',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.textSecondaryDark.withValues(alpha: 0.7)
                    : AppTheme.textSecondaryLight.withValues(alpha: 0.7),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PricingOptionWidget extends StatefulWidget {
  final String title;
  final String price;
  final String period;
  final String? savings;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const PricingOptionWidget({
    Key? key,
    required this.title,
    required this.price,
    required this.period,
    this.savings,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PricingOptionWidget> createState() => _PricingOptionWidgetState();
}

class _PricingOptionWidgetState extends State<PricingOptionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isRecommended) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: widget.isSelected
              ? LinearGradient(
                  colors: [
                    isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isSelected
              ? null
              : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? Colors.transparent
                : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
            width: 1,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color:
                        (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                            .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (widget.savings != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.successDark : AppTheme.successLight)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDark ? AppTheme.successDark : AppTheme.successLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.savings!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.successDark
                            : AppTheme.successLight,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SizedBox(height: 1.h),
            ],
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.isSelected
                        ? Colors.white
                        : (isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 1.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.price,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: widget.isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppTheme.primaryDark
                                  : AppTheme.primaryLight),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextSpan(
                    text: ' ${widget.period}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : (isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
            if (widget.isSelected) ...[
              SizedBox(height: 1.h),
              CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.white,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.isRecommended) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: content,
              );
            },
          ),
          Positioned(
            top: -1.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? AppTheme.warningDark : AppTheme.warningLight,
                      (isDark ? AppTheme.warningDark : AppTheme.warningLight)
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark
                              ? AppTheme.warningDark
                              : AppTheme.warningLight)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'recommend',
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Recommended',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }
}

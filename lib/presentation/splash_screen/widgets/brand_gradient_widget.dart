import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BrandGradientWidget extends StatelessWidget {
  final Widget child;

  const BrandGradientWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.backgroundDark,
                  AppTheme.surfaceDark.withValues(alpha: 0.8),
                  AppTheme.primaryDark.withValues(alpha: 0.1),
                ]
              : [
                  AppTheme.backgroundLight,
                  AppTheme.primaryLight.withValues(alpha: 0.05),
                  AppTheme.primaryLight.withValues(alpha: 0.1),
                ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';

/// Widget that gates premium features and shows upsell UI for non-premium users
class FeatureGate extends StatelessWidget {
  final PremiumFeature feature;
  final Widget child;
  final Widget? fallback;
  final bool showUpsell;
  final String? customUpsellTitle;
  final String? customUpsellMessage;
  final VoidCallback? onUpgrade;

  const FeatureGate({
    Key? key,
    required this.feature,
    required this.child,
    this.fallback,
    this.showUpsell = true,
    this.customUpsellTitle,
    this.customUpsellMessage,
    this.onUpgrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<EntitlementService>(
      builder: (context, entitlementService, _) {
        if (entitlementService.hasFeature(feature)) {
          return child;
        }

        // Show fallback or upsell UI for non-premium users
        if (fallback != null) {
          return fallback!;
        }

        if (showUpsell) {
          return _buildUpsellWidget(context, entitlementService);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUpsellWidget(BuildContext context, EntitlementService entitlementService) {
    return GestureDetector(
      onTap: () => _showUpsellDialog(context),
      child: Container(
        padding: EdgeInsets.all(4.w),
        margin: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customUpsellTitle ?? 'Unlock ${feature.displayName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    customUpsellMessage ?? feature.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpsellDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpsellDialog(
        feature: feature,
        title: customUpsellTitle,
        message: customUpsellMessage,
        onUpgrade: onUpgrade ?? () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(AppRoutes.premiumUpgrade);
        },
      ),
    );
  }
}

/// Simplified feature gate for basic checks
class SimpleFeatureGate extends StatelessWidget {
  final PremiumFeature feature;
  final Widget child;
  final Widget? lockOverlay;

  const SimpleFeatureGate({
    Key? key,
    required this.feature,
    required this.child,
    this.lockOverlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<EntitlementService>(
      builder: (context, entitlementService, _) {
        final hasAccess = entitlementService.hasFeature(feature);
        
        return Stack(
          children: [
            child,
            if (!hasAccess && lockOverlay != null) lockOverlay!,
            if (!hasAccess && lockOverlay == null) _buildDefaultLockOverlay(context),
          ],
        );
      },
    );
  }

  Widget _buildDefaultLockOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Premium Feature',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Upgrade to unlock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button wrapper that shows upsell for premium features
class PremiumButton extends StatelessWidget {
  final PremiumFeature feature;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const PremiumButton({
    Key? key,
    required this.feature,
    required this.onPressed,
    required this.child,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<EntitlementService>(
      builder: (context, entitlementService, _) {
        final hasAccess = entitlementService.hasFeature(feature);
        
        return ElevatedButton(
          onPressed: hasAccess ? onPressed : () => _showUpsell(context),
          style: style,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasAccess) ...[
                Icon(Icons.star, size: 16),
                SizedBox(width: 1.w),
              ],
              child,
            ],
          ),
        );
      },
    );
  }

  void _showUpsell(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UpsellDialog(
        feature: feature,
        onUpgrade: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(AppRoutes.premiumUpgrade);
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Widget to display banner ads with proper subscription checking.
/// 
/// Automatically hides ads for premium users and respects consent settings.
class AdBannerWidget extends StatefulWidget {
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const AdBannerWidget({
    Key? key,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionService, AdsService>(
      builder: (context, subscriptionService, adsService, child) {
        // Don't show ads to premium users
        if (subscriptionService.isPremium) {
          return const SizedBox.shrink();
        }

        // Don't show ads if consent not given or ads not loaded
        if (!adsService.shouldShowAds || !adsService.isBannerLoaded) {
          return const SizedBox.shrink();
        }

        final bannerAd = adsService.bannerAd;
        if (bannerAd == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? 
                   (Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.surfaceDark.withValues(alpha: 0.5)
                    : AppTheme.surfaceLight.withValues(alpha: 0.5)),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            child: Column(
              children: [
                // Ad label
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Advertisement',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      _buildPremiumBadge(context, subscriptionService),
                    ],
                  ),
                ),
                
                // Ad content
                Container(
                  alignment: Alignment.center,
                  height: 60, // Standard banner height
                  child: AdWidget(ad: bannerAd),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumBadge(BuildContext context, SubscriptionService subscriptionService) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.premiumUpgrade),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 12,
              color: Colors.white,
            ),
            SizedBox(width: 1.w),
            Text(
              'Remove Ads',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to show interstitial ad loading state or trigger button.
class AdInterstitialTrigger extends StatelessWidget {
  final VoidCallback? onAdShown;
  final Widget? child;

  const AdInterstitialTrigger({
    Key? key,
    this.onAdShown,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionService, AdsService>(
      builder: (context, subscriptionService, adsService, child) {
        // Don't show interstitials to premium users
        if (subscriptionService.isPremium) {
          return this.child ?? const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () async {
            if (adsService.shouldShowAds && adsService.isInterstitialLoaded) {
              final shown = await adsService.showInterstitialAd();
              if (shown && onAdShown != null) {
                onAdShown!();
              }
            }
          },
          child: this.child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Widget to show ad loading indicator.
class AdLoadingIndicator extends StatelessWidget {
  const AdLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdsService>(
      builder: (context, adsService, child) {
        if (!adsService.shouldShowAds) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 8.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 6.w,
                  height: 6.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Loading ad...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
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

/// Widget to show when ads fail to load with upgrade option.
class AdFailedWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const AdFailedWidget({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Support the app',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Upgrade to remove ads forever',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 3.w),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.premiumUpgrade),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upgrade',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
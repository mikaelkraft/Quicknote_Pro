import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BannerAdWidget extends StatelessWidget {
  final String? placement;

  const BannerAdWidget({
    Key? key,
    this.placement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationManager>(
      builder: (context, monetization, child) {
        // Don't show ads if user has premium or ads are disabled
        if (!monetization.ads.shouldShowAds || 
            monetization.premium.adFree ||
            !monetization.ads.isBannerAdLoaded ||
            monetization.ads.bannerAd == null) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: monetization.ads.bannerAd!.size.width.toDouble(),
              height: monetization.ads.bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: monetization.ads.bannerAd!),
            ),
          ),
        );
      },
    );
  }
}
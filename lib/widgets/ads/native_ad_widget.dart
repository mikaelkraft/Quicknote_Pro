import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../constants/ads_config.dart';
import '../../models/ad_placement.dart';
import '../../services/ads/ads_service.dart';

/// A native ad widget that blends seamlessly with the app's content.
/// 
/// Native ads match the look and feel of the surrounding content
/// while clearly marking themselves as advertisements.
class NativeAdWidget extends StatefulWidget {
  final String placementId;
  final NativeAdTemplate template;
  final EdgeInsets? margin;
  final double? height;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdDismissed;

  const NativeAdWidget({
    Key? key,
    required this.placementId,
    this.template = NativeAdTemplate.medium,
    this.margin,
    this.height,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdClicked,
    this.onAdDismissed,
  }) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  AdInstance? _currentAd;
  bool _isLoading = false;
  bool _isVisible = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!mounted) return;

    final adsService = context.read<AdsService>();
    if (!adsService.shouldShowAds) {
      setState(() {
        _isVisible = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ad = await adsService.loadAd(
        widget.placementId,
        preferredFormat: AdsConfig.formatNative,
      );

      if (mounted) {
        setState(() {
          _currentAd = ad;
          _isLoading = false;
        });

        if (ad != null) {
          await adsService.showAd(ad.id);
          widget.onAdLoaded?.call();
        } else {
          widget.onAdFailedToLoad?.call();
          _showFallbackContent();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        widget.onAdFailedToLoad?.call();
        _showFallbackContent();
      }
    }
  }

  void _showFallbackContent() {
    if (AdsConfig.showFallbackContent) {
      setState(() {
        _errorMessage = AdsConfig.fallbackContentText;
      });
    } else {
      setState(() {
        _isVisible = false;
      });
    }
  }

  void _onAdTapped() {
    if (_currentAd != null) {
      final adsService = context.read<AdsService>();
      adsService.onAdClicked(_currentAd!.id);
      widget.onAdClicked?.call();
    }
  }

  void _onCloseTapped() {
    if (_currentAd != null) {
      final adsService = context.read<AdsService>();
      adsService.onAdDismissed(_currentAd!.id, reason: 'user_close');
    }
    
    setState(() {
      _isVisible = false;
    });
    
    widget.onAdDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      height: widget.height ?? widget.template.height,
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: _buildAdContent(isDark),
        ),
      ),
    );
  }

  Widget _buildAdContent(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }

    if (_currentAd != null) {
      return _buildAdState(isDark);
    }

    return _buildFallbackState(isDark);
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading content...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 6.w,
            color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
          ),
          SizedBox(height: 2.h),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (AdsConfig.showFallbackContent) ...[
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              ),
              child: Text(
                'Upgrade to Premium',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdState(bool isDark) {
    switch (widget.template) {
      case NativeAdTemplate.small:
        return _buildSmallTemplate(isDark);
      case NativeAdTemplate.medium:
        return _buildMediumTemplate(isDark);
      case NativeAdTemplate.large:
        return _buildLargeTemplate(isDark);
    }
  }

  Widget _buildSmallTemplate(bool isDark) {
    return GestureDetector(
      onTap: _onAdTapped,
      child: Container(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            // Ad image/icon
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: 6.w,
              ),
            ),
            SizedBox(width: 3.w),
            
            // Ad content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Sponsored',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _onCloseTapped,
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Premium QuickNote Features',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Unlock unlimited notes & cloud sync',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediumTemplate(bool isDark) {
    return GestureDetector(
      onTap: _onAdTapped,
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sponsored label and close button
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Sponsored Content',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _onCloseTapped,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            
            // Main content
            Row(
              children: [
                // Ad image
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                        (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                            .withValues(alpha: 0.8),
                        Colors.purple.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
                SizedBox(width: 4.w),
                
                // Ad text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QuickNote Pro Premium',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Experience the full power of QuickNote with unlimited notes, cloud sync, advanced drawing tools, and ad-free experience.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            
            // Call to action button
            Container(
              width: double.infinity,
              height: 5.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Upgrade Now',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeTemplate(bool isDark) {
    return GestureDetector(
      onTap: _onAdTapped,
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Featured Content',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _onCloseTapped,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            
            // Large hero image
            Container(
              width: double.infinity,
              height: 25.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    Colors.purple,
                    Colors.blue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 12.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'QuickNote Pro',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Premium Experience',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            
            // Content
            Text(
              'Unlock the Full Potential of QuickNote',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Join thousands of users who have upgraded to Premium and experience unlimited notes, seamless cloud sync across all devices, advanced drawing tools with layers, and a completely ad-free interface.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            SizedBox(height: 2.h),
            
            // Features list
            Row(
              children: [
                Expanded(
                  child: _buildFeatureChip('∞ Notes', isDark),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildFeatureChip('Cloud Sync', isDark),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildFeatureChip('Ad-Free', isDark),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            
            // CTA Button
            Container(
              width: double.infinity,
              height: 6.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Start Premium Experience',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Center(
        child: Text(
          'Native Advertisement',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Enum for different native ad templates
enum NativeAdTemplate {
  small(120),
  medium(200),
  large(350);

  const NativeAdTemplate(this.height);
  
  final double height;
}

/// A simplified native ad widget for quick integration
class SimpleNativeAd extends StatelessWidget {
  final String placementId;
  final NativeAdTemplate template;
  final EdgeInsets? margin;

  const SimpleNativeAd({
    Key? key,
    required this.placementId,
    this.template = NativeAdTemplate.medium,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdsService>(
      builder: (context, adsService, child) {
        if (!adsService.shouldShowAds) {
          return const SizedBox.shrink();
        }

        return NativeAdWidget(
          placementId: placementId,
          template: template,
          margin: margin,
        );
      },
    );
  }
}
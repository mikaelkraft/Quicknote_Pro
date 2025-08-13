import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../constants/ads_config.dart';
import '../../models/ad_placement.dart';
import '../../services/ads/ads_service.dart';

/// A banner ad widget that displays horizontal ads at the bottom/top of content.
/// 
/// This widget integrates with the AdsService to load, display, and track
/// banner advertisements in a non-intrusive manner.
class BannerAdWidget extends StatefulWidget {
  final String placementId;
  final AdBannerSize size;
  final EdgeInsets? margin;
  final bool showCloseButton;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdDismissed;

  const BannerAdWidget({
    Key? key,
    required this.placementId,
    this.size = AdBannerSize.standard,
    this.margin,
    this.showCloseButton = true,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdClicked,
    this.onAdDismissed,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
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
        preferredFormat: AdsConfig.formatBanner,
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
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: widget.size.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                  .withValues(alpha: 0.2),
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
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            'Loading ad...',
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
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (AdsConfig.showFallbackContent) ...[
                  SizedBox(height: 0.5.h),
                  GestureDetector(
                    onTap: () {
                      // Navigate to premium upgrade
                      Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
                    },
                    child: Text(
                      'Upgrade to Premium →',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.showCloseButton)
            IconButton(
              onPressed: _onCloseTapped,
              icon: Icon(
                Icons.close,
                size: 18,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdState(bool isDark) {
    return GestureDetector(
      onTap: _onAdTapped,
      child: Container(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            // Mock ad icon/image
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
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.auto_awesome,
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
                          'Ad',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.showCloseButton)
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
                    'Discover amazing apps and services',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tap to learn more about premium features',
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

  Widget _buildFallbackState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(3.w),
      child: Center(
        child: Text(
          'Advertisement',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Enum for different banner ad sizes
enum AdBannerSize {
  standard(320, 50),
  large(320, 100),
  medium(300, 250),
  leaderboard(728, 90);

  const AdBannerSize(this.width, this.height);
  
  final double width;
  final double height;
}

/// A simplified banner ad widget for quick integration
class SimpleBannerAd extends StatelessWidget {
  final String placementId;
  final AdBannerSize size;
  final EdgeInsets? margin;

  const SimpleBannerAd({
    Key? key,
    required this.placementId,
    this.size = AdBannerSize.standard,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdsService>(
      builder: (context, adsService, child) {
        if (!adsService.shouldShowAds) {
          return const SizedBox.shrink();
        }

        return BannerAdWidget(
          placementId: placementId,
          size: size,
          margin: margin,
        );
      },
    );
  }
}
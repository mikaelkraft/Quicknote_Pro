import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../constants/ads_config.dart';
import '../../models/ad_placement.dart';
import '../../services/ads/ads_service.dart';

/// An interstitial ad overlay that appears between content transitions.
/// 
/// This widget displays full-screen ads at natural app transition points
/// with appropriate frequency capping and user controls.
class InterstitialAdOverlay extends StatefulWidget {
  final String placementId;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdDismissed;
  final VoidCallback? onAdClosed;

  const InterstitialAdOverlay({
    Key? key,
    required this.placementId,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdClicked,
    this.onAdDismissed,
    this.onAdClosed,
  }) : super(key: key);

  @override
  State<InterstitialAdOverlay> createState() => _InterstitialAdOverlayState();
}

class _InterstitialAdOverlayState extends State<InterstitialAdOverlay>
    with TickerProviderStateMixin {
  AdInstance? _currentAd;
  bool _isLoading = false;
  bool _isVisible = true;
  String? _errorMessage;
  int _countdown = 5; // Countdown before close button appears
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAd();
    _startCountdown();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        _countdown--;
      });
      
      return _countdown > 0;
    });
  }

  Future<void> _loadAd() async {
    if (!mounted) return;

    final adsService = context.read<AdsService>();
    if (!adsService.shouldShowAds) {
      _closeAd();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ad = await adsService.loadAd(
        widget.placementId,
        preferredFormat: AdsConfig.formatInterstitial,
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
      _closeAd();
    }
  }

  void _onAdTapped() {
    if (_currentAd != null) {
      final adsService = context.read<AdsService>();
      adsService.onAdClicked(_currentAd!.id);
      widget.onAdClicked?.call();
    }
  }

  Future<void> _closeAd({String reason = 'user_close'}) async {
    if (_currentAd != null) {
      final adsService = context.read<AdsService>();
      await adsService.onAdDismissed(_currentAd!.id, reason: reason);
      widget.onAdDismissed?.call();
    }
    
    await _slideController.reverse();
    await _fadeController.reverse();
    
    if (mounted) {
      Navigator.of(context).pop();
      widget.onAdClosed?.call();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        if (_countdown <= 0) {
          await _closeAd(reason: 'back_button');
          return false;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: _buildAdContent(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdContent(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _buildContent(isDark),
          ),
          _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
            .withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Advertisement',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (_countdown <= 0)
            GestureDetector(
              onTap: () => _closeAd(),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$_countdown',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return _buildLoadingContent(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorContent(isDark);
    }

    if (_currentAd != null) {
      return _buildAdContent_(isDark);
    }

    return _buildFallbackContent(isDark);
  }

  Widget _buildLoadingContent(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Loading content...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Please wait while we prepare your content',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 15.w,
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            ),
            SizedBox(height: 3.h),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (AdsConfig.showFallbackContent) ...[
              SizedBox(height: 3.h),
              Text(
                'Upgrade to Premium for an ad-free experience with unlimited features.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Upgrade to Premium',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdContent_(bool isDark) {
    return GestureDetector(
      onTap: _onAdTapped,
      child: Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero image
            Container(
              width: 40.w,
              height: 40.w,
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 15.w,
              ),
            ),
            SizedBox(height: 4.h),
            
            // Title
            Text(
              'Unlock QuickNote Pro Premium',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            
            // Description
            Text(
              'Experience the ultimate note-taking app with unlimited notes, seamless cloud sync, advanced drawing tools, and a completely ad-free interface.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            
            // Features
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureItem('∞', 'Unlimited\nNotes', isDark),
                _buildFeatureItem('☁️', 'Cloud\nSync', isDark),
                _buildFeatureItem('🎨', 'Pro\nTools', isDark),
                _buildFeatureItem('🚫', 'Ad\nFree', isDark),
              ],
            ),
            SizedBox(height: 4.h),
            
            // CTA Button
            Container(
              width: double.infinity,
              height: 7.h,
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Start Premium Experience',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildFeatureItem(String icon, String text, bool isDark) {
    return Column(
      children: [
        Container(
          width: 15.w,
          height: 15.w,
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(fontSize: 6.w),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFallbackContent(bool isDark) {
    return Center(
      child: Text(
        'Interstitial Advertisement',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Powered by QuickNote Pro',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show interstitial ads
class InterstitialAdHelper {
  /// Shows an interstitial ad if conditions are met
  static Future<bool> showInterstitialAd(
    BuildContext context,
    String placementId, {
    VoidCallback? onAdClosed,
  }) async {
    final adsService = context.read<AdsService>();
    
    if (!adsService.shouldShowAds) {
      return false;
    }

    // Check if we can show an interstitial ad for this placement
    final placement = adsService.placements[placementId];
    if (placement == null || 
        !placement.supportedFormats.contains(AdsConfig.formatInterstitial)) {
      return false;
    }

    // Show the interstitial overlay
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => InterstitialAdOverlay(
        placementId: placementId,
        onAdClosed: onAdClosed,
      ),
    ) ?? false;
  }

  /// Preloads an interstitial ad for better performance
  static Future<void> preloadInterstitialAd(
    BuildContext context,
    String placementId,
  ) async {
    final adsService = context.read<AdsService>();
    await adsService.loadAd(
      placementId,
      preferredFormat: AdsConfig.formatInterstitial,
    );
  }
}
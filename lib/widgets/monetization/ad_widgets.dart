import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Simple banner ad widget that handles display and tracking
class SimpleBannerAd extends StatefulWidget {
  final AdPlacement placement;
  final double? height;
  final EdgeInsets? margin;

  const SimpleBannerAd({
    Key? key,
    required this.placement,
    this.height,
    this.margin,
  }) : super(key: key);

  @override
  State<SimpleBannerAd> createState() => _SimpleBannerAdState();
}

class _SimpleBannerAdState extends State<SimpleBannerAd> {
  AdResult? _adResult;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adsService = context.read<AdsService>();
    
    // Enhanced placement validation
    if (!_validatePlacement()) {
      return;
    }
    
    final result = await adsService.requestAd(widget.placement);
    
    if (mounted) {
      setState(() => _adResult = result);
      
      // Track ad load result for KPI monitoring
      if (result.isSuccess) {
        await _trackAdMetric('ad_load_success', {
          'placement': widget.placement.name,
          'load_time': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await _trackAdMetric('ad_load_failed', {
          'placement': widget.placement.name,
          'error': result.message,
        });
      }
    }
  }

  /// Validate placement according to documentation specs
  bool _validatePlacement() {
    final adsService = context.read<AdsService>();
    
    // Check if ads are enabled and user is not premium
    if (!adsService.adsEnabled) {
      return false;
    }
    
    // Validate placement timing and frequency
    if (!adsService.canShowAd(widget.placement)) {
      return false;
    }
    
    return true;
  }

  /// Track ad-related metrics for analytics
  Future<void> _trackAdMetric(String eventName, Map<String, dynamic> properties) async {
    final analyticsService = AnalyticsService();
    await analyticsService.logEvent(eventName, {
      'timestamp': DateTime.now().toIso8601String(),
      ...properties,
    });
  }

  @override
  Widget build(BuildContext context) {
    final adsService = context.read<AdsService>();
    
    if (!adsService.adsEnabled || _isDismissed || _adResult?.isSuccess != true) {
      return const SizedBox.shrink();
    }

    return Container(
      height: widget.height ?? 15.w,
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: _buildAdContent(),
    );
  }

  Widget _buildAdContent() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        children: [
          // Ad content
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                // Ad icon
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.star,
                    color: theme.colorScheme.primary,
                    size: 5.w,
                  ),
                ),
                SizedBox(width: 3.w),
                
                // Ad text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Enhance Your Productivity',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Discover apps that boost your workflow',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // CTA button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Learn More',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Ad label
          Positioned(
            top: 1.w,
            left: 1.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Ad',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 8,
                ),
              ),
            ),
          ),
          
          // Dismiss button
          Positioned(
            top: 1.w,
            right: 1.w,
            child: GestureDetector(
              onTap: _dismissAd,
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 3.w,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          
          // Tap handler
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleAdTap,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAdTap() {
    final adsService = context.read<AdsService>();
    adsService.recordAdInteraction(widget.placement, AdInteraction.clicked);
    
    // In a real implementation, this would open the ad destination
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ad clicked! (Demo)')),
    );
  }

  void _dismissAd() {
    final adsService = context.read<AdsService>();
    adsService.recordAdInteraction(widget.placement, AdInteraction.dismissed);
    
    setState(() => _isDismissed = true);
  }
}

/// Native ad widget that blends with app content
class SimpleNativeAd extends StatefulWidget {
  final AdPlacement placement;
  final NativeAdTemplate template;

  const SimpleNativeAd({
    Key? key,
    required this.placement,
    this.template = NativeAdTemplate.medium,
  }) : super(key: key);

  @override
  State<SimpleNativeAd> createState() => _SimpleNativeAdState();
}

class _SimpleNativeAdState extends State<SimpleNativeAd> {
  AdResult? _adResult;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adsService = context.read<AdsService>();
    final result = await adsService.requestAd(widget.placement);
    
    if (mounted) {
      setState(() => _adResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsService = context.read<AdsService>();
    
    if (!adsService.adsEnabled || _isDismissed || _adResult?.isSuccess != true) {
      return const SizedBox.shrink();
    }

    switch (widget.template) {
      case NativeAdTemplate.small:
        return _buildSmallTemplate();
      case NativeAdTemplate.medium:
        return _buildMediumTemplate();
      case NativeAdTemplate.large:
        return _buildLargeTemplate();
    }
  }

  Widget _buildSmallTemplate() {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: [
          _buildAdIcon(),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdTitle('Boost Your Note-Taking'),
                _buildAdDescription('Try these productivity tips'),
              ],
            ),
          ),
          _buildDismissButton(),
        ],
      ),
    );
  }

  Widget _buildMediumTemplate() {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                _buildAdIcon(),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdTitle('Discover Premium Tools'),
                      _buildAdDescription('Handpicked productivity apps'),
                    ],
                  ),
                ),
                _buildDismissButton(),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Text(
              'Join thousands of users who have supercharged their productivity with these carefully selected tools.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          
          // CTA
          Padding(
            padding: EdgeInsets.all(3.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleAdTap,
                child: const Text('Explore Now'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeTemplate() {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 40.w,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Icon(
              Icons.image,
              size: 12.w,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAdIcon(),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildAdTitle('Transform Your Workflow'),
                    ),
                    _buildDismissButton(),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildAdDescription(
                  'Discover the top-rated productivity apps that thousands of professionals use to stay organized and efficient.',
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleAdTap,
                        child: const Text('Learn More'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    OutlinedButton(
                      onPressed: _dismissAd,
                      child: const Text('Not Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdIcon() {
    final theme = Theme.of(context);
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.apps,
        color: theme.colorScheme.primary,
        size: 6.w,
      ),
    );
  }

  Widget _buildAdTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAdDescription(String description) {
    return Text(
      description,
      style: Theme.of(context).textTheme.bodySmall,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDismissButton() {
    return GestureDetector(
      onTap: _dismissAd,
      child: Container(
        padding: EdgeInsets.all(1.w),
        child: Icon(
          Icons.close,
          size: 4.w,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  void _handleAdTap() {
    final adsService = context.read<AdsService>();
    adsService.recordAdInteraction(widget.placement, AdInteraction.clicked);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Native ad clicked! (Demo)')),
    );
  }

  void _dismissAd() {
    final adsService = context.read<AdsService>();
    adsService.recordAdInteraction(widget.placement, AdInteraction.dismissed);
    
    setState(() => _isDismissed = true);
  }
}

/// Interstitial ad helper for showing full-screen ads
class SmartInterstitialHelper {
  static Future<void> showSmartInterstitial(
    BuildContext context,
    AdPlacement placement, {
    bool isImportantTransition = false,
  }) async {
    final adsService = context.read<AdsService>();
    
    if (!adsService.adsEnabled) return;
    
    // Calculate probability based on importance
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final threshold = isImportantTransition ? 25 : 15; // 25% or 15% chance
    
    if (random >= threshold) return;
    
    final result = await adsService.requestAd(placement);
    if (!result.isSuccess) return;
    
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => InterstitialAdDialog(placement: placement),
      );
    }
  }
}

/// Full-screen interstitial ad dialog
class InterstitialAdDialog extends StatefulWidget {
  final AdPlacement placement;

  const InterstitialAdDialog({
    Key? key,
    required this.placement,
  }) : super(key: key);

  @override
  State<InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<InterstitialAdDialog> {
  int _countdown = 5;
  bool _canDismiss = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      } else if (mounted) {
        setState(() => _canDismiss = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog.fullscreen(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Advertisement',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (_canDismiss)
                    GestureDetector(
                      onTap: _dismissAd,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 6.w,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Skip in $_countdown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Ad content
            Expanded(
              child: Container(
                margin: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      size: 20.w,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Supercharge Your Productivity',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        'Discover premium tools and apps that will transform how you work and boost your efficiency.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      child: ElevatedButton(
                        onPressed: _handleAdTap,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(60.w, 6.h),
                        ),
                        child: const Text('Explore Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAdTap() {
    final adsService = context.read<AdsService>();
    adsService.recordAdInteraction(widget.placement, AdInteraction.clicked);
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interstitial ad clicked! (Demo)')),
    );
  }

  void _dismissAd() {
    final adsService = context.read<AdsService>();
    adsService.recordAdInteraction(widget.placement, AdInteraction.dismissed);
    
    Navigator.of(context).pop();
  }
}

/// Native ad template types
enum NativeAdTemplate {
  small,
  medium,
  large,
}
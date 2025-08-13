import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/ad_models.dart';
import '../../../services/ads/ad_service.dart';

/// Widget for displaying banner ads with dismissal option
class BannerAdWidget extends StatefulWidget {
  final String placementId;
  final VoidCallback? onDismissed;

  const BannerAdWidget({
    Key? key,
    required this.placementId,
    this.onDismissed,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with SingleTickerProviderStateMixin {
  final AdService _adService = AdService();
  AdImpression? _currentImpression;
  bool _isVisible = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadAd();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    final impression = await _adService.requestAd(widget.placementId);
    if (impression != null && mounted) {
      setState(() {
        _currentImpression = impression;
        _isVisible = true;
      });
      _animationController.forward();
    }
  }

  void _onAdClicked() {
    if (_currentImpression != null) {
      _adService.recordAdClick(_currentImpression!.id);
      // In real implementation, open ad destination
    }
  }

  void _onAdDismissed() {
    if (_currentImpression != null) {
      _adService.recordAdDismiss(_currentImpression!.id);
    }
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
        widget.onDismissed?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentImpression == null) {
      return const SizedBox.shrink();
    }

    final placement = AdPlacements.getById(widget.placementId);
    if (placement == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onAdClicked,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 6.w,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              'Remove ads and unlock all features',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (placement.isDismissible) ...[
                        SizedBox(width: 2.w),
                        IconButton(
                          onPressed: _onAdDismissed,
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 5.w,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
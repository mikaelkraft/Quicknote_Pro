import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import './widgets/feature_card_widget.dart';
import './widgets/premium_header_widget.dart';
import './widgets/pricing_option_widget.dart';
import './widgets/purchase_button_widget.dart';
import './widgets/promo_code_widget.dart';
import './widgets/banner_ad_widget.dart';

class PremiumUpgrade extends StatefulWidget {
  const PremiumUpgrade({Key? key}) : super(key: key);

  @override
  State<PremiumUpgrade> createState() => _PremiumUpgradeState();
}

class _PremiumUpgradeState extends State<PremiumUpgrade>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _featuresController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _featuresAnimation;

  bool _isLoading = false;
  String _selectedPlan = 'lifetime'; // 'monthly' or 'lifetime'
  String? _promoCode;
  final TextEditingController _promoController = TextEditingController();

  final List<Map<String, dynamic>> _premiumFeatures = [
    {
      'title': 'Unlimited Voice Notes',
      'description': 'Record and transcribe unlimited voice memos with AI',
      'icon': 'mic',
      'gradient': [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      'currentLimit': '10/month',
      'premiumLimit': 'Unlimited',
      'hasDemo': true,
    },
    {
      'title': 'Advanced Drawing Tools',
      'description': 'Professional drawing tools with layers and effects',
      'icon': 'brush',
      'gradient': [Color(0xFF06B6D4), Color(0xFF67E8F9)],
      'currentLimit': 'Basic tools',
      'premiumLimit': 'Pro tools + Layers',
      'hasDemo': true,
    },
    {
      'title': 'Cloud Sync',
      'description': 'Sync notes across all your devices seamlessly',
      'icon': 'cloud_sync',
      'gradient': [Color(0xFF10B981), Color(0xFF34D399)],
      'currentLimit': 'Local only',
      'premiumLimit': 'All devices',
      'hasDemo': false,
    },
    {
      'title': 'Ad-Free Experience',
      'description': 'Clean interface without any interruptions',
      'icon': 'block',
      'gradient': [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      'currentLimit': 'With ads',
      'premiumLimit': 'Ad-free',
      'hasDemo': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Track funnel step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monetization = Provider.of<MonetizationManager>(context, listen: false);
      monetization.analytics.trackFunnelStep('upgrade_funnel', 'premium_screen_viewed');
    });
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _featuresAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _featuresController,
      curve: Curves.elasticOut,
    ));

    _backgroundController.repeat(reverse: true);
    _featuresController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _featuresController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _onPlanSelected(String plan) {
    setState(() {
      _selectedPlan = plan;
    });
  }

  void _onFeatureTapped(Map<String, dynamic> feature) {
    if (feature['hasDemo']) {
      _showFeatureDemo(feature);
    }
  }

  void _showFeatureDemo(Map<String, dynamic> feature) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${feature['title']} Demo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 2.h),
              Container(
                height: 20.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: feature['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: feature['icon'],
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Interactive Demo',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Demo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startFreeTrial() async {
    final monetization = Provider.of<MonetizationManager>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Track purchase attempt
      monetization.analytics.trackFunnelStep('upgrade_funnel', 'purchase_attempted', extra: {
        'plan': _selectedPlan,
        'has_promo': _promoCode != null,
      });

      final productId = _selectedPlan == 'monthly' 
          ? ProductIds.premiumMonthly 
          : ProductIds.premiumLifetime;

      final success = await monetization.purchaseProduct(productId, promoCode: _promoCode);

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Purchase failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Purchase failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 2.w),
            Text('Welcome to Premium!'),
          ],
        ),
        content: Text('Thank you for upgrading to QuickNote Pro Premium! All features are now unlocked.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  void _restorePurchases() async {
    final monetization = Provider.of<MonetizationManager>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      await monetization.restorePurchases();
      
      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Complete'),
          content: Text(
            monetization.premium.isPremium 
                ? 'Your premium features have been restored!'
                : 'No previous purchases found.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to restore purchases: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onPromoCodeApplied(String code) {
    setState(() {
      _promoCode = code;
    });
  }

  void _onPromoCodeCleared() {
    setState(() {
      _promoCode = null;
    });
    _promoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<MonetizationManager>(
      builder: (context, monetization, child) {
        // Get dynamic pricing from A/B tests
        final monthlyPrice = monetization.getTestPrice(ProductIds.premiumMonthly);
        final lifetimePrice = monetization.getTestPrice(ProductIds.premiumLifetime);
        final buttonText = monetization.getUpgradeButtonText();

        return Scaffold(
          backgroundColor:
              isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          body: AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppTheme.backgroundDark,
                            AppTheme.surfaceDark.withValues(alpha: 0.8),
                            AppTheme.primaryDark.withValues(alpha: 0.1),
                          ]
                        : [
                            AppTheme.backgroundLight,
                            AppTheme.surfaceLight.withValues(alpha: 0.8),
                            AppTheme.primaryLight.withValues(alpha: 0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      0.0,
                      0.5 + (_backgroundAnimation.value * 0.3),
                      1.0,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      PremiumHeaderWidget(
                        onClose: () => Navigator.pop(context),
                      ),

                      // Show banner ad for free users
                      if (!monetization.premium.adFree && monetization.ads.shouldShowAds)
                        const BannerAdWidget(),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Column(
                            children: [
                              SizedBox(height: 2.h),

                              // Features section
                              AnimatedBuilder(
                                animation: _featuresAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _featuresAnimation.value,
                                    child: Column(
                                      children: _premiumFeatures
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final feature = entry.value;
                                        return AnimatedContainer(
                                          duration: Duration(
                                              milliseconds: 300 + (index * 100)),
                                          curve: Curves.easeOutBack,
                                          margin: EdgeInsets.only(bottom: 2.h),
                                          child: FeatureCardWidget(
                                            feature: feature,
                                            onTap: () => _onFeatureTapped(feature),
                                            animationDelay: index * 200,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: 3.h),

                              // Promo code section
                              PromoCodeWidget(
                                controller: _promoController,
                                onApplied: _onPromoCodeApplied,
                                onCleared: _onPromoCodeCleared,
                                appliedCode: _promoCode,
                              ),

                              SizedBox(height: 2.h),

                              // Pricing section
                              Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppTheme.surfaceDark
                                          : AppTheme.surfaceLight)
                                      .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: (isDark
                                            ? AppTheme.primaryDark
                                            : AppTheme.primaryLight)
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Choose Your Plan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppTheme.primaryDark
                                                : AppTheme.primaryLight,
                                          ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: PricingOptionWidget(
                                            title: 'Monthly',
                                            price: monthlyPrice,
                                            period: '/month',
                                            savings: _promoCode != null ? 'Promo Applied!' : null,
                                            isSelected: _selectedPlan == 'monthly',
                                            isRecommended: false,
                                            onTap: () => _onPlanSelected('monthly'),
                                          ),
                                        ),
                                        SizedBox(width: 3.w),
                                        Expanded(
                                          child: PricingOptionWidget(
                                            title: 'Lifetime',
                                            price: lifetimePrice,
                                            period: 'one-time',
                                            savings: _promoCode != null ? 'Promo Applied!' : 'Save 75%',
                                            isSelected: _selectedPlan == 'lifetime',
                                            isRecommended: true,
                                            onTap: () =>
                                                _onPlanSelected('lifetime'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 4.h),

                              // Purchase buttons
                              PurchaseButtonWidget(
                                isLoading: _isLoading,
                                selectedPlan: _selectedPlan,
                                buttonText: buttonText,
                                hasPromo: _promoCode != null,
                                onStartTrial: _startFreeTrial,
                                onRestore: _restorePurchases,
                              ),

                              SizedBox(height: 2.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

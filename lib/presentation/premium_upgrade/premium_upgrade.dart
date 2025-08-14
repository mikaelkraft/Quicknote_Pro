import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/analytics/analytics_service.dart';
import './widgets/feature_card_widget.dart';
import './widgets/premium_header_widget.dart';
import './widgets/pricing_option_widget.dart';
import './widgets/purchase_button_widget.dart';

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
  bool _hasLoggedPromptShown = false;
  final AnalyticsService _analyticsService = AnalyticsService();

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
    _trackScreenView();
  }

  void _trackScreenView() {
    // Log screen view
    _analyticsService.logScreenView('premium_upgrade');
    
    // Log upgrade prompt shown (once per screen open)
    if (!_hasLoggedPromptShown) {
      _analyticsService.trackMonetizationEvent(
        MonetizationEvent.upgradePromptShown(context: 'upgrade_page'),
      );
      _hasLoggedPromptShown = true;
    }
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
    super.dispose();
  }

  void _onPlanSelected(String plan) {
    setState(() {
      _selectedPlan = plan;
    });
    
    // Track upgrade started with the selected tier
    _analyticsService.trackMonetizationEvent(
      MonetizationEvent.upgradeStarted(tier: plan, context: 'plan_selection'),
    );
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
    setState(() {
      _isLoading = true;
    });

    // Track free trial started
    _analyticsService.trackMonetizationEvent(
      MonetizationEvent.upgradeStarted(
        tier: _selectedPlan,
        context: 'trial',
      ),
    );

    try {
      // Simulate purchase process
      await Future.delayed(const Duration(seconds: 2));

      if (kIsWeb) {
        _showWebCheckout();
      } else {
        _handleNativePurchase();
      }
    } catch (e) {
      _showErrorDialog('Purchase failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showWebCheckout() {
    // Web checkout redirect simulation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Web Checkout'),
        content: const Text('Redirecting to secure payment page...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleNativePurchase() {
    // Native purchase simulation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Successful'),
        content: const Text('Welcome to QuickNote Pro Premium!'),
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
    setState(() {
      _isLoading = true;
    });

    // Track restore purchases action
    _analyticsService.trackMonetizationEvent(
      MonetizationEvent.restorePurchases(source: 'purchase_button'),
    );

    // Simulate restore process
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Complete'),
        content: const Text('No previous purchases found.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                                        price: '\$2.99',
                                        period: '/month',
                                        savings: null,
                                        isSelected: _selectedPlan == 'monthly',
                                        isRecommended: false,
                                        onTap: () => _onPlanSelected('monthly'),
                                      ),
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: PricingOptionWidget(
                                        title: 'Lifetime',
                                        price: '\$74.99',
                                        period: 'one-time',
                                        savings: 'Save 30%',
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
  }
}

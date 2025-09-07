import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../core/feature_flags.dart';
import '../../services/payments/iap_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({Key? key}) : super(key: key);

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _featuresController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _featuresAnimation;
  
  bool _isLoading = false;
  String? _selectedProductId;

  // Premium features list
  final List<Map<String, dynamic>> _premiumFeatures = [
    {
      'icon': 'cloud_sync',
      'title': 'Unlimited Cloud Sync',
      'description': 'Sync across all your devices with iCloud Drive',
    },
    {
      'icon': 'palette',
      'title': 'Advanced Drawing Tools',
      'description': 'Professional doodling with layers and effects',
    },
    {
      'icon': 'attach_file',
      'title': 'File Attachments',
      'description': 'Add images, documents, and media to notes',
    },
    {
      'icon': 'folder_special',
      'title': 'Unlimited Folders',
      'description': 'Organize notes with nested folder structures',
    },
    {
      'icon': 'backup',
      'title': 'Advanced Backup',
      'description': 'Automatic backups with version history',
    },
    {
      'icon': 'search',
      'title': 'AI-Powered Search',
      'description': 'Smart search with content recognition',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeIAP();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  void _initializeIAP() async {
    final iapService = context.read<IAPService>();
    if (!iapService.isInitialized) {
      await iapService.initialize();
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _purchaseProduct(String productId) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _selectedProductId = productId;
    });

    try {
      final iapService = context.read<IAPService>();
      final success = await iapService.purchaseProduct(productId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase successful! Welcome to Premium!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedProductId = null;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final iapService = context.read<IAPService>();
      final success = await iapService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Purchases restored successfully!'
              : 'No previous purchases found.'
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppTheme.backgroundDark,
                        AppTheme.primaryDark.withOpacity(0.1),
                        AppTheme.accentDark.withOpacity(0.05),
                      ]
                    : [
                        AppTheme.backgroundLight,
                        AppTheme.primaryLight.withOpacity(0.1),
                        AppTheme.accentLight.withOpacity(0.05),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [
                  0.0,
                  0.6 + (_backgroundAnimation.value * 0.2),
                  1.0,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isDark),
              
              // Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _featuresAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _featuresAnimation.value,
                      child: child,
                    );
                  },
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      children: [
                        // Hero section
                        _buildHeroSection(isDark),
                        SizedBox(height: 4.h),
                        
                        // Features list
                        _buildFeaturesList(),
                        SizedBox(height: 4.h),
                        
                        // Pricing options
                        _buildPricingOptions(),
                        SizedBox(height: 3.h),
                        
                        // Store status info
                        if (!FeatureFlags.enableIAP) _buildStoreStatusInfo(),
                        
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _restorePurchases,
            child: Text(
              'Restore',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? AppTheme.accentDark : AppTheme.accentLight,
                (isDark ? AppTheme.accentDark : AppTheme.accentLight)
                    .withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: CustomIconWidget(
            iconName: 'star',
            color: Colors.white,
            size: 48,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Unlock Premium',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Get unlimited access to all features\nand sync across all your devices',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: _premiumFeatures.map((feature) {
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: feature['icon'],
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      feature['description'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingOptions() {
    return Consumer<IAPService>(
      builder: (context, iapService, child) {
        final products = iapService.products;
        
        if (products.isEmpty) {
          return _buildFallbackPricing();
        }
        
        return Column(
          children: products.map((product) {
            final isLoading = _isLoading && _selectedProductId == product.id;
            
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 2.h),
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _purchaseProduct(product.id),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(4.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        children: [
                          Text(
                            product.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            product.price,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (product.isLifetime) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              'Best Value - One Time Payment',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFallbackPricing() {
    return Column(
      children: [
        _buildPricingCard(
          title: 'Monthly Plan',
          price: IAPService.monthlyPrice,
          subtitle: 'Cancel anytime',
          onTap: () => _purchaseProduct(IAPService.monthlyProductId),
        ),
        SizedBox(height: 2.h),
        _buildPricingCard(
          title: 'Lifetime Plan',
          price: IAPService.lifetimePrice,
          subtitle: 'Best Value - One Time Payment',
          onTap: () => _purchaseProduct(IAPService.lifetimeProductId),
          isRecommended: true,
        ),
      ],
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String subtitle,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: isRecommended 
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(4.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading && _selectedProductId?.contains(title.toLowerCase()) == true
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
                children: [
                  if (isRecommended) ...[
                    Text(
                      'RECOMMENDED',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStoreStatusInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'info',
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            'Development Mode',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Store purchases are simulated for testing. The app builds without store configuration.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
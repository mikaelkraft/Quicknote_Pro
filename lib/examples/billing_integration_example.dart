// Example: Complete RevenueCat & Paystack Integration Usage
// This file demonstrates how to integrate the billing system into a Flutter app

import 'package:flutter/material.dart';
import 'package:quicknote_pro/services/billing/unified_billing_service.dart';
import 'package:quicknote_pro/constants/product_ids.dart';
import 'package:quicknote_pro/constants/feature_flags.dart';

class BillingIntegrationExample extends StatefulWidget {
  const BillingIntegrationExample({Key? key}) : super(key: key);

  @override
  State<BillingIntegrationExample> createState() => _BillingIntegrationExampleState();
}

class _BillingIntegrationExampleState extends State<BillingIntegrationExample> {
  final UnifiedBillingService _billingService = UnifiedBillingService.instance;
  bool _isInitialized = false;
  bool _hasPremiumAccess = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeBilling();
  }

  /// Initialize the billing system
  Future<void> _initializeBilling() async {
    try {
      // Initialize with current user ID
      await _billingService.initialize(userId: 'user_123');
      
      setState(() {
        _isInitialized = true;
        _hasPremiumAccess = _billingService.hasPremiumAccess;
      });
      
      print('✅ Billing initialized successfully');
      print('🎯 Preferred provider: ${_billingService.preferredProvider.name}');
      print('💎 Has premium access: $_hasPremiumAccess');
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize billing: $e';
      });
      print('❌ Billing initialization failed: $e');
    }
  }

  /// Purchase Premium Monthly subscription
  Future<void> _purchasePremiumMonthly() async {
    if (!_isInitialized) return;

    try {
      setState(() {
        _errorMessage = null;
      });

      print('🛒 Starting purchase: ${ProductIds.premiumMonthly}');
      
      final result = await _billingService.purchaseProduct(
        productId: ProductIds.premiumMonthly,
        userEmail: 'user@example.com', // Required for Paystack
      );

      if (result.success) {
        if (result.provider == BillingProvider.paystack) {
          // Handle Paystack web checkout
          final checkoutUrl = result.metadata?['checkout_url'] as String?;
          if (checkoutUrl != null) {
            print('🌐 Opening Paystack checkout: $checkoutUrl');
            // In a real app, open the URL using url_launcher
            _showCheckoutDialog(checkoutUrl);
          }
        } else {
          // RevenueCat purchase completed immediately
          print('✅ RevenueCat purchase completed');
          setState(() {
            _hasPremiumAccess = _billingService.hasPremiumAccess;
          });
          _showSuccessDialog();
        }
      } else {
        setState(() {
          _errorMessage = result.error;
        });
        print('❌ Purchase failed: ${result.error}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Purchase error: $e';
      });
      print('❌ Purchase exception: $e');
    }
  }

  /// Purchase Pro Monthly subscription
  Future<void> _purchaseProMonthly() async {
    if (!_isInitialized) return;

    try {
      final result = await _billingService.purchaseProduct(
        productId: ProductIds.proMonthly,
        userEmail: 'user@example.com',
      );

      if (result.success) {
        print('✅ Pro subscription purchased');
        setState(() {
          _hasPremiumAccess = _billingService.hasPremiumAccess;
        });
      }
    } catch (e) {
      print('❌ Pro purchase failed: $e');
    }
  }

  /// Purchase Premium Lifetime
  Future<void> _purchasePremiumLifetime() async {
    if (!_isInitialized) return;

    try {
      final result = await _billingService.purchaseProduct(
        productId: ProductIds.premiumLifetime,
        userEmail: 'user@example.com',
      );

      if (result.success) {
        print('✅ Premium Lifetime purchased');
        setState(() {
          _hasPremiumAccess = _billingService.hasPremiumAccess;
        });
      }
    } catch (e) {
      print('❌ Lifetime purchase failed: $e');
    }
  }

  /// Restore previous purchases
  Future<void> _restorePurchases() async {
    if (!_isInitialized) return;

    try {
      print('🔄 Restoring purchases...');
      
      final result = await _billingService.restorePurchases();
      
      if (result.success) {
        setState(() {
          _hasPremiumAccess = _billingService.hasPremiumAccess;
        });
        print('✅ Purchases restored successfully');
        _showRestoreSuccessDialog();
      } else {
        print('❌ Restore failed: ${result.error}');
        setState(() {
          _errorMessage = result.error;
        });
      }
    } catch (e) {
      print('❌ Restore exception: $e');
    }
  }

  /// Show checkout dialog for web payments
  void _showCheckoutDialog(String checkoutUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You will be redirected to complete your payment.'),
            const SizedBox(height: 16),
            Text('Checkout URL: $checkoutUrl'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, use url_launcher to open the URL
              print('Opening URL: $checkoutUrl');
            },
            child: const Text('Open Checkout'),
          ),
        ],
      ),
    );
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Successful! 🎉'),
        content: const Text('Thank you for your purchase. You now have premium access!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Show restore success dialog
  void _showRestoreSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchases Restored! ✅'),
        content: const Text('Your previous purchases have been restored.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Integration Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Initialized: ${_isInitialized ? '✅' : '❌'}'),
                    Text('Premium Access: ${_hasPremiumAccess ? '💎' : '🆓'}'),
                    Text('Provider: ${_billingService.preferredProvider.name}'),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Feature Flags Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feature Flags',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('RevenueCat: ${FeatureFlags.revenueCatEnabled ? '✅' : '❌'}'),
                    Text('Paystack: ${FeatureFlags.paystackEnabled ? '✅' : '❌'}'),
                    Text('Web Checkout: ${FeatureFlags.webCheckoutEnabled ? '✅' : '❌'}'),
                    Text('Mock Purchases: ${FeatureFlags.mockPurchasesEnabled ? '✅' : '❌'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Purchase Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Products',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _isInitialized ? _purchasePremiumMonthly : null,
                      child: const Text('Premium Monthly - \$0.99'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ElevatedButton(
                      onPressed: _isInitialized ? _purchaseProMonthly : null,
                      child: const Text('Pro Monthly - \$1.99'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ElevatedButton(
                      onPressed: _isInitialized ? _purchasePremiumLifetime : null,
                      child: const Text('Premium Lifetime - \$9.99'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    OutlinedButton(
                      onPressed: _isInitialized ? _restorePurchases : null,
                      child: const Text('Restore Purchases'),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Debug Information
            if (_isInitialized) ...[
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Available Products: ${_billingService.getAvailableProducts().length}'),
                      Text('Current User ID: ${_billingService.currentUserId ?? 'None'}'),
                      Text('Loading: ${_billingService.isLoading}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Billing service cleanup happens automatically
    super.dispose();
  }
}

// Example of how to integrate with app startup
class AppInitialization {
  static Future<void> initializeBilling() async {
    try {
      print('🚀 Initializing Quicknote Pro billing...');
      
      // Initialize billing service early in app lifecycle
      final billingService = UnifiedBillingService.instance;
      await billingService.initialize(userId: 'current_user_id');
      
      print('✅ Billing initialization completed');
      
      // Check if user has premium access
      if (billingService.hasPremiumAccess) {
        print('💎 User has premium access');
        // Enable premium features
      } else {
        print('🆓 User on free tier');
        // Show upgrade prompts as needed
      }
      
    } catch (e) {
      print('❌ Billing initialization failed: $e');
      // Continue without billing features
    }
  }
}

// Example configuration for different environments
class BillingEnvironments {
  static const development = {
    'FEATURE_FLAG_REVENUECAT_ENABLED': true,
    'FEATURE_FLAG_PAYSTACK_ENABLED': true,
    'FEATURE_FLAG_WEB_CHECKOUT_ENABLED': true,
    'FEATURE_FLAG_MOCK_PURCHASES_ENABLED': true,
  };
  
  static const staging = {
    'FEATURE_FLAG_REVENUECAT_ENABLED': true,
    'FEATURE_FLAG_PAYSTACK_ENABLED': true,
    'FEATURE_FLAG_WEB_CHECKOUT_ENABLED': true,
    'FEATURE_FLAG_MOCK_PURCHASES_ENABLED': false,
  };
  
  static const production = {
    'FEATURE_FLAG_REVENUECAT_ENABLED': true,
    'FEATURE_FLAG_PAYSTACK_ENABLED': true,
    'FEATURE_FLAG_WEB_CHECKOUT_ENABLED': true,
    'FEATURE_FLAG_MOCK_PURCHASES_ENABLED': false,
  };
}
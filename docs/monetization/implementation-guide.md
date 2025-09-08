# Monetization v1 Consolidation - Implementation Guide

## Overview

This document provides a comprehensive guide to the consolidated Monetization v1 system, integrating all monetization-related components into a unified, feature-flagged, and A/B testable framework.

## Architecture Overview

### Core Components

1. **Feature Flags System** (`lib/constants/feature_flags.dart`)
   - ENV-driven configuration for all monetization features
   - Percentage-based rollout control
   - Kill switch for emergency shutdowns
   - Debug and development overrides

2. **A/B Testing Service** (`lib/services/ab_testing_service.dart`)
   - Experiment management and user assignment
   - Conversion tracking and analytics integration
   - Configurable traffic allocation
   - Statistical significance monitoring

3. **Monetization Config Manager** (`lib/services/monetization_config_manager.dart`)
   - Centralized service coordination
   - Migration management
   - Runtime configuration
   - System health monitoring

4. **Enhanced Services**
   - Analytics Service: Firebase integration with event taxonomy
   - Monetization Service: Feature flags and A/B testing integration
   - Ads Service: Smart timing with frequency caps
   - Trial Service: Enhanced trial management
   - RevenueCat Service: Subscription management and entitlements

5. **Payment Integration**
   - RevenueCat SDK for cross-platform subscription management
   - Paystack integration for African markets via Cloudflare Workers
   - Comprehensive webhook handling for payment events

## Implementation Details

### Feature Flags Integration

All monetization features are now controlled by environment variables:

```dart
// Core monetization control
FEATURE_FLAG_MONETIZATION_ENABLED=true
FEATURE_FLAG_IAP_ENABLED=true
FEATURE_FLAG_SUBSCRIPTIONS_ENABLED=true
FEATURE_FLAG_REVENUECAT_ENABLED=true

// Payment providers
FEATURE_FLAG_PAYSTACK_ENABLED=true
FEATURE_FLAG_PAYSTACK_WEBHOOKS_ENABLED=true

// Ad system control  
FEATURE_FLAG_ADS_ENABLED=true
FEATURE_FLAG_BANNER_ADS_ENABLED=true
FEATURE_FLAG_INTERSTITIAL_ADS_ENABLED=true

// Pricing and upgrades
FEATURE_FLAG_PAYWALL_ENABLED=true
FEATURE_FLAG_TRIALS_ENABLED=true
FEATURE_FLAG_COUPONS_ENABLED=true

// Rollout percentages
FEATURE_FLAG_ADS_ROLLOUT_PERCENTAGE=100
FEATURE_FLAG_PAYWALL_ROLLOUT_PERCENTAGE=100
```

### A/B Testing Framework

The system includes pre-configured experiments:

1. **Paywall Headlines**: Test different value propositions
2. **Ad Timing**: Optimize ad display timing
3. **Trial Duration**: Test optimal trial lengths
4. **Pricing Display**: Test pricing presentation formats

Usage example:
```dart
final abTesting = configManager.abTesting;
final variant = abTesting.getVariant('paywall_headline');
final parameters = abTesting.getVariantParameters('paywall_headline');

// Use variant-specific content
final headline = parameters['headline'] ?? 'Default Headline';
```

### Analytics Integration

Enhanced event tracking with comprehensive taxonomy:

```dart
// Monetization events
analytics.trackMonetizationEvent(
  MonetizationEvent.upgradePromptShown(context: 'feature_limit'),
);

// A/B testing events
analytics.trackExperimentExposure('paywall_headline', 'variant_b');

// Feature usage tracking
analytics.trackFeatureEvent(
  FeatureEvent.voiceNote('started', {'duration': 30}),
);
```

### Ads Integration

Smart ad placement with feature flag control:

```dart
final adsService = configManager.ads;

// Check if ad can be shown (respects feature flags and frequency caps)
if (adsService.canShowAd(AdPlacement.noteListBanner)) {
  final result = await adsService.requestAd(AdPlacement.noteListBanner);
  if (result.isSuccess) {
    // Show ad
  }
}
```

## Usage Guide

### Product Configuration

The application supports the following subscription products:

#### Premium Tier
- **Monthly**: `quicknote_premium_monthly` - $1.99/month
- **Annual**: `quicknote_premium_annual` - $19.99/year (17% savings)
- **Lifetime**: `quicknote_premium_lifetime` - $74.99 one-time

#### Pro Tier
- **Monthly**: `quicknote_pro_monthly` - $2.99/month
- **Annual**: `quicknote_pro_annual` - $29.99/year (17% savings)
- **Lifetime**: `quicknote_pro_lifetime` - $114.99 one-time

#### Enterprise Tier
- **Monthly**: `quicknote_enterprise_monthly` - $2.00/user/month
- **Annual**: `quicknote_enterprise_annual` - $20.00/user/year (17% savings)

Product IDs and pricing are centralized in `lib/constants/product_ids.dart` and must match platform configurations (App Store, Google Play, Paystack).

### RevenueCat Integration

```dart
// Initialize RevenueCat service
final revenueCatService = context.read<MonetizationService>().revenueCatService;

// Check subscription status
final tier = revenueCatService.getCurrentTier();
final hasFeature = revenueCatService.hasFeatureAccess('premium_features');

// Purchase a product
final success = await revenueCatService.purchaseProduct('quicknote_premium_annual');

// Restore purchases
await revenueCatService.restorePurchases();
```

### Initialization

```dart
import 'package:quicknote_pro/services/monetization_config_manager.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MonetizationConfigManager _configManager = MonetizationConfigManager();

  @override
  void initState() {
    super.initState();
    _initializeMonetization();
  }

  Future<void> _initializeMonetization() async {
    try {
      await _configManager.initialize();
      setState(() {
        // Update UI when initialization complete
      });
    } catch (e) {
      // Handle initialization error
      print('Monetization initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _configManager,
      child: MaterialApp(
        // Your app configuration
      ),
    );
  }
}
```

### Feature Gating

```dart
import 'package:quicknote_pro/constants/feature_flags.dart';

class VoiceNoteButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final configManager = context.read<MonetizationConfigManager>();
    final monetization = configManager.monetization;

    return IconButton(
      onPressed: () {
        if (monetization.canUseFeature(FeatureType.voiceNoteRecording)) {
          // Allow feature usage
          _startVoiceRecording();
        } else {
          // Show upgrade prompt
          _showUpgradePrompt(context);
        }
      },
      icon: Icon(Icons.mic),
    );
  }
}
```

### A/B Testing

```dart
class PaywallScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final configManager = context.read<MonetizationConfigManager>();
    final abTesting = configManager.abTesting;
    
    // Get variant-specific parameters
    final parameters = abTesting.getVariantParameters('paywall_headline');
    final headline = parameters['headline'] ?? 'Upgrade to Premium';
    final subtitle = parameters['subtitle'] ?? 'Unlock all features';

    return Scaffold(
      body: Column(
        children: [
          Text(headline, style: Theme.of(context).textTheme.headline4),
          Text(subtitle, style: Theme.of(context).textTheme.subtitle1),
          // Rest of paywall UI
        ],
      ),
    );
  }
}
```

### Debug and Testing

```dart
// In debug mode, override features for testing
if (kDebugMode) {
  final configManager = MonetizationConfigManager();
  await configManager.initialize();
  
  // Override specific features
  configManager.overrideFeature('premium_themes_enabled', true);
  configManager.overrideFeature('ads_enabled', false);
  
  // Force A/B test variant
  configManager.abTesting.forceVariant('paywall_headline', 'benefit_focused');
}
```

## Migration Strategy

### Backwards Compatibility

The system maintains compatibility with existing code through:

1. **Wrapper Methods**: Existing APIs delegate to new implementations
2. **Data Migration**: Automatic migration of legacy storage keys
3. **Graceful Degradation**: Fallback to safe defaults if new systems fail

### Migration Steps

1. **Phase 1**: Deploy feature flags (gradual rollout)
2. **Phase 2**: Enable A/B testing infrastructure
3. **Phase 3**: Migrate services to use feature flags
4. **Phase 4**: Full data consolidation
5. **Phase 5**: Remove legacy code

See `docs/monetization/migration-plan.md` for detailed migration procedures.

## Monitoring and Rollout

### Key Metrics

- **Technical**: Error rates, response times, availability
- **Business**: Conversion rates, revenue per user, trial conversions
- **User Experience**: Session length, feature usage, app ratings

### Rollout Strategy

1. **Canary** (1% users, 3 days)
2. **Limited** (10% users, 1 week)
3. **Staged** (50% users, 1 week)
4. **Full** (100% users, ongoing)

See `docs/monetization/rollout-plan.md` for detailed rollout procedures.

## Testing

### Unit Tests

```bash
# Run feature flags tests
flutter test test/constants/feature_flags_test.dart

# Run A/B testing tests  
flutter test test/services/ab_testing_service_test.dart

# Run integration tests
flutter test test/integration/monetization_integration_test.dart
```

### Integration Testing

The system includes comprehensive integration tests covering:
- Service initialization and coordination
- Feature flag integration
- A/B testing workflows
- Analytics event tracking
- Error handling and rollback scenarios

## Environment Configuration

### Development
```env
FEATURE_FLAG_MONETIZATION_ENABLED=true
FEATURE_FLAG_DEBUG_MONETIZATION_ENABLED=true
FEATURE_FLAG_MOCK_PURCHASES_ENABLED=true
FEATURE_FLAG_BYPASS_PREMIUM_CHECKS=true
```

### Staging
```env
FEATURE_FLAG_MONETIZATION_ENABLED=true
FEATURE_FLAG_AB_TESTING_ENABLED=true
FEATURE_FLAG_PAYWALL_ROLLOUT_PERCENTAGE=50
FEATURE_FLAG_ADS_ROLLOUT_PERCENTAGE=50
```

### Production
```env
FEATURE_FLAG_MONETIZATION_ENABLED=true
FEATURE_FLAG_IAP_ENABLED=true
FEATURE_FLAG_ADS_ENABLED=true
FEATURE_FLAG_PAYWALL_ENABLED=true
FEATURE_FLAG_AB_TESTING_ENABLED=true
FEATURE_FLAG_PAYWALL_ROLLOUT_PERCENTAGE=100
FEATURE_FLAG_ADS_ROLLOUT_PERCENTAGE=100
```

## Troubleshooting

### Common Issues

1. **Feature not working**: Check feature flags are enabled
2. **A/B test not running**: Verify experiment is active and user is assigned
3. **Analytics not tracking**: Ensure Firebase is properly configured
4. **Performance issues**: Check rollout percentages and scale infrastructure

### Debug Tools

```dart
// Get system health status
final health = configManager.getSystemHealth();
print('System Health: $health');

// Export configuration for debugging
final config = configManager.exportConfiguration();
print('Configuration: $config');

// Check A/B test status
final experiments = configManager.abTesting.getExperimentStatus();
print('Experiments: $experiments');
```

### Emergency Procedures

```bash
# Kill switch activation
export FEATURE_FLAG_KILL_SWITCH_ACTIVE=true

# Disable specific features
export FEATURE_FLAG_ADS_ENABLED=false
export FEATURE_FLAG_PAYWALL_ENABLED=false

# Rollback to previous version
kubectl rollout undo deployment/quicknote-app
```

## Support and Maintenance

### Team Responsibilities

- **Engineering**: System maintenance, performance optimization
- **Product**: A/B test management, feature flag configuration
- **Analytics**: Data analysis, experiment interpretation
- **DevOps**: Infrastructure scaling, monitoring setup

### Documentation

- Feature flag reference: `docs/monetization/feature-flags.md`
- A/B testing guide: `docs/monetization/ab-testing.md`
- Migration procedures: `docs/monetization/migration-plan.md`
- Rollout monitoring: `docs/monetization/rollout-plan.md`
# Premium Entitlements and Feature Gating

This implementation provides a comprehensive premium entitlement system for the QuickNote Pro app, featuring cross-platform billing integration and elegant feature gating.

## Architecture Overview

### Core Services

1. **BillingService** (`lib/services/billing/billing_service.dart`)
   - Handles Play Billing (Android) and StoreKit (iOS) integration
   - Manages product loading, purchases, and verification
   - Provides real-time purchase status updates
   - Supports both subscription and one-time purchases

2. **EntitlementService** (`lib/services/entitlement/entitlement_service.dart`)
   - Manages premium status and feature access
   - Implements feature limits for free users
   - Caches entitlements locally for offline access
   - Provides feature-specific metadata and descriptions

3. **PremiumGateWidget** (`lib/widgets/premium_gate_widget.dart`)
   - Reusable UI component for feature gating
   - Supports two modes: full upsell view and read-only overlay
   - Contextual upgrade prompts with feature-specific messaging
   - Non-intrusive integration into existing workflows

## Premium Features

### Gated Features

| Feature | Free Limit | Premium |
|---------|------------|---------|
| Voice Note Transcription | 10/month | Unlimited |
| Voice Recording Length | 60 seconds | Unlimited |
| Notes Storage | 100 notes | Unlimited |
| Drawing Tools | Basic | Advanced tools & colors |
| Drawing Layers | None | Multiple layers |
| Export Formats | TXT only | PDF, Word, HTML |
| Cloud Sync | None | Full sync |
| Advanced Search | Basic | Filters & tags |
| Custom Themes | None | Full customization |

### Product Configuration

Products are defined in `lib/constants/product_ids.dart`:

```dart
class ProductIds {
  static const String premiumMonthly = 'quicknote_premium_monthly';  // $1.00/month
  static const String premiumLifetime = 'quicknote_premium_lifetime'; // $5.00 one-time
}
```

## Usage Examples

### Basic Feature Gating

```dart
PremiumGateWidget(
  feature: PremiumFeature.voiceNoteTranscription,
  child: VoiceTranscriptionWidget(),
)
```

### Read-Only Mode

```dart
PremiumGateWidget(
  feature: PremiumFeature.advancedDrawingTools,
  showAsReadOnly: true,
  child: DrawingToolsWidget(),
)
```

### Custom Upsell Message

```dart
PremiumGateWidget(
  feature: PremiumFeature.exportFormats,
  customTitle: 'Professional Export',
  customDescription: 'Export to multiple formats',
  child: ExportWidget(),
)
```

### Entitlement Checks

```dart
final entitlementService = context.read<EntitlementService>();

// Check feature access
if (entitlementService.hasFeature(PremiumFeature.voiceNoteTranscription)) {
  // Allow transcription
}

// Check usage limits
if (entitlementService.hasReachedLimit(PremiumFeature.voiceNoteTranscription, currentUsage)) {
  // Show upgrade prompt
}
```

## Implementation Details

### Billing Integration

The billing service automatically handles:
- Product discovery from app stores
- Purchase flow initiation
- Receipt verification
- Purchase restoration
- Error handling and retry logic

### Entitlement Caching

Entitlements are cached locally using SharedPreferences:
- Enables offline feature access
- Reduces network dependency
- Improves app responsiveness
- Syncs with billing service on startup

### Feature Limits

Free tier limits are enforced in real-time:
- Voice transcriptions: 10 per month
- Recording length: 60 seconds maximum
- Note storage: 100 notes maximum
- Other features: Premium-only access

### Developer Testing

Debug builds support developer override:
```dart
// Enable premium features for testing
await entitlementService.setDeveloperOverride(true);
```

## UI Components

### Premium Gate Widget Modes

1. **Upsell View**: Full feature description with upgrade button
2. **Read-Only View**: Grayed-out feature with overlay upgrade prompt

### Contextual Messaging

Each premium feature includes:
- Feature name and description
- Benefit list for premium upgrade
- Usage limits for free users
- Contextual upgrade prompts

### Visual Design

- Consistent amber branding for premium features
- Material Design 3 components
- Responsive layout with Sizer package
- Smooth animations and transitions

## Testing

### Unit Tests

- `test/services/billing/billing_service_test.dart`
- `test/services/entitlement/entitlement_service_test.dart`
- `test/widgets/premium_gate_widget_test.dart`

### Integration Tests

- `test/integration/premium_features_integration_test.dart`

### Manual Testing

Use the example screen at `lib/presentation/premium_features_example.dart` to test all premium gate patterns.

## Platform Setup

### Android

1. Add billing permission to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

2. Configure products in Google Play Console
3. Set up signing keys for release builds

### iOS

1. Configure products in App Store Connect
2. Set up StoreKit configuration file for testing
3. Configure provisioning profiles

### Web

The billing service gracefully handles web platform limitations and can integrate with web payment providers.

## Error Handling

The system includes comprehensive error handling:
- Network connectivity issues
- App store communication failures
- Invalid product configurations
- Purchase verification failures
- User cancellation scenarios

## Security Considerations

- Purchase verification should be implemented server-side in production
- Receipt validation prevents fraudulent access
- Local entitlement caching includes integrity checks
- Sensitive operations require recent authentication

## Future Enhancements

Potential improvements:
- Server-side receipt verification
- Usage analytics and metrics
- A/B testing for pricing strategies
- Promotional pricing support
- Family sharing integration
- Subscription management UI

## Dependencies

```yaml
dependencies:
  in_app_purchase: ^3.1.13  # Cross-platform billing
  provider: ^6.1.1          # State management
  shared_preferences: ^2.2.2 # Local caching
  sizer: ^2.0.15            # Responsive design
```

## Troubleshooting

### Common Issues

1. **Products not loading**: Check product IDs match store configuration
2. **Purchase not completing**: Verify app signing and store setup
3. **Entitlements not updating**: Check network connectivity and refresh logic
4. **UI not updating**: Ensure proper Provider integration

### Debug Tools

- Use developer override for testing premium features
- Check billing service error messages
- Monitor entitlement service logs
- Verify product loading in debug mode

For additional support, see the Flutter in_app_purchase plugin documentation and platform-specific billing guides.
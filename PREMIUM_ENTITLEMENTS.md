# Premium Entitlements System

This document explains how to use the premium entitlements and feature gating system implemented in QuickNote Pro.

## Overview

The premium entitlements system provides a comprehensive solution for gating advanced features behind premium purchases, with integration for Play Billing (Android) and StoreKit (iOS).

## Core Components

### 1. EntitlementService

The `EntitlementService` manages the user's premium status and feature access.

```dart
// Check if user has premium access
bool isPremium = entitlementService.isPremium;

// Check specific feature access
bool canUseVoiceNotes = entitlementService.hasFeature(PremiumFeature.unlimitedVoiceNotes);

// Grant premium access (for testing)
await entitlementService.grantPremium();

// Revoke premium access (for testing)
await entitlementService.revokePremium();
```

### 2. FeatureGate Widget

The `FeatureGate` widget conditionally shows content based on premium access.

```dart
FeatureGate(
  feature: PremiumFeature.advancedDrawingTools,
  child: AdvancedDrawingToolsWidget(),
  fallback: BasicDrawingToolsWidget(), // Optional fallback
  showUpsell: true, // Show upsell UI for non-premium users
)
```

### 3. SimpleFeatureGate Widget

For simple cases where you want to overlay a lock on premium features.

```dart
SimpleFeatureGate(
  feature: PremiumFeature.layersSupport,
  child: LayersWidget(),
  // Automatically shows lock overlay for non-premium users
)
```

### 4. PremiumButton Widget

Button that shows upsell dialog for non-premium users.

```dart
PremiumButton(
  feature: PremiumFeature.exportFormats,
  onPressed: () => exportToPDF(),
  child: Text('Export as PDF'),
)
```

### 5. UpsellDialog

Beautiful dialog for upgrading to premium.

```dart
showDialog(
  context: context,
  builder: (context) => UpsellDialog(
    feature: PremiumFeature.cloudSync,
    onUpgrade: () {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(AppRoutes.premiumUpgrade);
    },
  ),
);
```

## Premium Features

The system defines the following premium features:

- `unlimitedVoiceNotes` - Record unlimited voice memos
- `voiceTranscription` - Automatic speech-to-text conversion
- `longerRecordings` - Record up to 1 hour per session
- `backgroundRecording` - Continue recording when app is minimized
- `advancedDrawingTools` - Professional drawing tools and brushes
- `layersSupport` - Work with multiple drawing layers
- `exportFormats` - Export to PDF, Word, and other formats
- `cloudSync` - Sync notes across all devices
- `adFree` - Clean, distraction-free interface
- `prioritySupport` - Priority customer support

## Setup

### 1. Add to Provider Tree

The entitlement service is already integrated into the main app's provider tree:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: entitlementService),
    ChangeNotifierProvider.value(value: billingService),
    // ... other providers
  ],
  child: MyApp(),
)
```

### 2. Initialize Services

Services are initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final billingService = BillingService();
  final entitlementService = EntitlementService(billingService);
  await entitlementService.initialize();
  
  runApp(MyApp(entitlementService: entitlementService));
}
```

## Usage Examples

### Basic Feature Gating

```dart
// Show different content based on premium status
FeatureGate(
  feature: PremiumFeature.unlimitedVoiceNotes,
  child: UnlimitedVoiceNotesWidget(),
  fallback: LimitedVoiceNotesWidget(limit: 10),
)
```

### Contextual Upsell

```dart
// Show upsell prompt instead of hiding content
FeatureGate(
  feature: PremiumFeature.advancedDrawingTools,
  child: AdvancedToolsWidget(),
  showUpsell: true, // Shows contextual upsell
)
```

### Button with Premium Check

```dart
PremiumButton(
  feature: PremiumFeature.exportFormats,
  onPressed: () => exportToPDF(),
  child: Row(
    children: [
      Icon(Icons.picture_as_pdf),
      Text('Export as PDF'),
    ],
  ),
)
```

### Manual Premium Check

```dart
Consumer<EntitlementService>(
  builder: (context, entitlement, _) {
    if (entitlement.hasFeature(PremiumFeature.cloudSync)) {
      return SyncStatusWidget();
    } else {
      return UpgradePromptWidget();
    }
  },
)
```

## Development & Testing

### Debug Mode

In debug builds with `ProductIds.allowDevBypass = true`, all premium features are available for development testing.

### Manual Premium Control

You can manually grant/revoke premium access for testing:

```dart
// Grant premium access
await entitlementService.grantPremium(
  productId: ProductIds.premiumLifetime,
  purchaseDate: DateTime.now(),
);

// Revoke premium access
await entitlementService.revokePremium();
```

### Testing Purchase Flow

The billing service integrates with real Play Billing/StoreKit:

```dart
final billingService = Provider.of<BillingService>(context);
await billingService.purchaseProduct(ProductIds.premiumLifetime);
```

## Platform Configuration

### Android

Configure products in Google Play Console and update `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### iOS

Configure products in App Store Connect and update `ios/Runner/Info.plist` if needed.

## Error Handling

The system gracefully handles errors:

- Network failures during purchase verification
- Store connectivity issues
- Invalid purchase states
- Service initialization failures

Errors are logged and the app continues to function with appropriate fallbacks.

## Security Considerations

- Purchase verification should be implemented server-side in production
- Local storage is used for caching but verified against stores
- All premium checks include store verification
- Debug bypasses are disabled in release builds

## Testing

Comprehensive tests are provided:

```bash
flutter test test/services/entitlements/
flutter test test/widgets/premium/
```

Tests cover:
- Entitlement service functionality
- Feature gating behavior
- Purchase flow simulation
- Widget behavior for premium/free users
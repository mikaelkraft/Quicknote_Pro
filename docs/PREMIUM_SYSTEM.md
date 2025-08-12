# Premium Entitlements & Feature Gating

This document explains how to use the premium entitlement system implemented in QuickNote Pro.

## Overview

The premium system consists of several components:

1. **PremiumService** - Manages billing and subscription state
2. **FeatureGate** - Static utility for checking premium features
3. **UpsellWidget** - Contextual upgrade prompts
4. **FeatureExamples** - Example implementations

## Quick Start

### 1. Check Premium Status

```dart
// In your widget
Consumer<PremiumService>(
  builder: (context, premiumService, child) {
    if (premiumService.isPremium) {
      return PremiumFeatureWidget();
    } else {
      return FreeVersionWidget();
    }
  },
)
```

### 2. Gate a Feature

```dart
// Check if user can use a feature
final canUseFeature = FeatureGate.canRecordVoiceNote(
  userVoiceNotesCount, 
  premiumService.isPremium
);

if (!canUseFeature) {
  // Show upsell or limit message
  return UpsellWidgets.voiceNotes();
}
```

### 3. Show Contextual Upsell

```dart
// Use pre-built upsell widgets
UpsellWidgets.voiceNotes(
  onDismiss: () => setState(() => showUpsell = false),
)

// Or create custom upsell
ContextualUpsellWidget(
  featureName: 'custom feature',
  title: 'Custom Feature',
  subtitle: 'Description of what this unlocks',
  icon: Icons.star,
)
```

## Feature Categories

### Voice Notes
- **Free**: 10 voice notes per month, 2-minute recordings
- **Premium**: Unlimited notes, 1-hour recordings, AI transcription, background recording

```dart
// Check voice note limits
final canRecord = FeatureGate.canRecordVoiceNote(currentCount, isPremium);
final canTranscribe = FeatureGate.canTranscribeVoiceNote(isPremium);
final maxLength = FeatureGate.getMaxRecordingLength(isPremium);
```

### Drawing Tools
- **Free**: Basic tools, 1 layer
- **Premium**: Advanced tools, 10 layers, effects

```dart
// Check drawing features
final canUseAdvanced = FeatureGate.canUseAdvancedDrawingTools(isPremium);
final canUseLayers = FeatureGate.canUseLayers(requestedLayers, isPremium);
final maxLayers = FeatureGate.getMaxLayers(isPremium);
```

### Export & Cloud
- **Free**: TXT export only, local storage
- **Premium**: PDF/DOCX/MD export, cloud sync, 10GB storage

```dart
// Check export and cloud features
final canExportPDF = FeatureGate.canUseExportFormat('pdf', isPremium);
final canSync = FeatureGate.canUseCloudSync(isPremium);
final canUpload = FeatureGate.canUploadToCloud(currentUsageMB, isPremium);
```

## Purchase Flow

### 1. Navigate to Premium Screen
```dart
Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
```

### 2. Purchase a Product
```dart
final premiumService = context.read<PremiumService>();
final success = await premiumService.purchaseProduct(ProductIds.premiumLifetime);
```

### 3. Restore Purchases
```dart
await premiumService.restorePurchases();
```

## Error Handling

The system includes comprehensive error handling:

```dart
Consumer<PremiumService>(
  builder: (context, premiumService, child) {
    if (premiumService.lastError != null) {
      return ErrorWidget(premiumService.lastError!);
    }
    
    if (premiumService.isLoading) {
      return LoadingWidget();
    }
    
    return YourWidget();
  },
)
```

## Testing

### Development Mode
```dart
// Manually set premium status in debug builds
await premiumService.setDevelopmentPremiumStatus(true);
```

### Feature Gate Bypass
```dart
// Set environment variable to bypass all feature gates
// flutter run --dart-define=BYPASS_PREMIUM=true
```

### Unit Tests
```dart
// Test feature gating logic
expect(FeatureGate.canRecordVoiceNote(5, false), isTrue);
expect(FeatureGate.canRecordVoiceNote(10, false), isFalse);
expect(FeatureGate.canRecordVoiceNote(15, true), isTrue);
```

## Implementation Patterns

### 1. Feature-First Pattern
Check the feature, then show appropriate UI:

```dart
Widget buildVoiceNoteButton() {
  return Consumer<PremiumService>(
    builder: (context, premiumService, child) {
      final canRecord = FeatureGate.canRecordVoiceNote(count, premiumService.isPremium);
      
      return ElevatedButton(
        onPressed: canRecord ? _startRecording : _showUpsell,
        child: Text(canRecord ? 'Record' : 'Upgrade to Record'),
      );
    },
  );
}
```

### 2. Graceful Degradation Pattern
Show a limited version for free users:

```dart
Widget buildExportOptions() {
  return Consumer<PremiumService>(
    builder: (context, premiumService, child) {
      final formats = FeatureGate.getAvailableExportFormats(premiumService.isPremium);
      
      return Column(
        children: [
          ...formats.map((format) => ExportOption(format)),
          if (!premiumService.isPremium)
            UpsellWidgets.exportFormats(),
        ],
      );
    },
  );
}
```

### 3. Contextual Banner Pattern
Show upgrade prompts at the top of premium feature screens:

```dart
Widget buildDrawingScreen() {
  return Consumer<PremiumService>(
    builder: (context, premiumService, child) {
      return Column(
        children: [
          if (!premiumService.isPremium)
            PremiumFeatureBanner(
              message: 'Unlock advanced drawing tools with Premium',
            ),
          DrawingCanvas(),
        ],
      );
    },
  );
}
```

## Platform Configuration

### Android
- Billing permission added to AndroidManifest.xml
- Product IDs configured in Google Play Console
- Test purchases available in closed testing

### iOS
- StoreKit configuration in App Store Connect
- Product IDs must match exactly
- Sandbox testing available

## Best Practices

1. **Non-Intrusive**: Don't block core functionality completely
2. **Clear Value**: Explain what premium unlocks
3. **Contextual**: Show upsells when users try premium features
4. **Persistent**: Remember dismissal state for upsells
5. **Graceful**: Handle billing failures elegantly
6. **Testable**: Use feature flags for development
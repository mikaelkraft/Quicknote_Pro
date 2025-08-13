# Ads Integration Documentation

## Overview

QuickNote Pro includes a comprehensive ads system for the free tier that provides monetization while maintaining a great user experience. The system includes banner ads, native ads, interstitial ads, frequency capping, A/B testing, and detailed analytics.

## Architecture

### Core Components

1. **AdsService** - Central service managing all ad operations
2. **Ad Models** - Data structures for placements, instances, and analytics
3. **Ad Widgets** - UI components for displaying different ad formats
4. **Configuration** - Centralized ads configuration and settings

### Ad Formats Supported

- **Banner Ads** - Horizontal ads at top/bottom of content
- **Native Ads** - Ads that blend with app content
- **Interstitial Ads** - Full-screen ads between content transitions
- **Rewarded Video** - Video ads with rewards (future implementation)

## Implementation Guide

### 1. Service Integration

The `AdsService` is initialized in `main.dart` and provided via Provider:

```dart
// Initialize ads service
final adsService = AdsService();
await adsService.initialize();

// Add to providers
ChangeNotifierProvider.value(value: adsService),
```

### 2. Ad Placements

Define where ads appear using placement IDs:

```dart
// Available placements
AdsConfig.placementHome        // Home screen
AdsConfig.placementNoteList    // Note list view
AdsConfig.placementNoteDetails // Note details view
AdsConfig.placementSettings    // Settings screen
AdsConfig.placementSearch      // Search results
AdsConfig.placementFolders     // Folder organization
```

### 3. Adding Ads to Screens

#### Banner Ads
```dart
// Simple banner ad
const SimpleBannerAd(
  placementId: AdsConfig.placementNoteList,
  size: AdBannerSize.standard,
)

// Advanced banner ad with callbacks
BannerAdWidget(
  placementId: AdsConfig.placementHome,
  size: AdBannerSize.large,
  onAdLoaded: () => print('Ad loaded'),
  onAdClicked: () => print('Ad clicked'),
)
```

#### Native Ads
```dart
// Simple native ad
const SimpleNativeAd(
  placementId: AdsConfig.placementSettings,
  template: NativeAdTemplate.medium,
)

// Advanced native ad
NativeAdWidget(
  placementId: AdsConfig.placementHome,
  template: NativeAdTemplate.large,
  onAdClicked: () => navigateToUpgrade(),
)
```

### Interstitial Ads
```dart
// Show interstitial ad with smart timing
await SmartInterstitialHelper.showSmartInterstitial(
  context,
  AdsConfig.placementNoteList,
  isImportantTransition: true,
);

// Preload for better performance
await SmartInterstitialHelper.preloadSmartInterstitial(
  context,
  AdsConfig.placementNoteList,
);

// Automatic trigger widget
InterstitialTrigger(
  placementId: AdsConfig.placementHome,
  triggerOnInit: true,
  delaySeconds: 5,
  child: MyScreenWidget(),
)
```

### 4. Premium Integration

Disable ads when user upgrades to premium:

```dart
final adsService = context.read<AdsService>();
adsService.setPremiumUser(true);

// Track conversion
adsService.onAdConversion(adId, conversionData: {
  'type': 'premium_upgrade',
  'value': 14.99,
});
```

## Smart Interstitial Timing

The system includes intelligent interstitial ad timing to maximize revenue while respecting user experience:

### Smart Display Logic
- **Base probability**: 15% chance of showing an ad
- **Important transitions**: 25% chance (e.g., opening notes)
- **Session actions**: Requires at least 3 user actions before showing ads
- **Frequency capping**: Automatic enforcement of time-based caps
- **User behavior**: Adapts based on user interaction patterns

### Trigger Points
- Opening note editor from list (important transition)
- Navigating between major app sections
- App resume after backgrounding
- Natural content transition points

### Implementation
```dart
// Check if ad should be shown
bool shouldShow = SmartInterstitialHelper.shouldShowInterstitial(
  placementId: placementId,
  sessionActions: userActionCount,
  isImportantTransition: true,
);

// Show with smart timing
await SmartInterstitialHelper.showSmartInterstitial(
  context,
  placementId,
  isImportantTransition: true,
);
```

Ads respect frequency caps to avoid user fatigue:

- **Banner ads**: No cap (0 minutes)
- **Interstitial ads**: 30 minutes between shows
- **Native ads**: 5 minutes between shows
- **Rewarded video**: 15 minutes between shows

Session limits also apply per placement:
- Home: 10 ads per session
- Note List: 15 ads per session
- Settings: 5 ads per session

## A/B Testing

The system supports A/B testing for ad effectiveness:

```dart
// Get A/B test variant for placement
final variant = adsService.getAbTestVariant(placementId);

// Available test variants
'home_ad_position': ['top', 'bottom', 'middle']
'note_list_ad_frequency': ['every_5', 'every_10', 'every_15']
'ad_format_preference': ['banner_first', 'native_first', 'mixed']
```

## Analytics Tracking

The system tracks comprehensive analytics:

### Events Tracked
- `ad_impression` - Ad was loaded and shown
- `ad_click` - User clicked on an ad
- `ad_dismiss` - User dismissed an ad
- `ad_blocked` - Ad was blocked by user/system
- `ad_conversion` - Ad led to a conversion (e.g., upgrade)
- `ad_load_failure` - Ad failed to load
- `ad_frequency_capped` - Ad was not shown due to frequency cap

### Metrics Available
```dart
final metrics = await adsService.getMetrics(placementId);
print('CTR: ${metrics.clickThroughRate}');
print('Revenue: \$${metrics.revenue}');
print('eCPM: \$${metrics.eCPM}');
```

## Configuration

### Ad Configuration (`AdsConfig`)

Key settings in `lib/constants/ads_config.dart`:

```dart
// Master controls
static const bool adsEnabled = true;
static const bool abTestingEnabled = true;
static const bool analyticsEnabled = true;

// Fallback content
static const bool showFallbackContent = true;
static const String fallbackContentText = 'Support QuickNote Pro by upgrading to Premium!';

// Timeouts (milliseconds)
static const int bannerLoadTimeout = 10000;
static const int interstitialLoadTimeout = 15000;
```

### Placement Configuration

Each placement can be configured with:
- Supported ad formats
- Format priority order
- Session limits
- A/B testing enabled/disabled

## Error Handling

### Ad Load Failures

When ads fail to load:
1. Fallback content is shown (if enabled)
2. Analytics event is tracked
3. Retry logic with exponential backoff
4. Graceful degradation to no ads

### Network Issues

- Ads timeout after configured duration
- Failed loads don't block UI
- Offline mode disables ads automatically

## Performance Considerations

### Preloading
```dart
// Preload ads for better UX
await adsService.preloadAds([
  AdsConfig.placementHome,
  AdsConfig.placementNoteList,
]);
```

### Memory Management
- Ads are automatically cleaned up after dismissal
- Analytics data is batched and stored efficiently
- Frequency caps use minimal storage

### Battery Impact
- Ads are loaded asynchronously
- No background processing
- Minimal CPU usage for tracking

## Testing

### Unit Tests
Run the ads service tests:
```bash
flutter test test/services/ads_service_test.dart
```

### Integration Testing
Test ads in different scenarios:
- Fresh install (no previous data)
- Premium user (ads disabled)
- Network failures
- Frequency cap scenarios

### Manual Testing Checklist
- [ ] Ads load correctly in all placements
- [ ] Premium upgrade disables ads
- [ ] Frequency caps work as expected
- [ ] Analytics events are tracked
- [ ] Fallback content shows on failures
- [ ] A/B testing assigns variants

## Future Enhancements

### Planned Features
1. **Real Ad Networks** - Integration with AdMob, Meta, etc.
2. **Rewarded Videos** - Video ads with premium trial rewards
3. **Custom Campaigns** - Self-promotion of premium features
4. **Advanced Analytics** - Revenue attribution, cohort analysis
5. **Dynamic Configuration** - Remote config for ad settings

### Optimization Opportunities
1. **Machine Learning** - Personalized ad frequency
2. **Real-time Bidding** - Multiple ad network integration
3. **Contextual Ads** - Ads based on note content
4. **User Preferences** - Allow users to control ad types

## Troubleshooting

### Common Issues

**Ads not showing:**
- Check if user is premium (`adsService.isPremiumUser`)
- Verify ads are enabled (`AdsConfig.adsEnabled`)
- Check frequency caps haven't been reached
- Verify placement ID is correct

**Performance issues:**
- Reduce preloading frequency
- Check for memory leaks in ad widgets
- Optimize ad loading timeouts

**Analytics not tracking:**
- Ensure analytics are enabled (`AdsConfig.analyticsEnabled`)
- Check SharedPreferences permissions
- Verify event naming conventions

### Debug Mode

Enable debug logging for ads:
```dart
// In development builds
debugPrint('AdsService: ${message}');
```

## Compliance

### Privacy
- No personal data collection without consent
- Analytics are anonymized
- GDPR/CCPA compliant data handling

### App Store Guidelines
- Ads are clearly marked as advertisements
- No misleading or deceptive ads
- Appropriate content filtering
- Frequency capping to prevent spam

This documentation should be updated as the ads system evolves and new features are added.
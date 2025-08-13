# Ads Integration Strategy

This document outlines the advertising implementation for Quicknote Pro's monetization v1, including placement strategy, frequency capping, and user experience guidelines.

## Overview

The ads system is designed to provide non-intrusive revenue generation while maintaining a positive user experience. All ad placements include frequency caps and respect user preferences.

## Ad Placement Strategy

### Banner Ads
**Placement**: Note list screen between note items
- **Format**: Banner (320x50, 728x90)
- **Frequency**: Maximum 10 impressions per day
- **Interval**: Minimum 30 minutes between displays
- **Dismissible**: Yes
- **Reasoning**: Low-impact placement that doesn't interrupt core workflows

### Interstitial Ads
**Placement**: After completing note editing sessions
- **Format**: Full-screen interstitial
- **Frequency**: Maximum 3 impressions per day
- **Interval**: Minimum 60 minutes between displays
- **Dismissible**: No (auto-dismiss after 5 seconds)
- **Reasoning**: Natural break point in user flow

### Native Ads
**Placement**: Premium upgrade screen
- **Format**: Native content integration
- **Frequency**: Maximum 5 impressions per day
- **Interval**: Minimum 15 minutes between displays
- **Dismissible**: Yes
- **Reasoning**: Contextually relevant to premium features

### Rewarded Ads
**Placement**: Feature blocking scenarios
- **Format**: Rewarded video
- **Frequency**: Maximum 3 impressions per day
- **Interval**: Minimum 120 minutes between displays
- **Dismissible**: No (user chooses to watch)
- **Reasoning**: Provides value exchange for temporary feature access

## Frequency Capping Implementation

### Daily Limits
Each ad placement has a strict daily impression limit:
```dart
static const AdPlacement noteListBanner = AdPlacement(
  id: 'note_list_banner',
  maxDailyImpressions: 10,
  minIntervalMinutes: 30,
);
```

### Time Intervals
Minimum time between ad displays prevents ad fatigue:
- Banner ads: 30 minutes
- Interstitial ads: 60 minutes  
- Native ads: 15 minutes
- Rewarded ads: 120 minutes

### User Behavior Considerations
- New users see fewer ads in first 7 days
- High-engagement users have slightly higher limits
- Users approaching premium upgrade see more native ads
- Failed ad loads don't count toward impression limits

## Ad Formats and Providers

### Supported Formats
1. **Banner Ads** (320x50, 728x90)
   - Displayed at natural content breaks
   - Always dismissible with clear close button
   - Animate in/out smoothly

2. **Interstitial Ads** (Full screen)
   - Shown at task completion points
   - Auto-dismiss after 5 seconds
   - Can be skipped after 3 seconds

3. **Native Ads** (Content integration)
   - Match app design language
   - Clearly labeled as advertisements
   - Blend with premium feature suggestions

4. **Rewarded Video** (Full screen video)
   - User-initiated for benefit exchange
   - Clear value proposition before viewing
   - Immediate reward delivery after completion

### Provider Integration
The ad service supports multiple providers with fallback:
```dart
// Provider priority: Primary -> Secondary -> House ads
final adProviders = ['google_admob', 'unity_ads', 'house_ads'];
```

## User Experience Guidelines

### Non-Intrusive Principles
- Ads never interrupt active editing or creation
- All placements respect natural user flow breaks
- Clear visual distinction between ads and app content
- Smooth animations for ad appearance/dismissal

### Accessibility Considerations
- All ads meet WCAG 2.1 AA accessibility standards
- Screen reader compatible ad labels
- High contrast mode support
- Touch target size compliance (minimum 44pt)

### Performance Impact
- Ads load asynchronously to avoid blocking UI
- Image optimization for fast display
- Graceful degradation for slow connections
- Minimal impact on app launch time

## Premium User Experience

### Ad-Free Promise
Premium users never see advertisements:
```dart
Future<bool> canShowAd(String placementId) async {
  // Premium users don't see ads
  if (_isPremiumUser) return false;
  // ... frequency cap checks
}
```

### Upgrade Incentives
Free users see clear value proposition:
- "Remove ads with Premium" messaging
- Progressive ad frequency as limits approach
- Rewarded ad options for temporary ad-free periods

## Analytics and Optimization

### Key Metrics
- **Fill Rate**: Percentage of ad requests successfully filled
- **Click-Through Rate (CTR)**: User engagement with advertisements  
- **Dismissal Rate**: How often users dismiss ads
- **Revenue per Impression (RPI)**: Monetization effectiveness
- **User Retention Impact**: Effect of ads on user engagement

### A/B Testing Framework
- Test different placement positions
- Experiment with frequency cap variations
- Optimize ad format mix
- Measure impact on premium conversion

### Performance Monitoring
```dart
// Track ad performance metrics
await AdService().getAdMetrics(); // Returns CTR, dismissal rate, etc.
await AnalyticsService().trackAdEvent('ad_displayed', ...);
```

## Implementation Details

### Ad Request Flow
1. Check if user is premium (skip if yes)
2. Validate placement frequency caps
3. Check minimum interval since last ad
4. Request ad from provider with fallback
5. Track impression and analytics
6. Display with appropriate animations

### Error Handling
- Graceful fallback when ads fail to load
- No blocking of core app functionality
- User-friendly error states
- Automatic retry with exponential backoff

### Data Privacy
- No personally identifiable information in ad requests
- Respect user privacy settings and opt-outs
- GDPR/CCPA compliant consent handling
- Anonymous targeting based on app usage patterns

## Monetization Strategy

### Revenue Optimization
- Dynamic ad placement based on user behavior
- Higher-value ads for engaged users
- Seasonal campaign optimization
- Geographic targeting where appropriate

### Premium Conversion
- Strategic ad placement to encourage upgrades
- "Remove ads" as key premium benefit
- Temporary ad-free rewards for engagement
- Clear premium value proposition

## Testing and Quality Assurance

### Ad Quality Standards
- All ads reviewed for content appropriateness
- Brand safety filtering
- No intrusive or misleading advertisements
- Regular audit of ad creative content

### Technical Testing
- Ad loading performance testing
- Cross-platform compatibility verification
- Network failure scenario testing
- Memory usage optimization

### User Feedback Integration
- In-app feedback for ad quality
- Support for ad-related user complaints
- Regular review of user sentiment metrics
- Responsive adjustments based on feedback

## Future Enhancements

- **Smart Placement**: ML-based optimal timing prediction
- **Contextual Targeting**: Content-aware ad selection
- **Interactive Formats**: Playable ads and rich media
- **Cross-Platform Sync**: Frequency capping across devices
- **Real-Time Bidding**: Programmatic ad optimization
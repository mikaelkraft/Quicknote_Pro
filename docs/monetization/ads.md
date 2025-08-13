# Advertising Strategy

This document outlines the advertising implementation for Quicknote Pro, focusing on contextual, non-intrusive ad placements that respect the user experience.

## Ad Placement Strategy

### Core Principles
- **Contextual Relevance**: Ads should be related to productivity, creativity, or note-taking
- **Non-Intrusive**: Never interrupt active note creation or editing
- **Value-Added**: Ads should provide potential value to users
- **Respectful**: Honor user preferences and subscription status

### Primary Ad Placements

#### 1. Note List Interstitial
**Location**: Between note items in the main note list
**Format**: Native card format
**Frequency**: Maximum 1 per 10 notes
**Content**: Productivity tools, writing apps, educational content

```
┌─────────────────────┐
│ My Meeting Notes    │
├─────────────────────┤
│ Shopping List       │
├─────────────────────┤
│ [SPONSORED]         │
│ Productivity App    │
│ "Boost your focus"  │
├─────────────────────┤
│ Project Ideas       │
└─────────────────────┘
```

#### 2. Settings Page Banner
**Location**: Top of settings screen
**Format**: Banner (320x50 or 320x100)
**Frequency**: Static placement
**Content**: Pro upgrade, complementary apps, productivity services

#### 3. Export/Share Interstitial
**Location**: After successful note export (free users only)
**Format**: Full-screen interstitial with skip option
**Frequency**: Maximum 1 per day
**Content**: Cloud storage services, PDF tools, collaboration apps

#### 4. Search Results Bottom
**Location**: Below search results (when >5 results)
**Format**: Native search result format
**Frequency**: 1 per search session
**Content**: Note-taking tips, organization tools, related apps

### Secondary Ad Placements

#### 5. Onboarding Flow
**Location**: Between onboarding steps (step 3 of 5)
**Format**: Native tutorial card
**Frequency**: Once per user
**Content**: Getting started guides, productivity tips

#### 6. Empty State Screens
**Location**: When no notes exist in a folder
**Format**: Helpful tip with subtle ad integration
**Frequency**: Static placement
**Content**: Note-taking best practices, template suggestions

## Ad Formats

### Native Cards
- Match app's design language
- Clear "Sponsored" labeling
- Smooth animations consistent with app
- Tap-to-expand for more information

### Banner Ads
- Standard IAB sizes (320x50, 320x100, 300x250)
- Respect dark/light theme
- Non-animated for better performance
- Clear close button where appropriate

### Interstitial Ads
- Full-screen with prominent skip button
- 5-second minimum display time
- Smooth transitions in/out
- Never during active note editing

### Video Ads (Premium Feature)
- Rewarded video for temporary pro features
- 15-30 second videos maximum
- User-initiated only
- Clear value proposition

## Frequency Capping

### Global Limits
- Maximum 3 ad impressions per session
- Maximum 10 ad impressions per day
- Minimum 30-second gap between ads
- No ads during first 5 minutes of session

### Placement-Specific Limits
- **Note List**: 1 per 10 notes scrolled
- **Settings**: 1 static placement
- **Export**: 1 per day maximum
- **Search**: 1 per search session
- **Onboarding**: 1 lifetime per user

### User Behavior Adaptation
- Reduce frequency for highly engaged users
- Increase frequency for users showing conversion intent
- Pause ads for users who recently saw paywall
- Disable ads for recent subscription attempts

## Ad Content Guidelines

### Approved Categories
- Productivity and organization tools
- Educational platforms and courses
- Writing and creativity software
- Cloud storage and backup services
- Hardware (tablets, styluses, keyboards)
- Books and digital publications

### Prohibited Categories
- Adult content
- Gambling and betting
- Misleading health claims
- Cryptocurrency and trading
- Competitive note-taking apps
- Intrusive system utilities

### Quality Standards
- High-resolution creative assets
- Professional copywriting
- Clear call-to-action
- Transparent pricing information
- Verified advertiser credentials

## Implementation Architecture

### Ad Network Integration
```dart
class AdService {
  // Initialize ad networks
  static Future<void> initialize() async {
    await GoogleMobileAds.instance.initialize();
    await FacebookAudienceNetwork.initialize();
  }
  
  // Load contextual ads
  static Future<NativeAd?> loadNativeAd(String placement) async {
    final adRequest = AdRequest(
      keywords: ['productivity', 'notes', 'organization'],
      contentUrl: 'quicknote-pro://notes',
    );
    
    // Return native ad with proper error handling
  }
}
```

### Ad Mediation
- **Primary**: Google AdMob (highest fill rate)
- **Secondary**: Facebook Audience Network
- **Fallback**: House ads promoting pro features
- **Waterfall**: Optimize by eCPM and fill rate

### Revenue Optimization
- A/B testing for ad placement effectiveness
- Dynamic frequency adjustment based on engagement
- Seasonal campaign optimization
- User segment targeting (engagement level, subscription status)

## User Experience Guidelines

### Loading States
- Skeleton screens while ads load
- Graceful fallback for failed ad loads
- No layout shift when ads appear
- Smooth placeholder transitions

### User Controls
- "Why this ad?" information button
- Easy ad dismissal where appropriate
- Feedback mechanism for inappropriate ads
- Opt-out option in settings (with pro upgrade prompt)

### Performance Considerations
- Lazy loading for off-screen ads
- Image optimization and caching
- Minimal impact on app startup time
- Battery usage monitoring

## Privacy and Compliance

### Data Collection
- Minimal user data for ad targeting
- Respect user privacy preferences
- GDPR/CCPA compliant consent flows
- Clear data usage disclosure

### Targeting Parameters
- Device type and OS version
- App usage patterns (anonymous)
- General location (country/region)
- Content categories viewed
- NO personal information or note content

## Performance Metrics

### Revenue Metrics
- **eCPM**: Effective cost per mille
- **Fill Rate**: Percentage of ad requests filled
- **CTR**: Click-through rate
- **Revenue per User**: Ad revenue divided by active users

### User Experience Metrics
- **Session Length Impact**: Before/after ad implementation
- **Retention Impact**: User retention with/without ads
- **Conversion Impact**: Effect on pro upgrade conversion
- **User Satisfaction**: Feedback scores and ratings

### Optimization Targets
- eCPM >$2.00 for tier-1 markets
- Fill rate >85% across all placements
- <5% impact on session length
- <2% impact on retention rates

## Integration Guide

### Phase 1: Foundation
1. Implement ad service architecture
2. Add basic native ad placements
3. Implement frequency capping
4. Add user controls and privacy options

### Phase 2: Optimization
1. A/B test placement effectiveness
2. Implement advanced targeting
3. Add performance monitoring
4. Optimize based on user feedback

### Phase 3: Advanced Features
1. Rewarded video integration
2. Dynamic frequency adjustment
3. Seasonal campaign support
4. Advanced analytics integration
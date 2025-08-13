# Ads Integration Specification

This document defines the ad integration system for Quicknote Pro, including placement strategies, formats, and frequency controls.

## Overview

The ads system provides non-intrusive monetization through strategic ad placements with user-friendly frequency caps and dismissal options.

## Ad Placements

### 1. Note List Banner (`noteListBanner`)
- **Location**: Bottom of the notes list screen
- **Format**: Banner (320x50)
- **Frequency**: Maximum 20 per day, 5-minute intervals
- **Context**: Displayed while browsing notes
- **Dismissible**: Yes (collapses for session)

### 2. Note Creation Interstitial (`noteCreationInterstitial`)
- **Location**: After creating 5+ notes in a session
- **Format**: Interstitial (fullscreen)
- **Frequency**: Maximum 3 per day, 30-minute intervals
- **Context**: Between note creation flows
- **Dismissible**: Yes (skip after 5 seconds)

### 3. Settings Banner (`settingsBanner`)
- **Location**: Top of settings screen
- **Format**: Banner (320x100)
- **Frequency**: Maximum 10 per day, 10-minute intervals
- **Context**: While configuring app settings
- **Dismissible**: Yes (permanent for session)

### 4. Premium Prompt Interstitial (`premiumPromptInterstitial`)
- **Location**: Before showing premium upgrade prompts
- **Format**: Interstitial (fullscreen)
- **Frequency**: Maximum 2 per day, 1-hour intervals
- **Context**: When user hits feature limits
- **Dismissible**: Yes (with upgrade option)

### 5. Feature Discovery Native (`featureDiscoveryNative`)
- **Location**: Within feature onboarding flows
- **Format**: Native (contextual)
- **Frequency**: Maximum 5 per day, 15-minute intervals
- **Context**: During feature introduction
- **Dismissible**: Yes (inline close)

## Ad Formats

### Banner Ads
- **Sizes**: 320x50, 320x100, 728x90 (tablet)
- **Placement**: Top/bottom of screens
- **Behavior**: Fixed position, non-overlapping content
- **Auto-refresh**: Every 60 seconds when visible

### Interstitial Ads
- **Size**: Full screen (device dependent)
- **Timing**: Natural break points in user flow
- **Duration**: Dismissible after 5 seconds
- **Frequency**: Strict limits to prevent annoyance

### Native Ads
- **Integration**: Matches app design and content
- **Placement**: Within content flows
- **Labeling**: Clear "Advertisement" marking
- **Interaction**: Follows platform guidelines

## Frequency Capping

### Daily Limits
Each placement has individual daily limits:
- Banner ads: 10-20 impressions
- Interstitial ads: 2-3 impressions
- Native ads: 5 impressions

### Time Intervals
Minimum time between ad displays:
- Banner: 5-10 minutes
- Interstitial: 30-60 minutes
- Native: 15 minutes

### Session Management
- Track ads shown per session
- Reset counters daily at midnight
- Respect user dismissal preferences
- Pause ads during premium trials

## User Experience Guidelines

### Non-Intrusive Design
- Ads clearly labeled as advertisements
- Easy dismissal options for all formats
- No fake close buttons or misleading content
- Respect user's content creation flow

### Contextual Relevance
- Prefer productivity and tech-related ads
- Avoid competing note-taking apps
- Filter inappropriate content categories
- Prioritize user value over revenue

### Performance Considerations
- Lazy load ad content
- Cache ads for offline scenarios
- Minimize battery and data usage
- Fast loading times (<2 seconds)

## Premium User Handling

### Ad-Free Experience
- No ads for premium/pro subscribers
- Immediate ad removal after upgrade
- Grace period during payment processing
- Restore ad-free status after subscription restoration

### Trial Periods
- Respect free trial periods
- No ads during trial experiences
- Clear messaging about ad removal benefits
- Smooth transition between states

## Technical Implementation

### Ad SDK Integration
```dart
// Initialize ads service
final adsService = AdsService();
await adsService.initialize();

// Request ad with frequency checking
final result = await adsService.requestAd(AdPlacement.noteListBanner);
if (result.isSuccess) {
  // Display ad
  showAd(result.format, result.placement);
}

// Record user interaction
adsService.recordAdInteraction(
  AdPlacement.noteListBanner, 
  AdInteraction.clicked
);
```

### Frequency Management
- Local storage for frequency tracking
- Daily counter reset mechanism
- Cross-session persistence
- Analytics integration for monitoring

### Error Handling
- Graceful fallbacks for ad loading failures
- Network connectivity considerations
- SDK initialization error recovery
- User notification for persistent issues

## Analytics and Monitoring

### Key Metrics
- **Fill Rate**: Percentage of ad requests filled
- **CTR (Click Through Rate)**: Ad clicks / impressions
- **eCPM (Effective Cost Per Mille)**: Revenue per 1000 impressions
- **User Impact**: Session length and retention effects

### Event Tracking
All ad interactions are tracked through the analytics system:
- Ad requests and responses
- Impressions and viewability
- Clicks and conversions
- Dismissals and frequency caps

### Performance Monitoring
- Ad loading time measurement
- Error rate tracking
- Revenue attribution
- User experience impact assessment

## A/B Testing Framework

### Placement Testing
- Test different placement locations
- Measure impact on user engagement
- Optimize frequency cap settings
- Compare ad format effectiveness

### Format Experiments
- Banner vs native performance
- Size optimization tests
- Color and design variations
- Timing optimization

### Revenue Optimization
- eCPM maximization strategies
- Fill rate improvement tests
- Premium conversion impact analysis
- Long-term value trade-offs

## Compliance and Privacy

### Platform Requirements
- Follow Google AdMob guidelines
- Comply with Apple App Store policies
- Respect platform-specific ad requirements
- Maintain child safety standards

### Privacy Regulations
- GDPR consent management
- CCPA compliance for California users
- Clear privacy policy updates
- User control over data usage

### Content Filtering
- Block inappropriate content categories
- Respect regional content restrictions
- Implement brand safety measures
- Provide user reporting mechanisms

## Rollout Strategy

### Phase 1: Soft Launch
- Enable banner ads only
- 50% user rollout
- Monitor key metrics
- Gather user feedback

### Phase 2: Full Placement
- Enable all ad placements
- 100% user rollout
- Optimize frequency caps
- Fine-tune user experience

### Phase 3: Optimization
- A/B test improvements
- Revenue optimization
- Advanced targeting
- Premium conversion analysis

## Success Criteria

### Revenue Targets
- Monthly ad revenue goals
- Cost per acquisition improvement
- User lifetime value increase
- Premium conversion rate maintenance

### User Experience Metrics
- Retention rate stability
- Session length preservation
- App store rating maintenance
- User satisfaction scores

### Technical Performance
- Ad loading time < 2 seconds
- Error rate < 5%
- Fill rate > 90%
- Frequency cap compliance 100%
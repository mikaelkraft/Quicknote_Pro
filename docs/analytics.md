# Analytics and Event Taxonomy

This document defines the analytics foundation for Quicknote Pro's monetization tracking system.

## Overview

The analytics system tracks user behavior, feature usage, and monetization events to provide insights for product decisions and revenue optimization.

## Event Taxonomy

### Event Categories

1. **Monetization Events** (`monetization_*`)
   - Ad-related interactions
   - Premium upgrade flows
   - Feature limit encounters

2. **Engagement Events** (`engagement_*`)
   - Note creation and editing
   - Session tracking
   - Content sharing

3. **Feature Events** (`feature_*_*`)
   - Specific feature usage
   - Feature discovery
   - Feature completion rates

### Monetization Events

#### Ad Events
- `monetization_ad_requested`
  - Properties: `placement`, `format`
  - Triggers: When an ad is requested
  
- `monetization_ad_shown`
  - Properties: `placement`, `format`, `duration`
  - Triggers: When an ad is successfully displayed
  
- `monetization_ad_clicked`
  - Properties: `placement`, `format`, `destination`
  - Triggers: When user interacts with an ad
  
- `monetization_ad_dismissed`
  - Properties: `placement`, `format`, `method` (close/timeout)
  - Triggers: When ad is dismissed or times out

#### Premium Events
- `monetization_upgrade_prompt_shown`
  - Properties: `context`, `feature_blocked`, `user_tier`
  - Triggers: When upgrade prompt is displayed
  
- `monetization_upgrade_started`
  - Properties: `tier`, `context`, `price_point`
  - Triggers: When user initiates upgrade flow
  
- `monetization_upgrade_completed`
  - Properties: `tier`, `transaction_id`, `price_paid`
  - Triggers: When purchase is completed
  
- `monetization_upgrade_cancelled`
  - Properties: `tier`, `stage`, `reason`
  - Triggers: When user cancels upgrade process

#### Feature Limit Events
- `monetization_feature_limit_reached`
  - Properties: `feature`, `current_usage`, `limit`, `user_tier`
  - Triggers: When user hits feature usage limit

### Engagement Events

#### Core Engagement
- `engagement_session_started`
  - Properties: `app_version`, `device_type`
  - Triggers: App foreground/launch

- `engagement_session_ended`
  - Properties: `duration_seconds`, `notes_created`, `features_used`
  - Triggers: App background/close

- `engagement_note_created`
  - Properties: `note_type`, `has_media`, `folder`
  - Triggers: New note creation

- `engagement_note_edited`
  - Properties: `duration_seconds`, `characters_added`, `media_added`
  - Triggers: Note save after editing

- `engagement_note_shared`
  - Properties: `method`, `note_type`, `content_length`
  - Triggers: Note sharing action

### Feature Events

#### Voice Notes
- `feature_voice_note_started`
  - Properties: `recording_quality`, `user_tier`
  - Triggers: Voice recording starts

- `feature_voice_note_completed`
  - Properties: `duration_seconds`, `file_size`, `transcription_used`
  - Triggers: Voice recording saved

#### Drawing/Doodle
- `feature_doodle_started`
  - Properties: `canvas_size`, `user_tier`
  - Triggers: Drawing canvas opened

- `feature_doodle_tool_used`
  - Properties: `tool_type`, `is_premium_tool`
  - Triggers: Drawing tool selection

#### Sync
- `feature_sync_initiated`
  - Properties: `provider`, `note_count`, `manual`
  - Triggers: Sync process starts

- `feature_sync_completed`
  - Properties: `duration_seconds`, `notes_synced`, `errors`
  - Triggers: Sync process completes

## Key Performance Indicators (KPIs)

### Activation
- **First Value Action**: Time to first note creation
- **Feature Discovery**: Percentage of users trying voice notes, drawing
- **Setup Completion**: Cloud sync configuration rate

### Retention
- **Daily Active Users**: Users creating/editing notes daily
- **Weekly Active Users**: Users with weekly engagement
- **Feature Stickiness**: Repeated use of premium features

### Conversion
- **Upgrade Prompt CTR**: Click-through rate on upgrade prompts
- **Trial-to-Paid**: Conversion from free to premium tiers
- **Feature-to-Upgrade**: Conversion rate from feature limits to upgrades

### Revenue
- **Average Revenue Per User (ARPU)**: Monthly revenue per active user
- **Lifetime Value (LTV)**: Projected user lifetime revenue
- **Ad Revenue Per Session**: Revenue generated from ads per session

## Implementation Guidelines

### Event Properties
- Use consistent naming (snake_case)
- Include user context (tier, session_id)
- Track feature availability and restrictions
- Include performance metrics (duration, file_size)

### Privacy Compliance
- No personal data in event properties
- Use anonymized user identifiers
- Respect user opt-out preferences
- Comply with GDPR/CCPA requirements

### Data Quality
- Validate event properties before sending
- Use enums for categorical data
- Include client-side timestamps
- Implement retry logic for failed sends

## Analytics Integration

The `AnalyticsService` provides a unified interface for tracking all events:

```dart
// Track monetization events
analyticsService.trackMonetizationEvent(
  MonetizationEvent.upgradePromptShown(context: 'voice_limit_reached')
);

// Track engagement events
analyticsService.trackEngagementEvent(
  EngagementEvent.noteCreated()
);

// Track feature events
analyticsService.trackFeatureEvent(
  FeatureEvent.voiceNote('started', {'duration': 30})
);
```

## Reporting and Analysis

### Daily Reports
- User engagement metrics
- Feature usage trends
- Revenue performance
- Ad effectiveness

### Weekly Analysis
- Cohort retention analysis
- Feature adoption rates
- Conversion funnel performance
- User feedback correlation

### Monthly Reviews
- KPI trend analysis
- Pricing optimization insights
- Feature roadmap prioritization
- Revenue forecasting
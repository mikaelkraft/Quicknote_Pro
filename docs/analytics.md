# Analytics and Event Taxonomy

This document outlines the analytics implementation for Quicknote Pro's monetization v1, defining event taxonomy, implementation guidelines, and KPI alignment.

## Overview

The analytics system is designed to track user behavior across the activation, retention, and conversion funnel to power data-driven monetization decisions.

## Event Taxonomy

### Activation Events
Events that track user onboarding and initial engagement:

- `app_launched` - App startup and session initiation
- `onboarding_completed` - User completes initial setup flow
- `first_note_created` - User creates their first note
- `feature_discovered` - User interacts with key features for the first time

### Retention Events
Events that track ongoing user engagement:

- `session_started` - New user session begins
- `session_ended` - User session ends with duration metrics
- `note_created` - User creates a new note
- `note_edited` - User modifies existing note
- `note_deleted` - User removes a note
- `attachment_added` - User adds media/files to notes
- `search_performed` - User searches their notes
- `folder_created` - User organizes notes into folders

### Conversion Events
Events that track premium upgrade funnel:

- `premium_screen_viewed` - User views premium upgrade screen
- `premium_feature_blocked` - User hits free tier limitation
- `upgrade_button_tapped` - User initiates upgrade flow
- `purchase_started` - User begins payment process
- `purchase_completed` - Successful premium upgrade
- `purchase_failed` - Failed purchase attempt with error details
- `trial_started` - User begins free trial
- `subscription_cancelled` - User cancels premium subscription

### Ad Events
Events that track advertising effectiveness:

- `ad_displayed` - Ad shown to user with placement info
- `ad_clicked` - User interacts with advertisement
- `ad_dismissed` - User dismisses dismissible ad
- `ad_load_failed` - Ad fails to load with error details

### Usage Events
Events that track feature utilization:

- `voice_note_created` - User creates voice recording
- `drawing_created` - User creates drawing/doodle
- `ocr_used` - User performs text recognition
- `sync_triggered` - User syncs data to cloud
- `export_performed` - User exports notes

## Event Properties

### Standard Properties
Automatically added to all events:

- `platform` - Device platform (iOS/Android/Web)
- `app_version` - App version string
- `user_id` - Anonymous user identifier
- `session_id` - Current session identifier
- `timestamp` - Event occurrence time

### Feature-Specific Properties

#### Premium Events
- `subscription_type` - Plan type (monthly/lifetime/trial)
- `purchase_price` - Transaction amount
- `currency` - Transaction currency
- `feature_name` - Blocked feature identifier

#### Ad Events
- `ad_format` - Advertisement format (banner/interstitial/native/rewarded)
- `ad_placement` - Location identifier (note_list/editor/premium_screen)
- `ad_provider` - Ad network provider
- `impression_id` - Unique impression identifier

#### Error Properties
- `error_code` - System error code
- `error_message` - Human-readable error description

## KPI Alignment

### Activation KPIs
- **Time to First Note**: Measure `first_note_created` timestamp vs `app_launched`
- **Onboarding Completion Rate**: `onboarding_completed` / `app_launched`
- **Feature Discovery**: Unique `feature_discovered` events per user

### Retention KPIs
- **Daily Active Users**: Unique users with `session_started` events
- **Session Duration**: Average time between `session_started` and `session_ended`
- **Notes per Session**: Average `note_created` events per session
- **Return Rate**: Users with multiple sessions over time periods

### Conversion KPIs
- **Premium View Rate**: `premium_screen_viewed` / `premium_feature_blocked`
- **Upgrade Attempt Rate**: `upgrade_button_tapped` / `premium_screen_viewed`
- **Conversion Rate**: `purchase_completed` / `upgrade_button_tapped`
- **Revenue per User**: Total purchase amounts per user
- **Feature Block Impact**: Conversion rate by blocked feature type

### Ad Performance KPIs
- **Fill Rate**: `ad_displayed` / ad requests
- **Click-Through Rate**: `ad_clicked` / `ad_displayed`
- **Dismissal Rate**: `ad_dismissed` / `ad_displayed`
- **Revenue per Impression**: Ad revenue / `ad_displayed`

## Implementation Guidelines

### Event Validation
- All events must use predefined event names from `AnalyticsEvents` class
- Properties must use standardized keys from `AnalyticsProperties` class
- Events are validated before transmission to prevent data corruption

### Data Privacy
- User identifiers are anonymized and rotated periodically
- No personally identifiable information (PII) is collected
- Users can opt out of analytics collection
- Data retention follows platform guidelines (30 days local, 2 years server)

### Performance Considerations
- Events are batched and sent asynchronously to avoid UI blocking
- Local storage is limited to 1000 most recent events
- Failed transmissions are retried with exponential backoff
- Analytics service gracefully handles network failures

### Testing and Validation
- Use debug mode for real-time event validation
- Implement analytics dashboard for monitoring KPIs
- A/B test analytics implementation changes
- Regular audits of event taxonomy and property consistency

## Usage Examples

### Basic Event Tracking
```dart
// Track user action
await AnalyticsService().trackEvent(
  AnalyticsEvents.noteCreated,
  properties: {
    AnalyticsProperties.noteType: 'text',
  },
);

// Track premium feature blocking
await MonetizationService().trackFeatureBlocked('voice_note');

// Track ad interaction
await AdService().recordAdClick(impressionId);
```

### Conversion Funnel Analysis
```dart
// Get user metrics for conversion analysis
final metrics = await AnalyticsService().getUserMetrics();
final conversionRate = metrics['upgrade_attempts'] / metrics['premium_blocks_count'];
```

## Data Flow

1. **Event Generation**: User actions trigger events in app components
2. **Event Processing**: Analytics service adds standard properties and validates
3. **Local Storage**: Events stored locally for offline capability
4. **Batch Transmission**: Events sent to analytics backend in batches
5. **Analysis**: Backend processes events for real-time dashboards and reports

## Future Enhancements

- Cohort analysis for retention tracking
- Funnel analysis for conversion optimization
- A/B testing framework integration
- Real-time event streaming for immediate insights
- Machine learning for predictive analytics
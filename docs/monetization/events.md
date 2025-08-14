# Monetization Events Schema

This document defines the complete schema for monetization events tracked by Quicknote Pro. All events are implemented in `lib/services/analytics/events.dart` and follow Firebase Analytics best practices.

## Event Categories

### Ad Events

Track advertisement performance and user interaction.

#### `ad_requested`
Fired when an ad is requested from the ad network.
- **Parameters:**
  - `ad_placement` (string): Where the ad is requested (home_screen, note_editor, etc.)
  - `ad_format` (string): Banner, interstitial, rewarded, etc.
  - `ad_unit` (string): Ad unit ID

#### `ad_loaded`
Fired when an ad is successfully loaded.
- **Parameters:**
  - `ad_placement` (string): Ad placement location
  - `ad_format` (string): Ad format type
  - `ad_unit` (string): Ad unit ID
  - `ad_network` (string): Ad network provider

#### `ad_shown`
Fired when an ad is displayed to the user.
- **Parameters:**
  - `ad_placement` (string): Ad placement location
  - `ad_format` (string): Ad format type
  - `ad_unit` (string): Ad unit ID
  - `ad_network` (string): Ad network provider

#### `ad_clicked`
Fired when user clicks on an ad.
- **Parameters:**
  - `ad_placement` (string): Ad placement location
  - `ad_format` (string): Ad format type
  - `ad_unit` (string): Ad unit ID

#### `ad_closed`
Fired when user closes an ad.
- **Parameters:**
  - `ad_placement` (string): Ad placement location
  - `ad_format` (string): Ad format type

#### `ad_failed`
Fired when an ad fails to load or show.
- **Parameters:**
  - `ad_placement` (string): Ad placement location
  - `ad_format` (string): Ad format type
  - `error_code` (string): Error code from ad network
  - `error_message` (string): Error description

#### `ad_revenue`
Fired when ad revenue is recorded.
- **Parameters:**
  - `ad_placement` (string): Ad placement location
  - `ad_format` (string): Ad format type
  - `ad_revenue` (number): Revenue amount
  - `currency` (string): Currency code (USD, EUR, etc.)
  - `ad_network` (string): Ad network provider

### Upgrade/Purchase Events

Track user upgrade funnel and purchase behavior.

#### `upgrade_prompt_shown`
Fired when upgrade prompt is displayed.
- **Parameters:**
  - `upgrade_context` (string): Context where prompt appeared
  - `product_id` (string): Target product ID
  - `price_tier` (string): Premium monthly/yearly/lifetime

#### `upgrade_started`
Fired when user initiates upgrade process.
- **Parameters:**
  - `upgrade_context` (string): Where upgrade was initiated
  - `product_id` (string): Selected product ID
  - `price_tier` (string): Selected pricing tier
  - `plan_term` (string): monthly|annual|lifetime
  - `region` (string): base|africa
  - `per_user` (boolean): Whether pricing is per-user (enterprise)
  - `seats` (number): Number of seats for enterprise purchases
  - `base_price` (number): Base price before regional adjustment
  - `localized_price` (number): Final localized price

#### `upgrade_completed`
Fired when upgrade is successfully completed.
- **Parameters:**
  - `product_id` (string): Purchased product ID
  - `price_tier` (string): Purchased pricing tier
  - `payment_method` (string): Payment method used
  - `transaction_id` (string): Transaction identifier
  - `plan_term` (string): monthly|annual|lifetime
  - `region` (string): base|africa
  - `per_user` (boolean): Whether pricing is per-user (enterprise)
  - `seats` (number): Number of seats for enterprise purchases
  - `base_price` (number): Base price before regional adjustment
  - `localized_price` (number): Final price paid

**Example:**
```json
{
  "event": "upgrade_completed",
  "parameters": {
    "product_id": "premium_annual_africa",
    "price_tier": "premium",
    "payment_method": "credit_card",
    "transaction_id": "txn_abc123",
    "plan_term": "annual",
    "region": "africa",
    "per_user": false,
    "base_price": 19.99,
    "localized_price": 9.99
  }
}
```

#### `upgrade_cancelled`
Fired when user cancels upgrade process.
- **Parameters:**
  - `upgrade_context` (string): Where cancellation occurred
  - `product_id` (string): Product being purchased
  - `price_tier` (string): Selected pricing tier

#### `upgrade_restored`
Fired when user restores previous purchase.
- **Parameters:**
  - `product_id` (string): Restored product ID
  - `original_transaction_id` (string): Original transaction ID

### Feature Limit Events

Track feature usage limits and premium upselling opportunities.

#### `feature_limit_reached`
Fired when user hits a feature limit.
- **Parameters:**
  - `feature_name` (string): Limited feature name
  - `limit_type` (string): Daily, monthly, total, etc.
  - `current_usage` (number): Current usage count
  - `max_usage` (number): Maximum allowed usage

#### `feature_blocked`
Fired when premium feature is blocked for free users.
- **Parameters:**
  - `feature_name` (string): Blocked feature name
  - `upgrade_context` (string): Context of blocking

#### `premium_feature_used`
Fired when premium user uses premium feature.
- **Parameters:**
  - `feature_name` (string): Premium feature used
  - `is_premium` (boolean): User premium status

### Subscription Events

Track subscription lifecycle.

#### `subscription_started`
Fired when subscription begins.
- **Parameters:**
  - `product_id` (string): Subscription product ID
  - `subscription_type` (string): monthly, yearly, etc.
  - `period_type` (string): Billing period

#### `subscription_renewed`
Fired when subscription auto-renews.
- **Parameters:**
  - `product_id` (string): Subscription product ID
  - `renewal_date` (string): Next renewal date

#### `subscription_cancelled`
Fired when subscription is cancelled.
- **Parameters:**
  - `product_id` (string): Subscription product ID
  - `cancellation_reason` (string): Reason for cancellation

#### `subscription_expired`
Fired when subscription expires.
- **Parameters:**
  - `product_id` (string): Expired subscription product ID

### Trial Events

Track free trial usage and conversion.

#### `trial_started`
Fired when user starts free trial.
- **Parameters:**
  - `trial_type` (string): Feature trial, full premium, etc.
  - `trial_duration` (number): Trial duration in days

#### `trial_ended`
Fired when free trial expires.
- **Parameters:**
  - `trial_type` (string): Type of trial that ended
  - `trial_duration` (number): Actual trial duration

#### `trial_converted`
Fired when trial user converts to paid.
- **Parameters:**
  - `trial_type` (string): Type of trial converted
  - `conversion_rate` (number): Trial to paid conversion rate
  - `product_id` (string): Product purchased after trial

## Event Parameters

### Common Parameters

These parameters can be added to any event for additional context:

- `source` (string): Traffic source or campaign
- `session_id` (string): Current user session ID
- `user_id` (string): Unique user identifier
- `app_version` (string): Application version
- `platform` (string): iOS, Android, Web

### Ad Placement Values

Standardized placement identifiers:

- `home_screen`: Main app screen
- `note_editor`: Note editing interface
- `settings_screen`: Settings page
- `search_results`: Search results page
- `export_dialog`: Export/share dialogs
- `upgrade_prompt`: Upgrade prompts
- `interstitial`: Full-screen interstitial
- `banner`: Banner ad space
- `rewarded`: Rewarded video ads

### Feature Names

Standardized feature identifiers:

- `note_creation`: Creating new notes
- `cloud_sync`: Cloud synchronization
- `voice_notes`: Voice recording
- `doodling`: Drawing/sketching
- `ocr_scanning`: Text recognition
- `export_options`: Export features
- `themes`: Theme customization
- `backup_restore`: Backup operations
- `attachments`: File attachments
- `widgets`: Home screen widgets

### Product IDs

Available product identifiers:

- `premium_monthly`: Monthly premium subscription
- `premium_yearly`: Yearly premium subscription
- `premium_lifetime`: Lifetime premium purchase
- `ad_removal`: Remove ads only
- `cloud_storage`: Cloud storage upgrade

## Implementation Example

```dart
import 'package:quicknote_pro/core/app_export.dart';

// Track ad shown
analytics.logEvent(
  MonetizationEvents.adShown,
  MonetizationEventHelpers.adEventParams(
    placement: AdPlacements.homeScreen,
    format: 'banner',
    network: 'admob',
  ),
);

// Track feature limit reached
analytics.logEvent(
  MonetizationEvents.featureLimitReached,
  MonetizationEventHelpers.featureLimitParams(
    featureName: FeatureNames.voiceNotes,
    limitType: 'daily',
    currentUsage: 5,
    maxUsage: 5,
    isPremium: false,
  ),
);

// Track upgrade completion
analytics.logEvent(
  MonetizationEvents.upgradeCompleted,
  MonetizationEventHelpers.upgradeEventParams(
    context: 'feature_limit',
    productId: ProductIds.premiumMonthly,
    priceTier: 'monthly',
    transactionId: 'txn_123456',
  ),
);
```

## Best Practices

1. **Consistent Naming**: Use constants from `events.dart` to ensure consistent event names
2. **Parameter Validation**: Filter out null values before logging events
3. **Context Addition**: Add context parameters for better analysis
4. **Error Handling**: Handle Firebase Analytics errors gracefully
5. **Privacy Compliance**: Avoid logging PII (personally identifiable information)
6. **Performance**: Batch events when possible to reduce overhead

## Analytics Dashboard Setup

After implementing these events, set up Firebase Analytics dashboards to track:

1. **Ad Performance**: Revenue, CTR, fill rates by placement
2. **Upgrade Funnel**: Conversion rates from prompt to completion
3. **Feature Usage**: Premium vs free feature utilization
4. **Subscription Health**: Churn, renewal rates, LTV
5. **Trial Conversion**: Trial start to paid conversion rates

## Data Privacy

All events are designed to be GDPR and privacy-compliant:

- No PII is tracked
- User IDs are anonymized
- Analytics can be disabled by users
- Events use Firebase's built-in privacy features

## Planned Enhancements

### User Locale Tracking (Future Phase)

**Status**: Planned for implementation after initial localization infrastructure is deployed.

**Objective**: Track user locale preferences to analyze monetization performance across different languages and regions.

#### Planned Parameters

All monetization events will be enhanced with the following locale-related parameters:

```dart
Map<String, dynamic> localeParams = {
  'user_locale': 'es',           // User's current app locale (en, es, fr, de)
  'device_locale': 'es_MX',      // Device system locale
  'detected_region': 'latin_america',  // Auto-detected pricing region
  'currency_preference': 'USD',   // User's preferred currency (future)
};
```

#### Enhanced Event Examples

**upgrade_completed with locale tracking**:
```dart
{
  "event": "upgrade_completed",
  "parameters": {
    // Existing parameters
    "product_id": "premium_monthly",
    "plan_term": "monthly",
    "region": "latin_america",
    "base_price": 1.29,
    "localized_price": 1.29,
    
    // NEW: Locale parameters
    "user_locale": "es",
    "device_locale": "es_MX", 
    "detected_region": "latin_america",
    "locale_changed_recently": false  // Whether user changed locale in last 24h
  }
}
```

**feature_limit_reached with locale tracking**:
```dart
{
  "event": "feature_limit_reached", 
  "parameters": {
    // Existing parameters
    "feature_name": "voice_notes",
    "current_usage": 5,
    "max_usage": 5,
    
    // NEW: Locale parameters  
    "user_locale": "fr",
    "prompt_language": "fr",  // Language of the upgrade prompt shown
    "localized_feature_name": "Transcription vocale"
  }
}
```

#### Analytics Use Cases

1. **Localization ROI**: Measure monetization lift from localized vs English-only users
2. **Regional Performance**: Compare conversion rates across regions and languages  
3. **Feature Adoption**: Track which features drive upgrades in different locales
4. **Pricing Optimization**: Analyze regional pricing effectiveness by actual user locale
5. **Localization Quality**: Identify locales with lower conversion rates (potential translation issues)

#### Implementation Plan

**Phase 1**: Infrastructure (Current)
- Deploy localization system with ARB files
- Implement LocalizationService
- Update pricing strings to use localized keys

**Phase 2**: Locale Tracking (Next Release)
- Add user_locale parameter to all monetization events
- Implement locale detection and tracking
- Update analytics dashboards for locale segmentation

**Phase 3**: Advanced Locale Analytics (Future)
- A/B testing for different translations
- Dynamic locale switching tracking
- Currency preference analysis
- Regional pricing optimization based on locale data

#### Privacy Considerations

- Locale data is not personally identifiable
- Users can opt out of analytics tracking entirely
- Locale preferences stored locally, not linked to user accounts
- Aggregate data only used for product optimization

#### Success Metrics

- Conversion rate improvement in localized markets
- Feature adoption rates by locale
- Regional pricing performance validation
- User engagement metrics across languages

**Note**: Implementation of user locale tracking is dependent on successful deployment and validation of the base localization infrastructure.
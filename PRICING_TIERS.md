# Pricing Tiers and Free Limits Documentation

This document outlines the pricing structure, feature limitations, and upgrade paths for Quicknote Pro.

## Pricing Tiers

### Free Tier
The free tier provides core note-taking functionality with reasonable limits to encourage upgrade.

**Limits:**
- **Notes**: Maximum 100 notes
- **Voice Notes**: 10 per month
- **Exports**: 5 per month  
- **Attachments**: 3 per note, max 5MB each
- **Sync**: Local storage only (no cloud sync)
- **Themes**: Standard themes only
- **Drawing**: Basic tools only
- **Ads**: Includes advertisements
- **OCR**: Not available
- **Backups**: Limited local backups

### Premium Tier
The premium tier removes all limitations and provides advanced features.

**Features:**
- **Notes**: Unlimited
- **Voice Notes**: Unlimited
- **Exports**: Unlimited
- **Attachments**: Unlimited per note, up to 100MB each
- **Sync**: Cloud sync across all devices
- **Themes**: Custom themes and personalization
- **Drawing**: Advanced tools with layers and effects
- **Ads**: Ad-free experience
- **OCR**: Text recognition from images
- **Backups**: Unlimited cloud backups and restore points

## Subscription Options

### Monthly Subscription
- **Price**: $2.99/month
- **Billing**: Recurring monthly
- **Cancellation**: Cancel anytime
- **Features**: All premium features

### Lifetime Purchase
- **Price**: $14.99 one-time
- **Billing**: Single payment
- **Savings**: 75% compared to monthly (breaks even at 5 months)
- **Features**: All premium features forever
- **Recommended**: Yes (best value)

### Free Trial
- **Duration**: 7 days
- **Features**: Full premium access
- **Requirements**: No payment method required
- **Limitations**: One trial per user
- **Auto-renewal**: No (manual upgrade required)

## Feature Gating Strategy

### Soft Limits (Gradual Introduction)
- Show usage progress bars as users approach limits
- Display gentle reminders about premium benefits
- Provide context-sensitive upgrade prompts

### Hard Limits (Enforcement Points)
- Block actions when limits are reached
- Show limit reached dialogs with upgrade options
- Maintain data integrity (never delete user content)

### Premium Feature Gates
- Cloud sync button shows "Premium Required" 
- Advanced drawing tools are grayed out with upgrade prompt
- Custom themes show preview with unlock option
- OCR feature displays premium badge

## Upgrade Messaging Strategy

### Context-Sensitive Prompts
Different messages based on which limit was reached:

**Voice Note Limit:**
- Title: "Voice Note Limit Reached"
- Message: "You've used all 10 voice notes this month. Upgrade to Premium for unlimited voice recordings!"
- CTA: "Upgrade Now"

**Export Limit:**
- Title: "Export Limit Reached" 
- Message: "You've used all 5 exports this month. Upgrade to Premium for unlimited exports!"
- CTA: "Upgrade Now"

**Note Limit:**
- Title: "Note Limit Reached"
- Message: "You've reached the 100 note limit. Upgrade to Premium for unlimited notes!"
- CTA: "Upgrade Now"

**Feature Access:**
- Title: "Premium Feature"
- Message: "This feature is available with Premium. Unlock all advanced features!"
- CTA: "Unlock Now"

### Upgrade Path Flow
1. **Limit Reached** → Show context-specific dialog
2. **Upgrade Dialog** → Present pricing options with trial
3. **Trial Option** → 7-day free trial (if not used)
4. **Purchase Flow** → Platform-specific purchase
5. **Welcome** → Premium onboarding experience

## Analytics Events

### Core Monetization Events
```typescript
enum MonetizationEvent {
  freeLimitReached,     // User hits any free tier limit
  upgradeInitiated,     // User starts upgrade process
  upgradeCompleted,     // Successful purchase
  upgradeFailed,        // Failed purchase attempt
  trialStarted,         // Free trial activated
  trialExpired,         // Trial period ended
  subscriptionExpired,  // Monthly subscription expired
  restorePurchaseAttempted, // User tries to restore
  restorePurchaseSucceeded, // Restore successful
  restorePurchaseFailed,    // Restore failed
}
```

### Event Data Structure
```json
{
  "event_name": "freeLimitReached",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "user_tier": "free",
  "subscription_type": "none",
  "feature": "voice_note",
  "source": "limit_reached",
  "session_id": "session_123",
  "platform": "android"
}
```

## Implementation Guidelines

### Limit Enforcement
- Check limits before allowing actions (proactive)
- Show usage indicators in relevant UI areas
- Graceful degradation for premium features
- Never delete user content due to limits

### User Experience
- Clear communication about limits and benefits
- Non-intrusive upgrade prompts
- Preserve user flow when possible
- Quick trial activation

### Technical Implementation
- Centralized limit checking service
- Persistent usage tracking
- Secure entitlement validation
- Offline-first design

## Future Enhancements

### Promotional Features
- **Discounts**: Seasonal pricing promotions
- **Gifting**: Allow users to gift premium subscriptions
- **Referrals**: Earn premium time for successful referrals
- **Student Discounts**: Reduced pricing for students

### Advanced Pricing
- **Team Plans**: Multi-user subscriptions
- **Business Tier**: Advanced collaboration features
- **API Access**: Developer tier with API usage

### Trial Variations
- **Extended Trials**: 14-day trials for certain user segments
- **Feature-Specific Trials**: Trial specific premium features
- **Graduated Trials**: Increasing feature access over time

## Testing Strategy

### Edge Cases
- Trial expiration handling
- Subscription renewal failures
- Network connectivity issues
- Platform store integration errors
- Data synchronization conflicts

### User Scenarios
- Heavy free tier usage
- Trial to paid conversion
- Subscription cancellation and reactivation
- Multi-device usage patterns
- Offline usage and sync

### Metrics to Monitor
- Free to trial conversion rate
- Trial to paid conversion rate
- Feature usage patterns
- Churn analysis
- Revenue per user

## Platform Considerations

### iOS App Store
- StoreKit 2 integration
- Receipt validation
- Family sharing support
- Subscription management

### Google Play Store
- Play Billing Library 5.0+
- Real-time developer notifications
- Subscription management
- Play Pass compatibility

### Web Platform
- Stripe payment processing
- Subscription management
- Tax handling
- International pricing

## Support and Edge Cases

### Purchase Issues
- Failed payment handling
- Receipt validation errors
- Platform store downtime
- Refund processing

### Account Management
- Multiple device synchronization
- Account transfer between platforms
- Subscription sharing prevention
- Data export for canceling users

### Legal Compliance
- GDPR compliance for EU users
- CCPA compliance for California
- Subscription cancellation rights
- Data retention policies

---

*This documentation should be updated as pricing strategy evolves and new features are added.*
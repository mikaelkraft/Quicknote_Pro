# Pricing Strategy

This document defines the subscription tiers, feature limitations, and pricing model for Quicknote Pro's monetization strategy.

## Subscription Tiers

### Free Tier
**Target**: New users, casual note-takers, trial users
**Price**: $0/month
**Core Value**: Full basic note-taking functionality

#### Included Features
- ✅ Unlimited text notes
- ✅ Basic image attachments (up to 5 per note)
- ✅ Voice recording (up to 2 minutes per note)
- ✅ Basic doodle tools (pen, basic colors)
- ✅ Local storage and basic search
- ✅ Export to text format
- ✅ Basic folder organization (up to 5 folders)
- ✅ Dark/light theme

#### Limitations
- 📱 Single device sync only
- ⏱️ Voice note limit: 2 minutes per recording
- 🎨 Basic doodle tools only (3 colors, 2 brush sizes)
- 📤 Export limited to text format
- 🔍 Basic search (no full-text search in images/voice)
- 📁 Maximum 5 folders
- 🎯 Contextual ads displayed

### Pro Tier
**Target**: Regular users, productivity enthusiasts, students
**Price**: $4.99/month or $49.99/year (17% savings)
**Core Value**: Enhanced productivity and cross-device sync

#### Everything in Free, Plus:
- ✅ Unlimited cloud sync across all devices
- ✅ Voice recording up to 15 minutes per note
- ✅ Voice-to-text transcription
- ✅ Advanced doodle tools (unlimited colors, 10 brush sizes, shapes)
- ✅ OCR text recognition in images
- ✅ Export to PDF, Word, Markdown
- ✅ Advanced search (full-text, voice content, OCR)
- ✅ Unlimited folders and advanced organization
- ✅ Ad-free experience
- ✅ Weekly automatic backups
- ✅ Priority email support

#### Pro Limitations
- 📱 Up to 3 devices
- 💾 1GB cloud storage
- 🔄 Basic backup (weekly)
- 🎙️ Voice transcription in English only

### Premium Tier
**Target**: Power users, professionals, content creators
**Price**: $9.99/month or $99.99/year (17% savings)
**Core Value**: Advanced features and unlimited usage

#### Everything in Pro, Plus:
- ✅ Unlimited devices and cloud storage
- ✅ Voice recording unlimited duration
- ✅ Multi-language voice transcription (20+ languages)
- ✅ Advanced doodle tools (layers, advanced brushes, vector tools)
- ✅ Collaboration features (shared notes, comments)
- ✅ Advanced export options (PowerPoint, custom templates)
- ✅ Real-time sync across all devices
- ✅ Daily automatic backups with version history
- ✅ Advanced organization (tags, nested folders, smart folders)
- ✅ API access for integrations
- ✅ Priority phone support
- ✅ Early access to beta features

### Enterprise Tier
**Target**: Teams, organizations, educational institutions
**Price**: Custom pricing starting at $4.99/user/month
**Core Value**: Team collaboration and administrative controls

#### Everything in Premium, Plus:
- ✅ Team workspace management
- ✅ Admin dashboard and user management
- ✅ Advanced sharing and permissions
- ✅ SSO integration
- ✅ Compliance features (audit logs, data residency)
- ✅ Custom branding options
- ✅ Dedicated account manager
- ✅ SLA guarantees
- ✅ Custom integrations

## Feature Limits and Restrictions

### Storage Limits
| Feature | Free | Pro | Premium | Enterprise |
|---------|------|-----|---------|------------|
| Local Storage | Unlimited | Unlimited | Unlimited | Unlimited |
| Cloud Storage | - | 1GB | Unlimited | Unlimited |
| Voice Notes | 2 min/note | 15 min/note | Unlimited | Unlimited |
| Images per Note | 5 | 20 | Unlimited | Unlimited |
| Total Notes | Unlimited | Unlimited | Unlimited | Unlimited |

### Device and Sync
| Feature | Free | Pro | Premium | Enterprise |
|---------|------|-----|---------|------------|
| Devices | 1 | 3 | Unlimited | Unlimited |
| Real-time Sync | - | ✅ | ✅ | ✅ |
| Offline Access | ✅ | ✅ | ✅ | ✅ |
| Backup Frequency | Manual | Weekly | Daily | Daily |
| Version History | - | 7 days | 30 days | 90 days |

### Advanced Features
| Feature | Free | Pro | Premium | Enterprise |
|---------|------|-----|---------|------------|
| Voice Transcription | - | ✅ (English) | ✅ (20+ langs) | ✅ (Custom) |
| OCR | - | ✅ | ✅ | ✅ |
| Advanced Doodle | - | ✅ | ✅ (Layers) | ✅ (Custom) |
| Collaboration | - | - | ✅ | ✅ (Advanced) |
| API Access | - | - | ✅ | ✅ (Extended) |

## Upgrade Paths and Incentives

### Trial Strategy
- **Free to Pro**: 14-day free trial of Pro features
- **Pro to Premium**: 7-day free trial of Premium features
- **Trial Extensions**: Additional 7 days for completing onboarding
- **Feature Trials**: 24-hour trial of specific premium features

### Upgrade Triggers
1. **Storage Limit**: Prompt when approaching cloud storage limit
2. **Device Limit**: Suggest upgrade when trying to sync 4th device
3. **Voice Limit**: Offer transcription when voice note >2 minutes
4. **Export Limit**: Promote Pro when trying to export to PDF
5. **Search Limit**: Highlight advanced search when basic search fails

### Promotional Strategies
- **Student Discount**: 50% off for verified students
- **Annual Discount**: 17% savings for annual subscriptions
- **Family Plan**: Pro for $7.99/month (up to 4 users)
- **Loyalty Discount**: 10% off after 12 months of subscription
- **Referral Program**: 1 month free for each successful referral

### Win-back Campaigns
- **Churned Users**: 3 months at 50% off to return
- **Trial Expires**: 1 additional week free + 20% off first month
- **Failed Payment**: Grace period + payment reminder sequence
- **Downgrade**: Survey + targeted offer based on downgrade reason

## Regional Pricing

### Tier 1 Markets (USD Base)
- **United States**: $4.99/$9.99
- **Canada**: CAD $6.49/CAD $12.99
- **United Kingdom**: £4.49/£8.99
- **Australia**: AUD $7.49/AUD $14.99
- **Germany**: €4.99/€9.99

### Tier 2 Markets (30% Discount)
- **Brazil**: $3.49/$6.99
- **Mexico**: $3.49/$6.99
- **Eastern Europe**: €3.49/€6.99
- **South Korea**: $3.49/$6.99

### Tier 3 Markets (50% Discount)
- **India**: $2.49/$4.99
- **Southeast Asia**: $2.49/$4.99
- **South America**: $2.49/$4.99
- **Africa**: $2.49/$4.99

### Currency Considerations
- Local payment methods support
- Regular price review (quarterly)
- Economic factor adjustments
- Competitive analysis per region

## Implementation Guidelines

### Paywall Design
```dart
class PaywallService {
  static void showFeaturePaywall(String feature, BuildContext context) {
    // Show contextual paywall based on blocked feature
    // Highlight specific benefits for the feature
    // Include trial offer and pricing information
    // Provide clear upgrade path
  }
}
```

### Feature Gating
```dart
class EntitlementService {
  static bool canUseFeature(String feature, UserTier tier) {
    switch (feature) {
      case 'voice_transcription':
        return tier.isPro || tier.isPremium;
      case 'unlimited_cloud_storage':
        return tier.isPremium;
      case 'collaboration':
        return tier.isPremium || tier.isEnterprise;
      default:
        return true; // Free features
    }
  }
}
```

### Upgrade Flow
1. **Feature Detection**: User attempts premium feature
2. **Context Explanation**: Show why feature requires upgrade
3. **Benefit Highlighting**: Emphasize value of upgrade tier
4. **Trial Offer**: Present free trial option
5. **Purchase Flow**: Native platform purchase experience
6. **Confirmation**: Welcome and feature enablement

## Metrics and KPIs

### Conversion Metrics
- **Free to Pro Conversion**: Target 8-12%
- **Pro to Premium Conversion**: Target 15-20%
- **Trial to Paid Conversion**: Target 25-35%
- **Annual vs Monthly**: Target 60% annual subscriptions

### Revenue Metrics
- **ARPU (Average Revenue Per User)**: Target $2.50/month
- **LTV (Lifetime Value)**: Target $45 per user
- **Churn Rate**: Target <5% monthly for Pro, <3% for Premium
- **MRR Growth**: Target 15% month-over-month

### Feature Adoption
- **Voice Transcription**: Track usage post-upgrade
- **Cloud Sync**: Monitor cross-device engagement
- **Advanced Export**: Measure export format preferences
- **Collaboration**: Track shared note engagement

## Getting Started

### For Developers
1. Implement subscription platform integration (RevenueCat recommended)
2. Add feature gating throughout the app
3. Create paywall UI components
4. Implement trial logic and tracking
5. Add subscription status monitoring

### For Product Managers
1. Set up conversion tracking and analytics
2. Design A/B tests for paywall effectiveness
3. Create user journey documentation
4. Plan feature rollout schedule
5. Establish success metrics and monitoring

### For Marketing
1. Create subscription landing pages
2. Design promotional materials for each tier
3. Plan launch campaigns for pricing tiers
4. Set up referral and discount systems
5. Prepare customer support materials

## Competitive Analysis

### Market Positioning
- **vs. Notion**: More focused on mobile note-taking, simpler pricing
- **vs. Evernote**: Competitive pricing with better voice features
- **vs. Apple Notes**: Advanced features justify subscription model
- **vs. OneNote**: Premium collaboration features competitive advantage

### Pricing Benchmarks
- Industry average for productivity apps: $5-12/month
- Note-taking apps average: $3-8/month
- Voice transcription services: $10-20/month
- Cloud storage services: $2-10/month

Our pricing sits comfortably in the market range while offering competitive feature sets at each tier.
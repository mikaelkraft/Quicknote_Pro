# Pricing Tiers and Monetization Strategy

This document defines the pricing structure, feature limitations, and upgrade paths for Quicknote Pro.

> 📝 Note on Localization: As of version 1.1.0, all pricing tier names, billing periods, and key feature descriptions are now localized. See [docs/localization.md](localization.md) for details on supported languages and localization keys.

## Overview

Quicknote Pro uses a freemium model with four tiers: Free, Premium, Pro, and Enterprise. Each tier provides increasing value through expanded feature access and higher usage limits.

## Pricing Structure

### Base Market Pricing (USD)

| Tier        | Monthly         | Annual (status) | Lifetime |
|-------------|-----------------|-----------------|----------|
| Free        | $0              | -               | -        |
| Premium     | $0.99           | — (hidden)      | $9.99    |
| Pro         | $1.99           | — (hidden)      | $19.99   |
| Enterprise  | $4.99/user      | — (hidden)      | -        |

Notes
- Annual plans are currently hidden (reserved for future experimentation with an expected ~20% savings framing).
- Lifetime is available for Premium and Pro only.
- Enterprise is priced per user/month and includes advanced team/security features.
- Prices shown in-app use localized currency symbols; amounts are anchored to USD.

### Regional Pricing

- Paused for now. Current base pricing ($0.99–$1.99) reduces the need for regional adjustments.
- Keep analytics support for region to inform potential future rollouts.
- The app defaults to base pricing with localized currency formatting where supported.

## Pricing Tiers

### Free Tier
Price: $0  
Target: New users and light note-takers  
Value Proposition: Core note-taking with basic features

#### Features & Limits
- Notes: 50 notes per month
- Voice Recordings: 5 recordings per month (max 2 minutes each)
- Folders: 3 folders maximum
- Attachments: 10 attachments per month (images and files)
- Drawing: Basic doodling and canvas tools
- Export: Basic text export only
- Storage & Sync: Local storage and file system access only
- Device Sync: Manual import/export between devices (local files only)
- Ads: Yes (with frequency caps)

#### Restrictions
- No advanced drawing tools (layers, premium brushes, shapes)
- No voice note transcription
- No OCR text extraction from images
- No premium export formats (PDF, DOCX, Markdown)
- No cloud sync or storage capabilities
- No automatic device sync (manual import/export only)
- No custom themes

### Premium Tier
**Price**: $0.99/month or $9.99 lifetime  
**Target**: Regular users and productivity enthusiasts  
**Value Proposition**: Unlimited core features with advanced tools

#### Features & Limits
- Notes: Unlimited
- Voice Recordings: 100 recordings per month (max 10 minutes each)
- Voice Transcription: Automatic transcription of all voice notes
- Folders: Unlimited
- Attachments: Unlimited (images and files)
- Drawing: Advanced drawing tools, layers, premium brushes, shapes
- OCR: Text extraction from images and scanned documents
- Export: All formats (PDF, DOCX, Markdown, HTML)
- Storage & Sync: Cloud sync capabilities (storage managed by your cloud provider)
- Device Sync: Automatic sync across up to 3 devices
- Themes: Custom themes and dark mode
- Ads: Completely removed

#### Additional Benefits
- Priority cloud sync with automatic device synchronization
- Email support
- Advanced canvas tools with layers
- Voice note transcription with timestamps
- OCR text extraction and search
- Professional export templates

### Pro Tier
**Price**: $1.99/month or $19.99/year
**Target**: Power users and professionals
**Value Proposition**: All features plus advanced capabilities

#### Features & Limits
- Everything in Premium
- Voice Recordings: Unlimited (max 30 minutes each)
- Analytics: Advanced usage insights and productivity metrics
- Search: Advanced search with OCR integration
- Backup: Automated backup scheduling and versioning
- Templates: Custom export templates and formatting
- Encryption: Advanced encryption options for sensitive notes
- API Access: Integration capabilities with third-party apps
- Storage & Sync: Enhanced cloud sync capabilities (storage managed by your cloud provider)
- Device Sync: Automatic sync across up to 10 devices
- Support: Phone and email priority support

#### Exclusive Features
- Advanced search with OCR
- Automated backup scheduling
- Custom export templates
- Advanced encryption options

## Feature Gating Strategy

### Soft Limits
Features that become unavailable when limits are reached:
- Note creation after monthly limit
- Voice recording after count/duration limits
- Attachment uploads after limit

### Hard Restrictions
Features completely unavailable to free users:
- Advanced drawing tools (premium brushes, shapes, layers)
- Premium export formats
- Voice note transcription
- Cloud sync and storage capabilities
- Advanced themes

### Progressive Disclosure
Features shown but locked with upgrade prompts:
- Advanced drawing tools (visible but grayed out)
- Premium export options (available in menu but require upgrade)
- Extended voice recording duration (timer shows limit)

## Upgrade Path Design

### Contextual Prompts
Upgrade prompts appear when users encounter limits:

1. Note Limit Reached
   - Message: "You've reached your monthly note limit. Upgrade to Premium for unlimited notes."
   - CTA: "Upgrade Now" / "Learn More"
   - Context: After 50th note creation attempt

2. Voice Recording Limit
   - Message: "Monthly voice recording limit reached. Premium gives you 100 recordings per month."
   - CTA: "Upgrade to Premium"
   - Context: When attempting 6th recording

3. Advanced Feature Access
   - Message: "Advanced drawing tools are available with Premium. Try risk-free for 7 days."
   - CTA: "Start Free Trial"
   - Context: When tapping locked drawing tool

### Upgrade Flow
1. Feature Context: User encounters limitation
2. Value Proposition: Clear benefit explanation
3. Pricing Display: Transparent pricing with lifetime options
4. Trial Offer: 7-day free trial for Premium, 14-day for Pro
5. Purchase Flow: Platform-native purchase process
6. Onboarding: Guide to new features after upgrade

## Free Trial Strategy

### Trial Offerings
- **Premium**: 7-day free trial
- **Pro**: 14-day free trial
- **Annual Plans**: 30-day money-back guarantee

### Trial Experience
- Full feature access during trial
- Clear trial status in app with countdown
- Smart trial extension rewards for referrals and promotions
- Gentle reminders before trial ends
- Easy cancellation process
- Smooth transition to paid or downgrade

### Trial Conversion Tactics
- Progressive feature introduction during trial
- Usage analytics to show value delivered
- Personalized upgrade recommendations based on trial usage
- Limited-time upgrade discounts with coupon system
- Contextual prompts when trial is about to expire
- Trial extension rewards through referral program

## Referral and Coupon System

### Referral Program
- Referral Codes: Unique 8-character codes (QN + 6 alphanumeric)
- Referrer Rewards: Free month of service when referral converts
- Referee Rewards: 14-day Premium trial upon signup
- Tracking: Comprehensive analytics on referral performance
- Eligibility: All users can generate referral codes

### Coupon System
- Welcome Coupons: 25% off first month for new users (WELCOME25)
- Student Discounts: 20% off (applied to eligible plan types)
- Holiday Promotions: Fixed-amount or percentage discounts
- Win-Back Campaigns: 30% off for churned users (COMEBACK30)
- Annual Incentives: If/when annual is enabled, extra months free
- Flash Sales: Time-limited promotions (e.g., 48 hours)

### Coupon Features
- Multiple Discount Types: Percentage, fixed amount, free months, trial extensions
- Smart Eligibility: New users only, existing users, upgrade-only, renewal-only
- Usage Limits: Maximum uses per coupon and per user
- Minimum Purchase: Requirements for certain high-value coupons
- Expiration Management: Automatic validation of coupon validity
- Analytics Integration: Comprehensive tracking of coupon usage and effectiveness

## Value Communication

### Benefits Matrix

| Feature | Free | Premium | Pro |
|---------|------|---------|-----|
| Monthly Notes | 50 | Unlimited | Unlimited |
| Voice Recordings | 5 (2min) | 100 (10min) | Unlimited (30min) |
| Folders | 3 | Unlimited | Unlimited |
| Advanced Drawing | ❌ | ✅ | ✅ |
| Voice Transcription | ❌ | ✅ | ✅ |
| Premium Export | ❌ | ✅ | ✅ |
| Cloud Storage | 100MB | 1GB | 10GB |
| Ads | ✅ | ❌ | ❌ |
| Analytics | ❌ | ❌ | ✅ |
| Priority Support | ❌ | ✅ | ✅ |

### Key Selling Points

#### Premium vs Free
- Remove the 50-note monthly limit
- Advanced drawing tools for visual note-taking
- Voice note transcription saves time
- Export to professional formats
- Cloud sync capabilities enabled
- Ad-free focused experience

#### Pro vs Premium
- "Unlimited voice recordings for lectures and meetings"
- "10GB storage for extensive media collections"
- "Usage analytics to optimize productivity"
- "Priority support when you need help"

## Implementation Guidelines

### Usage Tracking
```dart
// Check feature availability (includes trial access)
final canUseFeature = monetizationService.canUseFeature(FeatureType.voiceNoteRecording);

// Record feature usage
await monetizationService.recordFeatureUsage(FeatureType.voiceNoteRecording);

// Check remaining usage
final remaining = monetizationService.getRemainingUsage(FeatureType.voiceNoteRecording);

// Access retention services
final referralCode = await monetizationService.referralService.generateReferralCode(userId: 'user123');
final availableCoupons = monetizationService.couponService.getApplicableCoupons(
  currentTier: UserTier.free,
  targetTier: UserTier.premium,
  term: PlanTerm.monthly,
  userId: 'user123',
);
final trialOffered = await monetizationService.trialService.startTrial(
  TrialConfig(tier: UserTier.premium, durationDays: 7),
);
```

### Upgrade Prompts
```dart
// Check if upgrade prompt should be shown (considers trial access)
final shouldShow = monetizationService.shouldShowUpgradePrompt(
  FeatureType.advancedDrawing,
  context: 'drawing_tool_selection'
);

if (shouldShow) {
  // Show contextual upgrade prompt with trial offer
  showUpgradePrompt(FeatureType.advancedDrawing);

  // Record prompt shown
  await monetizationService.recordUpgradePromptShown();
}

// Start trial instead of immediate upgrade
final trialConfig = TrialConfig(
  tier: UserTier.premium,
  durationDays: 7,
  type: TrialType.standard,
);
await monetizationService.trialService.startTrial(trialConfig);
```

### Feature Gating
```dart
// Gate premium features (with trial support)
Widget buildDrawingTool(DrawingTool tool) {
  final isAvailable = monetizationService.isFeatureAvailable(
    FeatureType.advancedDrawing
  );

  return GestureDetector(
    onTap: isAvailable ? () => selectTool(tool) : () => showUpgradeOrTrialPrompt(),
    child: Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Stack(
        children: [
          DrawingToolIcon(tool),
          if (!isAvailable && !monetizationService.hasActiveTrial)
            Positioned(
              top: 0,
              right: 0,
              child: TrialBadge(
                onTap: () => startTrial(UserTier.premium),
              ),
            ),
        ],
      ),
    ),
  );
}

// Smart prompt with trial option
void showUpgradeOrTrialPrompt() {
  if (monetizationService.trialService.trialEligibility[UserTier.premium]!) {
    showTrialOfferDialog();
  } else {
    showUpgradeDialog();
  }
}
```

## Revenue Optimization

### Pricing Psychology
- If/when annual plans are enabled, display clear “20% savings” vs monthly
- Premium tier positioned as “popular choice”
- Pro tier highlights “best value” for power users
- Clear monthly vs lifetime value framing

### Conversion Optimization
- A/B testing on upgrade prompt copy
- Timing optimization for upgrade prompts
- Personalized recommendations based on usage
- Social proof in upgrade screens

### Retention Strategies
- Onboarding for new premium features
- Regular feature announcements
- Usage analytics sharing (Pro tier)
- Exclusive preview access to new features
- Referral Program: Generate codes, track conversions, earn rewards
- Smart Coupon System: Contextual discounts based on user behavior
- Enhanced Trial Management: Multiple trial types for different user segments
- Win-Back Campaigns: Targeted offers for churned users
- Conversion Optimization: Smart timing and personalized promotions

## Analytics and Monitoring

### Key Metrics

#### Conversion Funnel
1. Feature Limit Encounters: Users hitting limits
2. Trial Offers Shown: Trial prompts displayed to eligible users
3. Trial Starts: Users beginning free trials
4. Trial Engagement: Active usage during trial period
5. Upgrade Prompt Views: Prompts shown to users (trial and non-trial)
6. Upgrade Intent: Users starting upgrade flow
7. Coupon Applications: Discount codes applied to purchases
8. Trial Conversions: Trials converting to paid subscriptions
9. Subscription Retention: Monthly retention rates
10. Referral Activations: Successful referral code applications

#### Revenue Metrics
- Monthly Recurring Revenue (MRR)
- Annual Recurring Revenue (ARR)
- Customer Lifetime Value (LTV)
- Customer Acquisition Cost (CAC)
- Churn rate by tier
- Upgrade/downgrade rates

### Event Tracking
All monetization and retention events are tracked:
- Feature limit encounters
- Trial offers, starts, extensions, and conversions
- Upgrade prompt displays and interactions
- Coupon views, applications, and validations
- Referral code generations and conversions
- Subscription changes and churn events
- Feature usage by tier (including trial usage)
- Retention campaign effectiveness
- Win-back campaign performance

## Success Criteria

### Short-term Goals (Month 1-3)
- 5% free-to-premium conversion rate
- 25% trial-to-paid conversion rate (improved with better trial experience)
- $5,000 monthly recurring revenue
- <5% monthly churn rate
- 10% referral program adoption rate
- 15% coupon utilization rate

### Medium-term Goals (Month 4-6)
- 8% free-to-premium conversion rate
- 35% trial-to-paid conversion rate (optimized trial flows)
- $15,000 monthly recurring revenue
- Premium users represent 60% of revenue
- 20% referral program adoption rate
- 30% of new users come through referrals or coupons

### Long-term Goals (Month 7-12)
- 12% free-to-premium conversion rate
- 45% trial-to-paid conversion rate (mature retention systems)
- $50,000 monthly recurring revenue
- Sustainable unit economics (LTV > 3x CAC)
- 25% referral program adoption rate
- 40% of revenue attributed to retention programs

## Competitive Analysis

### Market Positioning
- vs. Notion: Simpler, mobile-first experience
- vs. Evernote: Better multimedia integration
- vs. Apple Notes: Cross-platform availability
- vs. OneNote: Cleaner interface, better pricing

### Pricing Comparison
- Competitive with market leaders
- Clear value differentiation
- Aggressive trial offerings
- Transparent pricing model

## Future Pricing Considerations

### Potential Adjustments
- Reintroduce regional pricing with data-driven discounts
- Student discounts
- Family plans
- Lifetime purchase options
- Volume discounts for large enterprise deployments

### Feature Expansion
- AI-powered features (separate tier or add-on)
- Advanced collaboration tools
- Integration marketplace
- White-label licensing

## Localization Key Mapping

The following localization keys are used for pricing-related text:

### Tier Names
- pricing_free → "Free" / "Gratis" / "Gratuit" / "Kostenlos"
- pricing_premium → "Premium"
- pricing_pro → "Pro"
- pricing_enterprise → "Enterprise" / "Empresa" / "Entreprise" / "Unternehmen"

### Billing Terms
- planTerm_monthly → "Monthly" / "Mensual" / "Mensuel" / "Monatlich"
- planTerm_annual → "Annual" / "Anual" / "Annuel" / "Jährlich"
- planTerm_lifetime → "Lifetime" / "De por vida" / "À vie" / "Lebenslang"
- planTerm_perUser → "Per User" / "Por usuario" / "Par utilisateur" / "Pro Benutzer"
- planTerm_save20 → "Save 20%" / "Ahorrar 20%" / "Économiser 20%" / "20% sparen"

### Action Labels
- action_upgradeNow → "Upgrade Now" / "Actualizar ahora" / "Mettre à niveau maintenant" / "Jetzt upgraden"
- action_startFreeTrial → "Start Free Trial" / "Iniciar prueba gratuita" / "Commencer l'essai gratuit" / "Kostenlose Testversion starten"
- action_restorePurchase → "Restore Purchase" / "Restaurar compra" / "Restaurer l'achat" / "Kauf wiederherstellen"

### Feature Highlights
- feature_unlimitedNotes → "Unlimited notes" / "Notas ilimitadas" / "Notes illimitées" / "Unbegrenzte Notizen"
- feature_voiceTranscription → "Voice transcription" / "Transcripción de voz" / "Transcription vocale" / "Sprachtranskription"
- feature_advancedDrawingTools → "Advanced drawing tools" / "Herramientas de dibujo avanzadas" / "Outils de dessin avancés" / "Erweiterte Zeichenwerkzeuge"
- feature_noAds → "No ads" / "Sin anuncios" / "Sans publicité" / "Keine Werbung"
- feature_prioritySupport → "Priority support" / "Soporte prioritario" / "Support prioritaire" / "Prioritätssupport"

See [docs/localization.md](localization.md) for complete localization documentation and implementation details.

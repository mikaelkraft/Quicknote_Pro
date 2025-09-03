# Pricing Tiers and Paywall

<<<<<<< copilot/fix-78bc4ac8-0e66-4ec5-8426-4f6181bb6f96
Tiers (updated)
- Free: core note creation, sync limits, ads enabled.
- Premium: $0.99/month - unlimited notes, advanced features, no ads.
- Pro: $1.99/month - everything in Premium plus advanced analytics and priority support.
=======
## Finalized Pricing Tiers
>>>>>>> main

### Subscription Tiers
- **Free**: Core note creation, limited sync, ads enabled
- **Premium**: $1.99/month ($19.99/year, $74.99 lifetime) - Enhanced productivity features
- **Pro**: $2.99/month ($29.99/year, $114.99 lifetime) - Advanced capabilities
- **Enterprise**: $2.00/user/month ($19.99/user/year) - Team collaboration

### Regional Pricing
- **Base Market**: Standard USD pricing as above
- **Africa Region**: 
  - Premium: $0.99/month ($9.99/year, $37.99 lifetime)
  - Pro: $1.99/month ($19.99/year, $74.99 lifetime)  
  - Enterprise: $1.00/user/month ($9.99/user/year)

### Paywall Design
- Simple, distraction-free page with primary CTA
- Clear pricing display with annual discount highlighted (20% savings)
- Secondary CTA: restore purchase
<<<<<<< copilot/fix-78bc4ac8-0e66-4ec5-8426-4f6181bb6f96
- Trust elements: brief feature/value bullets
- Regional pricing optimized for maximum engagement

Experiment plan (post-v1 candidates)
- A/B headlines
- Annual vs monthly emphasis
- Trial duration variants
- Regional pricing variations

Checklist
- [x] Define feature matrix for Free vs Premium vs Pro
- [x] Establish price points optimized for engagement
- [x] Implement paywall screen and restore flow
- [ ] Wire analytics for view, dismiss, start, complete
- [ ] Draft copy and visuals with brand alignment
=======
- Trust elements: feature/value bullets by tier
- Regional pricing detection and display

### Analytics Parameters
New analytics parameters to track:
- `plan_term`: monthly|annual|lifetime
- `region`: base|africa
- `per_user`: boolean for enterprise pricing
- `seats`: number of seats for enterprise
- `base_price`: price before regional adjustment
- `localized_price`: final localized price

## Implementation Checklist

- [x] Define feature matrix for Free, Premium, Pro, Enterprise
- [x] Establish price points and regions (base market + Africa)
- [x] Add multi-term pricing (monthly, annual, lifetime)
- [x] Wire new analytics parameters for upgrade tracking
- [ ] Implement paywall screen with new pricing display
- [ ] Add restore flow with enterprise support
- [ ] Test regional pricing detection
- [ ] Draft copy and visuals with brand alignment
- [ ] A/B test annual vs monthly emphasis
>>>>>>> main

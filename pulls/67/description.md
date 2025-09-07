## Title: Monetization v1: consolidated implementation (supersedes #49/#44/#42/#40/#38)

### Summary
This PR consolidates Monetization v1 into a single, cohesive implementation. It integrates analytics and event taxonomy, ads for the free tier with smart timing and frequency caps (plus A/B hooks), pricing tiers with free limits and upgrade paths, paywall and upsell UX, and Pro theme entitlements. The aim is to land a minimal-risk foundation that is feature-flagged, backwards-compatible, and ready for staged rollout.

### Scope
- Analytics + event taxonomy for monetization and usage (from prior work: #61/#40)
- Ads integration for free tier with timing, frequency caps, and A/B hooks (#42/#32)
- Pricing tiers and free limits system (#44)
- Paywall and upsell UX (#38)
- Pro theme entitlements + feature gating (themes) (#36)
- Premium/Pro entitlements and feature gating scaffolding with cross-platform billing (#30/#26/#24)
- De-duplication and refactoring of overlapping logic from superseded branches

### Implementation
- Modularized monetization components (analytics, ads, paywall, pricing, entitlements) and shared helpers
- Config/ENV-driven feature flags to gate each monetization slice
- No breaking changes for existing users; defaults keep current behavior unless flags are enabled
- Interfaces abstracted to allow provider swap (ads, analytics, billing)
- A/B infra via simple variant bucketing (hash(user_id) % 100) with guardrails

### Feature Flags (ENV/config; default: Production OFF, Staging ON)
- FEATURE_MONETIZATION=true|false
- FEATURE_ADS=true|false
- FEATURE_PAYWALL=true|false
- FEATURE_PREMIUM_ENTITLEMENTS=true|false
- FEATURE_PRO_THEMES=true|false
- FEATURE_REFERRALS=true|false
- FEATURE_AB_TESTS=true|false
Kill switch: setting FEATURE_MONETIZATION=false disables all monetization features regardless of sub-flags.

### Analytics: Events (names subject to final provider mapping)
- monetization.paywall_view, monetization.paywall_accept, monetization.paywall_dismiss
- monetization.upsell_impression, monetization.upsell_click
- monetization.free_limit_reached, monetization.upgrade_flow_start, monetization.upgrade_success, monetization.upgrade_error
- entitlement.check, entitlement.grant, entitlement.revoke
- ads.impression, ads.click, ads.dismiss, ads.frequency_capped
- referral.link_view, referral.link_click, referral.apply_success, referral.apply_error, referral.signup
- themes.locked_click, themes.paywall_shown
- billing.purchase_start, billing.purchase_success, billing.purchase_cancel, billing.purchase_restore
Privacy: all events exclude PII beyond anonymous IDs; respect platform opt-outs.

### Ads Timing + Frequency Caps (initial policy)
- Interstitials: max 1 every 2 minutes AND max 1 per 5 significant navigations
- Show on note-close or app-return if last ad > 2 minutes and user not actively typing/recording
- Never show during recording, doodle canvas, or within 15s of app launch
- A/B buckets: control (no ads), baseline, smart-timing; cap rotations by variant
- Respect OS privacy/limit-ad-tracking flags; fallback to house ads if network unavailable

### Pricing Tiers (initial)
- Free: core notes, limited attachments, basic themes; daily/monthly usage caps
- Pro Monthly: all features incl. pro themes, doodle canvas unlocks, higher attachment/storage caps; no ads
- Pro Annual: same as Pro Monthly with discounted price and bonus referral credits
- Upgrade paths: in-app paywall/upsell entry points; restore purchases supported

### Referral Hooks (scaffold)
- Accept referral code on sign-up or from settings
- Credit referrer and referee with trial days or discount
- Track referral events and attribution windows

### Migration / Backfill Plan
- Grandfather existing users as Free; do not introduce new restrictions without a comms plan
- Add storage/schema keys for entitlements, subscription status, referral data (non-breaking)
- Backfill: initialize entitlements and counters for existing users on first post-update launch
- Billing: no-op on platforms without a configured provider; feature stays gated

### Testing Checklist
- Unit: feature-flag gating, analytics event emission, frequency-cap math, entitlement checks
- Integration: paywall flows, upgrade/restore, referral code application, ads suppression contexts
- E2E/manual: staging build with flags ON; verify crash-free rate, session flows, and UI polish
- Privacy: ensure opt-outs honored and no PII in analytics payloads
- A/B: verify stable bucketing, no cross-test collisions, metrics tagged by variant

### Risks & Mitigations
- User friction from paywalls/ads: staged rollout, generous defaults, rapid rollback via flags
- Revenue vs. UX balance: measure conversion, DAU retention, ad impressions/DAU, eCPM
- Provider instability: interface abstractions and network backoff; house ads fallback
- Compliance/privacy: minimize data, respect platform policies, audit events

### Rollout Plan & Monitoring
- Stage 0: internal (0%) dogfood; metrics/bugs
- Stage 1: 5% production (staged rollout); monitor crashes, latencies, conversion, complaints
- Stage 2: 25% production if green after 48–72h
- Stage 3: 100% production after 5–7 days with success criteria met
- Rollback criteria: crash rate +p50 > 0.5pp, upgrade funnel drop >20%, complaint surge, ad errors >5%

### Linkage
Supersedes #49, #44, #42, #40, #38
Closes #41
Closes #39
Closes #37
Closes #35
Closes #33
Closes #31

### Reviewers
Requesting review from @mikaelkraft. Ready for review.
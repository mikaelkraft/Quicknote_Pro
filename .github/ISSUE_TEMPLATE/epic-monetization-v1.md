# Epic: Monetization v1 (Tracking)

Goal
- Ship a cohesive first version of monetization: analytics foundation, ads integration, and pricing tiers.

Scope
- #39 Analytics and Event Taxonomy for Monetization and Usage
- #41 Ads Integration: Placement, Formats, and Frequency Caps
- #43 Pricing Tiers and Free Limits: Define Capabilities and Upgrade Path

Outcomes
- Reliable analytics taxonomy powering monetization decisions
- Non-intrusive ad placements with frequency caps
- Clear pricing tiers and upgrade path in-app

Checklist
- [ ] Define labels: area:monetization, type:feature, priority:p1/p2
- [ ] Create project board "Monetization v1" and add issues
- [ ] Draft docs (analytics.md, ads.md, pricing.md)
- [ ] Align metrics and events with KPIs (activation, retention, conversion)
- [ ] Implement and gate features per milestone timeline
- [ ] QA + rollout plan

Timeline
- Week 1–2: Analytics taxonomy, instrumentation plan
- Week 2–3: Ads placements + frequency capping
- Week 3–4: Pricing tiers, paywalls, upgrade UX
- Week 5: QA + rollout

Risks/Mitigations
- Signal quality: define strict event contracts and validation
- UX impact of ads: test placements with sensible caps and dismissals
- Pricing confusion: transparent tier matrix and in-app copy

Owners
- @mikaelkraft, @copilot (assign during kickoff)
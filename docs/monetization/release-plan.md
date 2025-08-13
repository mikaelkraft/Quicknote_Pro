# Release Plan

Phases (draft)
- Phase 0: Analytics instrumentation scaffolding
- Phase 1: Paywall baseline and Pro tier (ads off for Pro)
- Phase 2: Ads banner placement for Free
- Phase 3: Optional interstitial (flagged, gradual rollout)

Rollout safeguards
- Feature flags for each placement and purchase flow
- Gradual percentage rollouts
- Kill-switch documented and tested

Risks and mitigations
- Ad SDK regressions -> isolate behind flags, lazy load
- Purchase failures -> robust retry and restore purchase UX
- Privacy concerns -> explicit consent UI and data export/delete path

Checklist
- [ ] Define flags and defaults
- [ ] Write rollback procedure
- [ ] Pre-release QA checklist
- [ ] Post-release monitoring plan
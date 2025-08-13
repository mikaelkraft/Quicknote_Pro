# Ads Integration

Objectives
- Integrate an ad provider with minimal app surface changes, controllable via feature flags.

Provider selection (criteria)
- SDK size and startup impact
- Fill rate in target regions
- Mediation support
- Privacy compliance and COPPA/GDPR tooling

Placement strategy (draft)
- Non-intrusive: avoid blocking core note-taking flows
- Candidate placements: non-modal banner in list view; optional interstitial on app open (behind flag)

Feature flags
- `ads_enabled`
- `ads_interstitial_open_enabled`
- `ads_banner_list_enabled`

Testing matrix
- Platforms: iOS, Android, Web (if applicable)
- States: logged in/out, consent on/off, tier free/pro
- Network: offline, slow, normal

Checklist
- [ ] Select primary ad SDK and (optional) mediation layer (#48)
- [ ] Add feature flags and no-op shims when disabled
- [ ] Implement banner placement with graceful fallback
- [ ] Add analytics hooks for impression/click/error events
- [ ] Create QA checklist and test data providers
# Analytics Foundation and Architecture

Purpose
Define how we collect, process, and use analytics to inform Monetization v1 decisions while respecting user privacy.

Event schema (draft)
- Naming: use snake_case, past-tense verbs. Example: `note_created`, `paywall_viewed`.
- Required fields: `event_name`, `occurred_at`, `user_id` (hashed), `session_id`, `platform`, `app_version`, `context` (JSON object).
- Revenue-related events: `paywall_viewed`, `paywall_dismissed`, `purchase_started`, `purchase_completed`, `ad_impression`, `ad_click`.

Data flow (draft)
1) Client emits event -> 2) In-flight consent check -> 3) Buffered queue -> 4) Transport to telemetry backend -> 5) Storage -> 6) Dashboarding.

Privacy and consent
- Respect system-level tracking choices where applicable.
- Provide in-app consent controls and a data deletion path.
- Avoid PII; hash user identifiers client-side.

Instrumentation plan (high level)
- Screen views: paywall, settings, upgrade entry points.
- Key actions: purchase start/complete, ad interactions.
- Errors: purchase failures; ad fill/timeouts.

Checklist
- [ ] Finalize event names and required fields (#46)
- [ ] Select telemetry backend and SDK (self-hosted or managed)
- [ ] Implement consent gating and opt-out flows
- [ ] Document client interfaces for emitting events
- [ ] Define sampling and backoff strategies for low connectivity
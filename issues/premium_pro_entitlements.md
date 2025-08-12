# Premium/Pro Entitlements and Feature Gating

Implement premium entitlements to gate advanced features (voice note transcription, longer recordings, background recording, advanced doodle tools, export formats, layers, etc.).

- Integrate Play Billing (Android) and StoreKit (iOS) for non-consumable "Pro" upgrade.
- Add feature flags and entitlement checks in the app.
- Provide a gentle upsell UI in context and a graceful read-only mode for non-Pro users.
- Ensure quality user experience: permission checks, error handling, and comprehensive tests.

## Acceptance Criteria:
- Pro features are gated and only available to entitled users.
- Upsell and entitlement checks are non-intrusive and reliable.
- All purchases and entitlements are handled securely and robustly.

## Future/Related:
See issues for voice notes and doodle canvas features.
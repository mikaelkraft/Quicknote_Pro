# Ads Integration

Goals
- Non-intrusive placements with frequency caps and clear dismissal affordances.

Placements (draft)
- Home: inline card after N notes (e.g., after 10th)
- Editor: optional footer banner (off by default; experiment)
- Interstitial: post-share or app-open with tight caps

Formats
- Banner, Native inline, Interstitial (no rewarded in v1)

Frequency Caps (examples)
- Interstitial: 1 per 24h; 3 per 7d; max 10 impressions/user/month
- Banner/Inline: max 1 view per session per placement

Targeting/Exclusions
- No ads for paid users; respect "limit ad tracking"

Quality
- Block on low eCPM sources; network timeout budget (e.g., 800ms)

Telemetry
- impression, click, error, filled, no_fill, capped with full context.
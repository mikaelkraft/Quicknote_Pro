# Analytics and Event Taxonomy

Objectives
- Power decisions for acquisition, activation, retention, and revenue.

KPIs
- Activation Rate, 7/30-day Retention, Conversion to Paid, ARPPU, Ad eCPM

Event Conventions
- snake_case names; required fields: user_id, session_id, app_version, platform, ts
- Context objects: device, app, experiment, monetization

Core Events (draft)
- app_opened { launch_type }
- note_created { source, length }
- premium_paywall_viewed { paywall_id, source }
- premium_purchase_attempted { product_id, price, currency, offer_id }
- premium_purchase_succeeded { product_id, price, currency, offer_id }
- ad_impression { placement_id, demand_partner, format, ecpm, line_item_id }
- ad_click { placement_id, demand_partner, format }
- ad_capped { placement_id, cap_period, cap_value }

Governance
- Versioned schemas; validation at emit-time; drop unknown props; strict types.

Instrumentation Plan
- Map events to UI flows (#41, #43); add unit tests for payload shape; add sampling if needed.
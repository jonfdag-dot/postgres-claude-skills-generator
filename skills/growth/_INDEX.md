---
artifact_type: department_catalog
department: growth
refreshed_at: 2026-05-02T19:14:03Z
total_roles: 2
total_skills: 2
total_scripts: 4
sister_pair: [growth-marketing, product-analytics]
sister_axis: "acquisition + retention vs. in-product behavior"
department_archetypes: [b2b_acquisition, product_analytics]
department_primitives: [cohort_retention_matrix, pre_aggregate_grain, ratio_reconstruction, date_spine, period_over_period_lag, statistical_significance_gate]
department_tables_read: [public.users, public.signups, public.sessions, public.events, public.campaigns, public.attribution_touches, public.feature_flags, public.experiment_assignments, public.experiment_outcomes, public.feature_usage, public.user_properties]
---

# 📈 Growth — Department Catalog

Owns shipper acquisition, activation, retention, and in-product behavior on the Northwind portal (the web surface where shippers book and track shipments). Sister roles split at **the signup boundary**: `growth-marketing` owns the path BEFORE signup (acquisition, attribution) and cohort retention AFTER signup (D7/D30); `product-analytics` owns in-product behavior AFTER signup (feature adoption, A/B tests, in-product funnels).

## Department summary (Pass-C accumulator)

The department reasons in **cohorts** (signup-week, signup-month) for retention questions and **exposure-anchored windows** (`assigned_ts` for A/B work, `first_used_ts` for adoption work) for in-product questions. Critical distinctions: D7 retention is point-in-time (`session_ts BETWEEN cohort + 7d AND cohort + 8d`) — never cumulative through D∞; A/B test outcomes are gated on a 95% z-test (`|z| >= 1.96`); funnels are ordered events (window functions or LATERAL with `ORDER BY event_ts`), never cross-table joins. Sister-role discipline: `growth-marketing` requires `HAVING COUNT(*) >= 30` cohort-size floor; `product-analytics` requires `HAVING COUNT(*) >= 100` per variant.

## Roles in this department

| Role | Persona description (mirrored from SKILL.md frontmatter) | Skills | Scripts | Catalog |
|---|---|---|---|---|
| **growth-marketing** | Owns shipper acquisition, activation, cohort retention, and channel attribution. Sister role to product-analytics (in-product behavior). Cohort-first, point-in-time retention (not cumulative), funnels are ordered events not joins. | 1 | 2 | [growth-marketing/SKILL.md](growth-marketing/SKILL.md) |
| **product-analytics** | In-product behavior on the portal AFTER signup (feature adoption, A/B test outcomes, funnel conversion, engagement depth). Adoption-first, ordered-event funnels, A/B tests with significance gates. | 1 | 2 | [product-analytics/SKILL.md](product-analytics/SKILL.md) |

## Sister-role pairing logic

| If the question is about… | Route to |
|---|---|
| Cohort retention, signup funnel, channel attribution, campaign ROI, DAU/MAU/WAU (acquisition + retention) | `growth-marketing` |
| Feature adoption, A/B tests, in-product funnels, engagement depth, stickiness (in-product behavior) | `product-analytics` |
| Cross-axis (`D7 retention split by feature-adoption cohort`) | both — growth-marketing owns the cohort leg, product-analytics owns the feature leg; compose via Rung 3 cross-domain dispatch (CHION.md §3) |

## Department vocabulary (aggregated, deduplicated)

- **Cohorts & retention** — cohort · cohort retention · cohort analysis · cohort curve · retention · retention curve · D1 · D7 · D30
- **Acquisition** — signup · signup conversion · activation · source · source attribution · channel retention · campaign · campaign retention · campaign ROI · attribution
- **Active users** — DAU · MAU · WAU · active users · stickiness (DAU/MAU)
- **Pre-signup funnel** (growth-marketing) — signup funnel · activation funnel · visit-to-signup · signup conversion rate · first-shipment north-star · first shipment booked
- **In-product funnel** (product-analytics) — in-product funnel · feature funnel · variant conversion rate · in-product drop-off · in-product step-through · core in-product action · in-product north-star
- **Experiments** (product-analytics) — A/B test · experiment · variant · control vs treatment · conversion lift · statistical significance · z-test · feature flag · rollout · exposure
- **Adoption + engagement** (product-analytics) — feature adoption · feature usage · feature flag · stickiness · engagement depth · sessions per user · events per session

## Department-wide stop signals

- Never `WHERE session_ts >= cohort + 7 days` without an upper bound — that's cumulative D∞, not D7. Half-open day-N window mandatory.
- Never `AVG(is_retained_d7::INT)` or `AVG(is_adopted::INT)` — `avg_of_ratios`. Rebuild num/den per (cohort × dimension) cell.
- Never `COUNT(*)` over `public.events` for active-user math — use `COUNT(DISTINCT user_id)` over a rolling window.
- Never join events to events on `user_id` without ordering — funnels lose temporal sequence. Use window functions or LATERAL with `ORDER BY event_ts`.
- Never claim an A/B winner below 95% significance — gate on two-proportion z-test `|z| >= 1.96`.
- Always anchor experiment-result windows to `assigned_ts` (exposure), not `signup_ts`.
- Always denominate feature adoption against `eligible_user_count` (flag-enabled users), not raw MAU.

## How agents route within this department

1. Match question against role-level triggers above (acquisition + retention vs. in-product behavior).
2. Open the matching `<role>/SKILL.md` — load Persona, Curated Rule Pack, Layer 2 Domain Profile, Role Vocabulary, and the Scripts Index at the bottom.
3. Pick top-3 scripts whose triggers best match the user's question.
4. Open `<role>/scripts/<query>/README.md` for the 6-gate fit check; wrap via CTE-Mastermind (CHION.md §4); execute.

Sister-role swap rule (CHION.md §3 Rung 2): if the picked role produces no script fit, retry with the sister role. The pair shares `public.users` + `public.events` — the funnel crosses the signup boundary into in-product behavior.

---

[← Skills catalog (top)](../_INDEX.md) · [← Root CHION.md](../../../CHION.md)

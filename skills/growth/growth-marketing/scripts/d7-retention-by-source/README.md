---
artifact_type: script_semantic_layer
script_id: d7-retention-by-source
business_title: D7 Retention by Source — Weekly Cohorts
role: growth-marketing
department: growth
chosen_primitives: [cohort_retention_matrix, pre_aggregate_grain, ratio_reconstruction]
trigger_keywords: [D7 retention, week-1 retention, weekly cohort retention, source attribution, channel retention, campaign retention, D7 by source, source D7]
tables_read: [public.users, public.signups, public.sessions]
metric_behavior: ratio
default_grain: signup-week × source
last_run: 2026-04-22
promoted_from: 4 verified question instances (2026-02-19 → 2026-04-22)
status: verified
---

# D7 Retention by Source — Weekly Cohorts

> **Business question:** "What is D7 retention rate per signup-
> week cohort, split by acquisition source? Which channels deliver
> retaining users vs. one-and-done traffic?"

D7 retention is **point-in-time** — at least one session in the
day-7 window after signup, NOT cumulative through D∞. Reconstructed
per (cohort_week × source) cell — never `AVG(is_retained_d7::INT)`.

**Sister scripts** · [signup-funnel-conversion-weekly](../signup-funnel-conversion-weekly/README.md) (top-of-funnel companion).

---

## Result table

One row per (signup_week × source) cohort over the trailing 12 weeks
with cohort size ≥ 30. Each row has cohort size, retained-D7 count,
and the reconstructed retention rate.

### Columns

| column | type | role | description |
|---|---|---|---|
| `source` | text | dimension | One of `organic` · `google_ads` · `linkedin` · `referral` · `email` · `direct` · `partner` · `content` |
| `cohort_week` | timestamp | time | `DATE_TRUNC('week', users.signup_ts)` |
| `cohort_size` | bigint | metric | `COUNT(*)` of users in this (week × source) cohort |
| `retained_d7` | bigint | metric | `COUNT(DISTINCT user_id)` with at least one session in day-7 window |
| `d7_retention_rate` | numeric | derived | `retained_d7 / NULLIF(cohort_size, 0)` |

Ordered by `source, cohort_week`.

---

## Dos and don'ts

**Dos** · anchor every retention to `cohort_week` (signup-week truncation) · point-in-time D7 — `session_ts >= cohort_week + 7 days AND session_ts < cohort_week + 8 days` (half-open, NOT cumulative through D∞) · GROUP BY `(cohort_week, source)` BEFORE retention math · `HAVING COUNT(*) >= 30` cohort floor · `COUNT(DISTINCT user_id)` for retained users.

**Don'ts** · `AVG(is_retained_d7::INT)` (avg_of_ratios; small cohorts dominate) · `WHERE session_ts >= cohort_week + 7 days` without an upper bound (cumulative through D∞, not D7) · `COUNT(*)` for retained-active counting (over-counts power users with multiple sessions) · cross-cohort comparison without sample-size floor.

---

## Per-column details

### `public.users.signup_ts` — time · timestamptz · `cohort_anchor`

- **business_definition** · Timestamp the user account was created.
- **quality_trust** · NOT NULL · UTC · zero nulls
- **dos** · half-open windows · weekly `DATE_TRUNC` for cohort
- **don'ts** · SUM/AVG · use as event_time for retention (use `session_ts` for that)

### `public.sessions.session_ts` — time · timestamptz · `event_time`

- **business_definition** · Timestamp of a session event.
- **quality_trust** · NOT NULL · UTC
- **dos** · half-open day-7 window
- **don'ts** · cumulative window without upper bound · use as cohort anchor

### `public.signups.source` — categorical · row dimension · acquisition channel

- **business_definition** · Acquisition source recorded at signup.
- **values** · `organic` · `google_ads` · `linkedin` · `referral` · `email` · `direct` · `partner` · `content` — see samples below
- **quality_trust** · NULL ~6% (uncoded direct traffic) — coalesce to `'organic'` before grouping
- **dos** · GROUP BY `(cohort_week, source)` · COALESCE NULL → `'organic'`
- **don'ts** · aggregate the column itself · use `attribution_touches` as a substitute (per-event, not per-signup)

### `public.users.user_id` — key · partition + COUNT(DISTINCT)

- **business_definition** · Primary key on users.
- **dos** · COUNT(DISTINCT user_id) for retention numerator
- **don'ts** · COUNT(*) over sessions (over-counts power users)

---

## Value samples (column_value_samples)

### `public.signups.source`

| value | freq_est | rank | sample_type | co_occurrence (signup_ts) | co_occurrence (campaigns.channel) |
|---|---|---|---|---|---|
| `organic` | 4,820 | 1 | top | [2024-01-01 → 2026-04-30] | (none — non-paid) |
| `google_ads` | 2,940 | 2 | top | [2024-03-15 → 2026-04-30] | paid_search |
| `linkedin` | 1,680 | 3 | top | [2024-06-01 → 2026-04-30] | paid_social |
| `referral` | 1,210 | 4 | top | [2024-01-01 → 2026-04-30] | (none) |
| `email` | 924 | 5 | top | [2024-04-01 → 2026-04-30] | email |
| `direct` | 612 | 6 | rare | [2024-01-01 → 2026-04-30] | (none) |
| `partner` | 287 | 7 | rare | [2024-08-01 → 2026-04-30] | partner |
| `content` | 148 | 8 | rare | [2024-09-01 → 2026-04-30] | content |

---

## Template-level semantic (compact)

**Identity** · title `D7 Retention by Source — Weekly Cohorts` · analytical_pattern `cohort_retention_matrix` · primary_purpose surface acquisition-channel retention quality for marketing-spend reallocation · search_keywords D7 retention · channel retention · source attribution · cohort retention

**Decision record** · sort `source_then_cohort_week` · agg_fn `count_distinct_div_count` · time_col `users.signup_ts` · dimension `[signups.source, cohort_week]` · date_range `last_12_weeks` · time_grain `weekly_cohort`

**Business context** · default_aggregation `ratio_reconstruction` · default_grain `weekly_cohort_x_source` · additive_metrics [cohort_size · retained_d7] · non_additive_metrics [d7_retention_rate]

**Filters** · `signups.source` (multi_select, default all) · `users.signup_ts` (date_range, default `last_12_weeks`)

**Intent keywords** · trend [WoW retention] · ranking [best channel · worst channel · top source by D7] · comparison [organic vs paid · channel vs channel]

**Dashboard** · x = `cohort_week` (date_week) · y = `d7_retention_rate` (percent) · color by `source` · recommended_visualizations [line · heatmap · small_multiples]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `users.signup_ts >= CURRENT_DATE - INTERVAL '12 weeks'` (half-open).
2. CTE: cohorts with `(user_id, source, cohort_week)` from JOIN of `users` and `signups`.
3. CTE: `day7_active` — `DISTINCT s.user_id` where `session_ts BETWEEN cohort_week + 7 days AND cohort_week + 8 days` (half-open).
4. LEFT JOIN cohorts to day7_active; GROUP BY `(source, cohort_week)`.
5. `HAVING COUNT(*) >= 30` (cohort-size floor).
6. Reconstruct `d7_retention_rate = COUNT(DISTINCT retained.user_id) / NULLIF(COUNT(*), 0)`.

**Stop signals** · `AVG(is_retained_d7::INT)` · cumulative window through D∞ · `COUNT(*)` for retained users · cross-cohort comparison below the floor.

---

[← Persona: growth-marketing](../../SKILL.md) ·
[← Department: growth](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

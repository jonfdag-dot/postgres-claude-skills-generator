---
artifact_type: script_semantic_layer
script_id: signup-funnel-conversion-weekly
business_title: Signup Funnel Conversion — Weekly
role: growth-marketing
department: growth
chosen_primitives: [pre_aggregate_grain, ratio_reconstruction]
trigger_keywords: [signup conversion, signup funnel, visit to signup, activation funnel, top of funnel, conversion rate, weekly funnel]
tables_read: [public.sessions, public.users, public.events]
metric_behavior: ratio
default_grain: week × ordered_funnel_step
last_run: 2026-04-26
promoted_from: 3 verified question instances (2026-03-04 → 2026-04-26)
status: verified
---

# Signup Funnel Conversion — Weekly

> **Business question:** "Per signup-week, what is the conversion
> rate at each funnel step (visit → signup → first-shipment-booked)
> and the step-to-step conversion %?"

Funnel as **ordered events**, not cross-table joins. Computed at
weekly grain over the trailing 8 weeks. Step counts use
`COUNT(DISTINCT user_id)` reaching each step within the cohort window.

**Sister scripts** · [d7-retention-by-source](../d7-retention-by-source/README.md) (post-signup retention companion).

---

## Result table

One row per (week × funnel_step) over the trailing 8 weeks. Each
row is the count of distinct users reaching that step, with the
step-to-step conversion rate filled in (NULL for the entry step).

### Columns

| column | type | role | description |
|---|---|---|---|
| `cohort_week` | timestamp | time | `DATE_TRUNC('week', sessions.session_ts)` for the entry step |
| `funnel_step` | text | dimension | `1_visit` · `2_signed_up` · `3_first_shipment` |
| `step_users` | bigint | metric | `COUNT(DISTINCT user_id)` reaching this step |
| `prior_step_users` | bigint | derived | `LAG(step_users) OVER (PARTITION BY cohort_week ORDER BY funnel_step)` |
| `step_conversion_rate` | numeric | derived | `step_users / NULLIF(prior_step_users, 0)` |

Ordered by `cohort_week DESC, funnel_step`.

---

## Dos and don'ts

**Dos** · funnel as ORDERED events (`session_ts < signed_up_ts < booked_shipment_ts`) · `COUNT(DISTINCT user_id)` for step users (never `COUNT(*)`) · half-open weekly window · `NULLIF(prior_step_users, 0)` on the conversion ratio · `LAG()` partitioned by `cohort_week`.

**Don'ts** · cross-table JOINs to "match" event A and event B (loses ordering — user could hit B before A and still match) · `COUNT(*)` over events for active users (counts events, not users) · cumulative funnels without a per-cohort denominator · `AVG(step_conversion_rate)` for "average funnel" (use SUM-divided-by-SUM at the company level).

---

## Per-column details

### `public.sessions.session_ts` — time · timestamptz · `entry_step_anchor`

- **business_definition** · Timestamp of a session event; first step in the funnel.
- **quality_trust** · NOT NULL · UTC
- **dos** · half-open windows · weekly bucket
- **don'ts** · SUM/AVG · use as signup anchor (use `users.signup_ts` for that)

### `public.users.signup_ts` — time · timestamptz · `step_2_anchor`

- **business_definition** · Account creation timestamp.
- **dos** · enforce `signup_ts > session_ts` (ordered events)
- **don'ts** · use as cohort anchor when funneling from visit

### `public.events.event_ts` — time · timestamptz · `step_3_anchor`

- **business_definition** · Timestamp of a granular product event (e.g., `booked_shipment`).
- **dos** · enforce `event_ts > signup_ts` (ordered events) · filter `event_name = 'booked_shipment'` for the conversion step
- **don'ts** · cross-table JOIN without ordering · use raw event count for active users

### `public.events.event_name` — categorical · funnel-step selector

- **values** · `viewed_pricing` · `signed_up` · `connected_database` · `booked_shipment` · `rated_carrier` · `invited_teammate` · `upgraded_plan`
- **dos** · filter to the funnel step name (e.g., `'booked_shipment'` for the conversion step)
- **don'ts** · use raw event_name distribution for active users (`COUNT(DISTINCT user_id)` per step is the correct shape)

### `public.users.user_id` — key · `COUNT(DISTINCT)` source

- **business_definition** · Primary key on users.
- **dos** · COUNT(DISTINCT user_id) at every step
- **don'ts** · COUNT(*) (over-counts power users)

---

## Value samples (column_value_samples)

### `public.events.event_name` (funnel-relevant subset)

| value | freq_est | rank | sample_type | co_occurrence (event_ts) |
|---|---|---|---|---|
| `signed_up` | 12,621 | 1 | top (funnel step) | [2024-01-01 → 2026-04-30] |
| `booked_shipment` | 9,884 | 2 | top (funnel step) | [2024-01-01 → 2026-04-30] |
| `viewed_pricing` | 41,200 | 3 | top (page event) | [2024-01-01 → 2026-04-30] |
| `connected_database` | 4,310 | 4 | rare | [2024-04-15 → 2026-04-30] |
| `rated_carrier` | 6,820 | 5 | top | [2024-01-01 → 2026-04-30] |

---

## Template-level semantic (compact)

**Identity** · title `Signup Funnel Conversion — Weekly` · analytical_pattern `ordered_funnel` · primary_purpose surface step-to-step conversion drift for marketing / activation interventions · search_keywords signup conversion · funnel · activation · top of funnel

**Decision record** · sort `cohort_week_desc_then_funnel_step` · agg_fn `count_distinct_div_count_distinct` · time_col `sessions.session_ts` · dimension `funnel_step` · date_range `last_8_weeks` · time_grain `weekly`

**Business context** · default_aggregation `ratio_reconstruction` · default_grain `weekly_x_funnel_step` · additive_metrics [step_users] · non_additive_metrics [step_conversion_rate]

**Filters** · `sessions.session_ts` (date_range, default `last_8_weeks`) · `events.event_name` (filter to canonical funnel steps)

**Intent keywords** · trend [WoW funnel · drop-off trend] · ranking [worst step · best converting week] · comparison [vs prior week · vs cohort baseline]

**Dashboard** · x = `funnel_step` (categorical, ordered) · y = `step_users` (int, log scale) · color by `cohort_week` · recommended_visualizations [funnel · stacked_bar · line]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `session_ts >= CURRENT_DATE - INTERVAL '8 weeks'` (half-open).
2. CTE `step_1`: distinct (user_id, cohort_week) from `sessions`.
3. CTE `step_2`: distinct (user_id, cohort_week) from `users` where `signup_ts > MIN(session_ts)` (ordered).
4. CTE `step_3`: distinct (user_id, cohort_week) from `events` where `event_name = 'booked_shipment'` AND `event_ts > signup_ts` (ordered).
5. UNION-tag the step CTEs with `funnel_step` labels; `COUNT(DISTINCT user_id)` per (cohort_week, funnel_step).
6. `LAG(step_users) OVER (PARTITION BY cohort_week ORDER BY funnel_step)` for step-conversion rate.

**Stop signals** · cross-table JOIN without ordering · `COUNT(*)` for step users · cumulative funnel without per-cohort denominator · `AVG(step_conversion_rate)` for the company-wide funnel.

---

[← Persona: growth-marketing](../../SKILL.md) ·
[← Department: growth](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

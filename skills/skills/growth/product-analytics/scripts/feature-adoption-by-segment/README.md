---
artifact_type: script_semantic_layer
script_id: feature-adoption-by-segment
business_title: Feature Adoption by Segment
role: product-analytics
department: growth
chosen_primitives: [pre_aggregate_grain, ratio_reconstruction]
trigger_keywords: [feature adoption, feature usage, adoption by segment, adoption rate, stickiness, feature uptake]
tables_read: [public.events, public.feature_flags, public.feature_usage, public.user_properties]
metric_behavior: ratio
default_grain: feature × plan_tier (trailing 30d)
last_run: 2026-04-25
promoted_from: 3 verified question instances (2026-03-01 → 2026-04-25)
status: verified
---

# Feature Adoption by Segment

> **Business question:** "What % of eligible users used feature X
> within the last 30 days, broken down by plan tier? Which tier
> adopts each feature most?"

Adoption = `users_with_first_use_in_window /
NULLIF(eligible_user_count, 0)` per (feature × plan_tier). Eligible
denominator = users with the flag enabled at `flag_state IN
('beta', 'rolling_out', 'default_on')` — NOT raw MAU.

**Sister scripts** · [ab-test-conversion-lift](../ab-test-conversion-lift/README.md) (experiment-side companion).

---

## Result table

One row per (feature_key × plan_tier) over the trailing 30 days.
Each row reports eligible-user count, adopting-user count, and the
reconstructed adoption rate.

### Columns

| column | type | role | description |
|---|---|---|---|
| `feature_key` | text | dimension | Feature identifier (e.g., `multi-leg-routing` · `carrier-scorecard-export`) |
| `plan_tier` | text | dimension | One of `free` · `pro` · `business` · `enterprise` |
| `eligible_users` | bigint | metric | `COUNT(DISTINCT user_id)` with the flag enabled at any point in the window |
| `adopting_users` | bigint | metric | `COUNT(DISTINCT user_id)` with `feature_usage.first_used_ts` in the window |
| `adoption_rate` | numeric | derived | `adopting_users / NULLIF(eligible_users, 0)` |

Ordered by `feature_key, plan_tier`.

---

## Dos and don'ts

**Dos** · denominator = `eligible_user_count` (flag-enabled users), NOT raw MAU · filter `feature_flags.flag_state IN ('beta', 'rolling_out', 'default_on')` · pre-aggregate at (feature × plan_tier) BEFORE dividing · `COUNT(DISTINCT user_id)` for both numerator and denominator · `NULLIF` on the denominator · `feature_usage.use_count > 0` (drop sentinel rows).

**Don'ts** · adoption against raw MAU (inflates non-eligibility into the rate) · `AVG(is_adopted::INT)` (avg_of_ratios; small segments dominate) · `COUNT(*)` over events for adopting-user count (over-counts power users) · ignore `flag_state` (off / dev_only / internal flags should not appear in external adoption math).

---

## Per-column details

### `public.feature_usage.first_used_ts` — time · timestamptz · `feature_first_use`

- **business_definition** · Timestamp the user first used the feature.
- **quality_trust** · NOT NULL · UTC · NULL on never-used (treat absence as non-adoption, not zero)
- **dos** · half-open windows
- **don'ts** · SUM/AVG · use as eligibility anchor (use `feature_flags.flag_state` for that)

### `public.feature_usage.use_count` — int · counter

- **business_definition** · Total times the user has used the feature.
- **values** · `0` = sentinel (record exists but never used) · `1+` = real usage
- **dos** · filter `use_count > 0` for adoption math (drop sentinels)
- **don'ts** · SUM `use_count` for "adoption" (gives event count, not user count)

### `public.feature_flags.flag_state` — categorical · eligibility filter

- **business_definition** · Lifecycle state of the feature flag.
- **values** · `off` · `dev_only` · `internal` · `beta` · `rolling_out` · `default_on` · `archived` — see samples below
- **dos** · always restrict to user-facing states for external adoption math
- **don'ts** · include off / dev_only / internal in user-facing adoption rates

### `public.feature_flags.feature_key` — key · dimension · row dimension

- **business_definition** · Feature identifier.
- **dos** · GROUP BY feature_key for per-feature adoption
- **don'ts** · aggregate the column itself

### `public.user_properties.plan_tier` — categorical · row dimension

- **business_definition** · Customer plan tier.
- **values** · `free` · `pro` · `business` · `enterprise`
- **dos** · GROUP BY plan_tier for tier-by-tier adoption
- **don'ts** · cross-tier average without `eligible_user` weight

### `public.events.user_id` — key · `COUNT(DISTINCT)` source

- **dos** · `COUNT(DISTINCT user_id)` for active / adopting users
- **don'ts** · `COUNT(*)` over events (over-counts power users)

---

## Value samples (column_value_samples)

### `public.feature_flags.flag_state`

| value | freq_est | rank | sample_type | external-eligible |
|---|---|---|---|---|
| `default_on` | 84 | 1 | top | yes |
| `rolling_out` | 22 | 2 | top | yes |
| `beta` | 11 | 3 | rare | yes |
| `internal` | 8 | 4 | rare | no |
| `dev_only` | 5 | 5 | rare | no |
| `off` | 3 | 6 | rare | no |
| `archived` | 14 | 7 | rare | no |

### `public.user_properties.plan_tier`

| value | freq_est | rank | sample_type | co_occurrence (industry) |
|---|---|---|---|---|
| `free` | 6,210 | 1 | top | mixed |
| `pro` | 2,840 | 2 | top | mid_market |
| `business` | 942 | 3 | top | enterprise · mid_market |
| `enterprise` | 218 | 4 | rare | enterprise |

---

## Template-level semantic (compact)

**Identity** · title `Feature Adoption by Segment` · analytical_pattern `comparison` · primary_purpose surface adoption gaps per (feature × tier) for product-led growth interventions · search_keywords feature adoption · adoption rate · feature usage · stickiness

**Decision record** · sort `feature_then_plan_tier` · agg_fn `count_distinct_div_count_distinct` · time_col `feature_usage.first_used_ts` · dimension `[feature_flags.feature_key, user_properties.plan_tier]` · date_range `last_30_days` · time_grain `aggregate`

**Business context** · default_aggregation `ratio_reconstruction` · default_grain `feature_x_plan_tier` · additive_metrics [eligible_users · adopting_users] · non_additive_metrics [adoption_rate]

**Filters** · `feature_flags.flag_state` (multi_select, default `[beta, rolling_out, default_on]`) · `user_properties.plan_tier` (multi_select) · `feature_usage.first_used_ts` (date_range, default `last_30_days`)

**Intent keywords** · ranking [highest adoption · lowest adoption · top tier] · comparison [tier vs tier · feature vs feature]

**Dashboard** · x = `feature_key` (categorical) · y = `adoption_rate` (percent) · color by `plan_tier` · recommended_visualizations [bar · grouped_bar · heatmap]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `feature_flags.flag_state IN ('beta', 'rolling_out', 'default_on')`.
2. CTE `eligible`: `COUNT(DISTINCT user_id)` per (feature_key, plan_tier) where the flag is enabled.
3. CTE `adopters`: `COUNT(DISTINCT user_id)` per (feature_key, plan_tier) with `first_used_ts` in last 30 days AND `use_count > 0`.
4. JOIN eligible ⨝ adopters on `(feature_key, plan_tier)`.
5. `adoption_rate = adopting_users::FLOAT / NULLIF(eligible_users, 0)`.

**Stop signals** · adoption against raw MAU · `AVG(is_adopted::INT)` · `COUNT(*)` for adopting-user count · including non-eligible flag states.

---

[← Persona: product-analytics](../../SKILL.md) ·
[← Department: growth](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

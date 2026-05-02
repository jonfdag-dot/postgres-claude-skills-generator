---
artifact_type: script_semantic_layer
script_id: ab-test-conversion-lift
business_title: A/B Test Conversion + Lift (z-test gated)
role: product-analytics
department: growth
chosen_primitives: [pre_aggregate_grain, ratio_reconstruction, statistical_significance_gate]
trigger_keywords: [A/B test, ab test, experiment, variant, control vs treatment, conversion lift, statistical significance, z-test]
tables_read: [public.experiment_assignments, public.experiment_outcomes]
metric_behavior: ratio
default_grain: experiment × variant
last_run: 2026-04-28
promoted_from: 2 verified question instances (2026-03-22 → 2026-04-28)
status: verified
---

# A/B Test Conversion + Lift (z-test gated)

> **Business question:** "For experiment X, what is the conversion
> rate per variant, the lift (treatment vs control), and is the
> result statistically significant at 95%?"

Conversion = `COUNT(DISTINCT converted_user_id) /
NULLIF(COUNT(DISTINCT exposed_user_id), 0)` per variant. Lift =
`(p_treatment − p_control) / NULLIF(p_control, 0)`. Significance =
two-proportion z-test; `|z| >= 1.96` gates the "winner" claim.

**Sister scripts** · [feature-adoption-by-segment](../feature-adoption-by-segment/README.md) (adoption-side companion).

---

## Result table

One row per (experiment_id × variant). Each row reports exposure
count, conversion count, conversion rate, lift vs control, and the
two-proportion z-statistic with a gate flag.

### Columns

| column | type | role | description |
|---|---|---|---|
| `experiment_id` | text | dimension | Experiment identifier |
| `variant` | text | dimension | One of `control` · `treatment_a` · `treatment_b` (`holdout` excluded) |
| `exposed_users` | bigint | metric | `COUNT(DISTINCT user_id)` assigned to this variant |
| `converted_users` | bigint | metric | `COUNT(DISTINCT user_id)` with at least one outcome event after `assigned_ts` |
| `conversion_rate` | numeric | derived | `converted_users / NULLIF(exposed_users, 0)` |
| `lift_vs_control` | numeric | derived | `(this_rate − control_rate) / NULLIF(control_rate, 0)` (NULL on control row) |
| `z_statistic` | numeric | derived | Two-proportion z-stat vs control (NULL on control row) |
| `is_significant_95` | boolean | gate | `ABS(z_statistic) >= 1.96` |

Ordered by `experiment_id, variant`.

---

## Dos and don'ts

**Dos** · anchor outcome windows to `assigned_ts` (exposure-anchored, NOT signup-anchored) · pre-aggregate at variant grain BEFORE computing rate · `HAVING COUNT(DISTINCT user_id) >= 100` per variant (sample-size floor) · two-proportion z-test for significance · gate the "winner" claim on `|z| >= 1.96` · exclude `variant = 'holdout'` from treatment-vs-control comparison.

**Don'ts** · count outcome events from BEFORE `assigned_ts` (pre-exposure events do NOT belong to the variant) · report a sub-95% lift as "winning" — that's noise · `COUNT(*)` for exposed/converted users (over-counts power users) · include holdout in lift math (report holdout separately as a baseline check) · skip `NULLIF` (zero-conversion control breaks lift division).

---

## Per-column details

### `public.experiment_assignments.assigned_ts` — time · timestamptz · `exposure_anchor`

- **business_definition** · Timestamp the user was assigned to a variant; the **anchor** for the result window.
- **quality_trust** · NOT NULL · UTC · enforced unique per (user_id, experiment_id)
- **dos** · always anchor outcome windows to assigned_ts
- **don'ts** · use signup_ts as a substitute (signup-anchored windows include pre-exposure behavior)

### `public.experiment_outcomes.outcome_ts` — time · timestamptz · `outcome_event_time`

- **business_definition** · Timestamp the success event fired.
- **dos** · always enforce post-exposure ordering
- **don'ts** · count outcomes before `assigned_ts`

### `public.experiment_assignments.variant` — categorical · partition · row dimension

- **business_definition** · Variant label.
- **values** · `control` · `treatment_a` · `treatment_b` · `holdout` (excluded from lift math; reported separately)
- **dos** · GROUP BY variant; identify control as `'control'`
- **don'ts** · include `holdout` in treatment-vs-control comparisons

### `public.experiment_assignments.user_id` — key · `COUNT(DISTINCT)` source

- **dos** · `COUNT(DISTINCT user_id)` for both exposure and conversion
- **don'ts** · `COUNT(*)` (over-counts users with multiple assignment rows from upsert race conditions)

### `public.experiment_assignments.experiment_id` — key · partition

- **dos** · always filter to a specific `experiment_id`; lift is per-experiment
- **don'ts** · cross-experiment aggregation

---

## Value samples (column_value_samples)

### `public.experiment_assignments.variant`

| value | freq_est | rank | sample_type | included_in_lift_math |
|---|---|---|---|---|
| `control` | 10,420 | 1 | top | yes (baseline) |
| `treatment_a` | 10,380 | 2 | top | yes |
| `treatment_b` | 10,310 | 3 | top | yes |
| `holdout` | 1,050 | 4 | rare | no (separate baseline check) |

---

## Template-level semantic (compact)

**Identity** · title `A/B Test Conversion + Lift (z-test gated)` · analytical_pattern `experiment_evaluation` · primary_purpose surface ship/no-ship decisions for in-flight experiments with significance gating · search_keywords A/B test · experiment · variant · conversion lift · z-test · statistical significance

**Decision record** · sort `experiment_id_then_variant` · agg_fn `count_distinct_div_count_distinct` · time_col `experiment_assignments.assigned_ts` · dimension `[experiment_id, variant]` · date_range `experiment_lifetime` · time_grain `experiment-aggregate`

**Business context** · default_aggregation `ratio_reconstruction_with_zgate` · default_grain `experiment_x_variant` · additive_metrics [exposed_users · converted_users] · non_additive_metrics [conversion_rate · lift_vs_control · z_statistic]

**Filters** · `experiment_assignments.experiment_id` (text · required) · `experiment_assignments.variant` (multi_select, exclude `holdout`) · `experiment_assignments.assigned_ts` (date_range, default `experiment_lifetime`)

**Intent keywords** · comparison [variant vs control · lift] · gate [significant · 95% · ship · winner]

**Dashboard** · x = `variant` (categorical) · y₁ = `conversion_rate` (percent) · y₂ = `lift_vs_control` (percent) · color by `is_significant_95` (binary, hsl(--accent) for true · hsl(--muted) for false) · recommended_visualizations [bar · table · waterfall]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `experiment_id = :experiment_id` AND `variant != 'holdout'`.
2. CTE `exposure`: `COUNT(DISTINCT user_id)` per variant from `experiment_assignments`.
3. CTE `outcomes`: `COUNT(DISTINCT user_id)` per variant from `experiment_outcomes` joined to assignments where `outcome_ts > assigned_ts`.
4. JOIN; compute `conversion_rate` per variant.
5. Cross-join the control variant's rate; compute `lift_vs_control` and the two-proportion z-statistic.
6. `HAVING exposed_users >= 100` (sample-size floor).

**Stop signals** · pre-exposure outcome events · sub-95% lift reported as "winning" · `COUNT(*)` for exposure/conversion counts · holdout in lift math.

---

[← Persona: product-analytics](../../SKILL.md) ·
[← Department: growth](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

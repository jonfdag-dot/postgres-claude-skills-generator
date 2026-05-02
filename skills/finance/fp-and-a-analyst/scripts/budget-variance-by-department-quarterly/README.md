---
artifact_type: script_semantic_layer
script_id: budget-variance-by-department-quarterly
business_title: Budget Variance by Department — Quarterly
role: fp-and-a-analyst
department: finance
chosen_primitives: [pre_aggregate_grain, forecast_vs_actual, ratio_reconstruction]
trigger_keywords: [budget variance, OPEX variance, plan vs actual, variance by department, variance %, FvA, departmental variance]
tables_read: [public.budget_lines, public.actuals, public.opex_categories, public.scenarios]
metric_behavior: ratio
default_grain: department × quarter × current_scenario
last_run: 2026-04-24
promoted_from: 3 verified question instances (2026-02-12 → 2026-04-24)
status: verified
---

# Budget Variance by Department — Quarterly

> **Business question:** "What is the budget variance ($ and %)
> for each department, quarter by quarter, against the current
> scenario?"

Variance = `actuals − planned`. **Variance %** = `variance /
NULLIF(planned, 0)`. Reconstructed at department-grain BEFORE
division — never an `AVG` of per-line variance %.

**Sister scripts** · [runway-and-burn-monthly](../runway-and-burn-monthly/README.md) (cash-side companion).

---

## Result table

One row per (department × quarter) over the trailing 4 quarters,
filtered to the current scenario. Each row reports planned, actual,
absolute variance, and variance %.

### Columns

| column | type | role | description |
|---|---|---|---|
| `department_name` | text | dimension | One of `engineering` · `sales` · `marketing` · `g&a` · `operations` |
| `quarter` | timestamp | time | First day of the quarter bucket |
| `planned_usd` | numeric | metric | `SUM(budget_lines.amount_usd)` for the bucket |
| `actual_usd` | numeric | metric | `SUM(actuals.amount_usd)` for the bucket |
| `variance_usd` | numeric | derived | `actual_usd − planned_usd` |
| `variance_pct` | float | derived | `variance_usd / NULLIF(planned_usd, 0)` |

Ordered by `quarter DESC, ABS(variance_pct) DESC` (largest variances surface first).

---

## Dos and don'ts

**Dos** · pre-aggregate planned AND actual at (department × quarter) BEFORE dividing · join on `(line_id, period)` for `forecast_vs_actual` shape · filter `scenarios.is_current = true` for the in-flight plan · `NULLIF(planned_usd, 0)` for the % denominator · half-open quarter window.

**Don'ts** · `AVG(per_line_variance_pct)` — `avg_of_ratios` (small lines dominate) · compare actuals to a stale scenario without explicit caveat · omit `scenario_id` filter (multiple plans collide) · divide by zero when a line has $0 planned (must `NULLIF`).

---

## Per-column details

### `public.budget_lines.amount_usd` — metric · USD · additive

- **business_definition** · Planned dollars per line item × period × scenario, USD pre-converted.
- **quality_trust** · consistency `0.98` · completeness `1.0` · zero nulls in current scenario · reconciles to plan-of-record file
- **dos** · SUM at (department × quarter) before computing variance %
- **don'ts** · per-line variance then AVG · ignore scenario_id
- **hardening** · is_additive `true` · metric_behavior `tally`

### `public.actuals.amount_usd` — metric · USD · additive

- **business_definition** · Realized dollars per line item × period.
- **quality_trust** · consistency `0.97` · completeness varies (in-flight period rows may NULL until close) · reconciles to GL
- **dos** · SUM at (department × quarter) · treat NULL as $0 only at month-close
- **don'ts** · INNER JOIN to budget_lines (drops planned-but-unspent lines) · sum across an in-flight period without flagging
- **hardening** · is_additive `true` · metric_behavior `tally`

### `public.scenarios.scenario_id` — key · explicit per-read filter

- **business_definition** · Plan-of-record identifier (Plan, Q2-Reforecast, Stretch, Base).
- **values** · `Plan` · `Q1-Reforecast` · `Q2-Reforecast` · `Stretch` · `Base` — only one is `is_current = true`
- **quality_trust** · `is_current` flag enforced exclusive
- **dos** · always specify · use `is_current` for live FvA
- **don'ts** · omit (multiple plans collide) · compare actuals to a non-current plan without caveat

### `public.opex_categories.department_name` — dimension · row dimension

- **business_definition** · Department / cost-center label.
- **values** · `engineering` · `sales` · `marketing` · `g&a` · `operations` — see samples below
- **quality_trust** · zero nulls · low cardinality (5 distinct)
- **dos** · GROUP BY for variance rollups
- **don'ts** · aggregate the column itself

### `public.budget_lines.period` — time · date · `period_anchor`

- **business_definition** · First day of the budget period (month grain at the line level; bucketed to quarter for this query).
- **quality_trust** · NOT NULL · always month-aligned
- **dos** · half-open windows · quarterly `DATE_TRUNC`
- **don'ts** · SUM/AVG dates

---

## Value samples (column_value_samples)

### `public.opex_categories.department_name`

| value | freq_est | rank | sample_type | co_occurrence (period) |
|---|---|---|---|---|
| `engineering` | 88 | 1 | top | [2024-01-01 → 2026-04-01] |
| `sales` | 64 | 2 | top | [2024-01-01 → 2026-04-01] |
| `marketing` | 52 | 3 | top | [2024-01-01 → 2026-04-01] |
| `g&a` | 41 | 4 | top | [2024-01-01 → 2026-04-01] |
| `operations` | 37 | 5 | top | [2024-01-01 → 2026-04-01] |

### `public.scenarios` (filterable join target)

| scenario_name | is_current | sample_type | co_occurrence (period range) |
|---|---|---|---|
| `Q2-Reforecast` | `true` | top | [2026-04-01 → 2026-12-31] |
| `Plan` | `false` | top | [2026-01-01 → 2026-12-31] |
| `Q1-Reforecast` | `false` | top | [2026-01-01 → 2026-12-31] |
| `Stretch` | `false` | rare | [2026-01-01 → 2026-12-31] |

---

## Template-level semantic (compact)

**Identity** · title `Budget Variance by Department — Quarterly` · analytical_pattern `forecast_vs_actual` · primary_purpose surface department-level variance for QBR / monthly review · search_keywords budget variance · OPEX variance · plan vs actual · FvA · departmental variance

**Decision record** · sort `quarter_desc_then_abs_variance_desc` · agg_fn `sum` · time_col `budget_lines.period` · dimension `opex_categories.department_name` · date_range `trailing_4_quarters_start → current` · time_grain `quarterly`

**Business context** · default_aggregation `sum` · default_grain `quarterly` · additive_metrics [budget_lines.amount_usd · actuals.amount_usd] · non_additive_metrics [variance_pct]

**Filters** · `scenarios.is_current` (boolean, default `true`) · `opex_categories.department_name` (multi_select) · `period` (date_range, default `trailing_4_quarters`)

**Intent keywords** · ranking [largest variance · top variance · biggest miss] · comparison [vs plan · vs forecast · over budget · under budget]

**Dashboard** · x = `period` (date_quarter) · y₁ = `variance_pct` (percent, ratio_reconstruction) · y₂ = `variance_usd` (currency_usd) · color [hsl(--destructive) for over · hsl(--accent) for under] · recommended_visualizations [bar · waterfall · table]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `scenarios.is_current = true` (the live plan).
2. Filter `period >= CURRENT_DATE - INTERVAL '4 quarters'` (half-open).
3. Pre-aggregate `budget_lines.amount_usd` and `actuals.amount_usd` at (department_name × quarter) in CTEs.
4. JOIN on `(department_name, quarter)` (`forecast_vs_actual` shape).
5. Compute `variance_usd = actual − planned` and `variance_pct = variance / NULLIF(planned, 0)`.

**Stop signals** · `AVG(per_line_variance_pct)` · stale-scenario comparison · missing `NULLIF` on $0 planned lines · in-flight period rows treated as final without a partial-period flag.

---

[← Persona: fp-and-a-analyst](../../SKILL.md) ·
[← Department: finance](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

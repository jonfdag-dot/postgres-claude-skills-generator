---
artifact_type: script_semantic_layer
script_id: runway-and-burn-monthly
business_title: Runway & Monthly Burn
role: fp-and-a-analyst
department: finance
chosen_primitives: [cumulative_running_total, period_over_period_lag, snapshot_latest]
trigger_keywords: [runway, runway months, burn rate, burn, monthly burn, cash months, months of cash, cash position trajectory]
tables_read: [public.cash_balances, public.actuals]
metric_behavior: derived
default_grain: month × trailing-13
last_run: 2026-04-28
promoted_from: 3 verified question instances (2026-02-08 → 2026-04-28)
status: verified
---

# Runway & Monthly Burn

> **Business question:** "What is our monthly net burn over the
> trailing 13 months, and given the latest cash balance and the
> trailing-3-month average burn, how many months of runway do we
> have?"

Net burn = `outflow − revenue` per month. Runway = `latest cash /
trailing_3mo_avg_burn`. Reads `cash_balances` (month-end snapshot
fact) and `actuals` (in-flow + out-flow events).

**Sister scripts** · [budget-variance-by-department-quarterly](../budget-variance-by-department-quarterly/README.md) (variance companion).

---

## Result table

One row per month over the trailing 13 months, plus a derived
runway value attached to the latest row.

### Columns

| column | type | role | description |
|---|---|---|---|
| `month` | timestamp | time | First day of the month |
| `cash_eom_usd` | numeric | metric | End-of-month cash balance (snapshot, USD) |
| `outflow_usd` | numeric | metric | `SUM(actuals.amount_usd)` where `flow_direction='out'` |
| `inflow_usd` | numeric | metric | `SUM(actuals.amount_usd)` where `flow_direction='in'` |
| `net_burn_usd` | numeric | derived | `outflow_usd − inflow_usd` |
| `mom_burn_delta_usd` | numeric | derived | `net_burn_usd − LAG(net_burn_usd) OVER (ORDER BY month)` |
| `trailing_3mo_avg_burn_usd` | numeric | derived | `AVG(net_burn_usd) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` |
| `runway_months` | float | derived | `cash_eom_usd / NULLIF(trailing_3mo_avg_burn_usd, 0)` (latest row only; NULL on others) |

Ordered by `month DESC`.

---

## Dos and don'ts

**Dos** · use snapshot semantics on `cash_balances` (`ROW_NUMBER` per `(month_end, account_id)` ORDER BY `snapshot_ts DESC`) · trailing-3-month average for runway denominator (single-month burn is too noisy) · `NULLIF(burn, 0)` for the runway division · annotate the in-flight month as partial.

**Don'ts** · `SUM(cash_balances.amount_usd)` across days (snapshot fact) · single-month burn for runway (one bad month produces unreal runway) · gross burn for runway without explicit caveat · ignore inflow when defining burn (default is NET).

---

## Per-column details

### `public.cash_balances.amount_usd` — metric · USD · **snapshot** (NOT additive across time)

- **business_definition** · End-of-month cash position per account, USD.
- **quality_trust** · consistency `1.0` · completeness `1.0` · NOT NULL · reconciles to bank statements
- **dos** · use latest snapshot per month · sum across `account_id` within a month (additive across accounts) · half-open windows
- **don'ts** · SUM across months (double-counts pallets) · AVG across days (skews toward zero on weekends)
- **hardening** · is_additive `false` (across time) · is_additive `true` (across account_id within a month) · metric_behavior `snapshot`

### `public.actuals.amount_usd` — metric · USD · additive · with `flow_direction` partition

- **business_definition** · Realized cash flow, USD; `flow_direction ∈ {in, out}` partitions revenue from spend.
- **quality_trust** · consistency `0.97` · in-flight period rows may NULL until close · reconciles to GL
- **dos** · partition by `flow_direction` BEFORE summing · pre-aggregate at month grain BEFORE LAG()
- **don'ts** · sum across `flow_direction` without partition (collapses inflow + outflow to one number) · LAG over raw rows
- **hardening** · is_additive `true` · metric_behavior `tally`

### `public.cash_balances.snapshot_ts` — time · timestamptz · `snapshot_anchor`

- **business_definition** · Timestamp the cash snapshot was captured.
- **quality_trust** · NOT NULL · UTC · daily cadence on weekdays
- **dos** · take latest per month_end
- **don'ts** · AVG across snapshots (skews toward zero on weekends)

### `public.actuals.flow_direction` — categorical · partition

- **business_definition** · In-flow vs out-flow label.
- **values** · `out` (62,184 · top) · `in` (8,443 · top)
- **dos** · partition before SUM
- **don'ts** · ignore (collapses burn to gross flow)

---

## Value samples (column_value_samples)

### `public.actuals.flow_direction`

| value | freq_est | rank | sample_type | co_occurrence (period) |
|---|---|---|---|---|
| `out` | 62,184 | 1 | top | [2024-01-01 → 2026-04-30] |
| `in` | 8,443 | 2 | top | [2024-01-01 → 2026-04-30] |

---

## Template-level semantic (compact)

**Identity** · title `Runway & Monthly Burn` · analytical_pattern `time_series_with_derived_kpi` · primary_purpose surface monthly burn trajectory and current runway · search_keywords runway · runway months · burn · monthly burn · cash months

**Decision record** · sort `month_desc` · top_n `13` · agg_fn `sum` · time_col `month` · dimension `null` · date_range `trailing_13_months_start → current` · time_grain `monthly`

**Business context** · default_aggregation `sum (with flow_direction partition)` · default_grain `monthly` · additive_metrics [actuals.amount_usd] · non_additive_metrics [cash_balances.amount_usd · runway_months]

**Filters** · `actuals.period` (date_range, default `trailing_13_months`) · `actuals.flow_direction` (multi_select, default `[in, out]`)

**Intent keywords** · trend [burn trend · burn curve · MoM burn] · ranking [highest burn month · lowest burn month] · forecast [runway · cash months · how long]

**Dashboard** · x = `month` (date_month) · y₁ = `net_burn_usd` (currency_usd) · y₂ = `cash_eom_usd` (currency_usd) · single-value KPI tile = `runway_months` · color [hsl(--destructive) · hsl(--primary)] · recommended_visualizations [line · area · combo · kpi_tile]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Snapshot CTE: `ROW_NUMBER() OVER (PARTITION BY month_end, account_id ORDER BY snapshot_ts DESC) = 1` to take the latest cash per month-end; SUM across `account_id`.
2. Flow CTE: pre-aggregate `actuals.amount_usd` at month grain partitioned by `flow_direction`; `outflow_usd − inflow_usd` is net burn.
3. Window functions on the joined CTE: `LAG(net_burn_usd)` for MoM delta; `AVG(net_burn_usd) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` for trailing-3 burn.
4. Runway: latest-row `cash_eom_usd / NULLIF(trailing_3mo_avg_burn_usd, 0)`. Older rows return NULL.

**Stop signals** · SUM across months on cash_balances (snapshot fact) · single-month burn for runway · gross burn (outflow only) without caveat · ignoring `flow_direction` partition.

---

[← Persona: fp-and-a-analyst](../../SKILL.md) ·
[← Department: finance](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

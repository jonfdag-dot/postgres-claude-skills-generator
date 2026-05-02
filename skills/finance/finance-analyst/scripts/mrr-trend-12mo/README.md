---
artifact_type: script_semantic_layer
script_id: mrr-trend-12mo
business_title: MRR Trend — Trailing 12 Months
role: finance-analyst
department: finance
chosen_primitives: [pre_aggregate_grain, period_over_period_lag]
trigger_keywords: [MRR, MRR trend, MRR over 12 months, monthly recurring revenue, monthly recurring revenue trend, TTM MRR, MoM revenue]
tables_read: [public.revenue]
metric_behavior: tally
default_grain: month × trailing-13
last_run: 2026-04-18
promoted_from: 3 verified question instances (2026-02-22 → 2026-04-18)
status: verified
---

# MRR Trend — Trailing 12 Months

> **Business question:** "How has monthly recurring revenue (MRR)
> moved over the last 13 months, with month-over-month deltas in
> absolute USD and percent?"

13 months (not 12) so the first row in the output has a non-NULL
`LAG()` value. Single-series view (no segment breakdown). Reads
`public.revenue` only — no joins.

**Sister scripts** · [arr-by-segment](../arr-by-segment/README.md) (forward-looking ARR) · [renewal-recognition](../renewal-recognition/README.md) (renewal-only slice).

---

## Result table

One row per month over the trailing 13 months. Each row is the
total recognized revenue for that month plus the absolute and
percent change versus the prior month.

### Columns

| column | type | role | description |
|---|---|---|---|
| `month` | timestamp | time | First day of the month (DATE_TRUNC bucket) |
| `mrr_usd` | numeric | metric | Total recognized revenue for the month, USD |
| `mom_delta_usd` | numeric | derived | `mrr_usd − LAG(mrr_usd)`; NULL on the first row |
| `mom_delta_pct` | numeric | derived | `100 × delta / NULLIF(prior, 0)`, rounded to 2 decimals |

Ordered by `month DESC`.

---

## Dos and don'ts

**Dos** · pre-aggregate at month grain BEFORE applying `LAG()` · `NULLIF(LAG(...), 0)` for the percent denominator · annotate the partial in-progress month if displayed · `ORDER BY month` in the LAG window.

**Don'ts** · `LAG()` over raw event rows (yields prior event, not prior month) · mix rolling-30-day with calendar-month grains · `AVG(mom_delta_pct)` for "average growth" (use CAGR shape) · omit `NULLIF` (zero-revenue months trigger division-by-zero).

---

## Per-column details

### `public.revenue.amount_usd` — metric · USD · additive

- **definition** · USD-normalized recognized revenue per recognition event. See SKILL.md §2.1 for canonical formula + additivity class.
- **dos** · SUM at month grain BEFORE LAG · pair with `status = 'recognized'`
- **don'ts** · AVG amount_usd · LAG() over raw rows

### `public.revenue.recognition_ts` — time · timestamptz · `event_time`

- **definition** · Timestamp at which a revenue dollar was recognized. See SKILL.md §2.4 for time-role rules.
- **dos** · half-open windows · `DATE_TRUNC('month', recognition_ts)` for the trend bucket
- **don'ts** · SUM/AVG timestamps

### `public.revenue.status` — categorical · lifecycle dimension

- **definition** · Lifecycle state of a revenue event. See SKILL.md §2.5 for canonical values + always-on `status = 'recognized'` filter rule.
- **dos** · filter on every MRR rollup
- **don'ts** · omit (pending/reversed leak)

---

## Template-level semantic (compact)

**Identity** · title `MRR Trend — Trailing 12 Months` · analytical_pattern `time_series` · primary_purpose surface the canonical MRR curve for finance reviews; identify cliffs / spikes / inflection points · search_keywords MRR · monthly recurring revenue · MRR trend · MoM revenue · revenue trend · month over month

**Decision record** · sort `month_desc` · top_n `13` · agg_fn `sum` · time_col `revenue.recognition_ts` · dimension `null` · date_range `trailing_13_months_start → current` · time_grain `monthly`

**Business context** · default_aggregation `sum` · default_grain `monthly` · additive_metrics [revenue.amount_usd] · non_additive_metrics [mom_delta_pct]

**Filters** · `revenue.status` (select, default `recognized`) · `revenue.recognition_ts` (date_range, default `trailing_13_months`)

**Intent keywords** · trend [trend · over time · last year · month over month · MoM · trajectory · curve] · comparison [vs prior · prior month · last month]

**Dashboard** · x = `revenue.recognition_ts` (date_month) · y₁ = `revenue.amount_usd` (currency_usd, sum) · y₂ = `revenue.amount_usd` (percent, lag_diff_pct) · color [hsl(--primary) · hsl(--accent)] · recommended_visualizations [line · area · bar]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `revenue.recognition_ts >= CURRENT_DATE - INTERVAL '13 months' AND revenue.status = 'recognized'`.
2. GROUP BY `DATE_TRUNC('month', recognition_ts)` in a CTE.
3. `LAG(mrr_usd) OVER (ORDER BY month)` on the CTE (NEVER on raw rows).
4. Wrap the percent-delta denominator in `NULLIF(LAG(...), 0)`.

**Stop signals** · including the in-progress month without the partial flag · `AVG(mom_delta_pct)` for "average MoM growth" (use CAGR shape) · mixing rolling-30-day with calendar-month grains · LAG over raw event rows.

---

[← Persona: finance-analyst](../../SKILL.md) ·
[← Department: finance](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

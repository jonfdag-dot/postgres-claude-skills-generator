---
artifact_type: script_semantic_layer
script_id: gross-margin-by-segment-quarterly
business_title: Gross Margin by Segment — Quarterly
role: finance-analyst
department: finance
chosen_primitives: [pre_aggregate_grain, ratio_reconstruction]
trigger_keywords: [gross margin, GM, GM%, gross margin percentage, margin by segment, segment margin, segment profitability, gross profit, gross profit by segment]
tables_read: [public.revenue, public.contracts, public.segments, public.cogs]
metric_behavior: ratio
default_grain: segment × quarter
last_run: 2026-04-25
promoted_from: 2 verified question instances (2026-03-04 → 2026-04-25)
status: verified
---

# Gross Margin by Segment — Quarterly

> **Business question:** "What is gross margin (revenue − COGS) and
> gross margin % per business segment, per quarter, for the last
> 4 quarters?"

The canonical "which segments are most profitable" view. Margin
must be **reconstructed at segment grain** — `SUM(revenue) -
SUM(cogs)` THEN divided — never averaged from per-contract margins
(that's `avg_of_ratios`). Period-aligned COGS join prevents phantom
margin swings.

**Sister scripts** · [cogs-revenue-alignment](../cogs-revenue-alignment/README.md) (drill-down diagnostic when GM% surprises) · [arr-by-segment](../arr-by-segment/README.md) (revenue-only sister) · [renewal-recognition](../renewal-recognition/README.md) (revenue subset by motion).

---

## Result table

One row per (segment × quarter) over the trailing 4 quarters.
Revenue and COGS are summed at segment grain BEFORE division.
COGS is LEFT-JOINed to keep revenue rows with no matched COGS;
those surface as `NULL cogs_usd` and must be flagged.

### Columns

| column | type | role | description |
|---|---|---|---|
| `segment_name` | text | dimension | Business segment — one of `enterprise` · `mid_market` · `smb` · `partner` |
| `quarter` | timestamp | time | First day of the quarter bucket |
| `revenue_usd` | numeric | metric | `SUM(revenue.amount_usd)`, USD |
| `cogs_usd` | numeric | metric | `SUM(cogs.amount_usd)`, USD; **NULL = COGS coverage gap, do not silently 100%-margin** |
| `gross_profit_usd` | numeric | derived | `revenue_usd - cogs_usd` |
| `gross_margin_pct` | float | derived | `gross_profit_usd / NULLIF(revenue_usd, 0)` |

Ordered by `quarter DESC, gross_margin_pct DESC`.

---

## Dos and don'ts

**Dos** · pre-aggregate revenue AND COGS at (segment × quarter) BEFORE dividing · LEFT JOIN cogs (not INNER) to keep revenue rows with no matched COGS · enforce `DATE_TRUNC('quarter', cogs.recognition_ts) = DATE_TRUNC('quarter', revenue.recognition_ts)` in the JOIN · surface NULL `cogs_usd` rows explicitly.

**Don'ts** · `AVG(per_contract_margin_pct)` (`avg_of_ratios`) · INNER JOIN cogs (drops revenue rows with no matched COGS) · omit the period match in the COGS JOIN (phantom margin swings) · `AVG(gross_margin_pct)` for "company-wide GM%" (use `SUM(profit) / NULLIF(SUM(rev), 0)`).

---

## Per-column details

### `public.revenue.amount_usd` — metric · USD · additive

- **definition** · USD-normalized recognized revenue per recognition event. See SKILL.md §2.1 for canonical formula + additivity class.
- **dos** · SUM at (segment × quarter) before computing GM%
- **don'ts** · per-contract margin then AVG

### `public.cogs.amount_usd` — metric · USD · additive

- **business_definition** · USD-normalized cost-of-goods-sold per recognition event, attributed to a contract.
- **quality_trust** · consistency `0.93` · completeness `0.91` · 9% of contracts have no COGS row in the last 4 quarters (coverage gap) · reconciles to GL COGS account within 0.4%
- **dos** · LEFT JOIN cogs ON `contract_id` AND quarter match · SUM at (segment × quarter)
- **don'ts** · INNER JOIN (drops revenue with no matched COGS) · ignore COGS coverage gaps
- **hardening** · is_additive `true` · metric_behavior `tally` · comparison_direction `lower_is_better`

### `public.cogs.recognition_ts` — time · timestamptz · `event_time`

- **business_definition** · Timestamp at which a COGS dollar was recognized.
- **quality_trust** · NOT NULL · UTC · 4% of rows recognize in a different quarter than their paired revenue (alignment gap)
- **dos** · `DATE_TRUNC('quarter', ...)` in the JOIN condition
- **don'ts** · omit the quarter match (phantom swings)

### `public.revenue.recognition_ts` — time · timestamptz · `event_time`

- **definition** · Timestamp at which a revenue dollar was recognized. See SKILL.md §2.4 for time-role rules.
- **dos** · half-open windows · quarterly bucket
- **don'ts** · SUM/AVG timestamps

### `public.revenue.status` — categorical · lifecycle dimension

- **definition** · Lifecycle state of a revenue event. See SKILL.md §2.5 for canonical values + always-on `status = 'recognized'` filter rule.
- **dos** · filter on every margin rollup
- **don'ts** · omit

### `public.segments.segment_name` — dimension · categorical · row dimension

- **business_definition** · Customer-tier segment.
- **values** · `enterprise` (218 · top) · `mid_market` (624 · top) · `smb` (941 · top) · `partner` (59 · rare)
- **quality_trust** · zero null · low cardinality (4 distinct)
- **dos** · GROUP BY segment_name for margin rollups
- **don'ts** · aggregate segment_name itself

---

## Value samples (column_value_samples)

`public.revenue.status` canonical values + always-on filter: see SKILL.md §2.5.

### `public.segments.segment_name`

| value | freq_est | rank | sample_type | co_occurrence (signed_ts) | co_occurrence (contract_type) |
|---|---|---|---|---|---|
| `enterprise` | 218 | 1 | top | [2018-06-04 → 2026-04-15] | new_logo · renewal · expansion · one_time |
| `mid_market` | 624 | 2 | top | [2019-01-12 → 2026-04-28] | new_logo · renewal · expansion · one_time |
| `smb` | 941 | 3 | top | [2020-03-22 → 2026-04-29] | new_logo · renewal · one_time |
| `partner` | 59 | 4 | rare | [2021-09-02 → 2026-03-19] | new_logo · renewal |

---

## Template-level semantic (compact)

**Identity** · title `Gross Margin by Segment — Quarterly` · analytical_pattern `comparison` · primary_purpose surface segment-level profitability for board reviews and mix-shift analysis · search_keywords gross margin · GM% · segment margin · segment profitability · gross profit · margin by segment

**Decision record** · sort `quarter_desc_then_gm_pct_desc` · agg_fn `sum` · time_col `revenue.recognition_ts` · dimension `segments.segment_name` · date_range `trailing_4_quarters_start → current` · time_grain `quarterly`

**Business context** · default_aggregation `sum` · default_grain `quarterly` · additive_metrics [revenue.amount_usd · cogs.amount_usd] · non_additive_metrics [gross_margin_pct]

**Filters** · `revenue.status` (select, default `recognized`) · `segments.segment_name` (multi_select) · `revenue.recognition_ts` (date_range, default `trailing_4_quarters`)

**Intent keywords** · trend [margin trend · margin curve · QoQ margin] · ranking [highest margin · lowest margin · most profitable segment] · comparison [vs last quarter · segment vs segment · mix shift]

**Dashboard** · x = `revenue.recognition_ts` (date_quarter) · y₁ = `gross_margin_pct` (percent, ratio_reconstruction) · y₂ = `gross_profit_usd` (currency_usd, sum_minus_sum) · color [hsl(--primary) · hsl(--accent) · hsl(--secondary) · hsl(--muted)] · recommended_visualizations [bar · heatmap · table · small_multiples]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `revenue.status = 'recognized'` AND `recognition_ts >= CURRENT_DATE - INTERVAL '4 quarters'`.
2. JOIN `revenue` → `contracts` → `segments`.
3. LEFT JOIN `cogs` ON `contract_id` AND `DATE_TRUNC('quarter', cogs.recognition_ts) = DATE_TRUNC('quarter', revenue.recognition_ts)`.
4. GROUP BY `(segment_name, quarter)` and reconstruct `gross_margin_pct` as `(SUM(revenue) - SUM(cogs)) / NULLIF(SUM(revenue), 0)`.

**Stop signals** · `cogs_usd IS NULL` rows quietly emitted as 100% margin (surface explicitly) · cross-segment `AVG(gross_margin_pct)` for "company-wide GM%" (`avg_of_ratios`) · INNER JOIN on COGS · per-contract margin then AVG.

---

[← Persona: finance-analyst](../../SKILL.md) ·
[← Department: finance](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

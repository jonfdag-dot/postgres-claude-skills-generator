---
artifact_type: script_semantic_layer
script_id: renewal-recognition
business_title: Renewal Revenue Recognition
role: finance-analyst
department: finance
chosen_primitives: [pre_aggregate_grain]
trigger_keywords: [renewal recognition, renewals, renewal revenue, contract renewals, NRR, net retention revenue, recurring renewal]
tables_read: [public.revenue, public.contracts, public.segments]
metric_behavior: tally
default_grain: quarter × segment × renewal-only
last_run: 2026-04-09
promoted_from: 2 verified question instances (2026-03-15 → 2026-04-09)
status: verified
---

# Renewal Revenue Recognition

> **Business question:** "How much recognized revenue came from
> contract renewals (NOT new logos) in each of the last four
> quarters, broken down by business segment?"

The renewal-only slice of recognized revenue. Used to isolate the
"stickiness" half of the P&L from "new growth". Numerator-side
input for NRR. Filters `contracts.contract_type = 'renewal'`.

**Sister scripts** · [arr-by-segment](../arr-by-segment/README.md) (forward-looking, all motions) · [mrr-trend-12mo](../mrr-trend-12mo/README.md) (monthly grain, all motions) · [gross-margin-by-segment-quarterly](../gross-margin-by-segment-quarterly/README.md) (profitability of the renewal book).

---

## Result table

One row per (quarter × segment) over the trailing 4 quarters,
filtered to renewal contracts only. Each row reports renewing
contract count and renewal revenue.

### Columns

| column | type | role | description |
|---|---|---|---|
| `quarter` | timestamp | time | First day of the quarter bucket |
| `segment_name` | text | dimension | Business segment — one of `enterprise` · `mid_market` · `smb` · `partner` |
| `renewing_contracts` | bigint | metric | `COUNT(DISTINCT contract_id)` for the bucket |
| `renewal_revenue_usd` | numeric | metric | Recognized renewal revenue, USD |

Ordered by `quarter DESC, renewal_revenue_usd DESC`.

---

## Dos and don'ts

**Dos** · filter `contract_type = 'renewal'` AND `status = 'recognized'` · pre-aggregate at (quarter × segment) BEFORE division/comparison · JOIN revenue → contracts on `contract_id` (NEVER `customer_id`) · `COUNT(DISTINCT contract_id)` for renewing-contract count.

**Don'ts** · mix `renewal` and `expansion` in the same bucket (different motions) · annualize this output ×4 without smoothing (renewals are quarterly-lumpy) · `COUNT(*)` for renewing contracts (use `COUNT(DISTINCT)`) · use `orders.order_type = 'renewal'` instead of `contracts.contract_type` (booking ≠ recognition).

---

## Per-column details

### `public.revenue.amount_usd` — metric · USD · additive

- **definition** · USD-normalized recognized revenue per recognition event. See SKILL.md §2.1 for canonical formula + additivity class.
- **dos** · SUM at (quarter × segment) grain
- **don'ts** · AVG amount_usd across renewing contracts

### `public.revenue.recognition_ts` — time · timestamptz · `event_time`

- **definition** · Timestamp at which a revenue dollar was recognized. See SKILL.md §2.4 for time-role rules.
- **dos** · half-open windows · quarterly bucket
- **don'ts** · SUM/AVG timestamps

### `public.revenue.status` — categorical · lifecycle dimension

- **definition** · Lifecycle state of a revenue event. See SKILL.md §2.5 for canonical values + always-on `status = 'recognized'` filter rule.
- **dos** · filter on every renewal rollup
- **don'ts** · omit

### `public.contracts.contract_type` — categorical · acquisition motion · **isolation filter for this query**

- **business_definition** · Acquisition motion the contract represents — set at signing; immutable.
- **values** · `new_logo` (1,108 · top) · `renewal` (612 · top) · `expansion` (81 · rare) · `one_time` (41 · rare) — see samples below
- **quality_trust** · zero null · low cardinality (4 distinct) · DB CHECK constraint enforced
- **dos** · filter `contract_type = 'renewal'` for renewal rollups · GROUP BY for new-vs-renewal-vs-expansion decomposition
- **don'ts** · aggregate `contract_type` as a metric · mix `renewal` + `expansion` in the same bucket

### `public.contracts.contract_id` — key · primary key · `COUNT(DISTINCT)` source

- **business_definition** · Primary key on contracts.
- **dos** · `COUNT(DISTINCT contract_id)` per (quarter × segment)
- **don'ts** · SUM / AVG · `COUNT(*)` (over-counts when revenue events repeat per contract)

### `public.segments.segment_name` — dimension · categorical · row dimension

- **business_definition** · Customer-tier segment assigned at contract signing.
- **values** · `enterprise` (218 · top) · `mid_market` (624 · top) · `smb` (941 · top) · `partner` (59 · rare)
- **dos** · GROUP BY segment_name
- **don'ts** · aggregate segment_name itself

---

## Value samples (column_value_samples)

### `public.contracts.contract_type`

| value | freq_est | rank | sample_type | co_occurrence (signed_ts) | co_occurrence (segment_name) |
|---|---|---|---|---|---|
| `new_logo` | 1,108 | 1 | top | [2018-06-04 → 2026-04-29] | enterprise · mid_market · smb · partner |
| `renewal` | 612 | 2 | top | [2019-04-01 → 2026-04-30] | enterprise · mid_market · smb · partner |
| `expansion` | 81 | 3 | rare | [2022-01-15 → 2026-04-22] | enterprise · mid_market · smb |
| `one_time` | 41 | 4 | rare | [2020-08-12 → 2026-04-11] | smb · partner |

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

**Identity** · title `Renewal Revenue Recognition` · analytical_pattern `comparison` · primary_purpose surface the renewal-only slice of recognized revenue for NRR / retention storytelling and renewal-pipeline reviews · search_keywords renewal · renewal revenue · renewals · NRR · net retention revenue · contract renewals · recurring renewal

**Decision record** · sort `quarter_desc_then_revenue_desc` · agg_fn `sum` · time_col `revenue.recognition_ts` · dimension `segments.segment_name` · date_range `trailing_4_quarters_start → current` · time_grain `quarterly`

**Business context** · default_aggregation `sum` · default_grain `quarterly` · additive_metrics [revenue.amount_usd] · non_additive_metrics [renewing_contracts_count_distinct]

**Filters** · `contracts.contract_type` (select, default `renewal`) · `revenue.status` (select, default `recognized`) · `segments.segment_name` (multi_select) · `revenue.recognition_ts` (date_range, default `trailing_4_quarters`)

**Intent keywords** · trend [over the last 4 quarters · quarterly trend] · ranking [which segment renews most · top renewing segment] · comparison [renewals vs new logos · renewal vs expansion]

**Dashboard** · x = `revenue.recognition_ts` (date_quarter) · y = `revenue.amount_usd` (currency_usd, sum) · color [hsl(--primary) · hsl(--accent) · hsl(--secondary) · hsl(--muted)] · default_filter `contracts.contract_type = 'renewal'` · recommended_visualizations [bar · stacked_bar · table]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `revenue.status = 'recognized'` AND `contracts.contract_type = 'renewal'`.
2. Filter `recognition_ts >= CURRENT_DATE - INTERVAL '4 quarters'` (half-open).
3. JOIN `revenue` → `contracts` on `contract_id`; `contracts` → `segments` on `segment_id`.
4. GROUP BY `(DATE_TRUNC('quarter', recognition_ts), segment_name)`.

**Stop signals** · mixing `renewal` + `expansion` in the same bucket · annualizing ×4 without smoothing for the quarterly-lumpy renewal cadence · counting renewals from `orders.order_type` · `COUNT(*)` for renewing contracts.

---

[← Persona: finance-analyst](../../SKILL.md) ·
[← Department: finance](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

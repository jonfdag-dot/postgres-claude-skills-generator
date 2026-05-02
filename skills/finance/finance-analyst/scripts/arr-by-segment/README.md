---
artifact_type: script_semantic_layer
script_id: arr-by-segment
business_title: Annual Recurring Revenue by Segment
role: finance-analyst
department: finance
chosen_primitives: [pre_aggregate_grain]
trigger_keywords: [ARR, ARR by segment, annual recurring revenue, annual recurring revenue by segment, segment ARR, ARR breakdown]
tables_read: [public.revenue, public.contracts, public.segments]
metric_behavior: tally
default_grain: segment × current_quarter
last_run: 2026-04-22
promoted_from: 4 verified question instances (2026-02-08 → 2026-04-22)
status: verified
---

# Annual Recurring Revenue by Segment

> **Business question:** "What is our annualized recurring revenue
> (ARR) broken down by business segment as of the most recent
> closed quarter?"

ARR is a forward-looking subscription metric — `last-closed-quarter
recognized revenue × 4`. It is **derived from recognized revenue
only** (never bookings, never invoices) and **annualized from the
most recent closed quarter**, not from a TTM sum (which would
back-load churned customers).

**Sister scripts** · [mrr-trend-12mo](../mrr-trend-12mo/README.md) (monthly grain) · [renewal-recognition](../renewal-recognition/README.md) (renewal-only slice) · [gross-margin-by-segment-quarterly](../gross-margin-by-segment-quarterly/README.md) (profitability companion).

---

## Result table

One row per business segment. ARR is computed as
`SUM(last-closed-quarter recognized revenue) × 4`, reconstructed at
the segment grain BEFORE annualization.

### Columns

| column | type | role | description |
|---|---|---|---|
| `segment_name` | text | dimension | Business segment — one of `enterprise` · `mid_market` · `smb` · `partner` |
| `arr_usd` | numeric | metric | Annualized recurring revenue (last-quarter sum × 4), USD |

Ordered by `arr_usd DESC`.

---

## Dos and don'ts

**Dos** · filter `r.status = 'recognized'` always · pre-aggregate at `segments.segment_name` BEFORE the ×4 · half-open quarter window `[last_quarter_start, last_quarter_end)` · convert FX at `recognition_ts` (not signing date) · `COUNT(DISTINCT contract_id)` for the active-contracts companion metric.

**Don'ts** · `SUM(orders.total_amount)` — that's bookings · `SUM(invoices.amount)` — that's billed · include `pending` / `reversed` rows · TTM × 1 instead of last-quarter × 4 · JOIN revenue → contracts on `customer_id` (use `contract_id`) · annualize at signing-date FX rate.

---

## Per-column details

Compact deep-dive sourced from `ai_semantic_attributes`. Each
column carries the canonical 8-section card; here we collapse to a
scannable line-per-attribute.

### `public.revenue.amount_usd` — metric · USD · additive

- **definition** · USD-normalized recognized revenue per recognition event. See SKILL.md §2.1 for canonical formula + additivity class.
- **dos** · SUM at (segment × quarter), then ×4 for ARR · pair with `status = 'recognized'` every time
- **don'ts** · AVG amount_usd across contracts (yields contract-size mean) · SUM without status filter (pending/reversed leak)

### `public.revenue.recognition_ts` — time · timestamptz · `event_time`

- **definition** · Timestamp at which a revenue dollar was recognized under ASC 606. See SKILL.md §2.4 for time-role rules.
- **dos** · half-open windows `>= start AND < end` · `DATE_TRUNC('quarter', recognition_ts)` for ARR bucket
- **don'ts** · SUM/AVG timestamps · bucket against signing or invoice date as a substitute

### `public.revenue.status` — categorical · lifecycle dimension

- **definition** · Lifecycle state of a revenue event. See SKILL.md §2.5 for canonical values + always-on `status = 'recognized'` filter rule.
- **dos** · filter on every revenue rollup · GROUP BY status when auditing pending/reversed pipelines
- **don'ts** · omit the filter (pending/reversed leak) · SUM amount_usd across statuses without grouping

### `public.revenue.contract_id` — key · FK to contracts

- **business_definition** · Foreign key to `public.contracts.contract_id`; the join anchor that ties a revenue event to its contract.
- **quality_trust** · FK constraint enforced · every revenue row resolves to a contract
- **dos** · JOIN `revenue.contract_id = contracts.contract_id` (NEVER `customer_id`)
- **don'ts** · SUM contract_ids (categorical identifier)

### `public.segments.segment_name` — dimension · categorical · row dimension

- **business_definition** · Mutually-exclusive customer-tier segment assigned by RevOps at contract signing. Canonical row dimension for ARR / GM% / NRR.
- **values** · `enterprise` (218 · top) · `mid_market` (624 · top) · `smb` (941 · top) · `partner` (59 · rare) — sourced from `column_value_samples` below
- **quality_trust** · zero null segments across 1,842 contracts · low cardinality (4 distinct) · mutually exclusive
- **dos** · GROUP BY segment_name for ARR / margin / renewal · compare segments by ABSOLUTE dollars (non-overlapping)
- **don'ts** · aggregate segment_name itself · assume an "all" or "total" row exists

---

## Value samples

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

**Identity** · title `Annual Recurring Revenue by Segment` · analytical_pattern `ranking` · primary_purpose surface segment-level ARR for board / investor / sales-planning audiences · search_keywords ARR · annual recurring revenue · segment ARR · run-rate · GAAP recognition

**Decision record** · sort `arr_usd_desc` · agg_fn `sum` · time_col `revenue.recognition_ts` · dimension `segments.segment_name` · date_range `last_closed_quarter_start → last_closed_quarter_end` · time_grain `quarterly`

**Business context** · default_aggregation `sum` · default_grain `quarterly` · additive_metrics [revenue.amount_usd] · non_additive_metrics (none)

**Filters** · `revenue.status` (select, default `recognized`) · `segments.segment_name` (multi_select) · `revenue.recognition_ts` (date_range, default `last_closed_quarter`)

**Intent keywords** · ranking [highest · largest · top segment · biggest · rank by ARR] · comparison [vs · across segments · between segments · compare segment]

**Dashboard** · x = `segments.segment_name` (category) · y = `revenue.amount_usd` (currency_usd, sum_x4) · color [hsl(--primary) · hsl(--accent) · hsl(--secondary) · hsl(--muted)] · default_filter `revenue.status = 'recognized'` · recommended_visualizations [bar · table · donut]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `revenue.status = 'recognized'`.
2. Filter `recognition_ts` to the half-open last-closed-quarter window `[DATE_TRUNC('quarter', CURRENT_DATE) - INTERVAL '3 months', DATE_TRUNC('quarter', CURRENT_DATE))`.
3. JOIN `revenue` → `contracts` on `contract_id` (NEVER `customer_id`).
4. JOIN `contracts` → `segments` on `segment_id`.
5. GROUP BY `segments.segment_name` BEFORE the `× 4` annualization.

**Stop signals** · FX at signing date (use `recognition_ts`) · including `pending`/`reversed` rows · TTM × 1 instead of last-quarter × 4 · JOIN on `customer_id` instead of `contract_id` · the in-progress quarter (partial period understates ARR).

---

[← Persona: finance-analyst](../../SKILL.md) ·
[← Department: finance](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

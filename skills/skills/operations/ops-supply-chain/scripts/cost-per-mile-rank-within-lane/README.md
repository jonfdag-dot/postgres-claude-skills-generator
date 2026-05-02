---
artifact_type: script_semantic_layer
script_id: cost-per-mile-rank-within-lane
business_title: Cost-Per-Mile Rank Within Lane
role: ops-supply-chain
department: operations
chosen_primitives: [pre_aggregate_grain, ratio_reconstruction]
trigger_keywords: [cost per mile, CPM, CPM rank, cheapest carrier, lane cost, carrier cost benchmark, lane median CPM]
tables_read: [public.shipments, public.carriers, public.lanes]
metric_behavior: ratio
default_grain: carrier × lane (trailing 90d)
last_run: 2026-04-19
promoted_from: 3 verified question instances (2026-03-01 → 2026-04-19)
status: verified
---

# Cost-Per-Mile Rank Within Lane

> **Business question:** "For each lane, rank carriers by
> cost-per-mile, with the lane median for context. Which carriers
> drift > 15% above the lane median (re-bid candidates)?"

CPM = `SUM(total_cost) / NULLIF(SUM(miles), 0)` at (carrier × lane)
grain. Rank computed WITHIN lane. Lane median via `PERCENTILE_CONT`
on the per-carrier CPMs.

**Sister scripts** · [otd-by-carrier-lane-monthly](../otd-by-carrier-lane-monthly/README.md) (quality-side companion).

---

## Result table

One row per (carrier × lane) over the trailing 90 days, ordered by
CPM rank within each lane. Lane median + percent-above-median
included for re-bid decisioning.

### Columns

| column | type | role | description |
|---|---|---|---|
| `lane_id` | text | dimension | Lane code (`US-EAST` … `AU-E`) |
| `carrier_name` | text | dimension | Carrier display name |
| `shipments` | bigint | metric | Sample size for this (carrier × lane) |
| `cpm` | numeric | derived | `SUM(total_cost) / NULLIF(SUM(miles), 0)`, USD/mile |
| `lane_median_cpm` | numeric | derived | `PERCENTILE_CONT(0.5)` of per-carrier CPMs in this lane |
| `pct_above_median` | numeric | derived | `100 × (cpm − lane_median_cpm) / lane_median_cpm` |
| `cpm_rank` | int | derived | `RANK() OVER (PARTITION BY lane_id ORDER BY cpm)` (1 = cheapest) |

Ordered by `lane_id, cpm_rank`.

---

## Dos and don'ts

**Dos** · pre-aggregate `total_cost` and `miles` at (carrier × lane) BEFORE dividing · `NULLIF(SUM(miles), 0)` for the rate denominator · `HAVING COUNT(*) >= 30` sample-size floor · always `s.miles > 0` (zero-mile rows are data errors) · always `s.status != 'cancelled'` and `c.contract_tier != 'spot'`.

**Don'ts** · `AVG(cpm_per_shipment)` — `avg_of_ratios`; small expensive shipments dominate · cross-lane CPM rank (lane miles differ) · INNER JOIN with surveys table (drops uncovered shipments) · include zero-mile shipments in denominator (division produces infinity).

---

## Per-column details

### `public.shipments.total_cost` — metric · USD · additive

- **business_definition** · Total transportation cost for the shipment, USD pre-converted at delivery date.
- **quality_trust** · zero nulls · reconciles to AP within 0.3%
- **dos** · SUM at (carrier × lane) before dividing
- **don'ts** · per-shipment CPM then AVG

### `public.shipments.miles` — metric · int · additive · denominator

- **business_definition** · Distance traveled for the shipment in miles; EU/APAC pre-normalized from km.
- **quality_trust** · `miles = 0` rows are data errors (~0.4%) — exclude
- **dos** · `s.miles > 0` filter · SUM at (carrier × lane)
- **don'ts** · include zero-mile rows · use unnormalized km

### `public.shipments.delivery_ts` — time · timestamptz · `event_time`

- **business_definition** · Timestamp the shipment was delivered.
- **dos** · half-open windows
- **don'ts** · SUM/AVG timestamps

### `public.lanes.lane_id` — dimension · key · partition for rank

- **business_definition** · Origin-destination lane code; rank operates WITHIN this dimension.
- **values** · 14 distinct (`US-EAST` · `US-MIDWEST` · `US-WEST` · `EU-CEN` · `EU-NOR` · `APAC-PAC` · `APAC-IND` · `MX-N` · `MX-S` · `CA-EAST` · `CA-WEST` · `BR-S` · `ZA-N` · `AU-E`)
- **dos** · always partition by lane_id for ranks
- **don'ts** · cross-lane rank (lane miles differ)

### `public.carriers.contract_tier` — categorical · scope filter

- **values** · `prime` · `standard` · `spot` (excluded for benchmarking)
- **dos** · exclude `spot` for fair carrier-vs-carrier comparison
- **don'ts** · include spot in CPM benchmarks (spot pricing is volatile)

---

## Value samples (column_value_samples)

### `public.lanes.lane_id`

| value | freq_est | rank | sample_type | co_occurrence (carriers) |
|---|---|---|---|---|
| `US-EAST` | 1,432,800 | 1 | top | FedEx · UPS · Estes · YRC |
| `US-MIDWEST` | 1,124,400 | 2 | top | UPS · Estes · ABF |
| `US-WEST` | 989,100 | 3 | top | FedEx · UPS · Werner |
| `EU-CEN` | 612,000 | 4 | top | DHL · DPD · Geodis |
| `MX-S` | 184,500 | 5 | rare | Estafeta · FedEx · UPS |

### `public.carriers.contract_tier`

| value | freq_est | rank | sample_type |
|---|---|---|---|
| `standard` | 177 | 1 | top |
| `prime` | 130 | 2 | top |
| `spot` | 33 | 3 | rare (excluded) |

---

## Template-level semantic (compact)

**Identity** · title `Cost-Per-Mile Rank Within Lane` · analytical_pattern `ranking` · primary_purpose surface re-bid candidates (carriers > 15% above lane median) · search_keywords cost per mile · CPM · lane cost · cheapest carrier

**Decision record** · sort `lane_id_then_cpm_asc` · agg_fn `sum_div_sum_with_rank` · time_col `shipments.delivery_ts` · dimension `lanes.lane_id` · date_range `last_90_days` · time_grain `aggregate (no time bucket)`

**Business context** · default_aggregation `ratio_reconstruction` · default_grain `aggregate_by_carrier_lane` · additive_metrics [shipments.total_cost · shipments.miles] · non_additive_metrics [cpm · cpm_rank · pct_above_median]

**Filters** · `shipments.status` (multi_select, exclude `cancelled`) · `carriers.contract_tier` (multi_select, exclude `spot`) · `shipments.delivery_ts` (date_range, default `last_90_days`) · `lanes.lane_id` (multi_select)

**Intent keywords** · ranking [cheapest · most expensive · CPM rank · top · bottom] · comparison [vs lane median · above median · re-bid candidate]

**Dashboard** · x = `cpm` (currency_per_mile) · y = `carrier_name` (categorical) · grouped by `lane_id` (small multiples) · color by `pct_above_median` (continuous, hsl(--destructive) above 15%) · recommended_visualizations [bar · small_multiples · table]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `s.status != 'cancelled'` AND `c.contract_tier != 'spot'` AND `s.miles > 0`.
2. Filter `delivery_ts >= CURRENT_DATE - INTERVAL '90 days'`.
3. Pre-aggregate at (carrier × lane) in a CTE: SUM(total_cost), SUM(miles), COUNT(*).
4. `HAVING COUNT(*) >= 30` (sample-size floor).
5. Lane medians CTE: `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cpm)` per lane.
6. Final SELECT: join lane_carrier_cpm to lane_medians; compute `pct_above_median`; `RANK() OVER (PARTITION BY lane_id ORDER BY cpm)`.

**Stop signals** · `AVG(cpm_per_shipment)` (avg_of_ratios) · cross-lane rank · zero-mile shipments in denominator · spot-tier inclusion.

---

[← Persona: ops-supply-chain](../../SKILL.md) ·
[← Department: operations](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

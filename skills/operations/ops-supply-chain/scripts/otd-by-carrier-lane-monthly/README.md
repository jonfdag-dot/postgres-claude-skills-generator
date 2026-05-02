---
artifact_type: script_semantic_layer
script_id: otd-by-carrier-lane-monthly
business_title: OTD by Carrier × Lane — Monthly
role: ops-supply-chain
department: operations
chosen_primitives: [pre_aggregate_grain, ratio_reconstruction, period_over_period_lag]
trigger_keywords: [OTD, OTD by carrier, OTD by lane, monthly OTD, lane OTD trend, on-time delivery rate, carrier OTD]
tables_read: [public.shipments, public.carriers, public.lanes]
metric_behavior: ratio
default_grain: carrier × lane × month
last_run: 2026-04-12
promoted_from: 4 verified question instances (2026-03-12 → 2026-04-28)
status: verified
---

# OTD by Carrier × Lane — Monthly

> **Business question:** "What is on-time-delivery rate for each
> (carrier × lane) combination, monthly, with the month-over-month
> delta? Which carrier-lane pairs are deteriorating?"

OTD = `SUM(delivered_on_time::INT) / NULLIF(COUNT(*), 0)` at
(carrier × lane × month) grain. Reconstructed from numerator and
denominator at lane grain — never an `AVG` of shipment-level
booleans.

**Sister scripts** · [cost-per-mile-rank-within-lane](../cost-per-mile-rank-within-lane/README.md) (cost-side companion).

---

## Result table

One row per (carrier × lane × month). Each row has on-time count,
total count, OTD rate, and MoM delta partitioned by (carrier, lane).

### Columns

| column | type | role | description |
|---|---|---|---|
| `carrier_name` | text | dimension | Carrier (e.g., `FedEx`, `UPS`, `DHL`, `Estes`) |
| `lane_id` | text | dimension | Lane code (`US-EAST`, `US-MIDWEST`, …, `AU-E`) |
| `month` | timestamp | time | First day of the month bucket |
| `on_time_count` | bigint | metric | Numerator: shipments with `delivered_on_time = true` |
| `total_count` | bigint | metric | Denominator: total shipments after scope filters |
| `otd_rate` | numeric | derived | `on_time_count / NULLIF(total_count, 0)`, rounded to 4 decimals |
| `otd_delta_mom` | numeric | derived | `otd_rate − LAG(otd_rate) OVER (PARTITION BY carrier_name, lane_id ORDER BY month)` |

Ordered by `lane_id, carrier_name, month`.

---

## Dos and don'ts

**Dos** · pre-aggregate at (carrier × lane × month) BEFORE dividing · `NULLIF(COUNT(*), 0)` for the rate denominator · always `s.status != 'cancelled'` · always `c.contract_tier != 'spot'` for SLA work · half-open delivery_ts window · `LAG()` partitioned by `(carrier_name, lane_id)`.

**Don'ts** · `AVG(s.delivered_on_time::INT)` at shipment level then roll up — averages October's high volume against December's low volume · cross-lane `AVG(otd_rate)` for "carrier overall OTD" — lane-mix dominates, rank WITHIN lane · INNER JOIN `delivery_surveys` then SUM (survey covers ~30%; non-response is non-random) · include cancelled shipments in denominator.

---

## Per-column details

### `public.shipments.delivered_on_time` — boolean · numerator source

- **business_definition** · True if delivery occurred on or before the promised date (`promised_ts >= actual_delivery_ts`); NULL while in-transit.
- **quality_trust** · NULL while in-transit (~8% of in-flight rows) · once terminal, NOT NULL
- **dos** · CASE-to-int for SUM (boolean SUM is engine-dependent) · pair with `status != 'cancelled'`
- **don'ts** · `AVG(delivered_on_time::INT)` at shipment level (avg_of_ratios when rolled up)

### `public.shipments.status` — categorical · scope filter

- **business_definition** · Shipment lifecycle state.
- **values** · `delivered` (~71%) · `in_transit` (~22%) · `returned` (~5%) · `cancelled` (~2%) — see samples below
- **dos** · always exclude cancelled (denominator-pollution otherwise)
- **don'ts** · omit

### `public.carriers.contract_tier` — categorical · scope filter for SLA work

- **business_definition** · Tier label distinguishing prime / standard / spot carriers; spot is SLA-exempt.
- **values** · `prime` (~38%) · `standard` (~52%) · `spot` (~10%)
- **dos** · exclude spot from any SLA / OTD work · override only with explicit user scope
- **don'ts** · include spot in OTD rollups silently

### `public.shipments.delivery_ts` — time · timestamptz · `event_time`

- **business_definition** · Timestamp the shipment was delivered (or NULL if not yet terminal).
- **quality_trust** · UTC · NULL until terminal
- **dos** · half-open windows · monthly bucket
- **don'ts** · SUM/AVG timestamps · include in-transit rows

### `public.lanes.lane_id` — dimension · key · row-and-grouping dimension

- **business_definition** · Origin-destination lane code; 14 distinct values across global routes.
- **values** · `US-EAST` · `US-MIDWEST` · `US-WEST` · `EU-CEN` · `EU-NOR` · `APAC-PAC` · `APAC-IND` · `MX-N` · `MX-S` · `CA-EAST` · `CA-WEST` · `BR-S` · `ZA-N` · `AU-E`
- **dos** · GROUP BY lane_id always · rank carriers WITHIN lane
- **don'ts** · cross-lane average · roll up across lanes

### `public.carriers.carrier_name` — dimension · text · row dimension

- **business_definition** · Carrier display name.
- **quality_trust** · ~340 distinct values · zero nulls
- **dos** · GROUP BY carrier_name + lane_id together
- **don'ts** · GROUP BY carrier alone (cross-lane mix dominates)

---

## Value samples (column_value_samples)

### `public.shipments.status`

| value | freq_est | rank | sample_type | co_occurrence (delivery_ts) |
|---|---|---|---|---|
| `delivered` | 8,732,400 | 1 | top | [2024-01-01 → 2026-04-30] |
| `in_transit` | 2,706,000 | 2 | top | [2026-04-15 → 2026-04-30] |
| `returned` | 615,000 | 3 | rare | [2024-01-01 → 2026-04-29] |
| `cancelled` | 246,600 | 4 | rare | [2024-01-01 → 2026-04-30] |

### `public.carriers.contract_tier`

| value | freq_est | rank | sample_type |
|---|---|---|---|
| `standard` | 177 | 1 | top |
| `prime` | 130 | 2 | top |
| `spot` | 33 | 3 | rare |

---

## Template-level semantic (compact)

**Identity** · title `OTD by Carrier × Lane — Monthly` · analytical_pattern `time_series_with_ranking` · primary_purpose surface deteriorating (carrier × lane) pairs for re-bid decisions · search_keywords OTD · on-time delivery · monthly OTD · carrier OTD · lane OTD trend

**Decision record** · sort `lane_id_then_carrier_then_month` · agg_fn `count_with_case` · time_col `shipments.delivery_ts` · dimension `lanes.lane_id` · date_range `last_90_days` · time_grain `monthly`

**Business context** · default_aggregation `ratio_reconstruction` · default_grain `monthly_by_carrier_lane` · additive_metrics [on_time_count · total_count] · non_additive_metrics [otd_rate · otd_delta_mom]

**Filters** · `shipments.status` (multi_select, default `[delivered, in_transit, returned]`) · `carriers.contract_tier` (multi_select, default `[prime, standard]`) · `lanes.lane_id` (multi_select) · `shipments.delivery_ts` (date_range, default `last_90_days`)

**Intent keywords** · trend [trend · MoM · over time] · ranking [worst lane · best carrier · top lane] · comparison [vs prior month · carrier vs carrier within lane]

**Dashboard** · x = `month` (date_month) · y = `otd_rate` (percent) · color by `carrier_name` · small_multiples by `lane_id` · recommended_visualizations [line · small_multiples · heatmap]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `s.status != 'cancelled'` AND `c.contract_tier != 'spot'`.
2. Filter `delivery_ts` to half-open trailing-90-day window.
3. Pre-aggregate at (carrier × lane × month) in a CTE: `SUM(CASE WHEN delivered_on_time THEN 1 ELSE 0 END)` for numerator, `COUNT(*)` for denominator.
4. Reconstruct `otd_rate = on_time_count / NULLIF(total_count, 0)`.
5. `LAG(otd_rate) OVER (PARTITION BY carrier_name, lane_id ORDER BY month)` for MoM delta.

**Stop signals** · `AVG(delivered_on_time::INT)` at shipment level · cross-lane average for "carrier overall OTD" · including spot tier in SLA work · INNER JOIN `delivery_surveys` then SUM.

---

[← Persona: ops-supply-chain](../../SKILL.md) ·
[← Department: operations](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

---
artifact_type: script_semantic_layer
script_id: picking-rate-by-shift-weekly
business_title: Picking Rate by Shift — Weekly
role: warehouse-operations
department: operations
chosen_primitives: [pre_aggregate_grain, ratio_reconstruction]
trigger_keywords: [picking rate, picks per hour, labor utilization, shift productivity, warehouse productivity, picks per labor hour, pickrate]
tables_read: [public.pick_events, public.shifts, public.warehouse_locations]
metric_behavior: ratio
default_grain: warehouse × shift × week
last_run: 2026-04-23
promoted_from: 2 verified question instances (2026-03-10 → 2026-04-23)
status: verified
---

# Picking Rate by Shift — Weekly

> **Business question:** "What is picks-per-labor-hour for each
> (warehouse × shift) per week, over the trailing 8 weeks? Which
> shifts are losing productivity?"

Picking rate = `SUM(units_picked) / NULLIF(SUM(labor_hours), 0)` at
(warehouse × shift × week) grain. Shift partition required —
day-shift and night-shift cadences are different and **must not be
averaged together**.

**Sister scripts** · [inventory-on-hand-snapshot](../inventory-on-hand-snapshot/README.md) (snapshot companion).

---

## Result table

One row per (warehouse × shift × week) over the trailing 8 weeks.
Each row reports total picks, total labor-hours, and the
reconstructed picking rate.

### Columns

| column | type | role | description |
|---|---|---|---|
| `warehouse_id` | text | dimension | One of `WH-ATL` … `WH-MIA` |
| `shift_name` | text | dimension | `day` · `evening` · `night` |
| `week` | timestamp | time | First day of the ISO week |
| `units_picked` | bigint | metric | `SUM(pick_events.units_picked)` |
| `labor_hours` | numeric | metric | `SUM(shifts.hours_worked)` for the bucket |
| `picks_per_hour` | numeric | derived | `units_picked / NULLIF(labor_hours, 0)` |

Ordered by `warehouse_id, shift_name, week DESC`.

---

## Dos and don'ts

**Dos** · pre-aggregate picks AND labor-hours at (warehouse × shift × week) BEFORE dividing · `NULLIF(labor_hours, 0)` for the rate denominator · GROUP BY shift always · half-open week window · exclude `pick_events.cycle_time_min IS NULL` (first-pick-of-shift sentinel).

**Don'ts** · `AVG(picks_per_hour_per_event)` — `avg_of_ratios`; bursts of small picks dominate · cross-shift average (mixes day and night cadence) · cross-warehouse average (capacity differs) · INNER JOIN with `cycle_counts` (drops shifts with no count event).

---

## Per-column details

### `public.pick_events.units_picked` — metric · int · additive · numerator

- **business_definition** · Pallet-equivalents picked per pick event.
- **quality_trust** · zero nulls · reconciles to dispatch tally within 1%
- **dos** · SUM at (warehouse × shift × week) before dividing
- **don'ts** · per-event picks/hour then AVG · sum across shifts without partition

### `public.shifts.hours_worked` — metric · numeric · additive · denominator

- **business_definition** · Total labor-hours for the shift, summed across all workers on that shift.
- **quality_trust** · zero nulls · timekeeper-system reconciled
- **dos** · SUM at (warehouse × shift × week) · NULLIF on the denominator
- **don'ts** · forget the partition by shift_name (day-shift and night-shift have different baselines)

### `public.shifts.shift_name` — categorical · partition

- **business_definition** · Shift label.
- **values** · `day` · `evening` · `night`
- **quality_trust** · DB CHECK constraint · zero nulls
- **dos** · always partition rates by shift
- **don'ts** · cross-shift average (mixes cadence)

### `public.shifts.shift_start_ts` — time · timestamptz · `event_time`

- **business_definition** · Timestamp the shift started.
- **dos** · half-open · ISO week alignment
- **don'ts** · SUM/AVG timestamps

### `public.warehouse_locations.warehouse_id` — dimension · key · row dimension

- **business_definition** · Warehouse / DC identifier; 7 distinct.
- **values** · `WH-ATL` · `WH-DAL` · `WH-CHI` · `WH-LAX` · `WH-NJ` · `WH-SEA` · `WH-MIA`
- **dos** · GROUP BY warehouse_id
- **don'ts** · cross-warehouse rate average (capacity differs)

---

## Value samples (column_value_samples)

### `public.shifts.shift_name`

| value | freq_est | rank | sample_type | co_occurrence (warehouses) |
|---|---|---|---|---|
| `day` | 12,418 | 1 | top | all 7 warehouses |
| `evening` | 8,902 | 2 | top | all 7 warehouses |
| `night` | 4,210 | 3 | top | WH-ATL · WH-DAL · WH-CHI · WH-LAX · WH-NJ |

---

## Template-level semantic (compact)

**Identity** · title `Picking Rate by Shift — Weekly` · analytical_pattern `time_series_with_ratio` · primary_purpose surface productivity drift per (warehouse × shift) for labor-planning interventions · search_keywords picking rate · picks per hour · labor utilization · shift productivity

**Decision record** · sort `warehouse_id_then_shift_then_week_desc` · agg_fn `sum_div_sum` · time_col `shifts.shift_start_ts` · dimension `[warehouse_id, shift_name]` · date_range `last_8_weeks` · time_grain `weekly`

**Business context** · default_aggregation `ratio_reconstruction` · default_grain `weekly_by_warehouse_shift` · additive_metrics [units_picked · labor_hours] · non_additive_metrics [picks_per_hour]

**Filters** · `warehouse_locations.warehouse_id` (multi_select) · `shifts.shift_name` (multi_select, default all 3) · `shifts.shift_start_ts` (date_range, default `last_8_weeks`)

**Intent keywords** · trend [WoW · over time · trajectory] · ranking [most productive · least productive shift] · comparison [day vs night · WH vs WH]

**Dashboard** · x = `week` (date_week) · y = `picks_per_hour` (numeric) · color by `shift_name` · small_multiples by `warehouse_id` · recommended_visualizations [line · small_multiples · table]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `pick_events.cycle_time_min IS NOT NULL` (drop first-pick-of-shift sentinel).
2. Filter `shift_start_ts >= CURRENT_DATE - INTERVAL '8 weeks'` (half-open).
3. Pre-aggregate `units_picked` (from pick_events joined to shifts) and `hours_worked` (from shifts) at (warehouse × shift × week).
4. Reconstruct `picks_per_hour = units_picked / NULLIF(labor_hours, 0)`.

**Stop signals** · `AVG(picks_per_hour_per_event)` (avg_of_ratios) · cross-shift average · cross-warehouse rate average · INNER JOIN cycle_counts then SUM.

---

[← Persona: warehouse-operations](../../SKILL.md) ·
[← Department: operations](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

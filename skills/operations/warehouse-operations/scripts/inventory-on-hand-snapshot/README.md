---
artifact_type: script_semantic_layer
script_id: inventory-on-hand-snapshot
business_title: Current Inventory On-Hand by Warehouse × SKU
role: warehouse-operations
department: operations
chosen_primitives: [snapshot_latest, pre_aggregate_grain]
trigger_keywords: [inventory on hand, current stock, stock level, on-hand by warehouse, snapshot inventory, IOH, qty on hand]
tables_read: [public.inventory_snapshots, public.warehouse_locations, public.skus]
metric_behavior: snapshot
default_grain: warehouse × sku × latest_snapshot
last_run: 2026-04-26
promoted_from: 3 verified question instances (2026-02-22 → 2026-04-26)
status: verified
---

# Current Inventory On-Hand by Warehouse × SKU

> **Business question:** "What is the current inventory on-hand
> position per (warehouse × SKU)? Surface the latest snapshot for
> each combination — never sum across days."

`qty_on_hand` is a **snapshot fact** (the value at a point in time
is what matters), not a flow. The canonical pattern is `ROW_NUMBER`
to take the latest per (warehouse_id, sku_id) — never `SUM` across
days (the same pallet would be counted multiple times).

**Sister scripts** · [picking-rate-by-shift-weekly](../picking-rate-by-shift-weekly/README.md) (flow companion).

---

## Result table

One row per (warehouse × SKU), reflecting the **latest** snapshot.
Sums of `qty_on_hand` across rows are valid (additive across SKUs
within a warehouse and across warehouses for company-wide IOH) —
just NOT additive across time.

### Columns

| column | type | role | description |
|---|---|---|---|
| `warehouse_id` | text | dimension | One of `WH-ATL` · `WH-DAL` · `WH-CHI` · `WH-LAX` · `WH-NJ` · `WH-SEA` · `WH-MIA` |
| `sku_id` | text | key | SKU identifier |
| `sku_name` | text | dimension | Human-readable SKU label |
| `qty_on_hand` | int | metric | Latest snapshot quantity, pallet-equivalents |
| `snapshot_ts` | timestamp | time | Timestamp of the latest snapshot |

Ordered by `warehouse_id, qty_on_hand DESC` (largest stockholders first per warehouse).

---

## Dos and don'ts

**Dos** · `ROW_NUMBER() OVER (PARTITION BY warehouse_id, sku_id ORDER BY snapshot_ts DESC) = 1` for the latest snapshot · SUM `qty_on_hand` across (sku within warehouse) or (warehouse for company total) — additive in those dimensions · exclude `qty_on_hand < 0` (sentinel for untracked SKU) · half-open `snapshot_ts` window if scoping to a date.

**Don'ts** · `SUM(qty_on_hand)` across days · `AVG(qty_on_hand)` across daily snapshots · INNER JOIN `cycle_counts` then SUM (count-adjustment events would double-count) · use any snapshot other than the latest for "current" questions.

---

## Per-column details

### `public.inventory_snapshots.qty_on_hand` — metric · int · **snapshot** · NOT additive across time

- **business_definition** · Quantity of pallets on hand for a (warehouse × SKU) at a point in time.
- **quality_trust** · NOT NULL · `< 0` is a sentinel (~0.5%) — exclude · daily snapshot cadence · reconciles to cycle counts within ±2%
- **dos** · take the latest snapshot · sum across SKUs / warehouses (additive in those dimensions)
- **don'ts** · SUM across days (double-counts pallets) · AVG across daily snapshots
- **hardening** · is_additive `false` (across time) · is_additive `true` (across sku within warehouse) · metric_behavior `snapshot`

### `public.inventory_snapshots.snapshot_ts` — time · timestamptz · `snapshot_anchor`

- **business_definition** · Timestamp the snapshot was captured.
- **quality_trust** · NOT NULL · UTC · daily cadence (~midnight UTC)
- **dos** · ORDER BY DESC inside ROW_NUMBER
- **don'ts** · AVG/SUM

### `public.warehouse_locations.warehouse_id` — dimension · key · row dimension

- **business_definition** · Warehouse / DC identifier; 7 distinct values across the network.
- **values** · `WH-ATL` · `WH-DAL` · `WH-CHI` · `WH-LAX` · `WH-NJ` · `WH-SEA` · `WH-MIA`
- **dos** · GROUP BY warehouse_id · partition snapshot_latest by warehouse_id
- **don'ts** · cross-warehouse average (capacity differs)

### `public.skus.sku_id` — key · partition + grouping

- **business_definition** · Stock-keeping-unit identifier.
- **quality_trust** · ~14,200 active SKUs · zero nulls · enforced unique
- **dos** · partition snapshot_latest by `(warehouse_id, sku_id)`
- **don'ts** · SUM sku_id (categorical identifier)

---

## Value samples (column_value_samples)

### `public.warehouse_locations.warehouse_id`

| value | freq_est | rank | sample_type | co_occurrence (active_sku_count) |
|---|---|---|---|---|
| `WH-ATL` | 8,120 | 1 | top | high SKU diversity |
| `WH-DAL` | 7,640 | 2 | top | high SKU diversity |
| `WH-CHI` | 6,990 | 3 | top | high SKU diversity |
| `WH-LAX` | 6,440 | 4 | top | high SKU diversity |
| `WH-NJ` | 5,820 | 5 | top | high SKU diversity |
| `WH-SEA` | 4,210 | 6 | top | mid SKU diversity |
| `WH-MIA` | 3,490 | 7 | rare | mid SKU diversity |

---

## Template-level semantic (compact)

**Identity** · title `Current Inventory On-Hand by Warehouse × SKU` · analytical_pattern `snapshot_latest` · primary_purpose surface the live IOH position for cycle-count reconciliation, replenishment planning, stockout risk · search_keywords inventory on hand · current stock · stock level · IOH · snapshot inventory

**Decision record** · sort `warehouse_id_then_qty_desc` · agg_fn `latest_snapshot` · time_col `snapshot_ts` · dimension `warehouse_id` · date_range `current` · time_grain `snapshot`

**Business context** · default_aggregation `snapshot_latest` · default_grain `warehouse_x_sku` · additive_metrics (none across time; qty_on_hand additive across SKUs within a warehouse) · non_additive_metrics [qty_on_hand across time]

**Filters** · `warehouse_locations.warehouse_id` (multi_select) · `skus.sku_id` (text · in_list) · `inventory_snapshots.qty_on_hand` (`> 0` always-on)

**Intent keywords** · ranking [highest stock · lowest stock · top SKUs] · comparison [warehouse vs warehouse · this week vs last week]

**Dashboard** · x = `sku_id` (categorical) · y = `qty_on_hand` (int) · grouped by `warehouse_id` · color by warehouse · recommended_visualizations [bar · table · heatmap]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. CTE: `ROW_NUMBER() OVER (PARTITION BY warehouse_id, sku_id ORDER BY snapshot_ts DESC) AS rn` over `inventory_snapshots`.
2. Filter `rn = 1` (latest snapshot per warehouse × SKU).
3. Filter `qty_on_hand > 0` (drop untracked-SKU sentinel rows).
4. JOIN `warehouse_locations` and `skus` for human-readable labels.
5. ORDER BY `warehouse_id, qty_on_hand DESC`.

**Stop signals** · `SUM(qty_on_hand)` across days · `AVG` across daily snapshots · cross-warehouse capacity-blind average · INNER JOIN cycle_counts then SUM.

---

[← Persona: warehouse-operations](../../SKILL.md) ·
[← Department: operations](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

---
artifact_type: department_catalog
department: operations
refreshed_at: 2026-05-02T19:14:03Z
total_roles: 2
total_skills: 2
total_scripts: 4
sister_pair: [ops-supply-chain, warehouse-operations]
sister_axis: "between-warehouse vs. inside-warehouse"
department_archetypes: [logistics_supply_chain, warehouse_operations]
department_primitives: [pre_aggregate_grain, ratio_reconstruction, period_over_period_lag, snapshot_latest]
department_tables_read: [public.shipments, public.carriers, public.lanes, public.shippers, public.delivery_surveys, public.inventory_snapshots, public.pick_events, public.putaway_events, public.shifts, public.warehouse_locations, public.skus, public.cycle_counts]
---

# 🚚 Operations — Department Catalog

Owns carrier relationships, lane performance, fulfillment SLAs, and inventory positioning. Largest data volume in the company — `public.shipments` alone is ~12.3M rows. Sister roles split at **the warehouse boundary**: `ops-supply-chain` reads BETWEEN warehouses (carriers, lanes, OTD, customer delivery surveys); `warehouse-operations` reads INSIDE the four walls (inventory snapshots, picking flow, dock-to-stock lag, labor productivity).

## Department summary (Pass-C accumulator)

The department reasons in **lane × carrier × period** for between-warehouse questions and **warehouse × shift × SKU × snapshot-vs-flow** for inside-warehouse questions. Critical distinction: `inventory_snapshots.qty_on_hand` is a snapshot (point-in-time, never `SUM` across days) while `pick_events.units_picked` is a flow (SUM across periods). Sister-role discipline: `ops-supply-chain` refuses cross-lane averages (lane mix dominates) and excludes `contract_tier = 'spot'` from SLA reports; `warehouse-operations` refuses to share a CTE between snapshot and flow metrics, and excludes `qty_on_hand < 0` (sentinel for untracked SKU).

## Roles in this department

| Role | Persona description (mirrored from SKILL.md frontmatter) | Skills | Scripts | Catalog |
|---|---|---|---|---|
| **ops-supply-chain** | The primary supply-chain analyst role. Owns carrier on-time-delivery (OTD), lane cost benchmarks, fill rate, and quarterly carrier rebalancing reviews — the BETWEEN-warehouse axis. | 1 | 2 | [ops-supply-chain/SKILL.md](ops-supply-chain/SKILL.md) |
| **warehouse-operations** | Sister role to ops-supply-chain — the INSIDE-warehouse axis (inventory turnover, picking efficiency, labor utilization, dock-to-stock lag). | 1 | 2 | [warehouse-operations/SKILL.md](warehouse-operations/SKILL.md) |

## Sister-role pairing logic

| If the question is about… | Route to |
|---|---|
| Carrier OTD, lane cost, carrier scorecards, fill rate, rebalancing (between sites) | `ops-supply-chain` |
| Inventory on-hand, picking rate, dock-to-stock, turnover, SKU velocity (inside the four walls) | `warehouse-operations` |
| Cross-axis (`fill rate at MX-S vs. picker productivity`) | both — supply-chain owns the lane fill leg, warehouse-operations owns the picker leg; compose via Rung 3 cross-domain dispatch (CHION.md §3) |

## Department vocabulary (aggregated, deduplicated)

- **OTD** — OTD · on-time · on-time delivery · on-time rate · monthly OTD · rolling OTD · customer-perceived OTD · NPS OTD · spot vs prime OTD
- **Carrier comparisons** — carrier SLA · carrier scorecard · rebalance · carrier rebalancing · lane re-bid · lane mix
- **Lane economics** — lane · lane performance · lane cost · cost per mile · CPM · CPM rank · lane median CPM
- **Fulfillment quality** — fill rate · defect rate
- **Inventory** — inventory turn · turnover · stock velocity · on-hand · stock level · inventory on hand · IOH · qty on hand
- **Labor productivity** — picking · pick rate · picks per hour · units per hour · labor utilization · shift productivity · headcount efficiency
- **Throughput timing** — dock-to-stock · putaway · receive lag · cycle count · stockout · SKU velocity · slotting · throughput

## Department-wide stop signals

- Never `AVG(delivered_on_time::INT)` — `avg_of_ratios`. Reconstruct `SUM(on_time) / NULLIF(COUNT(*), 0)` at (carrier × lane × period) grain.
- Never compare a carrier's overall OTD across all lanes — lane mix dominates. Rank WITHIN lane via `RANK() OVER (PARTITION BY lane_id …)`.
- Never `SUM(qty_on_hand)` across `snapshot_date` — same physical pallet counted N times. Use `snapshot_latest` via `DISTINCT ON`.
- Never share a CTE between snapshot metrics (on-hand) and flow metrics (units picked) — different additivity classes.
- Always exclude `contract_tier = 'spot'` from SLA reports (spot is exempt) and `qty_on_hand < 0` from inventory work (sentinel).

## How agents route within this department

1. Match question against role-level triggers above (between-warehouse vs. inside-warehouse).
2. Open the matching `<role>/SKILL.md` — load Persona, Curated Rule Pack, Layer 2 Domain Profile, Role Vocabulary, and the Scripts Index at the bottom.
3. Pick top-3 scripts whose triggers best match the user's question.
4. Open `<role>/scripts/<query>/README.md` for the 6-gate fit check; wrap via CTE-Mastermind (CHION.md §4); execute.

Sister-role swap rule (CHION.md §3 Rung 2): if the picked role produces no script fit, retry with the sister role. The pair shares `public.shipments` + `public.skus` reach — flow questions can cross the warehouse boundary.

---

[← Skills catalog (top)](../_INDEX.md) · [← Root CHION.md](../../../CHION.md)

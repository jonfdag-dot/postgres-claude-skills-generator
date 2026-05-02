---
artifact_type: script_semantic_layer
script_id: cogs-revenue-alignment
business_title: COGS to Revenue Period Alignment
role: finance-analyst
department: finance
chosen_primitives: [pre_aggregate_grain]
trigger_keywords: [cogs alignment, cogs revenue match, margin reconciliation, period-aligned margin, phantom margin swing, cogs misalignment, revenue cogs reconciliation]
tables_read: [public.revenue, public.contracts, public.segments, public.cogs]
metric_behavior: derived
default_grain: contract × revenue_event (per-row diagnostic)
last_run: 2026-04-15
promoted_from: 2 verified question instances (2026-03-22 → 2026-04-15)
status: verified
---

# COGS to Revenue Period Alignment

> **Business question:** "For each contract that recognized revenue
> in the last 2 quarters, does its COGS recognize in the SAME
> quarter? Surface every mismatch — they are the source of phantom
> gross-margin swings."

This is a **diagnostic query**, not a P&L rollup. Returns one row
per contract-revenue-event with `alignment_flag ∈ {aligned,
misaligned}`. Reach for it when
[gross-margin-by-segment-quarterly](../gross-margin-by-segment-quarterly/README.md)
shows a margin swing that doesn't reconcile to known business
events.

**Sister scripts** · [gross-margin-by-segment-quarterly](../gross-margin-by-segment-quarterly/README.md) (the rollup this drills down from).

---

## Result table

One row per (contract × revenue-event) over the trailing 2 quarters.
Per-row diagnostic — **do not aggregate this output** (misaligned
rows would double-count across two quarters).

### Columns

| column | type | role | description |
|---|---|---|---|
| `contract_id` | bigint | key | Contract under inspection |
| `segment_name` | text | dimension | Segment for the contract |
| `revenue_quarter` | timestamp | time | `DATE_TRUNC('quarter', revenue.recognition_ts)` |
| `cogs_quarter` | timestamp | time | `DATE_TRUNC('quarter', cogs.recognition_ts)` |
| `alignment_flag` | text | derived | `'aligned'` if quarters match, else `'misaligned'` |
| `revenue_amount` | numeric | metric | Per-event revenue, USD |
| `cogs_amount` | numeric | metric | Per-event COGS, USD |

Ordered by `alignment_flag, contract_id` so misaligned rows surface first.

---

## Dos and don'ts

**Dos** · treat output as per-row data, not as a metric · filter `alignment_flag = 'misaligned'` to drill down · escalate findings to controllership for the actual fix · LEFT JOIN cogs (not INNER) so contracts with no COGS don't silently drop.

**Don'ts** · SUM or AVG the output rows · INNER JOIN cogs (drops contracts with no COGS — different bug class) · include older-than-2-quarter rows without confirming scope (closed periods) · hand-roll date arithmetic in this query to "fix" misalignment (escalate, don't repair).

---

## Per-column details

### `public.revenue.recognition_ts` — time · timestamptz · `event_time`

- **definition** · Timestamp at which a revenue dollar was recognized. See SKILL.md §2.4 for time-role rules.
- **dos** · compare against `cogs.recognition_ts` at quarter grain
- **don'ts** · SUM/AVG

### `public.cogs.recognition_ts` — time · timestamptz · `event_time`

- **business_definition** · Timestamp at which a COGS dollar was recognized.
- **quality_trust** · NOT NULL · UTC · 4% misalignment rate against paired `revenue.recognition_ts`
- **dos** · compare against `revenue.recognition_ts` at quarter grain · surface mismatches to controllership
- **don'ts** · realign in-query

### `derived.alignment_flag` — categorical · diagnostic · derived in-query (CASE WHEN)

- **business_definition** · Computed flag in `{'aligned', 'misaligned'}` indicating quarter match. Derived in-query via `CASE WHEN`; not a stored column.
- **values** · `aligned` (1,804 · top) · `misaligned` (76 · rare) — see samples below
- **quality_trust** · deterministic from inputs (`DATE_TRUNC` quarter equality)
- **dos** · `ORDER BY alignment_flag` to surface misaligned rows first · filter `alignment_flag = 'misaligned'` for drill-down
- **don'ts** · aggregate values associated with the flag (per-row diagnostic)

### `public.contracts.contract_id` — key · primary key · per-row anchor

- **business_definition** · Primary key on contracts.
- **dos** · use as the row anchor
- **don'ts** · SUM / AVG

### `public.segments.segment_name` — dimension · categorical · optional grouping

- **business_definition** · Customer-tier segment.
- **values** · `enterprise` (218 · top) · `mid_market` (624 · top) · `smb` (941 · top) · `partner` (59 · rare)
- **dos** · group misaligned rows by segment to find hot-spots
- **don'ts** · aggregate segment_name itself

---

## Value samples (column_value_samples)

### `derived.alignment_flag`

| value | freq_est | rank | sample_type | co_occurrence (revenue_quarter) | co_occurrence (cogs_quarter) | co_occurrence (segment_name) |
|---|---|---|---|---|---|---|
| `aligned` | 1,804 | 1 | top | [2025-11-01 → 2026-04-30] | [2025-11-01 → 2026-04-30] | enterprise · mid_market · smb · partner |
| `misaligned` | 76 | 2 | rare | [2025-11-04 → 2026-04-22] | [2025-08-15 → 2026-05-12] | enterprise · mid_market · smb |

`public.revenue.status` canonical values + always-on filter: see SKILL.md §2.5.

---

## Template-level semantic (compact)

**Identity** · title `COGS to Revenue Period Alignment` · analytical_pattern `diagnostic_audit` · primary_purpose diagnose phantom gross-margin swings caused by COGS recognition period misalignment · search_keywords cogs alignment · margin reconciliation · phantom margin swing · cogs misalignment · period alignment · revenue cogs match

**Decision record** · sort `alignment_flag_then_contract_id` · agg_fn `null` (per-row diagnostic) · time_col `revenue.recognition_ts` · dimension `derived.alignment_flag` · date_range `trailing_2_quarters_start → current` · time_grain `quarterly`

**Business context** · default_aggregation `null` · default_grain `per_row_diagnostic` · additive_metrics (none) · non_additive_metrics [alignment_flag]

**Filters** · `revenue.status` (select, default `recognized`) · `revenue.recognition_ts` (date_range, default `trailing_2_quarters`) · `derived.alignment_flag` (select, default `misaligned`)

**Intent keywords** · ranking [which contracts misalign most] · comparison [aligned vs misaligned · revenue quarter vs cogs quarter]

**Dashboard** · x = `contracts.contract_id` (identifier) · y₁ = `revenue.amount_usd` (currency_usd, per_row) · y₂ = `cogs.amount_usd` (currency_usd, per_row) · color [hsl(--destructive) · hsl(--primary)] · default_filter `derived.alignment_flag = 'misaligned'` · recommended_visualizations [table · list · scatter_diff]

---

## How to query

See [`query.sql`](query.sql) for the executable form.

**Transformations applied** (in order):

1. Filter `revenue.status = 'recognized'` AND `recognition_ts >= CURRENT_DATE - INTERVAL '2 quarters'`.
2. LEFT JOIN `cogs` ON `contract_id` (NO period match in the join — `alignment_flag` IS the diagnostic).
3. Filter `co.amount_usd IS NOT NULL` (drop COGS-coverage gaps so the diagnostic stays unambiguous).
4. `CASE WHEN DATE_TRUNC('quarter', revenue.recognition_ts) = DATE_TRUNC('quarter', cogs.recognition_ts) THEN 'aligned' ELSE 'misaligned' END`.

**Stop signals** · hand-rolled date arithmetic to "fix" misalignment in this query (surface, escalate, don't repair) · including older-than-2-quarter rows without confirming scope · treating output as a metric.

---

[← Persona: finance-analyst](../../SKILL.md) ·
[← Department: finance](../../../_INDEX.md) ·
[← Root CHION.md](../../../../../../CHION.md)

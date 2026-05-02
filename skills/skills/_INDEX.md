---
artifact_type: skills_catalog
refreshed_at: 2026-05-02T19:14:03Z
total_departments: 3
total_roles: 6
total_skills: 6
total_scripts: 15
universal_primitives: [pre_aggregate_grain, snapshot_latest, ratio_reconstruction, period_over_period_lag, date_spine, cohort_retention_matrix]
role_specific_extensions: [cumulative_running_total, forecast_vs_actual, statistical_significance_gate]
scale_tier: 2
---

# Skills Catalog — Workspace Top Level

Three departments, two sister-paired roles per department, one skill per employee, one verified SQL script per starred query. **Read this file first; route down through the cascade.**

> **Note:** "sister-paired" describes the data-shape axis the two roles split — **not** an equal script count. In the current mock the script counts are uneven (5/2/2/2/2/2 = 15) because `finance-analyst` happens to have more verified queries than the others. Real per-user / per-team exports will skew the same way: a role gets as many scripts as the user verified for it.

## Workspace summary (Pass-D accumulator)

This workspace exports the analytical brain of a six-employee team across three functional pillars: **finance** (recognized revenue + forward planning), **operations** (between-warehouse logistics + inside-warehouse fulfillment), and **growth** (acquisition + retention + in-product behavior). Each pillar contains a sister pair of roles that split the same data shape along an explicit axis — what already happened vs. what's being planned, what happens between sites vs. inside the four walls, what the user does before signup vs. inside the product.

Across all six employees the workspace ships **15 verified SQL scripts**, each anchored to a canonical `query.sql` and wrapped at runtime via the CTE-Mastermind pattern (CHION.md §4). Universal primitive vocabulary spans `pre_aggregate_grain` · `snapshot_latest` · `ratio_reconstruction` · `period_over_period_lag` · `date_spine` · `cohort_retention_matrix` plus role-specific extensions (`cumulative_running_total`, `forecast_vs_actual`, `statistical_significance_gate`).

## Cascade (top → leaf, increasing detail per level)

```
.claude/skills/
└── _INDEX.md                                  ← this file · workspace summary · cross-pillar vocabulary
    └── <department>/_INDEX.md                 ← department catalog · sister-role logic · dept vocabulary
        └── <role>/SKILL.md                    ← persona brain · Curated Rule Pack · Layer 2 Domain Profile · Role Vocabulary · Scripts Index
            └── scripts/<query>/README.md      ← 11-section semantic layer · 3 Studio shapes flattened
                └── scripts/<query>/query.sql  ← verified read-only SELECT (canonical · never mutated)
```

Each layer pulls frontmatter + headers from the layer below: the script README's frontmatter feeds SKILL.md's Scripts Index; SKILL.md's persona + trigger-keywords feed the department catalog; the department summaries feed this top catalog. **All frontmatter values must match their source SKILL.md or script README — drift is a compile bug.**

## Departments (Pass-1 routing)

| Department | Roles (sister pair) | Skills | Scripts | Catalog |
|---|---|---|---|---|
| 💰 **Finance** | `finance-analyst` ↔ `fp-and-a-analyst` | 2 | 7 | [finance/_INDEX.md](finance/_INDEX.md) |
| 🚚 **Operations** | `ops-supply-chain` ↔ `warehouse-operations` | 2 | 4 | [operations/_INDEX.md](operations/_INDEX.md) |
| 📈 **Growth** | `growth-marketing` ↔ `product-analytics` | 2 | 4 | [growth/_INDEX.md](growth/_INDEX.md) |

## Cross-workspace vocabulary (aggregated from all 6 personas)

The first-pass router scores incoming questions against this vocabulary, grouped by sub-domain. Any keyword match routes to the owning department; deeper resolution happens at the department + role level.

- **Finance — recognized revenue & GAAP** · revenue · recognized revenue · rev rec · GAAP · ASC 606 · ARR · MRR · TTM · recognition curve · GM% · gross margin · segment margin · by segment · COGS · renewal · churn ARR · contraction
- **Finance — planning & FP&A** · forecast · FvA · budget · variance · OPEX variance · scenario · what-if · runway · burn · cash months · plan vs actual · headcount plan · quarterly close
- **Operations — between-warehouse / supply chain** · OTD · on-time · carrier SLA · lane performance · CPM · cost per mile · carrier scorecard · rebalance · lane re-bid · fill rate · defect rate
- **Operations — inside-warehouse / fulfillment** · inventory turn · on-hand · stock level · picking · pick rate · labor utilization · shift productivity · dock-to-stock · putaway · cycle count · stockout · SKU velocity · throughput
- **Growth — acquisition & retention** · cohort · D1 · D7 · D30 · retention · signup · activation · source attribution · channel retention · campaign · DAU · MAU · WAU · signup funnel · activation funnel · visit-to-signup · signup conversion rate · first-shipment north-star
- **Growth — in-product behavior** · feature adoption · feature usage · stickiness · A/B test · experiment · variant · conversion lift · statistical significance · in-product funnel · feature funnel · variant conversion rate · in-product drop-off · in-product step-through · engagement depth · core in-product action · in-product north-star · feature flag · rollout · exposure

## Tables in scope (aggregated `tables_read` across all 6 personas)

- **Finance:** `public.revenue` · `public.contracts` · `public.segments` · `public.customers` · `public.cogs` · `public.invoices` · `public.currency_rates` · `public.budget_lines` · `public.actuals` · `public.forecasts` · `public.opex_categories` · `public.scenarios` · `public.cash_balances` · `public.headcount_plan`
- **Operations:** `public.shipments` · `public.carriers` · `public.lanes` · `public.shippers` · `public.delivery_surveys` · `public.inventory_snapshots` · `public.pick_events` · `public.putaway_events` · `public.shifts` · `public.warehouse_locations` · `public.skus` · `public.cycle_counts`
- **Growth:** `public.users` · `public.signups` · `public.sessions` · `public.events` · `public.campaigns` · `public.attribution_touches` · `public.feature_flags` · `public.experiment_assignments` · `public.experiment_outcomes` · `public.feature_usage` · `public.user_properties`

## Routing protocol (5-pass cascade)

1. **Pass 1 — Department match.** Score the question's vocabulary against each department's keyword block above. Multiple departments may match for cross-functional questions — top-3 hedging applies (CHION.md §2 Step 5).
2. **Pass 2 — Role match within department.** Open the matching `<dept>/_INDEX.md` → score against each role's persona description + trigger-keywords from the Roles table.
3. **Pass 3 — Persona load.** Open `<dept>/<role>/SKILL.md` for the full brain (persona narrative · Curated SQL Rule Pack · Layer 2 Domain Profile · Role Vocabulary · Scripts Index).
4. **Pass 4 — Script match.** At the bottom of `SKILL.md`, the Scripts Index maps trigger phrases → script folder. Take top-3 scripts; demote on fit-gate failure (CHION.md §3).
5. **Pass 5 — CTE-Mastermind wrap.** Per CHION.md §4 — script becomes `WITH base AS (...)`; secondary query layers constraints. Never mutate the base.

No LLM judgment between Pass 4 and Pass 5 — the Scripts Index is deterministic by design.

## Tie-breakers (when 2+ departments score equally)

Apply in order:
1. **`archetype` frontmatter match** — if the question's domain language aligns with a role's `archetype` (saas_finance · logistics_supply_chain · b2b_acquisition · product_analytics · warehouse_operations · saas_fp_and_a), prefer that role.
2. **`tables_read` overlap** — does the question implicate tables that one department's roles already read? Prefer that department.
3. **`chosen_primitives` match** — if the measure class needs a primitive that lives in one persona's pack (`cohort_retention_matrix` → growth; `forecast_vs_actual` → fp-and-a; `snapshot_latest` → warehouse), break the tie there.
4. **Sister-pair residual ambiguity** — when both sister roles still tie on residual generic terms after disambiguation: route by the role's distinguishing axis. **finance ↔ fp-and-a-analyst:** "what already happened" → finance-analyst · "what's planned / projected" → fp-and-a-analyst. **ops-supply-chain ↔ warehouse-operations:** "between sites · carriers · lanes" → ops-supply-chain · "inside the four walls · inventory · picking" → warehouse-operations. **growth-marketing ↔ product-analytics:** pre-signup or signup-event → growth-marketing · post-signup in-product behavior → product-analytics.

## Scaling

Today's tree (3 departments × 2 roles = 6 roles) is **Scale Tier 2** per CHION.md §2.5. Step 5 reads top `_INDEX.md` → department `_INDEX.md` → role `SKILL.md`. Adding more roles or departments stays in Tier 2 until role count exceeds 30, at which point Tier 3 (lazy-load split of `SKILL.md` into `SKILL.md` + `RULES.md` + `DOMAIN.md`) kicks in.

---

[← Root CHION.md](../../CHION.md) · [Workspace README](../../README.md)

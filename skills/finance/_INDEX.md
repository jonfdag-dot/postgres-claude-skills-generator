---
artifact_type: department_catalog
department: finance
refreshed_at: 2026-05-02T19:14:03Z
total_roles: 2
total_skills: 2
total_scripts: 7
sister_pair: [finance-analyst, fp-and-a-analyst]
sister_axis: "recognized vs. forecast"
department_archetypes: [saas_finance, saas_fp_and_a]
department_primitives: [pre_aggregate_grain, period_over_period_lag, ratio_reconstruction, cumulative_running_total, forecast_vs_actual]
department_tables_read: [public.revenue, public.contracts, public.segments, public.customers, public.cogs, public.invoices, public.currency_rates, public.budget_lines, public.actuals, public.forecasts, public.opex_categories, public.scenarios, public.cash_balances, public.headcount_plan]
---

# 💰 Finance — Department Catalog

Owns the financial truth of the company on **two time axes**: the recognized P&L (what already happened) and the planned P&L (what's about to happen). Sister roles split the same data shape — `finance-analyst` reports against the recognized-revenue book; `fp-and-a-analyst` models against the forecast / budget book. Cross-axis questions (`renewal margin in next quarter's plan`, `actual GM% against the Q2 reforecast`) route to BOTH personas; top-1 ships, top-2 stays as fallback.

## Department summary (Pass-C accumulator)

The department reasons in calendar quarters and fiscal year, distinguishing **booked vs. recognized vs. invoiced** (only recognized lands in the financial statements) and **plan vs. actual vs. forecast** (only the current scenario drives variance reporting). Recognition events live in `public.revenue` and recognize against `public.contracts`; planned amounts live in `public.budget_lines` and `public.forecasts` keyed to a fiscal-period scenario in `public.scenarios`. Sister-role discipline: `finance-analyst` refuses to compute revenue from order totals and requires `r.status = 'recognized'` on every revenue read; `fp-and-a-analyst` refuses to compare actuals to a stale scenario and requires `scenario_id` on every plan-vs-actual JOIN.

## Roles in this department

| Role | Persona description (mirrored from SKILL.md frontmatter) | Skills | Scripts | Catalog |
|---|---|---|---|---|
| **finance-analyst** | The default analyst role for the finance department. Owns recognized-revenue P&L, segment-margin reconstruction, ARR/MRR roll-ups, and renewal recognition. Reads only from `public.revenue` joined to `public.contracts` — NEVER from `public.orders` or `public.invoices`. | 1 | 5 | [finance-analyst/SKILL.md](finance-analyst/SKILL.md) |
| **fp-and-a-analyst** | Financial Planning & Analysis. Owns the forecast vs. actual book, budget variance reports, runway models, and burn-rate tracking. Reads from `public.budget_lines`, `public.forecasts`, `public.actuals`, `public.cash_balances`. | 1 | 2 | [fp-and-a-analyst/SKILL.md](fp-and-a-analyst/SKILL.md) |

## Sister-role pairing logic

| If the question is about… | Route to |
|---|---|
| Recognized revenue, ARR/MRR, renewal recognition, segment margin (what happened) | `finance-analyst` |
| Budget vs. actual, forecast revisions, runway / burn (what's planned, what's projected) | `fp-and-a-analyst` |
| Cross-axis (`actuals vs. plan for renewal revenue`) | both — finance-analyst owns the actuals leg, fp-and-a-analyst owns the variance leg; compose via Rung 3 cross-domain dispatch (CHION.md §3) |

## Department vocabulary (aggregated, deduplicated)

- **Recognition timing** — recognized · pending · reversed · GAAP · ASC 606 · `r.status = 'recognized'` (always-on filter)
- **Run-rate metrics** — ARR · MRR · TTM · trailing-twelve-months · recognition curve
- **Profitability** — GM% · gross margin · segment margin · segment profitability · COGS
- **Contract motions** — new_logo · renewal · expansion · contraction · churn ARR
- **Forecast lifecycle** — forecast · FvA · budget · plan · scenario · what-if · sensitivity · revision_id
- **Variance reporting** — budget variance · variance % · OPEX variance · plan vs actual · departmental variance
- **Cash trajectory** — runway · runway months · burn · burn rate · cash months · monthly burn · cumulative burn

## Department-wide stop signals

- Never read revenue from `public.orders.total_amount` (bookings, not P&L) or `public.invoices.amount` (billed, not recognized).
- Never `AVG(margin)` per contract — `avg_of_ratios`. Reconstruct `(SUM(rev) − SUM(cogs)) / NULLIF(SUM(rev), 0)` at segment grain.
- Never compare actuals to a non-current scenario without explicit caveat. Filter `scenarios.is_current = true` for live FvA.
- Currency conversion at recognition_ts (recognized side) or period (plan side) — never at signing date.

## How agents route within this department

1. Match question against role-level triggers above (finance-analyst recognized side · fp-and-a-analyst plan side).
2. Open the matching `<role>/SKILL.md` — load Persona, Curated Rule Pack, Layer 2 Domain Profile, Role Vocabulary, and the Scripts Index at the bottom.
3. Pick top-3 scripts whose triggers best match the user's question.
4. Open `<role>/scripts/<query>/README.md` for the 6-gate fit check; wrap via CTE-Mastermind (CHION.md §4); execute.

Sister-role swap rule (CHION.md §3 Rung 2): if the picked role produces no script fit, retry with the sister role.

---

[← Skills catalog (top)](../_INDEX.md) · [← Root CHION.md](../../../CHION.md)

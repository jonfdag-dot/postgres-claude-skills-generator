<div align="center">

<br/>

<p>
  <sub><strong>POSTGRES&nbsp;SQL&nbsp;SKILLS&nbsp;·&nbsp;FREE&nbsp;GENERATOR</strong></sub>
</p>

<h1>Postgres SQL Agent Skills for Claude Code, Cursor &amp; Codex — Verified, Auditable, Open Source</h1>

<p>
  <strong>Automatically generate verified Postgres SQL skills that prevent AI hallucinations in Claude Code, Cursor, and Codex. This workspace converts trusted queries into auditable, RLS-aware agent skills — free, MIT-licensed, deterministic.</strong>
</p>

<p>
  <a href="https://chion.ai/chion-md"><strong>Generate your skills file&nbsp;→</strong></a>
  &nbsp;·&nbsp;
  <em>Free to generate · read-only Postgres · 2-minute compile</em>
</p>

<!-- Primary row — brand + founder credibility -->
<p>
  <a href="https://chion.ai">
    <img src="https://img.shields.io/badge/Visit-chion.ai-c97d4a?style=for-the-badge&logo=postgresql&logoColor=white" alt="Visit chion.ai" />
  </a>
  &nbsp;
  <a href="https://www.linkedin.com/in/jonathan-dag/">
    <img src="https://img.shields.io/badge/Founder-Jonathan%20Dag-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="Founder — Jonathan Dag" />
  </a>
</p>

<!-- Secondary row — social platforms -->
<p>
  <a href="https://www.linkedin.com/company/chion-ai">
    <img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn" />
  </a>
  &nbsp;
  <a href="https://twitter.com/chionanalytics">
    <img src="https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white" alt="X" />
  </a>
  &nbsp;
  <a href="https://www.youtube.com/@chionai">
    <img src="https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube" />
  </a>
</p>

<br/>

<p>
  <sub>
    <strong>Free to generate</strong> &nbsp;·&nbsp; <strong>Read-only Postgres</strong> &nbsp;·&nbsp; <strong>One folder, any agent stack</strong> &nbsp;·&nbsp; <strong>Deterministic 2-minute compile</strong>
  </sub>
</p>

<br/>

</div>

---

## What this solves

Every company hits the same wall with AI analytics: the model writes SQL that *looks* right, runs against your database, and quietly answers the wrong question. Wrong join key. Wrong status filter. Snapshot summed across days. AVG of ratios. The query executes; the dashboard ships; the number is broken.

| Without Chion | With Chion |
|---|---|
| AI writes SQL that *looks* right | AI wraps a script your team already verified |
| Wrong join key, wrong status filter, snapshot summed across days | Iron-law primitives: half-open ranges, scope filters, no avg-of-ratios |
| Query runs · dashboard ships · the number is broken | Every answer cites the script path that produced it |
| You can't tell if the agent invented the join | You can read the SQL, copy it into psql, verify yourself |

**Chion fixes this once.** Your team verifies questions against your own database — not synthetic data, not a demo. Each verified question becomes a canonical SQL script. The framework organizes those scripts by department, role, and analytical pattern. The result is a single folder your AI tools read at every question — and the answer cites the exact verified script that produced it.

The more your team verifies, the sharper the agent gets. Crowdsourced inside one company. Compiled deterministically. Versioned like code.

---

## Features

| Feature | Benefit |
|---|---|
| 🤖 **Auto-generated Claude Skills** | Verified Postgres queries auto-distill into reusable skills, tagged by department and role. |
| 🔒 **Read-only, RLS-aware** | SELECT-only validator and PostgreSQL Row-Level Security honored end-to-end. Nothing in this folder mutates data. |
| 📜 **Verified, executable SQL** | Each skill ships as `{README.md, query.sql}`. The SQL file is the single source of truth — read it, copy it, run it in psql. |
| 🧠 **Three-tier semantic cascade** | `workspace → department → role/SKILL.md` matches native Claude skill discovery. CHION.md routes between them. |
| 🔁 **Deterministic compile** | Same input → byte-identical export. Diff agent files across releases the same way you diff code. |
| 🪶 **Drop-in for any agent stack** | Symlink `CHION.md` to `CLAUDE.md`, `AGENTS.md`, or `.cursor/rules/*.mdc`. One source of truth, no drift. |
| 📊 **13-phase audit trail** | Every answer cites the verified script that produced it. No hallucinated summaries — every figure traces to a row. |
| 🛡️ **MIT licensed, open-source** | Fork freely; no per-seat license; commercial use permitted. |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Database | PostgreSQL 15+ (any standard-Postgres dialect) |
| Hosted Postgres | AWS RDS · Azure Database for PostgreSQL · Google Cloud SQL · Neon · Supabase |
| Skill format | Markdown (`SKILL.md`) + verified SQL (`query.sql`) — Anthropic Claude Skills convention |
| AI tools | Claude Code · OpenAI Codex · Cursor · any agent reading root agent files |
| License | MIT |

---

## What you get when you export

| | Output |
|---|---|
| 📁 **One self-contained folder** | `CHION.md` (the agent contract) + `.claude/skills/` (the company tree) + `LICENSE`. Drop it into any repo your AI tool reads. |
| 👥 **Departments → roles → verified scripts** | Your team modeled as the analysts you'd actually hire — finance-analyst, fp-and-a-analyst, ops-supply-chain, etc. Each role carries the persona, rules, and verified queries that role owns. |
| 🧠 **Per-role analytical brain** | One `SKILL.md` per role: persona narrative, curated SQL rule pack, domain profile (entities · relationships · time roles · canonical values · stop signals), and a deterministic trigger → script index at the bottom. |
| 📜 **Verified, executable SQL** | Each script ships as `{README.md, query.sql}`. README is the semantic layer (business question, result table, dos/don'ts, per-column rules). `query.sql` is read-only SELECT, half-open time ranges, scope filters wired in. |
| 🔁 **Deterministic + re-compilable** | Same database state + same verified question set = byte-identical export. Diff across releases. Re-compile when you've verified more questions. |
| 🛡️ **Read-only by design** | Every script is SELECT-only with row caps and explicit filter values. Nothing in this folder mutates data. |

---

## Why this design — and why it works for AI tools

Six design choices, each defends against a class of analytics bug:

1. **Verified-only canon.** Scripts are not regenerated each turn. Once your team marks a query verified, it ships forever and the agent wraps it as a CTE rather than rewriting it. Eliminates "looks right, ran, wrong number" drift.

2. **Persona-based routing.** Questions resolve to the analyst whose data shape they actually live in. Finance questions land in `finance-analyst`'s brain (recognized revenue, ARR/MRR, margin); planning questions land in `fp-and-a-analyst` (forecast, variance, runway). The wrong-domain answer surface shrinks at every hop.

3. **Sister-pair coverage.** Each department covers two complementary axes that share data but split responsibility — *recognized vs. forecast* (finance), *between-warehouse vs. inside-warehouse* (operations), *acquisition vs. in-product* (growth). Cross-axis questions are routed to both sister roles and resolved without the agent having to invent a join.

4. **Universal Postgres primitives.** Every script composes from a small library of safe patterns — `pre_aggregate_grain`, `ratio_reconstruction`, `snapshot_latest`, `period_over_period_lag`, `date_spine`, `cohort_retention_matrix`. The corresponding anti-patterns (`avg_of_ratios`, `sum_of_snapshots`, `fanout`, `naked_limit_on_series`, `cumulative_retention`) are pinned as stop signals. The agent will not ship a query that violates them.

5. **Audit trail by default.** Every answer surfaces the source script path, the persona that routed to it, every always-on filter applied, and any soft-fail or partial-period flag. Silent drift — a fallback the user never sees — is a critical bug, not a feature.

6. **Bounded outputs.** ≤1,000 rows / ≤12,000 cells. The agent coarsens grain or applies TopK before generating; it never silently truncates. Half-open time predicates (`>= start AND < end`) on every range filter — never `BETWEEN` on timestamps.

The full contract — routing process, fallback ladder, iron laws, verification flow — lives in **[`CHION.md`](CHION.md)**. AI tools read that file first; it drives the cascade beneath `.claude/skills/`.

---

## How your team is modeled

Your real organization → analyst personas → verified queries.

```
.claude/skills/
└── _INDEX.md                                  workspace catalog · vocabulary · routing protocol
    └── <department>/_INDEX.md                 department catalog · roles · sister-pair logic
        └── <role>/SKILL.md                    persona brain · rule pack · domain profile · scripts index
            └── scripts/<query>/README.md      semantic layer · result table · dos/don'ts
                └── scripts/<query>/query.sql  verified read-only SELECT
```

Three tiers, each adds context the AI tool needs to answer correctly:

- **Workspace tier** — cross-department vocabulary; routes the question to the right department on the first hop.
- **Department tier** — sister-role pairing logic; routes to the right analyst within the department.
- **Role tier** — full persona, curated SQL rule pack, domain profile, and the deterministic trigger → script index. The bottom of every `SKILL.md` resolves the question to one verified script with no LLM judgment.

Adding a new analyst is one folder. Adding a new verified query is one folder under that role's `scripts/`. The framework absorbs growth without restructuring.

---

## Wiring it into your AI tool

The repo ships **one** root agent file: `CHION.md`. Every major AI tool reads its own preferred filename, but the content is the same.

| AI tool | Filename it reads | One-time setup |
|---|---|---|
| **Claude Code** | `CLAUDE.md` | `ln -s CHION.md CLAUDE.md` |
| **Codex** | `AGENTS.md` | `ln -s CHION.md AGENTS.md` |
| **Cursor** *(legacy)* | `.cursorrules` | `cp CHION.md .cursorrules` |
| **Cursor** *(modern)* | `.cursor/rules/chion.mdc` | `mkdir -p .cursor/rules && cp CHION.md .cursor/rules/chion.mdc` |
| **Other agents** | `CHION.md` directly | already canonical |

One source of truth, no drift between mirrors. The skill cascade beneath `.claude/skills/` is navigated by `CHION.md` (manual routing per its §2 + §3) rather than native skill auto-discovery, because the workspace nests roles under departments — a shape native flat skill loaders don't walk on their own.

---

## Installation

Clone the workspace and wire it into your AI tool:

```bash
# 1. Clone the Postgres SQL skills workspace
git clone https://github.com/jonfdag-dot/postgres-claude-skills-generator.git
cd postgres-claude-skills-generator

# 2. Drop into your project
cp -r . /path/to/your/repo/

# 3. Wire your AI tool to read CHION.md
ln -s CHION.md CLAUDE.md     # for Claude Code
ln -s CHION.md AGENTS.md     # for OpenAI Codex
cp CHION.md .cursorrules     # for Cursor (legacy)
mkdir -p .cursor/rules && cp CHION.md .cursor/rules/chion.mdc  # for Cursor (modern)
```

That's it. Open a question in your AI tool — it reads `CHION.md`, walks the cascade, picks the verified Claude Skill, wraps it as a CTE, executes, and returns the answer with the source path cited.

> 💡 **Want this generated for your database?** [chion.ai/chion-md](https://chion.ai/chion-md) — connect Postgres, verify questions, export your skills.

---

## About this example

This repo is a **published mock** of one Chion export. The fictitious company is **Northwind Logistics** — a third-party freight carrier marketplace coordinating shipments across 14 lanes for ~340 carriers. We chose logistics because it exercises every analytical pattern Chion supports: recognized revenue, planning/forecasting, between-warehouse logistics, inside-warehouse fulfillment, customer acquisition, in-product behavior.

```
                          Northwind Logistics
                                  │
   ┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
   │          │          │          │          │          │          │
finance-   fp-and-a-  ops-supply- warehouse- growth-   product-
analyst    analyst    chain      operations marketing  analytics
   │          │          │          │          │          │
 5 scripts  2 scripts  2 scripts  2 scripts  2 scripts  2 scripts

           (six analyst personas · 15 verified scripts · 3 departments)
```

A real Chion-generated workspace looks structurally identical to this; only the database under it is different. The schema, vocabulary, and verified queries here are illustrative — they show the **shape of output**, not Chion's internals.

---

## Generate this for your database

1. **Connect** — Visit [chion.ai/chion-md](https://chion.ai/chion-md). Point Chion at your Postgres database with read-only credentials. ~2 minutes.
2. **Use** — Ask analytics questions in plain English. Each answer is one candidate script.
3. **Verify** — In Studio, mark the answers your team trusts. Verified questions become canonical scripts.
4. **Review** — On the team / admin tier, your data lead opens the export tree, edits labels, prunes scripts, sets per-role table whitelists, then approves.
5. **Export** — Download this exact folder shape — populated with your analysts and your verified queries.

Three sequential compile passes (Persona → Curated SQL Rule Pack → Dense Domain Profile) produce the agent file. **Deterministic** — same input produces byte-identical output. Re-export anytime; diff like code.

<div align="center">

<br/>

<a href="https://chion.ai/chion-md"><strong>Generate your workspace&nbsp;→</strong></a>

<sub>2-minute setup &nbsp;·&nbsp; read-only Postgres credentials &nbsp;·&nbsp; no credit card</sub>

<br/>

</div>

---

## Pricing

| | Per-user export | Team / admin export |
|---|:---:|:---:|
| Single role · single skill folder | ✅ | ✅ |
| Verified queries auto-promoted to `scripts/` | ✅ | ✅ |
| Three-pass deterministic compile | ✅ | ✅ |
| Re-compile + diff across releases | ✅ | ✅ |
| Multi-role tree across departments | — | ✅ |
| Sister-role pairing within a department | — | ✅ |
| Leader-review page · edit before publish | — | ✅ |
| Per-role table whitelists (RLS-aligned) | — | ✅ |
| Add / rename / reassign analysts | — | ✅ |
| Promote drafts · demote noise · retire stale patterns | — | ✅ |

This Northwind workspace is a mock of the **team / admin** tier — six analyst personas, full leader-review surface, three sister-role pairings. A per-user export looks structurally identical to one branch of this tree (one analyst · one skill folder · their verified scripts).

---

## Documentation

**Product**
- 📖 [How it works](https://chion.ai/how-it-works) — The 13-phase deterministic pipeline (auto-profile · ask + route + generate · execute + chart + narrate)
- 🤖 [Generate your workspace](https://chion.ai/chion-md) — Connect Postgres, verify queries, export
- 🔒 [Trust & Security](https://chion.ai/trust) — Read-only enforcement, RLS, audit log
- 💰 [Pricing](https://chion.ai/pricing) — Free trial, no credit card

**Database integrations**
- [PostgreSQL hub](https://chion.ai/integrations/postgresql) · [AWS RDS](https://chion.ai/integrations/postgresql/aws-rds) · [Azure](https://chion.ai/integrations/postgresql/azure) · [GCP](https://chion.ai/integrations/postgresql/gcp) · [Neon](https://chion.ai/integrations/postgresql/neon) · [Supabase](https://chion.ai/integrations/postgresql/supabase)

**Related ecosystems**
- [Anthropic — Claude Skills overview](https://www.anthropic.com/news/skills) · [Anthropic skills repository](https://github.com/anthropics/skills) · [Cursor rules documentation](https://docs.cursor.com/context/rules)

**Follow**
- [LinkedIn (company)](https://www.linkedin.com/company/chion-ai) · [X / Twitter](https://twitter.com/chionanalytics) · [YouTube](https://www.youtube.com/@chionai) · [Jonathan Dag — Founder](https://www.linkedin.com/in/jonathan-dag/)

---

## Contributing

This repo is a **published mock** of a real Chion export. New verified scripts are not added here by hand — they're generated from your own Postgres database via [chion.ai/chion-md](https://chion.ai/chion-md).

What we welcome from the community:

- Issues describing problems with the export shape, routing logic, or the `CHION.md` contract
- Pull requests that improve docs, examples, or wiring instructions for additional AI tools
- Suggestions for analytical patterns Chion's primitive library does not yet cover

For commercial questions, reach out at [chion.ai/contact](https://chion.ai/contact).

---

## FAQ

<details>
<summary><strong>How does this prevent SQL injection or hallucinated columns?</strong></summary>

<br/>

Three layers of defense, all enforced in code (not LLM instructions):

- **L1 — read-only SELECT assertion.** A single SELECT is required; comments are stripped; multi-statement and DDL are rejected before the query is sent.
- **L2 — forbidden-keyword regex.** Any statement matching `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `CREATE`, `DROP`, `TRUNCATE`, `ALTER`, `GRANT`, `REVOKE`, `COPY`, or `INTO` is rejected at parse time.
- **L3 — `statement_timeout` + `LIMIT` wrap.** Every executed query is wrapped in an outer LIMIT subquery (≤1,000 rows / 12,000 cells) with a Postgres `statement_timeout`. The pipeline coarsens grain or applies TopK before silently truncating.

Hallucinated columns are blocked separately at the **typed-SQL-contract** stage (pipeline phase 8): every column reference in the generated SQL must exist in your live schema and be permitted by the contract. Out-of-contract references are rejected before execution.

The verified SQL script (`query.sql`) is itself canonical — the agent wraps it as `WITH base AS (…)` and never mutates it. New filters and aggregations layer on the secondary query, never inside the verified base.

</details>

<details>
<summary><strong>Does it work with Supabase, Neon, AWS RDS, Azure, or Google Cloud SQL?</strong></summary>

<br/>

Yes. The skill format is database-shape-agnostic — any standard PostgreSQL 12+ instance works. Shipped managed-Postgres connectors:

- **AWS RDS for PostgreSQL** — direct connection or via VPC peering
- **Azure Database for PostgreSQL** — flexible server + single server
- **Google Cloud SQL for PostgreSQL** — Cloud SQL Proxy supported
- **Neon** — serverless Postgres works as-is
- **Supabase** — pooler port (6543) works; transaction-mode poolers tested
- **Self-hosted PostgreSQL** — any instance reachable from the agent's egress

PgBouncer (transaction or session mode) and other connection poolers are supported. Read replicas are encouraged for production.

</details>

<details>
<summary><strong>How do I add a new verified Claude Skill?</strong></summary>

<br/>

The canonical path is through **Chion Studio** at [chion.ai](https://chion.ai/chion-md):

1. Open Studio and either **upload your existing query log** or **ask analytics questions in plain English** against your connected Postgres database.
2. **Verify the answers** you trust. Each verified question becomes a candidate skill; after two instances of the same pattern, the semantic pipeline auto-promotes it to a reusable skill.
3. **Re-run the skills export** from Studio's admin page. Chion regenerates the workspace folder with the new verified skill placed under the matching `<department>/<role>/scripts/<skill-id>/` folder, with `query.sql` and `README.md` produced by the three-pass deterministic compile.
4. Drop the refreshed export into your repo (or `git pull` if you've checked it in).

The compile is deterministic — same input + same database state produces byte-identical output. Diff agent files across releases the same way you diff code.

> **Hand-editing the folder is possible** but not the supported path — Studio is the source of truth for skill verification and the metadata fields (`metric_behavior`, `chosen_primitives`, `trigger_keywords`, `tables_read`) that drive routing.

</details>

<details>
<summary><strong>Can I use this with Cursor or Codex, not just Claude Code?</strong></summary>

<br/>

Yes. The repo ships **one** root agent file: `CHION.md`. Every major AI tool reads its own preferred filename, but the content is byte-identical:

- **Claude Code** — symlink `CHION.md` → `CLAUDE.md`
- **OpenAI Codex** — symlink `CHION.md` → `AGENTS.md`
- **Cursor (legacy)** — copy `CHION.md` → `.cursorrules`
- **Cursor (modern)** — copy `CHION.md` → `.cursor/rules/chion.mdc`

The skill cascade beneath `.claude/skills/` is navigated by `CHION.md`'s manual routing (per its §2 + §3) rather than native skill auto-discovery, because the workspace nests roles under departments — a shape native flat skill loaders don't walk on their own.

</details>

<details>
<summary><strong>Do I need to be on Chion's paid tier to use this repo?</strong></summary>

<br/>

**This repository is MIT-licensed** — free to use, fork, modify, and ship in commercial products. The published mock (Northwind Logistics) demonstrates the export shape and the `CHION.md` agent contract.

To **generate your own** workspace from your live Postgres database, Chion offers:

- **10-day free trial** — no credit card. Connect Postgres, ask questions, verify answers.
- **Starter** — $29/mo. **3 questions/hour.** `CHION.md` export only (the agent-contract file).
- **Pro** — $99/mo. **10 questions/hour.** `CHION.md` export only.
- **Max** — $299/mo. **Unlimited questions.** Full `CHION.md` + **Skills export** (this folder shape — `.claude/skills/` with verified `query.sql` + `README.md` per skill).
- **Enterprise** — custom. Unlimited questions + Skills export + multi-employee tree + leader-review page + per-role RLS-aligned table whitelists + frontmatter overrides.

The *generation service* is what the paid tiers cover — connecting to your live database, running the semantic pipeline, auto-promoting verified queries. **Skills export (this folder shape) is gated to Max and Enterprise tiers.** Starter and Pro can export the `CHION.md` agent contract for use in Claude Code / Codex / Cursor, but skill auto-generation into the `.claude/skills/` cascade requires Max+. The *output format itself* (`CHION.md`, `SKILL.md`, the cascade convention) is open — hand-authoring skills following this convention is free forever.

</details>

<details>
<summary><strong>How does this compare to writing CLAUDE.md by hand?</strong></summary>

<br/>

Hand-written `CLAUDE.md` files are static prose — they describe your repo conventions but don't ground the agent in your actual database schema, verified queries, or runtime guardrails. Chion-exported `CHION.md` (and its CLAUDE.md mirror) is:

- **Auto-generated from verified queries** — no manual taxonomy work
- **Schema-anchored** — every column reference traces to your real Postgres schema
- **Auditable** — every answer cites the verified script that produced it
- **Re-compilable** — diff across releases the same way you diff code
- **Multi-tool** — same content for Claude Code, Codex, and Cursor

Hand-written CLAUDE.md works for repo-context grounding. Chion-exported skills work for analytics-grade SQL where verification matters.

</details>

<details>
<summary><strong>Does Chion respect Row-Level Security and read replicas?</strong></summary>

<br/>

Yes — RLS is honored end-to-end on every query. If a row is hidden from the connecting role, it is hidden from Chion. Recommended setup:

1. Create a dedicated read-only role with `CONNECT` on the database, `USAGE` on schemas, and `SELECT` on the tables Chion can query.
2. Apply your RLS policies to that role. Chion respects them automatically.
3. Point Chion at a **read replica** for production. Read-only SELECTs map perfectly to a replica endpoint: zero write risk, offloaded compute, no impact on transactional workloads.

The connection uses TLS (`sslmode=require`); credentials are AES-256-GCM encrypted in a vault and loaded into memory only at connection time (Load-Consume-Purge pattern).

</details>

<details>
<summary><strong>Does the LLM see my actual data rows?</strong></summary>

<br/>

No. The LLM receives only **schema metadata** (table names, column names, types, foreign keys) and **controlled column summaries** (top-N value samples for categorical columns; never raw rows from numeric or PII-flagged columns).

Chion's pre-designed analytic strategies use the LLM to *propose* SQL bound to a typed contract; your database executes the SQL; results render server-side and are discarded when the session ends. The model never touches actual customer rows.

Provider terms for paid commercial API tiers (Anthropic, OpenAI, Google, Mistral) prohibit training on customer inputs. No data retention beyond the session.

</details>

---

## License

[MIT](LICENSE) — use freely, fork freely, build on top freely.

<br/>

<div align="center">

<sub>PROJECT&nbsp;STATUS</sub>

<p>
  <img src="https://img.shields.io/badge/license-MIT-c97d4a?style=flat-square" alt="MIT License" />
  &nbsp;
  <img src="https://img.shields.io/badge/postgres-15%2B-336791?style=flat-square&logo=postgresql&logoColor=white" alt="PostgreSQL 15+" />
  &nbsp;
  <img src="https://img.shields.io/badge/generated_by-chion.ai-c97d4a?style=flat-square" alt="Generated by chion.ai" />
</p>

<br/>

<a href="https://chion.ai"><img src="https://chion.ai/chion-logo-light.png" width="80" alt="Chion" /></a>

<p>
  <strong><a href="https://chion.ai">chion.ai</a></strong>
  &nbsp;·&nbsp;
  <a href="https://chion.ai/chion-md">Generate your workspace</a>
  &nbsp;·&nbsp;
  <a href="https://chion.ai/contact">Contact</a>
</p>

<sub>Built by <a href="https://www.linkedin.com/in/jonathan-dag/">Jonathan Dag</a> &nbsp;·&nbsp; Made with ☕ and Postgres in Florida.</sub>

<br/>

</div>

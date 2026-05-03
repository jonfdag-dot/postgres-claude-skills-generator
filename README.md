<div align="center">

<br/>

<p>
  <sub><strong>POSTGRES&nbsp;SQL&nbsp;SKILLS&nbsp;·&nbsp;FREE&nbsp;GENERATOR</strong></sub>
</p>

<h1>Chion Skills Generator for Postgres SQL Database</h1>

<p>
  <strong>Ask a question. Cite the SQL.</strong>
</p>

<p>
  Your company's analytics agent — auto-generated from the verified queries your team already trusts.<br/>
  One Postgres connection. One compile pass. One folder any AI tool can read.
</p>

<p>
  <a href="https://chion.ai/chion-md"><strong>Generate your skills file&nbsp;→</strong></a>
  &nbsp;·&nbsp;
  <em>Free to generate · read-only Postgres · 2-minute compile</em>
</p>

<br/>

<!-- Single social row — always-render shields.io badges -->
<p>
  <a href="https://chion.ai">
    <img src="https://img.shields.io/badge/Visit-chion.ai-c97d4a?style=for-the-badge&logo=postgresql&logoColor=white" alt="Visit chion.ai" />
  </a>
  &nbsp;
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
  &nbsp;
  <a href="https://www.linkedin.com/in/jonathan-dag/">
    <img src="https://img.shields.io/badge/Founder-Jonathan%20Dag-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="Founder — Jonathan Dag" />
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

## Quick start

```bash
git clone https://github.com/jonfdag-dot/postgres-claude-skills-generator.git
cp -r postgres-claude-skills-generator/. /path/to/your/repo/
cd postgres-claude-skills-generator
ln -s CHION.md CLAUDE.md     # or AGENTS.md, or copy to .cursorrules / .cursor/rules/
```

That's it. Open a question in your AI tool — it reads `CHION.md`, walks the cascade, picks the verified script, wraps it, executes, returns the answer with the source path cited.

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

## Resources

**Chion**
- [chion.ai](https://chion.ai) — Product overview
- [chion.ai/chion-md](https://chion.ai/chion-md) — Generate your workspace
- [chion.ai/contact](https://chion.ai/contact) — Talk to the team

**Follow**
- [LinkedIn (company)](https://www.linkedin.com/company/chion-ai)
- [X / Twitter](https://twitter.com/chionanalytics)
- [YouTube](https://www.youtube.com/@chionai)
- [Jonathan Dag — Founder](https://www.linkedin.com/in/jonathan-dag/)

**Related ecosystems**
- [Anthropic — Claude Skills overview](https://www.anthropic.com/news/skills)
- [Anthropic skills repository](https://github.com/anthropics/skills)
- [Cursor rules documentation](https://docs.cursor.com/context/rules)

---

## Contributing

This repo is a **published mock** of a real Chion export. New verified scripts are not added here by hand — they're generated from your own Postgres database via [chion.ai/chion-md](https://chion.ai/chion-md).

What we welcome from the community:

- Issues describing problems with the export shape, routing logic, or the `CHION.md` contract
- Pull requests that improve docs, examples, or wiring instructions for additional AI tools
- Suggestions for analytical patterns Chion's primitive library does not yet cover

For commercial questions, reach out at [chion.ai/contact](https://chion.ai/contact).

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

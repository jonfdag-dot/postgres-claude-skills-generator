-- ============================================================================
-- script_id: budget-variance-by-department-quarterly
--
-- Variance ($ and %) per department per quarter, against the
-- current scenario only. Pre-aggregates planned and actual at
-- (department × quarter) BEFORE division — never AVGs per-line
-- variance %.

WITH planned AS (
  SELECT
    o.department_name,
    DATE_TRUNC('quarter', b.period) AS quarter,
    SUM(b.amount_usd)               AS planned_usd
  FROM public.budget_lines b
  JOIN public.opex_categories o ON o.line_id = b.line_id
  JOIN public.scenarios s       ON s.scenario_id = b.scenario_id
  WHERE s.is_current = true
    AND b.period >= CURRENT_DATE - INTERVAL '4 quarters'
  GROUP BY o.department_name, DATE_TRUNC('quarter', b.period)
),
actual AS (
  SELECT
    o.department_name,
    DATE_TRUNC('quarter', a.period) AS quarter,
    SUM(a.amount_usd)               AS actual_usd
  FROM public.actuals a
  JOIN public.opex_categories o ON o.line_id = a.line_id
  WHERE a.period >= CURRENT_DATE - INTERVAL '4 quarters'
  GROUP BY o.department_name, DATE_TRUNC('quarter', a.period)
)
SELECT
  COALESCE(p.department_name, a.department_name) AS department_name,
  COALESCE(p.quarter, a.quarter)                 AS quarter,
  COALESCE(p.planned_usd, 0)                     AS planned_usd,
  COALESCE(a.actual_usd, 0)                      AS actual_usd,
  COALESCE(a.actual_usd, 0)
    - COALESCE(p.planned_usd, 0)                 AS variance_usd,
  (COALESCE(a.actual_usd, 0) - COALESCE(p.planned_usd, 0))::FLOAT
    / NULLIF(p.planned_usd, 0)                   AS variance_pct
FROM planned p
FULL OUTER JOIN actual a
  ON a.department_name = p.department_name
 AND a.quarter         = p.quarter
ORDER BY quarter DESC, ABS(COALESCE(
  (COALESCE(a.actual_usd, 0) - COALESCE(p.planned_usd, 0))::FLOAT
    / NULLIF(p.planned_usd, 0), 0)) DESC;

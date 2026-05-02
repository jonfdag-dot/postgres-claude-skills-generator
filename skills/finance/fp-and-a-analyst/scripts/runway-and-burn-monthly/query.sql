-- ============================================================================
-- script_id: runway-and-burn-monthly
--
-- Trailing-13-month net burn + runway. Snapshot-aware on
-- cash_balances (latest per month-end, summed across accounts).
-- Net burn = SUM(outflow) − SUM(inflow). Runway = latest cash /
-- trailing-3-month-average burn.

WITH cash_snapshots AS (
  SELECT
    DATE_TRUNC('month', cb.snapshot_ts) AS month,
    cb.account_id,
    cb.amount_usd,
    ROW_NUMBER() OVER (
      PARTITION BY DATE_TRUNC('month', cb.snapshot_ts), cb.account_id
      ORDER BY cb.snapshot_ts DESC
    ) AS rn
  FROM public.cash_balances cb
  WHERE cb.snapshot_ts >= CURRENT_DATE - INTERVAL '13 months'
    AND cb.amount_usd >= 0
),
cash_eom AS (
  SELECT
    month,
    SUM(amount_usd) AS cash_eom_usd
  FROM cash_snapshots
  WHERE rn = 1
  GROUP BY month
),
flows AS (
  SELECT
    DATE_TRUNC('month', a.period) AS month,
    SUM(CASE WHEN a.flow_direction = 'out' THEN a.amount_usd ELSE 0 END) AS outflow_usd,
    SUM(CASE WHEN a.flow_direction = 'in'  THEN a.amount_usd ELSE 0 END) AS inflow_usd
  FROM public.actuals a
  WHERE a.period >= CURRENT_DATE - INTERVAL '13 months'
  GROUP BY DATE_TRUNC('month', a.period)
),
joined AS (
  SELECT
    COALESCE(c.month, f.month) AS month,
    c.cash_eom_usd,
    COALESCE(f.outflow_usd, 0) AS outflow_usd,
    COALESCE(f.inflow_usd, 0)  AS inflow_usd,
    COALESCE(f.outflow_usd, 0) - COALESCE(f.inflow_usd, 0) AS net_burn_usd
  FROM cash_eom c
  FULL OUTER JOIN flows f ON f.month = c.month
)
SELECT
  month,
  cash_eom_usd,
  outflow_usd,
  inflow_usd,
  net_burn_usd,
  net_burn_usd - LAG(net_burn_usd) OVER (ORDER BY month) AS mom_burn_delta_usd,
  AVG(net_burn_usd) OVER (
    ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS trailing_3mo_avg_burn_usd,
  CASE
    WHEN month = (SELECT MAX(month) FROM joined)
      THEN cash_eom_usd::FLOAT / NULLIF(
        AVG(net_burn_usd) OVER (
          ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 0)
    ELSE NULL
  END AS runway_months
FROM joined
ORDER BY month DESC;

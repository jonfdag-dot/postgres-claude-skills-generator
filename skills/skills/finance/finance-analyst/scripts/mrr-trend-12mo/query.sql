-- ============================================================================
-- script_id: mrr-trend-12mo
--
-- Trailing-13-month monthly recurring revenue (extra month so the
-- first MoM row is non-NULL), with month-over-month delta in USD
-- and %. Reads only `recognized` rows from `revenue`; never from
-- bookings or invoices.

WITH monthly_recognized AS (
  SELECT
    DATE_TRUNC('month', r.recognition_ts) AS month,
    SUM(r.amount_usd)                     AS mrr_usd
  FROM revenue r
  WHERE r.recognition_ts >= CURRENT_DATE - INTERVAL '13 months'
    AND r.status = 'recognized'
  GROUP BY DATE_TRUNC('month', r.recognition_ts)
)
SELECT
  month,
  mrr_usd,
  mrr_usd - LAG(mrr_usd) OVER (ORDER BY month) AS mom_delta_usd,
  ROUND(
    100.0 * (mrr_usd - LAG(mrr_usd) OVER (ORDER BY month))
    / NULLIF(LAG(mrr_usd) OVER (ORDER BY month), 0)
  , 2) AS mom_delta_pct
FROM monthly_recognized
ORDER BY month DESC;

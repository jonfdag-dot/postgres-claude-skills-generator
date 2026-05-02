-- ============================================================================
-- script_id: gross-margin-by-segment-quarterly
--
-- Gross margin by business segment, quarterly grain. Pre-aggregates
-- revenue and COGS at segment × quarter BEFORE dividing — never
-- averages per-contract margins. COGS join enforces same-quarter
-- recognition to prevent phantom margin swings from period
-- misalignment.

SELECT
  s.segment_name,
  DATE_TRUNC('quarter', r.recognition_ts) AS quarter,
  SUM(r.amount_usd)                       AS revenue_usd,
  SUM(co.amount_usd)                      AS cogs_usd,
  SUM(r.amount_usd) - SUM(co.amount_usd)  AS gross_profit_usd,
  (SUM(r.amount_usd) - SUM(co.amount_usd))::FLOAT
    / NULLIF(SUM(r.amount_usd), 0)        AS gross_margin_pct
FROM revenue r
JOIN contracts c ON c.contract_id = r.contract_id
JOIN segments s  ON s.segment_id  = c.segment_id
LEFT JOIN cogs co
  ON co.contract_id = r.contract_id
  AND DATE_TRUNC('quarter', co.recognition_ts)
    = DATE_TRUNC('quarter', r.recognition_ts)
WHERE r.recognition_ts >= CURRENT_DATE - INTERVAL '4 quarters'
  AND r.status = 'recognized'
GROUP BY s.segment_name, DATE_TRUNC('quarter', r.recognition_ts)
ORDER BY quarter DESC, gross_margin_pct DESC;

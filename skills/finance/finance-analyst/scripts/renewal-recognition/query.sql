-- ============================================================================
-- script_id: renewal-recognition
--
-- Recognized revenue from RENEWAL contracts only (not new logos,
-- not expansion, not one-time). Filters
-- `contracts.contract_type = 'renewal'` to isolate the renewal book.

SELECT
  DATE_TRUNC('quarter', r.recognition_ts) AS quarter,
  s.segment_name,
  COUNT(DISTINCT c.contract_id)           AS renewing_contracts,
  SUM(r.amount_usd)                       AS renewal_revenue_usd
FROM revenue r
JOIN contracts c ON c.contract_id = r.contract_id
JOIN segments s  ON s.segment_id  = c.segment_id
WHERE r.recognition_ts >= CURRENT_DATE - INTERVAL '4 quarters'
  AND r.status        = 'recognized'
  AND c.contract_type = 'renewal'
GROUP BY DATE_TRUNC('quarter', r.recognition_ts), s.segment_name
ORDER BY quarter DESC, renewal_revenue_usd DESC;

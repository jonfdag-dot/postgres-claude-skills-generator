-- ============================================================================
-- script_id: arr-by-segment
--
-- Annualized recurring revenue at the most recent closed quarter,
-- bucketed by business segment. Reads from `revenue` (recognition
-- events) only — never from `orders` or `invoices`. ARR = last-closed-
-- quarter recognized revenue × 4 (NOT TTM, which back-loads churn).

SELECT
  s.segment_name,
  SUM(r.amount_usd) * 4 AS arr_usd
FROM revenue r
JOIN contracts c ON c.contract_id = r.contract_id
JOIN segments s  ON s.segment_id  = c.segment_id
WHERE r.recognition_ts >= DATE_TRUNC('quarter', CURRENT_DATE) - INTERVAL '3 months'
  AND r.recognition_ts <  DATE_TRUNC('quarter', CURRENT_DATE)
  AND r.status = 'recognized'
GROUP BY s.segment_name
ORDER BY arr_usd DESC;

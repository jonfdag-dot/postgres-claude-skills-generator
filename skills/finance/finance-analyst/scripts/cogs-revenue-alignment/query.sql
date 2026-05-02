-- ============================================================================
-- script_id: cogs-revenue-alignment
--
-- Per-row diagnostic — NOT a P&L rollup. Surfaces every contract
-- whose COGS recognition period misaligns with its revenue
-- recognition period (common cause of phantom gross-margin swings).
-- Drops contracts with no COGS coverage; use a separate query for
-- COGS-coverage gaps.

SELECT
  c.contract_id,
  s.segment_name,
  DATE_TRUNC('quarter', r.recognition_ts)  AS revenue_quarter,
  DATE_TRUNC('quarter', co.recognition_ts) AS cogs_quarter,
  CASE
    WHEN DATE_TRUNC('quarter', r.recognition_ts)
       = DATE_TRUNC('quarter', co.recognition_ts) THEN 'aligned'
    ELSE 'misaligned'
  END                                      AS alignment_flag,
  r.amount_usd                             AS revenue_amount,
  co.amount_usd                            AS cogs_amount
FROM revenue r
JOIN contracts c ON c.contract_id = r.contract_id
JOIN segments s  ON s.segment_id  = c.segment_id
LEFT JOIN cogs co ON co.contract_id = r.contract_id
WHERE r.recognition_ts >= CURRENT_DATE - INTERVAL '2 quarters'
  AND r.status = 'recognized'
  AND co.amount_usd IS NOT NULL
ORDER BY alignment_flag, c.contract_id;

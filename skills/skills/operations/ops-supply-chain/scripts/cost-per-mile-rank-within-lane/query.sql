-- ============================================================================
-- script_id: cost-per-mile-rank-within-lane
--
-- CPM rank within each lane, with lane-median for context. Drives
-- "re-bid this lane?" decisions when a carrier drifts > 15% above
-- the lane median. Pre-aggregates total_cost and miles at lane grain
-- BEFORE dividing — never AVGs per-shipment CPM.

WITH lane_carrier_cpm AS (
  SELECT
    l.lane_id,
    c.carrier_name,
    SUM(s.total_cost)::FLOAT / NULLIF(SUM(s.miles), 0) AS cpm,
    COUNT(*)                                            AS shipments
  FROM public.shipments s
  JOIN public.carriers  c ON c.carrier_id = s.carrier_id
  JOIN public.lanes     l ON l.lane_id    = s.lane_id
  WHERE s.status        != 'cancelled'
    AND c.contract_tier != 'spot'
    AND s.miles          > 0
    AND s.delivery_ts   >= CURRENT_DATE - INTERVAL '90 days'
  GROUP BY l.lane_id, c.carrier_name
  HAVING COUNT(*) >= 30
),
lane_medians AS (
  SELECT
    lane_id,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cpm) AS lane_median_cpm
  FROM lane_carrier_cpm
  GROUP BY lane_id
)
SELECT
  lc.lane_id,
  lc.carrier_name,
  lc.shipments,
  ROUND(lc.cpm::NUMERIC, 4)              AS cpm,
  ROUND(lm.lane_median_cpm::NUMERIC, 4)  AS lane_median_cpm,
  ROUND(((lc.cpm - lm.lane_median_cpm)
    / lm.lane_median_cpm * 100)::NUMERIC, 2) AS pct_above_median,
  RANK() OVER (PARTITION BY lc.lane_id ORDER BY lc.cpm) AS cpm_rank
FROM lane_carrier_cpm lc
JOIN lane_medians     lm ON lm.lane_id = lc.lane_id
ORDER BY lc.lane_id, cpm_rank;

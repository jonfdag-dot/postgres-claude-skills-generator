-- ============================================================================
-- script_id: otd-by-carrier-lane-monthly
--
-- OTD rate per (carrier × lane × month) over the trailing 90 days,
-- with month-over-month delta partitioned by (carrier, lane).
-- Pre-aggregates numerator and denominator at lane grain BEFORE
-- division — never AVGs shipment-level booleans.

WITH monthly_otd AS (
  SELECT
    c.carrier_name,
    l.lane_id,
    DATE_TRUNC('month', s.delivery_ts) AS month,
    SUM(CASE WHEN s.delivered_on_time THEN 1 ELSE 0 END) AS on_time_count,
    COUNT(*)                                              AS total_count,
    SUM(CASE WHEN s.delivered_on_time THEN 1 ELSE 0 END)::FLOAT
      / NULLIF(COUNT(*), 0)                               AS otd_rate
  FROM public.shipments s
  JOIN public.carriers  c ON c.carrier_id = s.carrier_id
  JOIN public.lanes     l ON l.lane_id    = s.lane_id
  WHERE s.status        != 'cancelled'
    AND c.contract_tier != 'spot'
    AND s.delivery_ts   >= CURRENT_DATE - INTERVAL '90 days'
  GROUP BY c.carrier_name, l.lane_id, DATE_TRUNC('month', s.delivery_ts)
)
SELECT
  carrier_name,
  lane_id,
  month,
  on_time_count,
  total_count,
  ROUND(otd_rate::NUMERIC, 4) AS otd_rate,
  otd_rate - LAG(otd_rate) OVER (
    PARTITION BY carrier_name, lane_id
    ORDER BY month
  ) AS otd_delta_mom
FROM monthly_otd
ORDER BY lane_id, carrier_name, month;

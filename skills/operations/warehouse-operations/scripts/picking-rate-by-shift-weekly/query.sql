-- ============================================================================
-- script_id: picking-rate-by-shift-weekly
--
-- Picks-per-labor-hour per (warehouse × shift × week) over the
-- trailing 8 weeks. Pre-aggregates picks and labor-hours at lane
-- grain BEFORE dividing — never AVGs per-event rates. Always
-- partition by shift_name (day/evening/night cadences differ).

WITH weekly_picks AS (
  SELECT
    sh.warehouse_id,
    sh.shift_name,
    DATE_TRUNC('week', sh.shift_start_ts) AS week,
    SUM(p.units_picked)                   AS units_picked
  FROM public.pick_events p
  JOIN public.shifts      sh ON sh.shift_id = p.shift_id
  WHERE p.cycle_time_min IS NOT NULL
    AND sh.shift_start_ts >= CURRENT_DATE - INTERVAL '8 weeks'
  GROUP BY sh.warehouse_id, sh.shift_name, DATE_TRUNC('week', sh.shift_start_ts)
),
weekly_hours AS (
  SELECT
    sh.warehouse_id,
    sh.shift_name,
    DATE_TRUNC('week', sh.shift_start_ts) AS week,
    SUM(sh.hours_worked)                  AS labor_hours
  FROM public.shifts sh
  WHERE sh.shift_start_ts >= CURRENT_DATE - INTERVAL '8 weeks'
  GROUP BY sh.warehouse_id, sh.shift_name, DATE_TRUNC('week', sh.shift_start_ts)
)
SELECT
  wp.warehouse_id,
  wp.shift_name,
  wp.week,
  wp.units_picked,
  wh.labor_hours,
  wp.units_picked::NUMERIC / NULLIF(wh.labor_hours, 0) AS picks_per_hour
FROM weekly_picks  wp
JOIN weekly_hours  wh
  ON wh.warehouse_id = wp.warehouse_id
 AND wh.shift_name   = wp.shift_name
 AND wh.week         = wp.week
ORDER BY wp.warehouse_id, wp.shift_name, wp.week DESC;

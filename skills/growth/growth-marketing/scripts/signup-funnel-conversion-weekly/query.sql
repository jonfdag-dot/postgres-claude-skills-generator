-- ============================================================================
-- script_id: signup-funnel-conversion-weekly
--
-- Weekly funnel: visit → signup → first-shipment-booked. Funnel
-- modeled as ORDERED EVENTS, not cross-table joins. step_users
-- always COUNT(DISTINCT user_id), never COUNT(*) over events.

WITH step_1_visits AS (
  SELECT
    s.user_id,
    DATE_TRUNC('week', MIN(s.session_ts)) AS cohort_week
  FROM public.sessions s
  WHERE s.session_ts >= CURRENT_DATE - INTERVAL '8 weeks'
  GROUP BY s.user_id
),
step_2_signups AS (
  SELECT
    u.user_id,
    s1.cohort_week
  FROM step_1_visits s1
  JOIN public.users u ON u.user_id = s1.user_id
  WHERE u.signup_ts >= s1.cohort_week
),
step_3_first_booked AS (
  SELECT
    s2.user_id,
    s2.cohort_week
  FROM step_2_signups s2
  JOIN LATERAL (
    SELECT MIN(e.event_ts) AS first_booked_ts
    FROM public.events e
    WHERE e.user_id     = s2.user_id
      AND e.event_name  = 'booked_shipment'
  ) fb ON true
  JOIN public.users u ON u.user_id = s2.user_id
  WHERE fb.first_booked_ts > u.signup_ts
),
unioned AS (
  SELECT cohort_week, '1_visit'             AS funnel_step, user_id FROM step_1_visits
  UNION ALL
  SELECT cohort_week, '2_signed_up'         AS funnel_step, user_id FROM step_2_signups
  UNION ALL
  SELECT cohort_week, '3_first_shipment'    AS funnel_step, user_id FROM step_3_first_booked
),
counts AS (
  SELECT
    cohort_week,
    funnel_step,
    COUNT(DISTINCT user_id) AS step_users
  FROM unioned
  GROUP BY cohort_week, funnel_step
)
SELECT
  cohort_week,
  funnel_step,
  step_users,
  LAG(step_users) OVER (PARTITION BY cohort_week ORDER BY funnel_step) AS prior_step_users,
  step_users::FLOAT / NULLIF(
    LAG(step_users) OVER (PARTITION BY cohort_week ORDER BY funnel_step),
    0
  ) AS step_conversion_rate
FROM counts
ORDER BY cohort_week DESC, funnel_step;

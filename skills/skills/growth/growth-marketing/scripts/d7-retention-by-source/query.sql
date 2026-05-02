-- ============================================================================
-- script_id: d7-retention-by-source
--
-- D7 retention split by signup-week cohort × acquisition source.
-- Point-in-time semantics — at least one session in the day-7
-- window after signup (NOT cumulative through D∞). Reconstructed
-- per (cohort × source) cell — never AVG of per-user booleans.

WITH cohorts AS (
  SELECT
    u.user_id,
    COALESCE(su.source, 'organic')         AS source,
    DATE_TRUNC('week', u.signup_ts)        AS cohort_week
  FROM public.users u
  JOIN public.signups su ON su.user_id = u.user_id
  WHERE u.signup_ts >= CURRENT_DATE - INTERVAL '12 weeks'
),
day7_active AS (
  SELECT DISTINCT s.user_id
  FROM public.sessions s
  JOIN cohorts c ON c.user_id = s.user_id
  WHERE s.session_ts >= c.cohort_week + INTERVAL '7 days'
    AND s.session_ts <  c.cohort_week + INTERVAL '8 days'
)
SELECT
  c.source,
  c.cohort_week,
  COUNT(*)                                            AS cohort_size,
  COUNT(d.user_id)                                    AS retained_d7,
  COUNT(d.user_id)::FLOAT / NULLIF(COUNT(*), 0)       AS d7_retention_rate
FROM cohorts c
LEFT JOIN day7_active d ON d.user_id = c.user_id
GROUP BY c.source, c.cohort_week
HAVING COUNT(*) >= 30
ORDER BY c.source, c.cohort_week;

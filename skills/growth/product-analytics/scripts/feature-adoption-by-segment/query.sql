-- ============================================================================
-- script_id: feature-adoption-by-segment
--
-- Feature adoption per (feature × plan_tier) over the trailing 30
-- days. Eligible denominator = users with the flag enabled in
-- external-facing states (beta / rolling_out / default_on) — NOT
-- raw MAU.

WITH eligible_features AS (
  SELECT feature_key
  FROM public.feature_flags
  WHERE flag_state IN ('beta', 'rolling_out', 'default_on')
),
eligible AS (
  SELECT
    fu.feature_key,
    up.plan_tier,
    COUNT(DISTINCT fu.user_id) AS eligible_users
  FROM public.feature_usage fu
  JOIN eligible_features      ef ON ef.feature_key = fu.feature_key
  JOIN public.user_properties up ON up.user_id    = fu.user_id
  GROUP BY fu.feature_key, up.plan_tier
),
adopters AS (
  SELECT
    fu.feature_key,
    up.plan_tier,
    COUNT(DISTINCT fu.user_id) AS adopting_users
  FROM public.feature_usage fu
  JOIN eligible_features      ef ON ef.feature_key = fu.feature_key
  JOIN public.user_properties up ON up.user_id    = fu.user_id
  WHERE fu.first_used_ts >= CURRENT_DATE - INTERVAL '30 days'
    AND fu.use_count > 0
  GROUP BY fu.feature_key, up.plan_tier
)
SELECT
  e.feature_key,
  e.plan_tier,
  e.eligible_users,
  COALESCE(a.adopting_users, 0)             AS adopting_users,
  COALESCE(a.adopting_users, 0)::FLOAT
    / NULLIF(e.eligible_users, 0)           AS adoption_rate
FROM eligible e
LEFT JOIN adopters a
  ON a.feature_key = e.feature_key
 AND a.plan_tier   = e.plan_tier
ORDER BY e.feature_key, e.plan_tier;

-- ============================================================================
-- script_id: ab-test-conversion-lift
--
-- Per-variant conversion + lift vs control with two-proportion
-- z-test significance gate at 95% (|z| >= 1.96). Outcome windows
-- are exposure-anchored (outcome_ts > assigned_ts). Sample-size
-- floor of 100 per variant.

WITH exposure AS (
  SELECT
    ea.experiment_id,
    ea.variant,
    COUNT(DISTINCT ea.user_id) AS exposed_users,
    MIN(ea.assigned_ts)        AS first_assigned_ts
  FROM public.experiment_assignments ea
  WHERE ea.variant != 'holdout'
  GROUP BY ea.experiment_id, ea.variant
),
outcomes AS (
  SELECT
    ea.experiment_id,
    ea.variant,
    COUNT(DISTINCT eo.user_id) AS converted_users
  FROM public.experiment_assignments ea
  JOIN public.experiment_outcomes    eo
    ON eo.experiment_id = ea.experiment_id
   AND eo.user_id       = ea.user_id
   AND eo.outcome_ts    > ea.assigned_ts
  WHERE ea.variant != 'holdout'
  GROUP BY ea.experiment_id, ea.variant
),
combined AS (
  SELECT
    e.experiment_id,
    e.variant,
    e.exposed_users,
    COALESCE(o.converted_users, 0)              AS converted_users,
    COALESCE(o.converted_users, 0)::FLOAT
      / NULLIF(e.exposed_users, 0)              AS conversion_rate
  FROM exposure e
  LEFT JOIN outcomes o
    ON o.experiment_id = e.experiment_id
   AND o.variant       = e.variant
  WHERE e.exposed_users >= 100
),
control AS (
  SELECT experiment_id, exposed_users AS n_c, converted_users AS x_c, conversion_rate AS p_c
  FROM combined
  WHERE variant = 'control'
)
SELECT
  c.experiment_id,
  c.variant,
  c.exposed_users,
  c.converted_users,
  c.conversion_rate,
  CASE
    WHEN c.variant = 'control' THEN NULL
    ELSE (c.conversion_rate - ctrl.p_c) / NULLIF(ctrl.p_c, 0)
  END AS lift_vs_control,
  CASE
    WHEN c.variant = 'control' THEN NULL
    ELSE (c.conversion_rate - ctrl.p_c) / NULLIF(SQRT(
      (((c.converted_users + ctrl.x_c)::FLOAT
        / NULLIF((c.exposed_users + ctrl.n_c), 0))
       * (1 - ((c.converted_users + ctrl.x_c)::FLOAT
        / NULLIF((c.exposed_users + ctrl.n_c), 0)))
       * (1.0/NULLIF(c.exposed_users, 0) + 1.0/NULLIF(ctrl.n_c, 0)))
    ), 0)
  END AS z_statistic,
  CASE
    WHEN c.variant = 'control' THEN NULL
    ELSE ABS(
      (c.conversion_rate - ctrl.p_c) / NULLIF(SQRT(
        (((c.converted_users + ctrl.x_c)::FLOAT
          / NULLIF((c.exposed_users + ctrl.n_c), 0))
         * (1 - ((c.converted_users + ctrl.x_c)::FLOAT
          / NULLIF((c.exposed_users + ctrl.n_c), 0)))
         * (1.0/NULLIF(c.exposed_users, 0) + 1.0/NULLIF(ctrl.n_c, 0)))
      ), 0)
    ) >= 1.96
  END AS is_significant_95
FROM combined c
LEFT JOIN control ctrl ON ctrl.experiment_id = c.experiment_id
ORDER BY c.experiment_id, c.variant;

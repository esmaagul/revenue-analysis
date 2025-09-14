/* =============================================================
Project 2 - ALL METRICS by Month x Language x Age_Group (PostgreSQL)
Tables:
  - project.games_payments(user_id, payment_date, revenue_amount_usd)
  - project.games_paid_users(user_id, language, age)
Notes:
  - All queries segment by language and age_group (derived from u.age).
  - Designed to run each block independently if needed.
============================================================= */

-- Helper CASE for age_group (use in SELECT):
--   CASE
--     WHEN u.age IS NULL THEN 'Unknown'
--     WHEN u.age < 18 THEN '<18'
--     WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
--     WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
--     WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
--     WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
--     WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
--     ELSE '65+'
--   END AS age_group


/* =============================================================
1) MRR (Monthly Recurring Revenue)
============================================================= */
SELECT 
  DATE_TRUNC('month', gp.payment_date)::date AS month,
  u.language,
  CASE
    WHEN u.age IS NULL THEN 'Unknown'
    WHEN u.age < 18 THEN '<18'
    WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
    WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
    WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
    WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
    WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
    ELSE '65+'
  END AS age_group,
  SUM(gp.revenue_amount_usd) AS mrr
FROM project.games_payments gp
JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
  ON u.user_id = gp.user_id
GROUP BY 1,2,3
ORDER BY 1,2,3;


/* =============================================================
2) Paid Users (distinct paying users in the month)
============================================================= */
SELECT 
  DATE_TRUNC('month', gp.payment_date)::date AS month,
  u.language,
  CASE
    WHEN u.age IS NULL THEN 'Unknown'
    WHEN u.age < 18 THEN '<18'
    WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
    WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
    WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
    WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
    WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
    ELSE '65+'
  END AS age_group,
  COUNT(DISTINCT gp.user_id) AS paid_users
FROM project.games_payments gp
JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
  ON u.user_id = gp.user_id
GROUP BY 1,2,3
ORDER BY 1,2,3;


/* =============================================================
3) ARPPU = MRR / Paid Users (per segment per month)
============================================================= */
WITH monthly AS (
  SELECT 
    DATE_TRUNC('month', gp.payment_date)::date AS month,
    u.language,
    CASE
      WHEN u.age IS NULL THEN 'Unknown'
      WHEN u.age < 18 THEN '<18'
      WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
      WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
      WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
      WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
      WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
      ELSE '65+'
    END AS age_group,
    SUM(gp.revenue_amount_usd) AS total_revenue,
    COUNT(DISTINCT gp.user_id) AS paid_users
  FROM project.games_payments gp
  JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
    ON u.user_id = gp.user_id
  GROUP BY 1,2,3
)
SELECT 
  month, language, age_group,
  total_revenue / NULLIF(paid_users, 0) AS arppu
FROM monthly
ORDER BY 1,2,3;


/* =============================================================
4) New Paid Users (first-time payers in a given month)
============================================================= */
WITH user_first AS (
  SELECT 
    gp.user_id,
    MIN(DATE_TRUNC('month', gp.payment_date))::date AS first_month,
    u.language,
    CASE
      WHEN u.age IS NULL THEN 'Unknown'
      WHEN u.age < 18 THEN '<18'
      WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
      WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
      WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
      WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
      WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
      ELSE '65+'
    END AS age_group
  FROM project.games_payments gp
  JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
    ON u.user_id = gp.user_id
  GROUP BY 1,3,4
)
SELECT 
  first_month AS month,
  language, age_group,
  COUNT(user_id) AS new_paid_users
FROM user_first
GROUP BY 1,2,3
ORDER BY 1,2,3;


/* =============================================================
5) New MRR (revenue from new paid users in their first month)
============================================================= */
WITH user_first AS (
  SELECT 
    gp.user_id,
    MIN(DATE_TRUNC('month', gp.payment_date))::date AS first_month,
    u.language,
    CASE
      WHEN u.age IS NULL THEN 'Unknown'
      WHEN u.age < 18 THEN '<18'
      WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
      WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
      WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
      WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
      WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
      ELSE '65+'
    END AS age_group
  FROM project.games_payments gp
  JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
    ON u.user_id = gp.user_id
  GROUP BY 1,3,4
)
SELECT
  uf.first_month AS month,
  uf.language,
  uf.age_group,
  SUM(gp.revenue_amount_usd) AS new_mrr
FROM project.games_payments gp
JOIN user_first uf
  ON uf.user_id = gp.user_id
 AND DATE_TRUNC('month', gp.payment_date)::date = uf.first_month
GROUP BY 1,2,3
ORDER BY 1,2,3;


/* =============================================================
6) Churned Users (paid in prev month, not paid in current month)
   Attribution: churn month (m), segment keys from PREVIOUS month.
============================================================= */
WITH user_month AS (
  SELECT DISTINCT
    gp.user_id,
    DATE_TRUNC('month', gp.payment_date)::date AS month
  FROM project.games_payments gp
),
prev_month_users AS (
  SELECT 
    um.user_id,
    um.month AS prev_month,
    (um.month + INTERVAL '1 month')::date AS churn_month
  FROM user_month um
),
churned_core AS (
  SELECT 
    pmu.user_id,
    pmu.prev_month,
    pmu.churn_month
  FROM prev_month_users pmu
  LEFT JOIN user_month thism
    ON thism.user_id = pmu.user_id
   AND thism.month   = pmu.churn_month
  WHERE thism.user_id IS NULL
)
SELECT
  c.churn_month AS month,
  u.language,
  CASE
    WHEN u.age IS NULL THEN 'Unknown'
    WHEN u.age < 18 THEN '<18'
    WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
    WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
    WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
    WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
    WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
    ELSE '65+'
  END AS age_group,
  COUNT(DISTINCT c.user_id) AS churned_users
FROM churned_core c
JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
  ON u.user_id = c.user_id
GROUP BY 1,2,3
ORDER BY 1,2,3;


/* =============================================================
7) Churn Rate = Churned Users(X) / Paid Users(X-1) (per segment)
============================================================= */
WITH paid_prev AS (
  SELECT 
    DATE_TRUNC('month', gp.payment_date)::date AS prev_month,
    u.language,
    CASE
      WHEN u.age IS NULL THEN 'Unknown'
      WHEN u.age < 18 THEN '<18'
      WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
      WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
      WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
      WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
      WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
      ELSE '65+'
    END AS age_group,
    COUNT(DISTINCT gp.user_id) AS paid_users_prev
  FROM project.games_payments gp
  JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
    ON u.user_id = gp.user_id
  GROUP BY 1,2,3
),
churned AS (
  WITH user_month AS (
    SELECT DISTINCT gp.user_id, DATE_TRUNC('month', gp.payment_date)::date AS month
    FROM project.games_payments gp
  ),
  prev_month_users AS (
    SELECT um.user_id, um.month AS prev_month, (um.month + INTERVAL '1 month')::date AS churn_month
    FROM user_month um
  ),
  churned_core AS (
    SELECT pmu.user_id, pmu.prev_month, pmu.churn_month
    FROM prev_month_users pmu
    LEFT JOIN user_month thism ON thism.user_id = pmu.user_id AND thism.month = pmu.churn_month
    WHERE thism.user_id IS NULL
  )
  SELECT
    c.churn_month AS month,
    u.language,
    CASE
      WHEN u.age IS NULL THEN 'Unknown'
      WHEN u.age < 18 THEN '<18'
      WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
      WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
      WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
      WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
      WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
      ELSE '65+'
    END AS age_group,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM churned_core c
  JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
    ON u.user_id = c.user_id
  GROUP BY 1,2,3
)
SELECT
  c.month,
  c.language,
  c.age_group,
  c.churned_users::numeric / NULLIF(p.paid_users_prev, 0) AS churn_rate
FROM churned c
JOIN paid_prev p
  ON p.prev_month = (c.month - INTERVAL '1 month')::date
 AND p.language   = c.language
 AND p.age_group  = c.age_group
ORDER BY 1,2,3;


/* =============================================================
8) Churned Revenue (sum of previous-month revenue of churned users)
============================================================= */
WITH user_month_revenue AS (
  SELECT
    gp.user_id,
    DATE_TRUNC('month', gp.payment_date)::date AS month,
    SUM(gp.revenue_amount_usd) AS revenue
  FROM project.games_payments gp
  GROUP BY 1,2
),
user_month AS (
  SELECT DISTINCT user_id, month FROM user_month_revenue
),
prev_month_users AS (
  SELECT 
    um.user_id,
    um.month AS prev_month,
    (um.month + INTERVAL '1 month')::date AS churn_month
  FROM user_month um
),
churned AS (
  SELECT 
    pmu.user_id,
    pmu.prev_month,
    pmu.churn_month
  FROM prev_month_users pmu
  LEFT JOIN user_month thism
    ON thism.user_id = pmu.user_id
   AND thism.month   = pmu.churn_month
  WHERE thism.user_id IS NULL
)
SELECT
  c.churn_month AS month,
  u.language,
  CASE
    WHEN u.age IS NULL THEN 'Unknown'
    WHEN u.age < 18 THEN '<18'
    WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
    WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
    WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
    WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
    WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
    ELSE '65+'
  END AS age_group,
  SUM(umr.revenue) AS churned_revenue
FROM churned c
JOIN user_month_revenue umr
  ON umr.user_id = c.user_id
 AND umr.month   = c.prev_month
JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
  ON u.user_id = c.user_id
GROUP BY 1,2,3
ORDER BY 1,2,3;


/* =============================================================
9) Revenue Churn Rate = Churned Revenue(X) / MRR(X-1) per segment
============================================================= */
WITH mrr_prev AS (
  SELECT 
    DATE_TRUNC('month', gp.payment_date)::date AS prev_month,
    u.language,
    CASE
      WHEN u.age IS NULL THEN 'Unknown'
      WHEN u.age < 18 THEN '<18'
      WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
      WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
      WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
      WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
      WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
      ELSE '65+'
    END AS age_group,
    SUM(gp.revenue_amount_usd) AS mrr_prev
  FROM project.games_payments gp
  JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u
    ON u.user_id = gp.user_id
  GROUP BY 1,2,3
),
churned_rev AS (
  WITH user_month_revenue AS (
    SELECT gp.user_id, DATE_TRUNC('month', gp.payment_date)::date AS month, SUM(gp.revenue_amount_usd) AS revenue
    FROM project.games_payments gp
    GROUP BY 1,2
  ),
  user_month AS (SELECT DISTINCT user_id, month FROM user_month_revenue),
  prev_month_users AS (
    SELECT um.user_id, um.month AS prev_month, (um.month + INTERVAL '1 month')::date AS churn_month
    FROM user_month um
  ),
  churned AS (
    SELECT pmu.user_id, pmu.prev_month, pmu.churn_month
    FROM prev_month_users pmu
    LEFT JOIN user_month thism ON thism.user_id = pmu.user_id AND thism.month = pmu.churn_month
    WHERE thism.user_id IS NULL
  )
  SELECT
    c.churn_month AS month,
    u.language,
    CASE
      WHEN u.age IS NULL THEN 'Unknown'
      WHEN u.age < 18 THEN '<18'
      WHEN u.age BETWEEN 18 AND 24 THEN '18–24'
      WHEN u.age BETWEEN 25 AND 34 THEN '25–34'
      WHEN u.age BETWEEN 35 AND 44 THEN '35–44'
      WHEN u.age BETWEEN 45 AND 54 THEN '45–54'
      WHEN u.age BETWEEN 55 AND 64 THEN '55–64'
      ELSE '65+'
    END AS age_group,
    SUM(umr.revenue) AS churned_revenue
  FROM churned c
  JOIN user_month_revenue umr ON umr.user_id = c.user_id AND umr.month = c.prev_month
  JOIN (SELECT DISTINCT user_id, language, age FROM project.games_paid_users) u ON u.user_id = c.user_id
  GROUP BY 1,2,3
)
SELECT
  cr.month,
  cr.language,
  cr.age_group,
  cr.churned_revenue::numeric / NULLIF(mp.mrr_prev, 0) AS revenue_churn_rate
FROM churned_rev cr
JOIN mrr_prev mp
  ON mp.prev_month = (cr.month - INTERVAL '1 month')::date
 AND mp.language   = cr.language
 AND mp.age_group  = cr.age_group
ORDER BY 1,2,3;


/* =============================================================
10) Expansion / Contraction MRR (existing payers who changed spend)
============================================================= */
WITH user_month_revenue AS (
  SELECT
    gp.user_id,
    DATE_TRUNC('month', gp.payment_date)::date AS month,
    SUM(gp.revenue_amount_usd) AS revenue
  FROM project.games_payments gp
  GROUP BY 1,2
),
pairs AS (
  SELECT
    umr.user_id,
    umr.month AS month,
    umr.revenue AS cur_rev,
    LAG(umr.revenue) OVER (PARTITION BY umr.user_id ORDER BY umr.month) AS prev_rev
  FROM user_month_revenue umr
),
seg AS (
  SELECT DISTINCT user_id, language, age FROM project.games_paid_users
)
SELECT
  p.month,
  s.language,
  CASE
    WHEN s.age IS NULL THEN 'Unknown'
    WHEN s.age < 18 THEN '<18'
    WHEN s.age BETWEEN 18 AND 24 THEN '18–24'
    WHEN s.age BETWEEN 25 AND 34 THEN '25–34'
    WHEN s.age BETWEEN 35 AND 44 THEN '35–44'
    WHEN s.age BETWEEN 45 AND 54 THEN '45–54'
    WHEN s.age BETWEEN 55 AND 64 THEN '55–64'
    ELSE '65+'
  END AS age_group,
  SUM(CASE WHEN p.prev_rev > 0 AND p.cur_rev > p.prev_rev THEN (p.cur_rev - p.prev_rev) ELSE 0 END) AS expansion_mrr,
  SUM(CASE WHEN p.prev_rev > 0 AND p.cur_rev < p.prev_rev THEN (p.prev_rev - p.cur_rev) ELSE 0 END) AS contraction_mrr
FROM pairs p
JOIN seg s ON s.user_id = p.user_id
GROUP BY 1,2,3
ORDER BY 1,2,3;




select * 
FROM project.games_payments gp
JOIN project.games_paid_users u ON gp.user_id = u.user_id;


WITH user_month_revenue AS (
  SELECT
    gp.user_id,
    DATE_TRUNC('month', gp.payment_date)::date AS month,
    SUM(gp.revenue_amount_usd) AS revenue
  FROM project.games_payments gp
  GROUP BY 1,2
)
SELECT
    u.user_id,
    u.language,
    CAST(u.age AS TEXT) || 'Y' AS age,
    CASE WHEN u.has_older_device_model = TRUE THEN '✓' ELSE '✗' END AS has_older_device,
    COUNT(umr.month) AS active_months,
    SUM(umr.revenue) AS total_revenue
FROM user_month_revenue umr
JOIN project.games_paid_users u 
  ON umr.user_id = u.user_id
GROUP BY u.user_id, u.game_name, u.language, u.age, u.has_older_device_model
ORDER BY total_revenue DESC;





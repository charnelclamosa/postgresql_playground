-- =====================================================================
-- SOLUTIONS (PostgreSQL). Try each exercise on your own first.
-- Run a section after:  SET search_path TO exNN_...;
-- =====================================================================

-- ---------------------------------------------------------------------
-- 01 Top-N per group  (top 2 revenue ranks per category, ties included)
-- ---------------------------------------------------------------------
SET search_path TO ex01_top_n;

WITH revenue AS (
    SELECT p.category,
           p.product_name,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    JOIN order_items oi USING (product_id)
    GROUP BY p.category, p.product_name
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
    FROM revenue
)
SELECT category, product_name, revenue, revenue_rank
FROM ranked
WHERE revenue_rank <= 2
ORDER BY category, revenue_rank, product_name;

-- ---------------------------------------------------------------------
-- 02 CDC dedup  (current state, deleted rows removed)
-- ---------------------------------------------------------------------
SET search_path TO ex02_cdc_dedup;

WITH latest AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY changed_at DESC, change_id DESC
           ) AS rn
    FROM customers_cdc
)
SELECT customer_id, email, plan, changed_at
FROM latest
WHERE rn = 1
  AND op <> 'D'
ORDER BY customer_id;

-- ---------------------------------------------------------------------
-- 03 Calendar spine + running total + 3-day moving average
-- ---------------------------------------------------------------------
SET search_path TO ex03_running_totals;

WITH calendar AS (
    SELECT d::date AS day
    FROM generate_series(DATE '2026-01-01', DATE '2026-01-10', INTERVAL '1 day') AS d
),
daily AS (
    SELECT c.day,
           COALESCE(SUM(o.amount), 0) AS revenue
    FROM calendar c
    LEFT JOIN orders o ON o.order_date = c.day
    GROUP BY c.day
)
SELECT day,
       revenue,
       SUM(revenue) OVER (ORDER BY day)                                        AS cumulative_revenue,
       ROUND(AVG(revenue) OVER (ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3d
FROM daily
ORDER BY day;

-- ---------------------------------------------------------------------
-- 04 Sessionization (new session when gap > 30 minutes)
-- ---------------------------------------------------------------------
SET search_path TO ex04_sessions;

WITH flagged AS (
    SELECT *,
           CASE
               WHEN LAG(event_ts) OVER w IS NULL THEN 1
               WHEN event_ts - LAG(event_ts) OVER w > INTERVAL '30 minutes' THEN 1
               ELSE 0
           END AS is_new_session
    FROM events
    WINDOW w AS (PARTITION BY user_id ORDER BY event_ts)
),
numbered AS (
    SELECT *,
           SUM(is_new_session) OVER (PARTITION BY user_id ORDER BY event_ts) AS session_number
    FROM flagged
)
SELECT user_id,
       session_number,
       MIN(event_ts) AS session_start,
       MAX(event_ts) AS session_end,
       COUNT(*)      AS event_count,
       ROUND(EXTRACT(EPOCH FROM MAX(event_ts) - MIN(event_ts)) / 60)::int AS duration_minutes
FROM numbered
GROUP BY user_id, session_number
ORDER BY user_id, session_number;

-- ---------------------------------------------------------------------
-- 05 Monthly cohort retention
-- ---------------------------------------------------------------------
SET search_path TO ex05_cohort;

WITH cohorts AS (
    SELECT user_id, DATE_TRUNC('month', signup_date)::date AS cohort_month
    FROM users
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
),
activity_months AS (
    SELECT DISTINCT
           c.cohort_month,
           c.user_id,
           (EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', a.activity_date), c.cohort_month)) * 12
            + EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', a.activity_date), c.cohort_month)))::int
               AS months_since_signup
    FROM cohorts c
    JOIN activity a USING (user_id)
)
SELECT am.cohort_month,
       am.months_since_signup,
       COUNT(*)                                             AS active_users,
       cs.cohort_size,
       ROUND(100.0 * COUNT(*) / cs.cohort_size, 1)          AS retention_pct
FROM activity_months am
JOIN cohort_sizes cs USING (cohort_month)
GROUP BY am.cohort_month, am.months_since_signup, cs.cohort_size
ORDER BY am.cohort_month, am.months_since_signup;

-- ---------------------------------------------------------------------
-- 06 Ordered funnel (each step must happen after the previous one)
-- ---------------------------------------------------------------------
SET search_path TO ex06_funnel;

WITH s1 AS (
    SELECT user_id, MIN(event_ts) AS t1
    FROM events WHERE event_name = 'view_product'
    GROUP BY user_id
),
s2 AS (
    SELECT s1.user_id, s1.t1, MIN(e.event_ts) AS t2
    FROM s1
    JOIN events e ON e.user_id = s1.user_id
                 AND e.event_name = 'add_to_cart'
                 AND e.event_ts > s1.t1
    GROUP BY s1.user_id, s1.t1
),
s3 AS (
    SELECT s2.user_id, s2.t2, MIN(e.event_ts) AS t3
    FROM s2
    JOIN events e ON e.user_id = s2.user_id
                 AND e.event_name = 'begin_checkout'
                 AND e.event_ts > s2.t2
    GROUP BY s2.user_id, s2.t2
),
s4 AS (
    SELECT s3.user_id, MIN(e.event_ts) AS t4
    FROM s3
    JOIN events e ON e.user_id = s3.user_id
                 AND e.event_name = 'purchase'
                 AND e.event_ts > s3.t3
    GROUP BY s3.user_id
),
funnel AS (
    SELECT 1 AS step_order, 'view_product'   AS step_name, COUNT(*) AS users FROM s1
    UNION ALL SELECT 2, 'add_to_cart',     COUNT(*) FROM s2
    UNION ALL SELECT 3, 'begin_checkout',  COUNT(*) FROM s3
    UNION ALL SELECT 4, 'purchase',        COUNT(*) FROM s4
)
SELECT step_order,
       step_name,
       users,
       ROUND(100.0 * users / LAG(users) OVER (ORDER BY step_order), 1) AS pct_of_previous,
       ROUND(100.0 * users / FIRST_VALUE(users) OVER (ORDER BY step_order), 1) AS pct_of_top
FROM funnel
ORDER BY step_order;

-- ---------------------------------------------------------------------
-- 07 SCD2 dimension + point-in-time join
-- ---------------------------------------------------------------------
SET search_path TO ex07_scd2;

-- Part 1: the dimension (valid_from inclusive, valid_to exclusive, NULL = open)
SELECT customer_id,
       tier,
       effective_date                                                        AS valid_from,
       LEAD(effective_date) OVER (PARTITION BY customer_id ORDER BY effective_date) AS valid_to,
       (LEAD(effective_date) OVER (PARTITION BY customer_id ORDER BY effective_date) IS NULL) AS is_current
FROM customer_tier_changes
ORDER BY customer_id, valid_from;

-- Part 2: revenue by the tier the customer had ON THE ORDER DATE
WITH dim AS (
    SELECT customer_id,
           tier,
           effective_date AS valid_from,
           LEAD(effective_date) OVER (PARTITION BY customer_id ORDER BY effective_date) AS valid_to
    FROM customer_tier_changes
)
SELECT COALESCE(d.tier, 'unknown') AS tier,
       COUNT(*)                    AS orders,
       SUM(o.amount)               AS revenue
FROM orders o
LEFT JOIN dim d
       ON d.customer_id = o.customer_id
      AND o.order_date >= d.valid_from
      AND (o.order_date < d.valid_to OR d.valid_to IS NULL)
GROUP BY COALESCE(d.tier, 'unknown')
ORDER BY revenue DESC;

-- ---------------------------------------------------------------------
-- 08 Gaps in hourly sensor data
-- ---------------------------------------------------------------------
SET search_path TO ex08_sensor_gaps;

WITH pairs AS (
    SELECT sensor_id,
           reading_ts AS gap_start,
           LEAD(reading_ts) OVER (PARTITION BY sensor_id ORDER BY reading_ts) AS gap_end
    FROM readings
)
SELECT sensor_id,
       gap_start,
       gap_end,
       (EXTRACT(EPOCH FROM gap_end - gap_start) / 3600)::int - 1 AS missing_readings
FROM pairs
WHERE gap_end - gap_start > INTERVAL '1 hour'
ORDER BY sensor_id, gap_start;

-- ---------------------------------------------------------------------
-- 09 Reconciliation (NULL-safe comparison)
-- ---------------------------------------------------------------------
SET search_path TO ex09_reconciliation;

SELECT COALESCE(s.order_id, t.order_id) AS order_id,
       CASE
           WHEN t.order_id IS NULL THEN 'missing_in_target'
           WHEN s.order_id IS NULL THEN 'extra_in_target'
           ELSE 'value_mismatch'
       END AS issue_type,
       s.status  AS source_status,  t.status  AS target_status,
       s.amount  AS source_amount,  t.amount  AS target_amount
FROM source_orders s
FULL OUTER JOIN target_orders t ON s.order_id = t.order_id
WHERE s.order_id IS NULL
   OR t.order_id IS NULL
   OR s.status IS DISTINCT FROM t.status
   OR s.amount IS DISTINCT FROM t.amount
ORDER BY order_id;

-- ---------------------------------------------------------------------
-- 10 Recursive hierarchy
-- ---------------------------------------------------------------------
SET search_path TO ex10_hierarchy;

-- Part 1: everyone, with depth and management chain
WITH RECURSIVE org AS (
    SELECT employee_id, name, manager_id, 0 AS depth, name::text AS path
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.name, e.manager_id, o.depth + 1, o.path || ' > ' || e.name
    FROM employees e
    JOIN org o ON e.manager_id = o.employee_id
)
SELECT employee_id, name, depth, path
FROM org
ORDER BY path;

-- Part 2: total (direct + indirect) reports per manager
WITH RECURSIVE reports AS (
    SELECT manager_id AS manager_id, employee_id
    FROM employees
    WHERE manager_id IS NOT NULL
    UNION ALL
    SELECT r.manager_id, e.employee_id
    FROM reports r
    JOIN employees e ON e.manager_id = r.employee_id
)
SELECT m.name AS manager,
       COUNT(*) AS total_reports,
       SUM(e.salary) AS total_report_salary
FROM reports r
JOIN employees m ON m.employee_id = r.manager_id
JOIN employees e ON e.employee_id = r.employee_id
GROUP BY m.name
ORDER BY total_reports DESC, manager;

-- ---------------------------------------------------------------------
-- 11 Find and remove duplicates
-- ---------------------------------------------------------------------
SET search_path TO ex11_duplicates;

-- Part 1: which (normalized) emails are duplicated?
SELECT LOWER(TRIM(email))  AS email_normalized,
       COUNT(*)            AS occurrences,
       ARRAY_AGG(customer_id ORDER BY customer_id) AS customer_ids
FROM customers
WHERE email IS NOT NULL
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1
ORDER BY email_normalized;

-- Part 2: the rows that would be removed (keep the earliest; ties -> lowest id)
SELECT customer_id, email, created_at
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY LOWER(TRIM(email))
               ORDER BY created_at, customer_id
           ) AS rn
    FROM customers
    WHERE email IS NOT NULL
) t
WHERE rn > 1
ORDER BY customer_id;

-- Part 3: delete them (run inside a transaction and check the count first)
BEGIN;
DELETE FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM (
        SELECT customer_id,
               ROW_NUMBER() OVER (
                   PARTITION BY LOWER(TRIM(email))
                   ORDER BY created_at, customer_id
               ) AS rn
        FROM customers
        WHERE email IS NOT NULL
    ) t
    WHERE rn > 1
);
SELECT COUNT(*) AS remaining_rows FROM customers;
ROLLBACK;  -- use COMMIT once you are happy

-- Variant: table with NO primary key and fully identical rows (PostgreSQL)
-- DELETE FROM t WHERE ctid IN (
--   SELECT ctid FROM (
--     SELECT ctid, ROW_NUMBER() OVER (PARTITION BY col_a, col_b ORDER BY ctid) rn FROM t
--   ) x WHERE rn > 1);
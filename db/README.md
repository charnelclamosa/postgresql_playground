# SQL Interview Exercises for Data Engineering (PostgreSQL)

Each exercise has: a business scenario, the tables, the task, the exact expected output, and what interviewers are usually checking. Load the data from `init/NN_*.sql` (plain tables in `public`, so `\dt` shows them). Reference solutions are in `solutions/NN_*.sql`: try first, then compare.

| # | Topic | Tables | Difficulty |
|---|-------|--------|-----------|
| 01 | Top-N per group, ties | `products`, `order_items` | Easy |
| 02 | CDC dedup to current state | `customers_cdc` | Easy-Medium |
| 03 | Calendar spine, running total, moving average | `daily_orders` | Medium |
| 04 | Sessionization | `session_events` | Medium-Hard |
| 05 | Cohort retention | `users`, `activity` | Medium-Hard |
| 06 | Ordered conversion funnel | `funnel_events` | Hard |
| 07 | SCD Type 2 + point-in-time join | `customer_tier_changes`, `tier_orders` | Medium |
| 08 | Gaps in time-series data | `readings` | Medium |
| 09 | Source vs. warehouse reconciliation | `source_orders`, `target_orders` | Medium |
| 10 | Recursive CTE hierarchy | `employees` | Medium-Hard |
| 11 | Find and remove duplicates | `customers` | Easy-Medium |

---

## 01. Top-N per group

**Scenario.** A retail client wants a weekly "best sellers" report: the top 2 products by revenue in each category.

**Tables.** `products(product_id, product_name, category)`, `order_items(order_item_id, order_id, product_id, quantity, unit_price)`. Revenue = `quantity * unit_price`.

**Task.** Return the top 2 revenue *ranks* per category. If products tie for 2nd place, include all of them. Products with no sales are excluded.

**Expected output**

| category | product_name | revenue | revenue_rank |
|---|---|---|---|
| Electronics | Phone X | 4000.00 | 1 |
| Electronics | Headphones | 2400.00 | 2 |
| Electronics | Laptop Pro | 2400.00 | 2 |
| Furniture | Standing Desk | 1800.00 | 1 |
| Furniture | Desk Chair | 1250.00 | 2 |
| Stationery | Notebook | 600.00 | 1 |
| Stationery | Pen Set | 600.00 | 1 |

**What they check.** `RANK` vs `DENSE_RANK` vs `ROW_NUMBER` (and why ties matter), aggregating *before* ranking, and filtering on a window result via CTE/subquery.

---

## 02. Deduplicate a CDC feed to current state

**Scenario.** A client replicates their CRM into your lake via change data capture. The table holds every insert/update/delete. Build the "current customers" view.

**Table.** `customers_cdc(change_id, customer_id, email, plan, op, changed_at)` where `op` is `I`, `U` or `D`.

**Task.** Return one row per customer reflecting its latest state, excluding customers whose latest change is a delete. Two changes can share the same timestamp (customer 3): the higher `change_id` wins.

**Expected output**

| customer_id | email | plan | changed_at |
|---|---|---|---|
| 1 | a@new.com | pro | 2026-03-05 12:00:00 |
| 3 | c@x.com | enterprise | 2026-01-20 11:00:00 |
| 4 | d@x.com | free | 2026-03-01 00:00:00 |

**What they check.** `ROW_NUMBER() ... ORDER BY changed_at DESC, change_id DESC` with a deterministic tiebreaker, and applying the delete filter *after* picking the latest row (filtering deletes first would resurrect customer 2).

---

## 03. Calendar spine, running total, moving average

**Scenario.** Finance wants a daily revenue dashboard for 1-10 Jan 2026. Days with no orders must still appear.

**Table.** `daily_orders(order_id, order_date, amount)`.

**Task.** For every day from 2026-01-01 to 2026-01-10 return daily revenue (0 if none), cumulative revenue, and the average daily revenue over the current and previous 2 calendar days (fewer days at the start; rounded to 2 decimals).

**Expected output**

| day | revenue | cumulative_revenue | moving_avg_3d |
|---|---|---|---|
| 2026-01-01 | 150.00 | 150.00 | 150.00 |
| 2026-01-02 | 200.00 | 350.00 | 175.00 |
| 2026-01-03 | 0 | 350.00 | 116.67 |
| 2026-01-04 | 150.00 | 500.00 | 116.67 |
| 2026-01-05 | 90.00 | 590.00 | 80.00 |
| 2026-01-06 | 300.00 | 890.00 | 180.00 |
| 2026-01-07 | 0 | 890.00 | 130.00 |
| 2026-01-08 | 60.00 | 950.00 | 120.00 |
| 2026-01-09 | 100.00 | 1050.00 | 53.33 |
| 2026-01-10 | 80.00 | 1130.00 | 80.00 |

**What they check.** `generate_series` + `LEFT JOIN` (a window over only the days that have orders gives wrong averages), `COALESCE`, and window frames (`ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`).

---

## 04. Sessionization

**Scenario.** A media client sends raw clickstream events and wants sessions: a new session starts after **more than 30 minutes** of inactivity.

**Table.** `session_events(event_id, user_id, event_ts, event_name)`.

**Task.** One row per session: `user_id`, `session_number` (per user, from 1), `session_start`, `session_end`, `event_count`, `duration_minutes`.

**Expected output**

| user_id | session_number | session_start | session_end | event_count | duration_minutes |
|---|---|---|---|---|---|
| 1 | 1 | 2026-03-01 09:00:00 | 2026-03-01 09:25:00 | 3 | 25 |
| 1 | 2 | 2026-03-01 10:30:00 | 2026-03-01 10:45:00 | 2 | 15 |
| 2 | 1 | 2026-03-01 08:00:00 | 2026-03-01 08:30:00 | 2 | 30 |
| 2 | 2 | 2026-03-01 09:05:00 | 2026-03-01 09:05:00 | 1 | 0 |
| 3 | 1 | 2026-03-01 12:00:00 | 2026-03-01 12:00:00 | 1 | 0 |

**What they check.** The classic gaps-and-islands pattern: `LAG` to flag session starts, then a running `SUM` of the flags to assign session ids. Note user 2: a gap of *exactly* 30 minutes stays in the same session.

---

## 05. Monthly cohort retention

**Scenario.** A SaaS client wants a retention table: of the users who signed up in a month, how many were active in each following month?

**Tables.** `users(user_id, signup_date)`, `activity(user_id, activity_date)`.

**Task.** For each signup-month cohort and each `months_since_signup` in which there was activity, return `active_users` (distinct), `cohort_size` and `retention_pct` (1 decimal). Only return rows that have activity.

**Expected output**

| cohort_month | months_since_signup | active_users | cohort_size | retention_pct |
|---|---|---|---|---|
| 2026-01-01 | 0 | 4 | 4 | 100.0 |
| 2026-01-01 | 1 | 2 | 4 | 50.0 |
| 2026-01-01 | 2 | 2 | 4 | 50.0 |
| 2026-02-01 | 0 | 3 | 3 | 100.0 |
| 2026-02-01 | 1 | 2 | 3 | 66.7 |

**What they check.** `DATE_TRUNC`, computing month offsets correctly, counting *distinct* users (a user active several times in a month counts once), and dividing by cohort size, not by active users.

---

## 06. Ordered conversion funnel

**Scenario.** An e-commerce client wants funnel conversion: view product, add to cart, begin checkout, purchase.

**Table.** `funnel_events(user_id, event_name, event_ts)`.

**Task.** For each step, count users who completed it **after completing the previous step** (strict order), with `pct_of_previous` and `pct_of_top` (1 decimal). Edge cases in the data: user 6 purchases without cart/checkout, user 7 adds to cart *before* viewing, user 8 purchases twice, user 9 skips checkout.

**Expected output**

| step_order | step_name | users | pct_of_previous | pct_of_top |
|---|---|---|---|---|
| 1 | view_product | 10 | | 100.0 |
| 2 | add_to_cart | 7 | 70.0 | 70.0 |
| 3 | begin_checkout | 5 | 71.4 | 50.0 |
| 4 | purchase | 3 | 60.0 | 30.0 |

**What they check.** Whether you enforce ordering (a naive `COUNT(DISTINCT user_id) ... WHERE event_name = ...` gives 10/8/5/5), handle repeat events, and use `LAG` / `FIRST_VALUE` for the percentages.

---

## 07. SCD Type 2 + point-in-time join

**Scenario.** A loyalty program records tier changes. Analysts need revenue by the tier the customer had **when the order was placed**, not today's tier.

**Tables.** `customer_tier_changes(customer_id, tier, effective_date)`, `tier_orders(order_id, customer_id, order_date, amount)`.

**Task, part 1.** Build the SCD2 dimension: `customer_id, tier, valid_from, valid_to, is_current`. `valid_from` is inclusive, `valid_to` is exclusive and NULL for the open record.

| customer_id | tier | valid_from | valid_to | is_current |
|---|---|---|---|---|
| 1 | bronze | 2025-01-01 | 2025-06-01 | f |
| 1 | silver | 2025-06-01 | 2025-11-15 | f |
| 1 | gold | 2025-11-15 | NULL | t |
| 2 | bronze | 2025-03-01 | 2025-09-10 | f |
| 2 | silver | 2025-09-10 | NULL | t |
| 3 | bronze | 2025-02-01 | NULL | t |

**Task, part 2.** Join `tier_orders` to the dimension and return `tier`, `orders`, `revenue`. Orders placed before a customer's first tier record are labelled `unknown`.

| tier | orders | revenue |
|---|---|---|
| silver | 3 | 350.00 |
| gold | 1 | 300.00 |
| bronze | 3 | 190.00 |
| unknown | 1 | 25.00 |

**What they check.** `LEAD` for validity windows, half-open interval joins (order 5 falls exactly on customer 2's change date and must land in `silver`), and `LEFT JOIN` so unmatched orders are not silently dropped.

---

## 08. Gaps in time-series data

**Scenario.** An IoT client's sensors should report every hour. They want to know where data is missing.

**Table.** `readings(sensor_id, reading_ts, temperature_c)`.

**Task.** List each gap: `sensor_id`, `gap_start` (last reading before the gap), `gap_end` (next reading), and `missing_readings` (number of expected hourly readings absent). Sensors without gaps are not listed.

**Expected output**

| sensor_id | gap_start | gap_end | missing_readings |
|---|---|---|---|
| A | 2026-04-01 01:00:00 | 2026-04-01 04:00:00 | 2 |
| C | 2026-04-01 01:00:00 | 2026-04-01 05:00:00 | 3 |
| C | 2026-04-01 06:00:00 | 2026-04-01 08:00:00 | 1 |

**What they check.** `LEAD`/`LAG` partitioned by sensor, interval arithmetic, and the off-by-one in `missing = hours_between - 1`. Follow-up question to expect: "How would you do this at scale with `generate_series` and an anti-join, or with time_bucket in TimescaleDB?"

---

## 09. Source vs. warehouse reconciliation

**Scenario.** After a pipeline migration, the client asks you to prove the warehouse matches the source system.

**Tables.** `source_orders(order_id, status, amount)`, `target_orders(order_id, status, amount)`.

**Task.** Return every discrepancy with `order_id`, `issue_type` (`missing_in_target`, `extra_in_target` or `value_mismatch`), and the source/target status and amount. Orders 7 has NULL status on both sides (not a discrepancy); order 8 has NULL in the source and a value in the target (a discrepancy).

**Expected output**

| order_id | issue_type | source_status | target_status | source_amount | target_amount |
|---|---|---|---|---|---|
| 2 | value_mismatch | pending | shipped | 50.00 | 50.00 |
| 3 | value_mismatch | shipped | shipped | 75.50 | 75.00 |
| 4 | missing_in_target | cancelled | NULL | 20.00 | NULL |
| 6 | extra_in_target | NULL | shipped | NULL | 10.00 |
| 8 | value_mismatch | NULL | shipped | 15.00 | 15.00 |

**What they check.** `FULL OUTER JOIN`, and NULL-safe comparison with `IS DISTINCT FROM` (using `<>` silently misses order 8).

---

## 10. Recursive CTE hierarchy

**Scenario.** An HR-analytics client stores employees with a `manager_id`. They want the org tree and rollups.

**Table.** `employees(employee_id, name, manager_id, salary)`.

**Task, part 1.** List everyone with `depth` (CEO = 0) and `path` (e.g. `Alice > Bob > Dave`), sorted by path.

| employee_id | name | depth | path |
|---|---|---|---|
| 1 | Alice | 0 | Alice |
| 2 | Bob | 1 | Alice > Bob |
| 4 | Dave | 2 | Alice > Bob > Dave |
| 7 | Grace | 3 | Alice > Bob > Dave > Grace |
| 8 | Heidi | 3 | Alice > Bob > Dave > Heidi |
| 5 | Eve | 2 | Alice > Bob > Eve |
| 3 | Carol | 1 | Alice > Carol |
| 6 | Frank | 2 | Alice > Carol > Frank |
| 9 | Ivan | 3 | Alice > Carol > Frank > Ivan |

**Task, part 2.** For each manager, the total number of direct + indirect reports and their combined salary.

| manager | total_reports | total_report_salary |
|---|---|---|
| Alice | 8 | 1055.00 |
| Bob | 4 | 430.00 |
| Carol | 2 | 215.00 |
| Dave | 2 | 185.00 |
| Frank | 1 | 85.00 |

**What they check.** `WITH RECURSIVE` anchor + recursive member, building paths, and rolling up across levels (not just direct reports). Follow-up: "What happens if the data contains a cycle?"

---

## 11. Find and remove duplicates

**Scenario.** A client's customer table was loaded from several sources and the same person appears more than once. They want to know which records are duplicated, and then a clean-up that keeps one record per customer.

**Table.** `customers(customer_id, email, first_name, last_name, created_at)`. Two emails are the same customer if they match after lower-casing and trimming. Rows with a NULL email are **not** duplicates of each other.

**Task, part 1.** Find the duplicated emails: `email_normalized`, `occurrences`, `customer_ids`.

| email_normalized | occurrences | customer_ids |
|---|---|---|
| bob@x.com | 3 | {4,5,6} |
| john@x.com | 2 | {1,2} |

**Task, part 2.** List the rows that would be deleted if you keep the earliest record per customer (ties on `created_at`: lowest `customer_id`).

| customer_id | email | created_at |
|---|---|---|
| 2 | JOHN@x.com | 2026-01-05 09:00:00 |
| 5 | bob@x.com | 2026-01-03 09:00:00 |
| 6 | bob@x.com | 2026-02-01 09:00:00 |

**Task, part 3.** Write the `DELETE`. After it, 6 of the 9 rows remain.

**What they check.**
- `GROUP BY ... HAVING COUNT(*) > 1` to *find* duplicates, versus `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` with `rn > 1` to pick which rows to *remove*.
- Normalizing before comparing: a plain `GROUP BY email` misses john@x.com (case and trailing space) and wrongly reports the two NULL emails as a duplicate group.
- A deterministic tiebreaker (customers 4 and 5 have identical timestamps).
- Safe practice: preview with a `SELECT`, run the `DELETE` in a transaction and check the row count.
- Follow-up: "What if the table has no primary key and the rows are fully identical?" In PostgreSQL, use `ctid` (see the variant at the end of the solution); elsewhere, create a deduplicated copy with `SELECT DISTINCT` and swap the tables.
-- Answer for exercise 11: Find and remove duplicates
-- EXPLAIN ANALYSE
-- Get the rows that has duplicates, and check the total occurrence of the duplicates.
SELECT LOWER(BTRIM(email)) AS email_normalized, 
  COUNT(*) AS occurrence, 
  ARRAY_AGG(customer_id ORDER BY customer_id) AS customer_ids 
  FROM customers 
  WHERE email IS NOT NULL 
  GROUP BY LOWER(BTRIM(email)) 
  HAVING COUNT(*) > 1;

-- Find the duplicate rows that will be deleted.
SELECT customer_id, email, created_at
FROM (
  SELECT *,
  ROW_NUMBER() OVER (
    PARTITION BY LOWER(BTRIM(email))
    ORDER BY created_at, customer_id
  ) AS occurrence
  FROM customers
  WHERE email IS NOT NULL
)
WHERE occurrence > 1
ORDER BY customer_id;

-- Delete the duplicates
BEGIN;
DELETE FROM customers
WHERE customer_id IN (
  SELECT customer_id FROM (
    SELECT customer_id,
    ROW_NUMBER() OVER (
      PARTITION BY LOWER(BTRIM(email))
      ORDER BY created_at, customer_id
    ) AS occurrence
    FROM customers
    WHERE email IS NOT NULL
  )
  where occurrence > 1
);
SELECT COUNT(*) AS remaining_rows FROM customers; 
ROLLBACK; -- Use `COMMIT;` instead to do the delete operation.
-- COMMIT;
-- Exercise 07: Build an SCD Type 2 dimension and do a point-in-time join
CREATE TABLE customer_tier_changes (
  customer_id    INT  NOT NULL,
  tier           TEXT NOT NULL,
  effective_date DATE NOT NULL,
  PRIMARY KEY (customer_id, effective_date)
);

CREATE TABLE tier_orders (
  order_id    INT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date  DATE NOT NULL,
  amount      NUMERIC(10,2) NOT NULL
);

INSERT INTO customer_tier_changes VALUES
 (1, 'bronze', '2025-01-01'),
 (1, 'silver', '2025-06-01'),
 (1, 'gold',   '2025-11-15'),
 (2, 'bronze', '2025-03-01'),
 (2, 'silver', '2025-09-10'),
 (3, 'bronze', '2025-02-01');

INSERT INTO tier_orders VALUES
 (1, 1, '2025-02-01', 100),
 (2, 1, '2025-07-01', 200),
 (3, 1, '2025-12-01', 300),
 (4, 2, '2025-04-01',  50),
 (5, 2, '2025-09-10',  70),
 (6, 2, '2025-12-31',  80),
 (7, 3, '2025-08-01',  40),
 (8, 3, '2024-12-01',  25);
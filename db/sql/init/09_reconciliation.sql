-- Exercise 09: Source vs. warehouse reconciliation
CREATE TABLE source_orders (
  order_id INT PRIMARY KEY,
  status   TEXT,
  amount   NUMERIC(10,2) NOT NULL
);

CREATE TABLE target_orders (
  order_id INT PRIMARY KEY,
  status   TEXT,
  amount   NUMERIC(10,2) NOT NULL
);

INSERT INTO source_orders VALUES
 (1, 'shipped',   100.00),
 (2, 'pending',    50.00),
 (3, 'shipped',    75.50),
 (4, 'cancelled',  20.00),
 (5, 'shipped',   200.00),
 (7, NULL,         30.00),
 (8, NULL,         15.00);

INSERT INTO target_orders VALUES
 (1, 'shipped',   100.00),
 (2, 'shipped',    50.00),
 (3, 'shipped',    75.00),
 (5, 'shipped',   200.00),
 (6, 'shipped',    10.00),
 (7, NULL,         30.00),
 (8, 'shipped',    15.00);
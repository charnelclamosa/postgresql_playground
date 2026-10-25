-- Exercise 03: Calendar spine, running total, moving average
CREATE TABLE daily_orders (
  order_id   INT PRIMARY KEY,
  order_date DATE NOT NULL,
  amount     NUMERIC(10,2) NOT NULL
);

INSERT INTO daily_orders VALUES
 (1,  '2026-01-01', 100),
 (2,  '2026-01-01',  50),
 (3,  '2026-01-02', 200),
 (4,  '2026-01-04', 120),
 (5,  '2026-01-04',  30),
 (6,  '2026-01-05',  90),
 (7,  '2026-01-06', 300),
 (8,  '2026-01-08',  60),
 (9,  '2026-01-09',  45),
 (10, '2026-01-09',  55),
 (11, '2026-01-10',  80);
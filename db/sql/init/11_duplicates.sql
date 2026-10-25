-- Exercise 11: Find and remove duplicates
CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  email       TEXT,
  first_name  TEXT NOT NULL,
  last_name   TEXT NOT NULL,
  created_at  TIMESTAMP NOT NULL
);

INSERT INTO customers VALUES
 (1, 'john@x.com',   'John',   'Smith', '2026-01-01 09:00:00'),
 (2, 'JOHN@x.com ',  'John',   'Smith', '2026-01-05 09:00:00'),  -- case + trailing space
 (3, 'mary@x.com',   'Mary',   'Jones', '2026-01-02 09:00:00'),
 (4, 'bob@x.com',    'Bob',    'Lee',   '2026-01-03 09:00:00'),
 (5, 'bob@x.com',    'Bob',    'Lee',   '2026-01-03 09:00:00'),  -- same timestamp as 4
 (6, 'bob@x.com',    'Robert', 'Lee',   '2026-02-01 09:00:00'),
 (7, 'alice@x.com',  'Alice',  'Wong',  '2026-01-10 09:00:00'),
 (8, NULL,           'Ghost',  'One',   '2026-01-11 09:00:00'),
 (9, NULL,           'Ghost',  'Two',   '2026-01-12 09:00:00');
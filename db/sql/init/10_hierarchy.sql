-- Exercise 10: Recursive CTE on an org hierarchy
CREATE TABLE employees (
  employee_id INT PRIMARY KEY,
  name        TEXT NOT NULL,
  manager_id  INT REFERENCES employees(employee_id),
  salary      NUMERIC(10,2) NOT NULL
);

INSERT INTO employees VALUES
 (1, 'Alice', NULL, 300),
 (2, 'Bob',   1,    200),
 (3, 'Carol', 1,    210),
 (4, 'Dave',  2,    120),
 (5, 'Eve',   2,    125),
 (6, 'Frank', 3,    130),
 (7, 'Grace', 4,     90),
 (8, 'Heidi', 4,     95),
 (9, 'Ivan',  6,     85);
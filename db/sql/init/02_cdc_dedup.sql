-- Exercise 02: Deduplicate a CDC feed to current state
CREATE TABLE customers_cdc (
  change_id   INT PRIMARY KEY,          -- monotonically increasing per event
  customer_id INT NOT NULL,
  email       TEXT,
  plan        TEXT,
  op          CHAR(1) NOT NULL CHECK (op IN ('I','U','D')),
  changed_at  TIMESTAMP NOT NULL
);

INSERT INTO customers_cdc VALUES
 (1, 1, 'a@x.com',   'free',       'I', '2026-01-01 10:00:00'),
 (2, 1, 'a@x.com',   'pro',        'U', '2026-02-01 09:00:00'),
 (3, 1, 'a@new.com', 'pro',        'U', '2026-03-05 12:00:00'),
 (4, 2, 'b@x.com',   'free',       'I', '2026-01-10 08:00:00'),
 (5, 2, 'b@x.com',   'free',       'D', '2026-02-15 08:00:00'),
 (6, 3, 'c@x.com',   'pro',        'I', '2026-01-20 11:00:00'),
 (7, 3, 'c@x.com',   'enterprise', 'U', '2026-01-20 11:00:00'),
 (8, 4, 'd@x.com',   'free',       'I', '2026-03-01 00:00:00');
-- Exercise 06: Ordered conversion funnel
CREATE TABLE funnel_events (
  user_id    INT NOT NULL,
  event_name TEXT NOT NULL,   -- view_product, add_to_cart, begin_checkout, purchase
  event_ts   TIMESTAMP NOT NULL
);

INSERT INTO funnel_events VALUES
 -- U1: full funnel
 (1,'view_product','2026-04-01 10:00'),
 (1,'add_to_cart','2026-04-01 10:05'),
 (1,'begin_checkout','2026-04-01 10:10'),
 (1,'purchase','2026-04-01 10:15'),
 -- U2: stops at checkout
 (2,'view_product','2026-04-01 11:00'),
 (2,'add_to_cart','2026-04-01 11:02'),
 (2,'begin_checkout','2026-04-01 11:05'),
 -- U3: stops at cart
 (3,'view_product','2026-04-01 12:00'),
 (3,'add_to_cart','2026-04-01 12:03'),
 -- U4: only views
 (4,'view_product','2026-04-01 13:00'),
 -- U5: full funnel
 (5,'view_product','2026-04-02 09:00'),
 (5,'add_to_cart','2026-04-02 09:01'),
 (5,'begin_checkout','2026-04-02 09:02'),
 (5,'purchase','2026-04-02 09:03'),
 -- U6: view then purchase, skipped middle steps
 (6,'view_product','2026-04-02 10:00'),(6,'purchase','2026-04-02 10:30'),
 -- U7: cart BEFORE first view (out of order)
 (7,'add_to_cart','2026-04-02 11:00'),(7,'view_product','2026-04-02 11:05'),
 -- U8: full funnel, purchased twice
 (8,'view_product','2026-04-03 08:00'),
 (8,'add_to_cart','2026-04-03 08:05'),
 (8,'begin_checkout','2026-04-03 08:10'),
 (8,'purchase','2026-04-03 08:15'),
 (8,'purchase','2026-04-03 09:00'),
 -- U9: skipped checkout
 (9,'view_product','2026-04-03 10:00'),
 (9,'add_to_cart','2026-04-03 10:05'),
 (9,'purchase','2026-04-03 10:10'),
 -- U10: stops at checkout
 (10,'view_product','2026-04-03 11:00'),
 (10,'add_to_cart','2026-04-03 11:05'),
 (10,'begin_checkout','2026-04-03 11:10');
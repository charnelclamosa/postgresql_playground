-- Exercise 04: Sessionization (gaps and islands)
CREATE TABLE session_events (
  event_id   INT PRIMARY KEY,
  user_id    INT NOT NULL,
  event_ts   TIMESTAMP NOT NULL,
  event_name TEXT NOT NULL
);

INSERT INTO session_events VALUES
 (1,  1, '2026-03-01 09:00:00', 'page_view'),
 (2,  1, '2026-03-01 09:10:00', 'click'),
 (3,  1, '2026-03-01 09:25:00', 'page_view'),
 (4,  1, '2026-03-01 10:30:00', 'page_view'),
 (5,  1, '2026-03-01 10:45:00', 'click'),
 (6,  2, '2026-03-01 08:00:00', 'page_view'),
 (7,  2, '2026-03-01 08:30:00', 'click'),
 (8,  2, '2026-03-01 09:05:00', 'page_view'),
 (9,  3, '2026-03-01 12:00:00', 'page_view');
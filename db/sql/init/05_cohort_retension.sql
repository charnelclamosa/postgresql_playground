-- Exercise 05: Monthly cohort retention
CREATE TABLE users (
  user_id     INT PRIMARY KEY,
  signup_date DATE NOT NULL
);

CREATE TABLE activity (
  user_id       INT NOT NULL REFERENCES users(user_id),
  activity_date DATE NOT NULL
);

INSERT INTO users VALUES
 (1, '2026-01-05'), (2, '2026-01-12'), (3, '2026-01-20'), (4, '2026-01-28'),
 (5, '2026-02-03'), (6, '2026-02-14'), (7, '2026-02-25');

INSERT INTO activity VALUES
 (1, '2026-01-06'), (1, '2026-02-10'), (1, '2026-03-03'),
 (2, '2026-01-12'), (2, '2026-02-20'),
 (3, '2026-01-21'),
 (4, '2026-01-29'), (4, '2026-03-15'),
 (5, '2026-02-04'), (5, '2026-03-08'),
 (6, '2026-02-14'), (6, '2026-03-01'),
 (7, '2026-02-26');
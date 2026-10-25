-- Exercise 08: Detect gaps in time-series sensor readings
CREATE TABLE readings (
  sensor_id     TEXT      NOT NULL,
  reading_ts    TIMESTAMP NOT NULL,
  temperature_c NUMERIC(5,2),
  PRIMARY KEY (sensor_id, reading_ts)
);

-- Readings are expected every hour.
INSERT INTO readings VALUES
 -- Sensor A: missing 02:00 and 03:00
 ('A','2026-04-01 00:00',18.1),('A','2026-04-01 01:00',17.9),
 ('A','2026-04-01 04:00',17.2),('A','2026-04-01 05:00',17.0),
 -- Sensor B: complete
 ('B','2026-04-01 00:00',20.0),('B','2026-04-01 01:00',19.8),('B','2026-04-01 02:00',19.5),
 ('B','2026-04-01 03:00',19.1),('B','2026-04-01 04:00',18.9),
 -- Sensor C: missing 02:00-04:00 and 07:00
 ('C','2026-04-01 00:00',15.0),('C','2026-04-01 01:00',14.8),
 ('C','2026-04-01 05:00',14.1),('C','2026-04-01 06:00',14.0),
 ('C','2026-04-01 08:00',14.6);
-- ============================================================
-- IBM 6500 | IC/CP-W04 | Lecture 1: BigQuery SQL Basics
-- Author: Sim Saini
-- Data: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- ============================================================


-- ------------------------------------------------------------
-- 1) SELECT / FROM / LIMIT
-- Pick two columns and return the first 20 rows
-- ------------------------------------------------------------
SELECT event_date, event_name
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
LIMIT 20;


-- ------------------------------------------------------------
-- 2) WHERE filters rows
-- Keep only purchase events
-- ------------------------------------------------------------
SELECT event_date, event_name, user_pseudo_id
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = 'purchase'
LIMIT 50;


-- ------------------------------------------------------------
-- 3) ORDER BY sorts results
-- Most recent purchases first
-- ------------------------------------------------------------
SELECT event_date, event_timestamp, event_name
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = 'purchase'
ORDER BY event_timestamp DESC
LIMIT 20;

-- 3b) Readable timestamps (GA4 stores microseconds)
SELECT TIMESTAMP_MICROS(event_timestamp) AS event_time,
       event_name
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
ORDER BY event_timestamp DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 4) COUNT, SUM, AVG, MIN, MAX
-- ------------------------------------------------------------

-- 4a) Count total events in December 2020
SELECT COUNT(*) AS event_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231';

-- 4b) Count purchase events in December 2020
SELECT COUNT(*) AS purchase_events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = 'purchase'
  AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201231';


-- ------------------------------------------------------------
-- 5) GROUP BY controls the grain
-- ------------------------------------------------------------

-- 5a) Events by day (one row = one day)
SELECT event_date, COUNT(*) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
GROUP BY event_date
ORDER BY event_date;

-- 5b) Top event types (one row = one event name)
SELECT event_name, COUNT(*) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
GROUP BY event_name
ORDER BY events DESC
LIMIT 15;


-- ------------------------------------------------------------
-- 6) HAVING filters after grouping
-- Only event types with at least 50,000 events
-- ------------------------------------------------------------
SELECT event_name, COUNT(*) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
GROUP BY event_name
HAVING COUNT(*) >= 50000
ORDER BY events DESC;


-- ------------------------------------------------------------
-- 7) Wildcard tables + _TABLE_SUFFIX
-- Scan only the first week of December 2020
-- ------------------------------------------------------------
SELECT event_date, COUNT(*) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
GROUP BY event_date
ORDER BY event_date;

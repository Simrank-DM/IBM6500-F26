-- ============================================================
-- IBM 6500 | Milestone 4: SQL Pack (Individual)
-- Author: Simran Kaur
-- Data: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Window: Holiday season 2020 (Black Friday through December)
-- ============================================================


-- ------------------------------------------------------------
-- Q1 | Filtering & scoping
-- Highest-value orders over Black Friday to Cyber Monday 2020
-- ------------------------------------------------------------
SELECT
  PARSE_DATE('%Y%m%d', event_date) AS order_date,
  ecommerce.transaction_id,
  device.category AS device_category,
  geo.country,
  ecommerce.total_item_quantity AS items_in_order,
  ecommerce.purchase_revenue_in_usd AS revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201127' AND '20201130'  -- BF to Cyber Monday only
  AND event_name = 'purchase'
  AND ecommerce.purchase_revenue_in_usd >= 100          -- high-value orders
ORDER BY revenue_usd DESC
LIMIT 25;


-- ------------------------------------------------------------
-- Q2 | Filtering + grouping & aggregation
-- December performance by device: events, users, purchases, revenue
-- ------------------------------------------------------------
SELECT
  device.category AS device_category,
  COUNT(*) AS events,                                   -- events, not users
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNTIF(event_name = 'purchase') AS purchase_events,
  ROUND(SUM(ecommerce.purchase_revenue_in_usd), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(SUM(ecommerce.purchase_revenue_in_usd),
                    COUNT(DISTINCT user_pseudo_id)), 2) AS revenue_per_user
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
GROUP BY device_category
ORDER BY users DESC;


-- ------------------------------------------------------------
-- Q3 | Grouping & aggregation (item level)
-- December revenue by product category
-- ------------------------------------------------------------
SELECT
  item.item_category,
  COUNT(DISTINCT ecommerce.transaction_id) AS orders,
  SUM(item.quantity) AS units_sold,
  ROUND(SUM(item.item_revenue_in_usd), 2) AS item_revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(items) AS item                                    -- grain: one row per item per order
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  AND event_name = 'purchase'
GROUP BY item.item_category
ORDER BY item_revenue_usd DESC
LIMIT 15;


-- ------------------------------------------------------------
-- Q4 | UNNEST event_params (string_value)
-- Top pages in the first week of December
-- ------------------------------------------------------------
SELECT
  REGEXP_REPLACE(
    (SELECT value.string_value
     FROM UNNEST(event_params)
     WHERE key = 'page_location'),
    r'\?.*$', '') AS page_url,                          -- drop query strings
  COUNT(*) AS page_views,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
  AND event_name = 'page_view'
GROUP BY page_url
ORDER BY page_views DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q5 | UNNEST event_params (int_value) + CTE
-- Daily sessions and average engaged time per session
-- ------------------------------------------------------------
WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS dt,
    CONCAT(user_pseudo_id, '-', CAST(
      (SELECT value.int_value FROM UNNEST(event_params)
       WHERE key = 'ga_session_id') AS STRING)) AS session_key,
    (SELECT value.int_value FROM UNNEST(event_params)
     WHERE key = 'engagement_time_msec') AS engagement_msec
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201214'
)
SELECT
  dt,
  FORMAT_DATE('%a', dt) AS weekday,
  COUNT(DISTINCT session_key) AS sessions,
  ROUND(SAFE_DIVIDE(SUM(engagement_msec) / 1000,
                    COUNT(DISTINCT session_key)), 1) AS avg_engaged_sec_per_session
FROM base
GROUP BY dt
ORDER BY dt;


-- ------------------------------------------------------------
-- Q6 | CTE structure + UNNEST (string + int)
-- Sessions and session conversion rate by source / medium
-- ------------------------------------------------------------
WITH events AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    event_name,
    (SELECT value.int_value FROM UNNEST(event_params)
     WHERE key = 'ga_session_id') AS session_id,
    (SELECT value.string_value FROM UNNEST(event_params)
     WHERE key = 'source') AS source,
    (SELECT value.string_value FROM UNNEST(event_params)
     WHERE key = 'medium') AS medium
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
),
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    -- first source/medium pair seen in the session
    ARRAY_AGG(IF(source IS NULL, NULL, STRUCT(source, medium))
              IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS traffic,
    COUNTIF(event_name = 'purchase') > 0 AS converted
  FROM events
  WHERE session_id IS NOT NULL
  GROUP BY user_pseudo_id, session_id
)
SELECT
  IFNULL(traffic.source, '(not set)') AS source,
  IFNULL(traffic.medium, '(not set)') AS medium,
  COUNT(*) AS sessions,
  COUNTIF(converted) AS converting_sessions,
  ROUND(COUNTIF(converted) / COUNT(*) * 100, 2) AS session_conv_rate_pct
FROM sessions
GROUP BY 1, 2
HAVING COUNT(*) >= 500
ORDER BY sessions DESC;


-- ------------------------------------------------------------
-- Q7 | Combining with multiple CTEs: purchase funnel
-- Users reaching each ecommerce step in December
-- ------------------------------------------------------------
WITH user_steps AS (
  SELECT
    user_pseudo_id,
    MAX(IF(event_name = 'view_item', 1, 0))      AS viewed_item,
    MAX(IF(event_name = 'add_to_cart', 1, 0))    AS added_to_cart,
    MAX(IF(event_name = 'begin_checkout', 1, 0)) AS began_checkout,
    MAX(IF(event_name = 'purchase', 1, 0))       AS purchased
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
  GROUP BY user_pseudo_id
),
funnel AS (
  SELECT 1 AS step_order, 'view_item' AS step, SUM(viewed_item) AS users FROM user_steps
  UNION ALL SELECT 2, 'add_to_cart',    SUM(added_to_cart)  FROM user_steps
  UNION ALL SELECT 3, 'begin_checkout', SUM(began_checkout) FROM user_steps
  UNION ALL SELECT 4, 'purchase',       SUM(purchased)      FROM user_steps
)
SELECT
  step_order,
  step,
  users,
  ROUND(users / FIRST_VALUE(users) OVER (ORDER BY step_order) * 100, 1) AS pct_of_viewers,
  ROUND(users / LAG(users) OVER (ORDER BY step_order) * 100, 1) AS pct_of_previous_step
FROM funnel
ORDER BY step_order;


-- ------------------------------------------------------------
-- Q8 | Join: landing page -> session purchases
-- Which landing pages lead to sessions that buy?
-- ------------------------------------------------------------
WITH landings AS (
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(
      (SELECT value.int_value FROM UNNEST(event_params)
       WHERE key = 'ga_session_id') AS STRING)) AS session_key,
    ANY_VALUE(REGEXP_REPLACE(
      (SELECT value.string_value FROM UNNEST(event_params)
       WHERE key = 'page_location'),
      r'\?.*$', '')) AS landing_page
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'session_start'
  GROUP BY session_key                                   -- one row per session
),
session_revenue AS (
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(
      (SELECT value.int_value FROM UNNEST(event_params)
       WHERE key = 'ga_session_id') AS STRING)) AS session_key,
    SUM(ecommerce.purchase_revenue_in_usd) AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'purchase'
  GROUP BY session_key
)
SELECT
  l.landing_page,
  COUNT(*) AS sessions,
  COUNT(r.session_key) AS converting_sessions,
  ROUND(COUNT(r.session_key) / COUNT(*) * 100, 2) AS conv_rate_pct,
  ROUND(IFNULL(SUM(r.revenue_usd), 0), 2) AS revenue_usd
FROM landings l
LEFT JOIN session_revenue r
  ON l.session_key = r.session_key
WHERE l.session_key IS NOT NULL
GROUP BY l.landing_page
HAVING COUNT(*) >= 300
ORDER BY sessions DESC
LIMIT 15;

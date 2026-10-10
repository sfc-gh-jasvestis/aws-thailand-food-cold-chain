-- Synthetic site-day observations for a fictional Thailand food cold chain network.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild is
-- reproducible: per-site pallet capacity, refrigeration plant age and disruption propensity,
-- volume from weekly seasonality and a festival-season ordering peak, wear between
-- preventive-maintenance (PM) visits, category-weighted disruption causes, and two
-- regional events.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.SITES AS
WITH sites AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS SITE_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 30))
), draws AS (
  SELECT SITE_INDEX,
         MOD(ABS(HASH(SITE_INDEX, 'thfcc-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(SITE_INDEX, 'thfcc-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(SITE_INDEX, 'thfcc-pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(SITE_INDEX, 'thfcc-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(SITE_INDEX, 'thfcc-capacity')), 1000000) / 1e6 AS U_CAPACITY
  FROM sites
)
SELECT 'CC-' || LPAD(SITE_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic cold chain site ' || LPAD(SITE_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (7 and 5 are coprime): every market and site type is
       -- present, with Bangkok the largest hub city.
       CASE MOD(SITE_INDEX, 7) WHEN 0 THEN 'Bangkok' WHEN 1 THEN 'Bangkok' WHEN 2 THEN 'Samut Sakhon'
            WHEN 3 THEN 'Chon Buri' WHEN 4 THEN 'Chiang Mai' WHEN 5 THEN 'Khon Kaen'
            ELSE 'Hat Yai' END AS REGION,
       CASE MOD(SITE_INDEX, 5) WHEN 0 THEN 'Frozen Warehouse' WHEN 1 THEN 'Chilled Distribution Center'
            WHEN 2 THEN 'Seafood Processing Dock' WHEN 3 THEN 'Cross-Dock' ELSE 'Reefer Truck Depot' END AS CATEGORY,
       SITE_INDEX,
       ROUND(1 + U_AGE * 17, 1) AS AGE_YEARS,
       -- Base daily disruption probability 0.5%-3.5%; ~15% of sites are chronic (x3).
       (0.006 + U_RATE * 0.028) * IFF(U_RATE > 0.86, 3, 1) AS BASE_DISRUPTION_RATE,
       7 * (1 + FLOOR(U_PM * 3)) AS PM_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS PM_COMPLETION_PROB,
       ROUND(CASE MOD(SITE_INDEX, 5) WHEN 0 THEN 360 WHEN 1 THEN 610 WHEN 2 THEN 480
                  WHEN 3 THEN 520 ELSE 300 END * (0.8 + U_CAPACITY * 0.4)) AS DAILY_CAPACITY,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.SITE_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), regional_events AS (
  -- Two market-wide events in the window.
  SELECT * FROM VALUES (27, 'Hat Yai', 'Monsoon flood road closure', 9.0),
                       (61, 'Chiang Mai', 'Grid power outage', 6.0)
    AS o(DAY_INDEX, REGION, EVENT_CAUSE, HOURS)
), base AS (
  SELECT h.ID AS ENTITY_ID, h.SITE_INDEX, h.CATEGORY, h.REGION, h.AGE_YEARS,
         h.BASE_DISRUPTION_RATE, h.PM_INTERVAL_DAYS, h.PM_COMPLETION_PROB, h.DAILY_CAPACITY,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         24.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + h.SITE_INDEX * 3, h.PM_INTERVAL_DAYS) AS DAYS_SINCE_PM,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'thfcc-dis')), 1000000) / 1e6 AS U_DIS,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'thfcc-down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'thfcc-cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'thfcc-pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'thfcc-volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'thfcc-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'thfcc-hit')), 1000000) / 1e6 AS U_HIT,
         e.EVENT_CAUSE, e.HOURS AS EVENT_HOURS
  FROM RAW.SITES h CROSS JOIN days d
  LEFT JOIN regional_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = h.REGION
), loaded AS (
  SELECT *,
         IFF(DAYS_SINCE_PM = 0, 1, 0) AS PM_DUE,
         IFF(DAYS_SINCE_PM = 0 AND U_PMDONE < PM_COMPLETION_PROB, 1, 0) AS PM_COMPLETED,
         -- Refrigeration plant wear rises between PM visits; weak PM discipline carries wear over.
         DAYS_SINCE_PM / PM_INTERVAL_DAYS + (1 - PM_COMPLETION_PROB) AS WEAR,
         -- Backlog stress episode: 8 of every 25 days per site (staggered), e.g. a promotion-driven order surge.
         IFF(MOD(DAY_INDEX + SITE_INDEX * 7, 25) < 8, 1, 0) AS STRESS,
         -- Volume: weekly low day and a festival-season ordering peak on day 47 (+48%) easing over 3 days.
         ROUND(DAILY_CAPACITY * (0.66 + 0.29 * U_VOLUME)
               * IFF(MOD(DAY_INDEX, 7) = 6, 0.70, 1.0)
               * CASE DAY_INDEX - 47 WHEN 0 THEN 1.48 WHEN 1 THEN 1.30 WHEN 2 THEN 1.12 ELSE 1.0 END) AS PALLETS
  FROM base
), disruptions AS (
  SELECT *, PALLETS / DAILY_CAPACITY AS LOAD_RATIO,
         LEAST(0.5, BASE_DISRUPTION_RATE * (0.4 + 1.6 * WEAR) * (0.3 + PALLETS / DAILY_CAPACITY)
                    * (1 + AGE_YEARS / 25) * (1 + 2.5 * STRESS)) AS P_DIS
  FROM loaded
), counted AS (
  SELECT *,
         CASE WHEN EVENT_HOURS IS NOT NULL THEN 1
              WHEN U_DIS < P_DIS / 4 THEN 2
              WHEN U_DIS < P_DIS THEN 1
              ELSE 0 END AS DISRUPTION_COUNT
  FROM disruptions
), timed AS (
  SELECT *,
         -- Refrigeration or dispatch downtime: exponential, mean depends on site type.
         CASE WHEN DISRUPTION_COUNT = 0 THEN 0.0
              WHEN EVENT_HOURS IS NOT NULL THEN EVENT_HOURS
              ELSE LEAST(20.0, ROUND(DISRUPTION_COUNT * (0.5 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Frozen Warehouse' THEN 3.2 WHEN 'Chilled Distribution Center' THEN 2.1
                                 WHEN 'Seafood Processing Dock' THEN 2.7 WHEN 'Cross-Dock' THEN 1.6 ELSE 2.4 END), 1))
         END AS DOWNTIME_HOURS,
         -- In-range rate (pallets kept within their temperature band and delivered in the
         -- committed window): base by site type, minus wear and overload, minus the disruption hit.
         LEAST(0.995, GREATEST(0.50,
           CASE CATEGORY WHEN 'Frozen Warehouse' THEN 0.962 WHEN 'Chilled Distribution Center' THEN 0.948
                         WHEN 'Seafood Processing Dock' THEN 0.921 WHEN 'Cross-Dock' THEN 0.957 ELSE 0.934 END
             - 0.034 * WEAR - 0.06 * GREATEST(0, LOAD_RATIO - 0.9) - 0.009 * U_NOISE
             - DISRUPTION_COUNT * (0.08 + 0.12 * U_HIT))) AS IN_RANGE_RATE
  FROM counted
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS,
       PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
       DISRUPTION_COUNT,
       CASE WHEN DISRUPTION_COUNT = 0 THEN 'None'
            WHEN EVENT_CAUSE IS NOT NULL THEN EVENT_CAUSE
            WHEN CATEGORY = 'Frozen Warehouse' THEN IFF(U_CAUSE < 0.45, 'Compressor failure', IFF(U_CAUSE < 0.75, 'Defrost cycle fault', 'Freezer door left open'))
            WHEN CATEGORY = 'Chilled Distribution Center' THEN IFF(U_CAUSE < 0.5, 'Evaporator fan fault', IFF(U_CAUSE < 0.8, 'Labour shortfall', 'WMS sync failure'))
            WHEN CATEGORY = 'Seafood Processing Dock' THEN IFF(U_CAUSE < 0.55, 'Ice supply shortfall', 'Blast freezer outage')
            WHEN CATEGORY = 'Cross-Dock' THEN IFF(U_CAUSE < 0.6, 'Reefer truck no-show', 'Dock door fault')
            ELSE IFF(U_CAUSE < 0.55, 'Reefer unit breakdown', 'Temperature logger gap') END AS ROOT_CAUSE,
       PM_DUE, PM_COMPLETED,
       PALLETS,
       FLOOR(PALLETS * IN_RANGE_RATE) AS IN_RANGE_PALLETS,
       ROUND(PALLETS * (3.0 + U_VOLUME * 1.5)) AS TEMP_CHECKS,
       ROUND(PALLETS * (3.0 + U_VOLUME * 1.5) * (0.006 + 0.011 * WEAR + 0.025 * DISRUPTION_COUNT + 0.004 * U_NOISE)) AS EXCURSION_CHECKS,
       ROUND(4.6 + 3.3 * WEAR + 4.2 * GREATEST(0, LOAD_RATIO - 0.8) + 2.0 * STRESS + 4.8 * DISRUPTION_COUNT + U_NOISE * 1.2, 2) AS DWELL_HOURS,
       ROUND(LEAST(100, 100 * LOAD_RATIO * (0.82 + 0.12 * U_NOISE) + 7 * STRESS + 5 * DISRUPTION_COUNT), 1) AS COMPRESSOR_LOAD_PCT,
       ROUND(87.0 + 11.0 * IN_RANGE_RATE + 1.4 * U_NOISE, 1) AS ORDER_FILL_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM timed;

-- Refrigeration equipment readiness per site (snapshot): units required versus on hand.
CREATE TABLE RAW.EQUIPMENT_READINESS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Frozen Warehouse' THEN 'Compressor rack' WHEN 'Chilled Distribution Center' THEN 'Evaporator unit'
                     WHEN 'Seafood Processing Dock' THEN 'Blast freezer' WHEN 'Cross-Dock' THEN 'Dock door seal'
                     ELSE 'Reefer unit' END AS EQUIPMENT_TYPE,
       6 + MOD(ABS(HASH(ID, 'thfcc-req')), 23) AS REQUIRED_QTY,
       FLOOR((6 + MOD(ABS(HASH(ID, 'thfcc-req')), 23)) * (0.70 + MOD(ABS(HASH(ID, 'thfcc-avail')), 1000) / 1000 * 0.35)) AS ON_HAND_QTY,
       MOD(ABS(HASH(ID, 'thfcc-order')), 4) AS ON_ORDER_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.SITES;

-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TELEMETRY.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic cold chain operations knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.SITE_SOP_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, h.CATEGORY
  FROM RAW.SITE_DAILY r JOIN RAW.SITES h ON h.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.DISRUPTION_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' cold chain response' AS TITLE,
  'Synthetic demo SOP. Site type: ' || CATEGORY || '. Disruption cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: notify the site shift lead, tag affected pallets with their lot and order IDs, record the last logged product temperature and warn the receiving site. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%compressor%' OR ROOT_CAUSE ILIKE '%evaporator%' OR ROOT_CAUSE ILIKE '%defrost%' OR ROOT_CAUSE ILIKE '%blast freezer%' OR ROOT_CAUSE ILIKE '%reefer unit%' THEN 'switch to the standby refrigeration unit from the readiness pool, move at-risk pallets to a holding chamber in the same temperature band and log the failed unit for inspection.'
       WHEN ROOT_CAUSE ILIKE '%door%' THEN 'close and check the door seal, run a pull-down cycle and spot-check product temperature on pallets nearest the door before release.'
       WHEN ROOT_CAUSE ILIKE '%flood%' OR ROOT_CAUSE ILIKE '%power%' THEN 'start backup generation where fitted, keep chamber doors closed, reroute outbound reefer trucks through the next open site and send revised arrival times to customers.'
       WHEN ROOT_CAUSE ILIKE '%ice%' THEN 'call the backup ice supplier, prioritise chilled seafood lots by catch time and hold lower-priority intake until ice stock recovers.'
       WHEN ROOT_CAUSE ILIKE '%truck%' OR ROOT_CAUSE ILIKE '%labour%' THEN 'call the backup reefer carrier or labour pool, keep staged pallets inside the cold zone and notify customers of the revised delivery window.'
       WHEN ROOT_CAUSE ILIKE '%wms%' OR ROOT_CAUSE ILIKE '%logger%' THEN 'switch to manual temperature logging at the agreed interval, scan confirmations once the system resyncs and quarantine any pallet with a gap in its record until reviewed.'
       ELSE 'record the issue, contain affected pallets in the cold zone and escalate to the regional cold chain lead.'
     END
  || ' Step 3: if dock dwell exceeds 12 hours or compressor load exceeds 92% after recovery, keep the site on the watch list and route new orders elsewhere. '
  || 'Step 4: confirm recovery of the in-range rate and record the root cause and lot IDs in the excursion log.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.SITE_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.SITE_SOP_DOCS);

-- ---------- Pallet dock-dwell anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.DWELL_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, DWELL_HOURS::FLOAT AS DWELL
FROM RAW.SITE_DAILY;
CREATE OR REPLACE VIEW ML.DWELL_TRAIN AS
SELECT * FROM ML.DWELL_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.DWELL_SERIES);
CREATE OR REPLACE VIEW ML.DWELL_DETECT AS
SELECT * FROM ML.DWELL_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.DWELL_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.DWELL_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.DWELL_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'DWELL',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.DWELL_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS DWELL, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.DWELL_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.DWELL_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'DWELL'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.COLD_CHAIN_ANALYTICS
  TABLES (
    sites AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'sites', 'facilities', 'nodes', 'warehouses')
      COMMENT = 'One row per cold chain site (entity), 90-day totals',
    risk AS ML.DISRUPTION_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day cold chain disruption probability per site',
    causes AS CURATED.DISRUPTION_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Cold chain disruptions by root cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Network-wide totals per day'
  )
  RELATIONSHIPS (risk_site AS risk (ENTITY_ID) REFERENCES sites)
  FACTS (
    sites.in_range_f AS IN_RANGE_PALLETS,
    sites.pallets_f AS PALLETS,
    sites.checks_f AS TEMP_CHECKS,
    sites.excursions_f AS EXCURSION_CHECKS,
    sites.disruptions_f AS DISRUPTION_COUNT,
    sites.downtime_hours_f AS DOWNTIME_HOURS,
    sites.operating_hours_f AS OPERATING_HOURS,
    sites.planned_hours_f AS PLANNED_HOURS,
    risk.disruption_prob_f AS DISRUPTION_PROB_7D,
    causes.cause_disruptions_f AS DISRUPTION_COUNT,
    causes.cause_out_of_range_f AS OUT_OF_RANGE_PALLETS,
    causes.cause_hours_f AS DOWNTIME_HOURS,
    daily.day_in_range_f AS IN_RANGE_PALLETS,
    daily.day_pallets_f AS PALLETS,
    daily.day_disruptions_f AS DISRUPTION_COUNT
  )
  DIMENSIONS (
    sites.site_id AS ENTITY_ID WITH SYNONYMS = ('site', 'entity', 'entity id', 'site code'),
    sites.site_name AS ENTITY_NAME,
    sites.region AS REGION WITH SYNONYMS = ('region', 'city', 'province', 'hub city') COMMENT = 'Thailand hub city',
    sites.site_type AS CATEGORY WITH SYNONYMS = ('site type', 'facility type', 'category'),
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    sites.site_count AS COUNT(sites.site_id) WITH SYNONYMS = ('number of entities', 'entity count', 'number of sites'),
    sites.in_range_pallet_pct AS 100 * SUM(sites.in_range_f) / NULLIF(SUM(sites.pallets_f), 0)
      WITH SYNONYMS = ('in-range rate', 'temperature compliance') COMMENT = 'Temperature-compliant pallets / pallets handled',
    sites.total_disruptions AS SUM(sites.disruptions_f) WITH SYNONYMS = ('disruptions', 'cold chain disruptions'),
    sites.excursion_checks_per_1k AS 1000 * SUM(sites.excursions_f) / NULLIF(SUM(sites.checks_f), 0),
    sites.total_pallets AS SUM(sites.pallets_f) WITH SYNONYMS = ('pallet volume', 'pallets handled'),
    sites.total_temp_checks AS SUM(sites.checks_f),
    sites.refrigeration_uptime_pct AS 100 * SUM(sites.operating_hours_f) / NULLIF(SUM(sites.planned_hours_f), 0),
    sites.total_downtime_hours AS SUM(sites.downtime_hours_f),
    risk.avg_disruption_prob AS AVG(risk.disruption_prob_f),
    causes.cause_disruptions AS SUM(causes.cause_disruptions_f),
    causes.cause_out_of_range_pallets AS SUM(causes.cause_out_of_range_f),
    causes.cause_downtime_hours AS SUM(causes.cause_hours_f),
    daily.daily_in_range_pct AS 100 * SUM(daily.day_in_range_f) / NULLIF(SUM(daily.day_pallets_f), 0),
    daily.daily_pallets AS SUM(daily.day_pallets_f),
    daily.daily_disruptions AS SUM(daily.day_disruptions_f)
  )
  COMMENT = 'Synthetic Thailand food cold chain analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.COLD_CHAIN_AGENT
  COMMENT = 'Cold chain assistant over a synthetic Thailand food cold chain network'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give site IDs and numbers with units."
  orchestration: "Use cold_chain_analyst for temperature-compliant pallets, disruptions, temperature excursions, pallet volume, sites, regions, risk and root causes. Use sop_search for disruption response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: cold_chain_analyst
      description: "Temperature-compliant pallets, cold chain disruptions, excursions per 1,000 temperature checks, pallet volume, refrigeration uptime, root causes and disruption-risk scores per site"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic disruption-response SOPs by site type and cause"
tool_resources:
  cold_chain_analyst:
    semantic_view: __DEMO_DB__.APP.COLD_CHAIN_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.SITE_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), SITE_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, DWELL_HOURS FLOAT, COMPRESSOR_LOAD_PCT FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION TH_FOOD_COLD_CHAIN_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (SITE_ID, EVENT_TS, DWELL_HOURS, COMPRESSOR_LOAD_PCT, SOP_HINT)
    SELECT t.SITE_ID, t.EVENT_TS, t.DWELL_HOURS, t.COMPRESSOR_LOAD_PCT,
           'Check ' || h.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.SITES h ON h.ID = t.SITE_ID
    LEFT JOIN ML.DISRUPTION_RISK_SCORES r ON r.ENTITY_ID = t.SITE_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.SITE_ID = t.SITE_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('TH_FOOD_COLD_CHAIN_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Thailand cold chain site telemetry alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.SITE_ID = t.SITE_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.DISRUPTION_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.DISRUPTION_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.DISRUPTION_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.DISRUPTION_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'DWELL_HOURS', DWELL_HOURS,
             'COMPRESSOR_LOAD_PCT', COMPRESSOR_LOAD_PCT, 'DWELL_7D', DWELL_7D, 'DISRUPTIONS_30D', DISRUPTIONS_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:DISRUPTION::FLOAT, 4) AS DISRUPTION_PROB_7D,
         CASE WHEN PRED:probability:DISRUPTION::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:DISRUPTION::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;

-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Cold Chain Monitoring
-- ============================================================================
USE DATABASE COLD_CHAIN;
USE SCHEMA CURATED;

-- FLEET_COMPLIANCE_STATUS: Real-time compliance status of all 800 vehicles and 35 facilities
-- Source: VEHICLES, COLD_STORAGE, TEMPERATURE_READINGS
CREATE OR REPLACE DYNAMIC TABLE CURATED.FLEET_COMPLIANCE_STATUS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = COLDCHAIN_WH
AS
SELECT * FROM RAW.VEHICLES;
-- TODO: Replace with actual join/aggregation logic per demo

-- EXCURSION_TIMESERIES: Temperature deviation timeseries for ML.ANOMALY_DETECTION
-- Source: TEMPERATURE_READINGS
CREATE OR REPLACE DYNAMIC TABLE CURATED.EXCURSION_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = COLDCHAIN_WH
AS
SELECT * FROM RAW.TEMPERATURE_READINGS;
-- TODO: Replace with actual join/aggregation logic per demo

-- ROUTE_RISK_SCORES: Route-level cold chain failure risk scoring
-- Source: SHIPMENTS, EXCURSION_EVENTS, VEHICLES
CREATE OR REPLACE DYNAMIC TABLE CURATED.ROUTE_RISK_SCORES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = COLDCHAIN_WH
AS
SELECT * FROM RAW.SHIPMENTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- PRODUCT_LOSS_SUMMARY: Product loss attribution by vehicle, route, and root cause
-- Source: PRODUCT_LOSS, EXCURSION_EVENTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.PRODUCT_LOSS_SUMMARY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = COLDCHAIN_WH
AS
SELECT * FROM RAW.PRODUCT_LOSS;
-- TODO: Replace with actual join/aggregation logic per demo


-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Cold Chain Monitoring
-- ============================================================================
USE DATABASE COLD_CHAIN;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_INGEST_TELEMETRY
  WAREHOUSE = COLDCHAIN_WH
  SCHEDULE = 'USING CRON */5 * * * * UTC'
  COMMENT = 'Ingest and process latest temperature readings'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_DETECT_ANOMALIES
  WAREHOUSE = COLDCHAIN_WH
  AFTER APP.TASK_INGEST_TELEMETRY
  COMMENT = 'Run ML.ANOMALY_DETECTION on temperature patterns'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_SEND_ALERTS
  WAREHOUSE = COLDCHAIN_WH
  AFTER APP.TASK_DETECT_ANOMALIES
  COMMENT = 'Send alerts for detected excursions and predicted failures'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_SEND_ALERTS RESUME;
ALTER TASK APP.TASK_DETECT_ANOMALIES RESUME;
ALTER TASK APP.TASK_INGEST_TELEMETRY RESUME;

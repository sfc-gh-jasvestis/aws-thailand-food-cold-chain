-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Cold Chain Monitoring
-- ============================================================================
USE DATABASE COLD_CHAIN;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_thailand_food_cold_chain_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: TEMP_EXCURSION_ALERT
CREATE OR REPLACE ALERT APP.TEMP_EXCURSION_ALERT
  WAREHOUSE = COLDCHAIN_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Temperature excursion detected — product at risk'
IF (EXISTS (
  SELECT 1 FROM CURATED.FLEET_COMPLIANCE_STATUS
  WHERE 1=1 -- Condition: TEMPERATURE > THRESHOLD + 2°C for > 15 minutes
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_food_cold_chain_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Cold Chain Monitoring: Temperature excursion detected — product at risk',
    'Temperature excursion detected — product at risk'
  );

ALTER ALERT APP.TEMP_EXCURSION_ALERT RESUME;

-- Alert: COMPRESSOR_FAILURE_ALERT
CREATE OR REPLACE ALERT APP.COMPRESSOR_FAILURE_ALERT
  WAREHOUSE = COLDCHAIN_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Compressor failure predicted — schedule maintenance'
IF (EXISTS (
  SELECT 1 FROM CURATED.FLEET_COMPLIANCE_STATUS
  WHERE 1=1 -- Condition: COMPRESSOR_ANOMALY_SCORE > 0.9
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_food_cold_chain_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Cold Chain Monitoring: Compressor failure predicted — schedule maintenance',
    'Compressor failure predicted — schedule maintenance'
  );

ALTER ALERT APP.COMPRESSOR_FAILURE_ALERT RESUME;


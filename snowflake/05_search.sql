-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Cold Chain Monitoring
-- ============================================================================
USE DATABASE COLD_CHAIN;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.MAINTENANCE_SEARCH
  ON WORK_ORDER_NOTES
  ATTRIBUTES ASSET_TYPE, ASSET_ID, ISSUE_CATEGORY
  WAREHOUSE = COLDCHAIN_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.EQUIPMENT_MAINTENANCE
);

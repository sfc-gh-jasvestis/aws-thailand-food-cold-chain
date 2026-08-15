-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Cold Chain Monitoring
-- ============================================================================
USE DATABASE COLD_CHAIN;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): OnPoint Historical Weather
--   Real data: https://app.snowflake.com/marketplace/listing/GZSOZBT22EH
--   Using mock table: WEATHER_THAILAND
CREATE TABLE IF NOT EXISTS RAW.WEATHER_THAILAND (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);


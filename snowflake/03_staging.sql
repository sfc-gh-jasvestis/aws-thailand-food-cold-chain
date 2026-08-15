-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Cold Chain Monitoring
-- Country: THAILAND | Currency: THB
-- ============================================================================
USE DATABASE COLD_CHAIN;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- VEHICLES: 800 rows — Refrigerated trucks with GPS and temperature IoT sensors
-- COLD_STORAGE: 35 rows — Cold storage warehouses and distribution centers
-- TEMPERATURE_READINGS: 2,000,000 rows — IoT temperature readings every 5 minutes (800 trucks × 35 facilities × 30 days)
-- EXCURSION_EVENTS: 1,200 rows — Temperature excursion events with duration and product impact
-- SHIPMENTS: 45,000 rows — Active and historical shipment records
-- EQUIPMENT_MAINTENANCE: 3,000 rows — Refrigeration equipment maintenance records
-- PRODUCT_LOSS: 800 rows — Product spoilage and rejection records from cold chain failures
-- THAI_FOOD_LOGISTICS: 8 rows — Thailand cold chain logistics industry context

-- ============================================================================
-- Cold Chain Monitoring
-- Real-time cold chain monitoring across 800 trucks and 35 cold storage facilities — IoT Core tracks temperature excursions, ML.ANOMALY_DETECTION predicts equipment failure, and SNS alerts operations before product loss.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS COLD_CHAIN;
CREATE WAREHOUSE IF NOT EXISTS COLDCHAIN_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE COLD_CHAIN;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE COLDCHAIN_WH;

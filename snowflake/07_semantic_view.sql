-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Cold Chain Monitoring
-- ============================================================================
USE DATABASE COLD_CHAIN;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.COLD_CHAIN_ANALYTICS
  COMMENT = 'Cold chain compliance, temperature monitoring, and product loss analytics'
AS
  TABLES (
    CURATED.FLEET_COMPLIANCE_STATUS AS fleet_compliance_status,CURATED.EXCURSION_TIMESERIES AS excursion_timeseries,CURATED.ROUTE_RISK_SCORES AS route_risk_scores,CURATED.PRODUCT_LOSS_SUMMARY AS product_loss_summary
  );

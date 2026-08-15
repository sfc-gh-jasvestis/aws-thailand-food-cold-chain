-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Cold Chain Monitoring
-- ============================================================================
USE DATABASE COLD_CHAIN;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.COLD_CHAIN_AGENT
  COMMENT = 'Cold Chain Monitoring AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'COLD_CHAIN.APP.COLD_CHAIN_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'COLD_CHAIN.SEARCH.MAINTENANCE_SEARCH', TOOL_DESCRIPTION => 'Search documents for Food & Agribusiness information')
  )
  SYSTEM_PROMPT = 'You are the Cold Chain Intelligence Agent monitoring 800 refrigerated trucks and 35 cold storage facilities across Thailand''s food distribution network.';

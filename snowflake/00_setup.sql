-- Generated from generator/demo_specs/aws-thailand-food-cold-chain.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-thailand-food-cold-chain
-- This is the schema that is actually deployed for THAILAND_FOOD_COLD_CHAIN.

-- THAILAND_FOOD_COLD_CHAIN  (Cold Chain Monitoring)
-- generated from generator/demo_specs/aws-thailand-food-cold-chain.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS THAILAND_FOOD_COLD_CHAIN;
CREATE SCHEMA IF NOT EXISTS THAILAND_FOOD_COLD_CHAIN.RAW;
CREATE SCHEMA IF NOT EXISTS THAILAND_FOOD_COLD_CHAIN.CURATED;
CREATE SCHEMA IF NOT EXISTS THAILAND_FOOD_COLD_CHAIN.APP;
USE DATABASE THAILAND_FOOD_COLD_CHAIN;

-- 5 real regions; entity names carry their region so the two always agree

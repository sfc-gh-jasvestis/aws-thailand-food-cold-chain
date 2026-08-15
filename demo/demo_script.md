# Demo Script: Cold Chain Monitoring
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake monitors temperature compliance across the entire cold chain, detects anomalies predicting equipment failure, and auto-alerts logistics teams — replacing blind spots with real-time ML-powered cold chain intelligence"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Wichai Anantabutr** | VP Supply Chain & Logistics | React App (SPCS) | Product loss rate, temperature excursion frequency, fleet compliance, cost per cold chain failure |
| **Jintana Srikumpa** | Cold Chain Operations Manager | Amazon QuickSight | Real-time temperature alerts, equipment maintenance, driver compliance, route optimization |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 8 tables | VEHICLES (800), COLD_STORAGE (35), TEMPERATURE_READINGS (2000000), EXCURSION_EVENTS (1200), SHIPMENTS (45000), EQUIPMENT_MAINTENANCE (3000), PRODUCT_LOSS (800), THAI_FOOD_LOGISTICS (8) |
| **CURATED** | 4 Dynamic Tables | FLEET_COMPLIANCE_STATUS, EXCURSION_TIMESERIES, ROUTE_RISK_SCORES, PRODUCT_LOSS_SUMMARY |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 3000 documents indexed |
| **Agent** | COLD_CHAIN_AGENT | Semantic View + Search tools |


---

## The Story

Thailand's food cold chain spans 800 refrigerated trucks and 35 storage facilities distributing seafood, poultry, and prepared meals nationwide. Temperature excursions cause ฿180M quarterly in product loss — but traditional monitoring only alerts after the damage is done. ML-powered prediction catches failures 5-7 days early.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "Cold chain compliance rate: 94.2% — 47 trucks currently non-compliant."

**Action**: Point at compliance rate gauge

### [0:45–1:30] REAL-TIME MONITORING

**Show**: Real-Time Monitoring tab

> "Live fleet map — 800 trucks color-coded by temperature status (green/amber/red)."

**Action**: Show live fleet map with temperature colors

### [1:30–2:15] PREDICTIVE COLD CHAIN

**Show**: Predictive Cold Chain tab

> "ML.ANOMALY_DETECTION identifies compressor degradation patterns 5-7 days before failure."

**Action**: Show anomaly detection timeline for at-risk compressors

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Wichai asks: 'What routes have the highest cold chain failure rate?'"

**Action**: Type: 'Routes ranked by cold chain failure rate'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Seven Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.ANOMALY_DETECTION on cold chain temperature** — Only demo applying anomaly detection to refrigeration compressor degradation patterns
2. **2M IoT readings via Snowpipe Streaming** — 5-minute granularity temperature monitoring across 835 cold chain assets
3. **Predictive compressor failure (5-7 day warning)** — ML.FORECAST on compressor health metrics with maintenance scheduling
4. **Thai food logistics context** — Realistic Thai distribution routes, facility names, and CP Foods-scale operations
5. **Product loss attribution** — Automatic tracing from temperature excursion to specific product lots affected
6. **Route risk scoring via Dynamic Tables** — Real-time risk assessment by distribution route based on historical failures and ambient conditions


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM COLD_CHAIN.RAW.TEMPERATURE_READINGS` → 2000000
- [ ] `SELECT COUNT(*) FROM COLD_CHAIN.RAW.EXCURSION_EVENTS` → 1200
- [ ] `SELECT COUNT(*) FROM COLD_CHAIN.CURATED.FLEET_COMPLIANCE_STATUS WHERE STATUS = 'NON_COMPLIANT'` → ~47

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM COLD_CHAIN.ML.EXCURSION_FORECAST_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM COLD_CHAIN.ML.TEMP_ANOMALY_RESULTS` → >=30

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM COLD_CHAIN.AI.EXCURSION_ROOT_CAUSE` → 1200


# Cold Chain Monitoring

**Thailand - Food & Agribusiness**
Use case: Cold Chain & Temperature Compliance

> Real-time cold chain monitoring across 800 trucks and 35 cold storage facilities — IoT Core tracks temperature excursions, ML.ANOMALY_DETECTION predicts equipment failure, and SNS alerts operations before product loss.

## Why Snowflake

Snowflake monitors temperature compliance across the entire cold chain, detects anomalies predicting equipment failure, and auto-alerts logistics teams — replacing blind spots with real-time ML-powered cold chain intelligence

- **ML.ANOMALY_DETECTION on cold chain temperature** - Only demo applying anomaly detection to refrigeration compressor degradation patterns
- **2M IoT readings via Snowpipe Streaming** - 5-minute granularity temperature monitoring across 835 cold chain assets
- **Predictive compressor failure (5-7 day warning)** - ML.FORECAST on compressor health metrics with maintenance scheduling
- **Thai food logistics context** - Realistic Thai distribution routes, facility names, and CP Foods-scale operations
- **Product loss attribution** - Automatic tracing from temperature excursion to specific product lots affected
- **Route risk scoring via Dynamic Tables** - Real-time risk assessment by distribution route based on historical failures and ambient conditions

## What is deployed

| | |
|---|---|
| Database | `THAILAND_FOOD_COLD_CHAIN` |
| Service | `THAILAND_FOOD_COLD_CHAIN_APP` |
| Compute pool | `SEA_DEMOS_THAILAND_POOL` |
| Dimension table | `RAW.THAI_FOOD_LOGISTICS` (20 rows) |
| Fact table | `RAW.TEMPERATURE_READINGS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | THB (฿) |

Regions in play: Bangkok, Chonburi, Rayong, Chiang Mai, Songkhla
Segments: Frozen Seafood, Chilled Poultry, Fresh Produce, Dairy

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh THAILAND_FOOD_COLD_CHAIN
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Cold Chain Compliance | `94.2%` | average per event |
| Product Loss (QTD) | `฿180M` | total across Thai Food Logistics |
| Predicted Failures (7d) | `12` | total across Thai Food Logistics |
| Active Shipments | `835` | total across Thai Food Logistics |
| Avg Transit Temp | `-18.3°C` | average per event |
| Door-Open Events Today | `47` | total across Thai Food Logistics |
| On-Time Delivery | `91.8%` | average per event |


## Demo flow

1. Executive Cockpit
2. Real-Time Monitoring
3. Predictive Cold Chain
4. Ask AI
5. Architecture & Data

## Talking points

- **94.2%** - cold chain compliance rate (47 trucks non-compliant)
- **฿180M** - quarterly product loss from cold chain failures (US$5.1M)
- **12 failures** - predicted in next 7 days (ML.ANOMALY_DETECTION)
- **2M readings** - temperature data points ingested monthly (5-min resolution)
- **835 assets** - monitored (800 trucks + 35 cold storage facilities)
- **5-7 days** - advance warning for compressor failures

## Business impact

- Thailand's cold chain logistics market valued at ฿85B (US$2.4B) growing 8% annually (Krungsri Research)
- Cold chain failures cause 30-40% of food loss in Southeast Asian supply chains (FAO)
- Predictive cold chain monitoring reduces product loss by 25-40% through early intervention (McKinsey Supply Chain)
- CP Foods operates 1,000+ refrigerated trucks delivering to 130,000 points across Thailand (CP Foods)

---
Generated from `generator/demo_specs/aws-thailand-food-cold-chain.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-thailand-food-cold-chain` instead.

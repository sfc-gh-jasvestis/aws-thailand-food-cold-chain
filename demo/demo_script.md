# Thailand Food Cold Chain Control Tower

**Thailand - Temperature-Controlled Food Distribution**
Use case: Temperature-compliant pallets, pallet traceability and disruption risk

> Cold chain monitoring for a fictional food distributor's network of 30 sites across 6 Thai hub cities (frozen warehouses, chilled distribution centers, seafood processing docks, cross-docks and reefer truck depots): dynamic tables, a holdout-evaluated disruption-risk classifier, a pallet-volume forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile temperature-compliant pallets, excursion checks and refrigeration uptime from RAW site data, with checks in `run_core.py`
- **Disruption-risk classification** gives a holdout-evaluated next-7-day disruption probability per site
- **Pallet-volume forecast** projects 14 days of network-wide pallet volume with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.SITES` (30 rows) |
| Fact table | `RAW.SITE_DAILY` (2,700 site-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `DISRUPTION_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.DISRUPTION_RISK_SCORES`, `ML.DISRUPTION_RISK_HOLDOUT_METRICS`, `ML.VOLUME_FORECAST`, `ML.DWELL_ANOMALIES` |

Hub cities: Bangkok, Samut Sakhon, Chon Buri, Chiang Mai, Khon Kaen, Hat Yai.
Site types: Frozen Warehouse, Chilled Distribution Center, Seafood Processing Dock, Cross-Dock, Reefer Truck Depot.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Temperature-Compliant Pallets | 89.3% |
| Cold Chain Disruptions | 415 |
| Excursions per 1k Checks | 19.20 |
| Pallets Handled | 975,029 |
| Refrigeration Uptime | 98.4% |
| Cold Chain Sites | 30 |
| Refrigeration Readiness | 84.9% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily temperature-compliant pallets, out-of-range pallets by disruption cause, site table
2. Predictive: holdout metrics, risk bands, 14-day pallet-volume forecast, pallet dock-dwell anomalies
3. Site Health: refrigeration uptime, refrigeration readiness, PM compliance against temperature-compliant pallets, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Per-site in-range rate ranges from 85.4% to 92.8%. Chon Buri is the lowest hub city, at 87.9%.
- Reefer truck no-shows push the most pallets out of range of the 14 disruption causes.
- The risk model is evaluated on a time-based holdout: precision 0.67 and recall 0.63 at 0.5, against a 0.53 base rate. Present it as triage, not a guarantee.
- The Hat Yai monsoon flood road closure and the Chiang Mai grid power outage are excluded from disruption labels, because they are city-wide events, not site-driven.
- Pallet traceability: SOPs require tagging affected pallets with their lot and order IDs, and each site-day records temperature-compliant pallets and order fill rate.

## Business impact

Use only the sourced references in `README.md` (Business Impact).

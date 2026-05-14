/* @bruin

name: analytics.fx_impact_analysis
type: bq.sql
description: Analyses relationship between USD/MYR movements and sector stock performance.
connection: bigquery_default

materialization:
  type: table
  strategy: create+replace

depends:
  - marts.fact_daily_prices

secrets:
  - key: bigquery_default
    inject_as: bigquery_default

columns:
  - name: year_month
    type: STRING
    description: Year-month period
    checks:
      - name: not_null
  - name: sector
    type: STRING
    description: GICS sector
    checks:
      - name: not_null
  - name: avg_usd_myr
    type: FLOAT64
    description: Average USD/MYR rate for the month
    checks:
      - name: positive
  - name: usd_myr_change_pct
    type: FLOAT64
    description: Month-over-month change in USD/MYR rate (%)
  - name: avg_sector_return_pct
    type: FLOAT64
    description: Average daily stock return for sector
  - name: myr_depreciation_flag
    type: BOOL
    description: TRUE if MYR weakened vs USD

@bruin */

WITH monthly_base AS (
    SELECT
        FORMAT_DATE('%Y-%m', trade_date)    AS year_month,
        sector,
        AVG(usd_myr_rate)                   AS avg_usd_myr,
        AVG(daily_return_pct)               AS avg_sector_return_pct
    FROM `hale-mantra-431702-u3.marts.fact_daily_prices`
    WHERE usd_myr_rate IS NOT NULL
      AND daily_return_pct IS NOT NULL
    GROUP BY year_month, sector
)
SELECT
    year_month,
    sector,
    ROUND(avg_usd_myr, 4)                   AS avg_usd_myr,
    ROUND(
        (avg_usd_myr - LAG(avg_usd_myr) OVER (PARTITION BY sector ORDER BY year_month))
        / NULLIF(LAG(avg_usd_myr) OVER (PARTITION BY sector ORDER BY year_month), 0) * 100,
        4
    )                                       AS usd_myr_change_pct,
    ROUND(avg_sector_return_pct, 4)         AS avg_sector_return_pct,
    CASE
        WHEN avg_usd_myr > LAG(avg_usd_myr) OVER (PARTITION BY sector ORDER BY year_month)
        THEN TRUE ELSE FALSE
    END                                     AS myr_depreciation_flag
FROM monthly_base
ORDER BY year_month DESC, sector

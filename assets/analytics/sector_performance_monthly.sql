/* @bruin

name: analytics.sector_performance_monthly
type: bq.sql
description: Monthly sector-level aggregation showing average return, volatility, and total volume.
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
    description: Year-month period (YYYY-MM)
    checks:
      - name: not_null
  - name: sector
    type: STRING
    description: GICS sector
    checks:
      - name: not_null
  - name: avg_monthly_return_pct
    type: FLOAT64
    description: Average daily return % for the month
  - name: return_volatility
    type: FLOAT64
    description: Standard deviation of daily returns
  - name: total_volume
    type: INT64
    description: Total shares traded for the month
  - name: high_volatility_days
    type: INT64
    description: Count of stock-days where return exceeded ±3%
  - name: stock_count
    type: INT64
    description: Number of distinct stocks in sector
    checks:
      - name: positive

@bruin */

SELECT
    FORMAT_DATE('%Y-%m', trade_date)        AS year_month,
    sector,
    ROUND(AVG(daily_return_pct), 4)         AS avg_monthly_return_pct,
    ROUND(STDDEV(daily_return_pct), 4)      AS return_volatility,
    SUM(volume)                             AS total_volume,
    COUNTIF(is_high_volatility = TRUE)      AS high_volatility_days,
    COUNT(DISTINCT ticker)                  AS stock_count
FROM `hale-mantra-431702-u3.marts.fact_daily_prices`
WHERE trade_date IS NOT NULL
  AND daily_return_pct IS NOT NULL
GROUP BY year_month, sector
ORDER BY year_month DESC, sector

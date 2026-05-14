/* @bruin

name: marts.fact_daily_prices
type: bq.sql
description: Core fact table joining daily stock prices with company dimension and USD/MYR exchange rate.
connection: bigquery_default

materialization:
  type: table
  strategy: create+replace
  partition_by: trade_date
  cluster_by:
    - sector
    - ticker

depends:
  - staging.stg_stock_prices
  - staging.stg_exchange_rates
  - marts.dim_companies

secrets:
  - key: bigquery_default
    inject_as: bigquery_default

columns:
  - name: ticker
    type: STRING
    description: Stock ticker
    primary_key: true
    checks:
      - name: not_null
  - name: trade_date
    type: DATE
    description: Trading date
    primary_key: true
    checks:
      - name: not_null
  - name: company_name
    type: STRING
    description: Company name
    checks:
      - name: not_null
  - name: sector
    type: STRING
    description: GICS sector
    checks:
      - name: not_null
  - name: subsector
    type: STRING
    description: GICS sub-sector
  - name: is_shariah_compliant
    type: BOOL
    description: Shariah compliance flag
  - name: open_price
    type: FLOAT64
    description: Opening price MYR
    checks:
      - name: positive
  - name: high_price
    type: FLOAT64
    description: High price MYR
    checks:
      - name: positive
  - name: low_price
    type: FLOAT64
    description: Low price MYR
    checks:
      - name: positive
  - name: close_price
    type: FLOAT64
    description: Closing price MYR
    checks:
      - name: not_null
      - name: positive
  - name: volume
    type: INT64
    description: Shares traded
    checks:
      - name: non_negative
  - name: daily_return_pct
    type: FLOAT64
    description: Daily return %
  - name: price_range
    type: FLOAT64
    description: Intraday high minus low
    checks:
      - name: non_negative
  - name: usd_myr_rate
    type: FLOAT64
    description: USD/MYR rate on that date
  - name: close_price_usd
    type: FLOAT64
    description: Close price converted to USD
  - name: is_high_volatility
    type: BOOL
    description: TRUE if daily return exceeds plus or minus 3%

@bruin */

WITH fx AS (
    SELECT DISTINCT rate_date, usd_myr_rate
    FROM `hale-mantra-431702-u3.staging.stg_exchange_rates`
    WHERE target_currency = 'MYR'
      AND usd_myr_rate IS NOT NULL
      AND usd_myr_rate > 0
)
SELECT
    sp.ticker,
    sp.trade_date,
    dc.company_name,
    dc.sector,
    dc.subsector,
    dc.is_shariah_compliant,
    sp.open_price,
    sp.high_price,
    sp.low_price,
    sp.close_price,
    sp.volume,
    sp.daily_return_pct,
    sp.price_range,
    fx.usd_myr_rate,
    ROUND(sp.close_price / NULLIF(fx.usd_myr_rate, 0), 4) AS close_price_usd,
    CASE WHEN ABS(sp.daily_return_pct) > 3 THEN TRUE ELSE FALSE END AS is_high_volatility
FROM `hale-mantra-431702-u3.staging.stg_stock_prices` sp
LEFT JOIN `hale-mantra-431702-u3.marts.dim_companies` dc ON sp.ticker = dc.ticker
LEFT JOIN fx ON sp.trade_date = fx.rate_date

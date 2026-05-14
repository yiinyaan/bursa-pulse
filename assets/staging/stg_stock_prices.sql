/* @bruin

name: staging.stg_stock_prices
type: bq.sql
description: Cleaned stock price data with daily return and price range calculations.
connection: bigquery_default

materialization:
  type: table
  strategy: create+replace

depends:
  - raw.stock_prices

secrets:
  - key: bigquery_default
    inject_as: bigquery_default

columns:
  - name: ticker
    type: STRING
    description: Yahoo Finance ticker symbol
    primary_key: true
    checks:
      - name: not_null
  - name: trade_date
    type: DATE
    description: Trading date
    primary_key: true
    checks:
      - name: not_null
  - name: open_price
    type: FLOAT64
    description: Opening price in MYR
    checks:
      - name: not_null
      - name: positive
  - name: high_price
    type: FLOAT64
    description: Intraday high price in MYR
    checks:
      - name: not_null
      - name: positive
  - name: low_price
    type: FLOAT64
    description: Intraday low price in MYR
    checks:
      - name: not_null
      - name: positive
  - name: close_price
    type: FLOAT64
    description: Closing price in MYR
    checks:
      - name: not_null
      - name: positive
  - name: volume
    type: INT64
    description: Shares traded
    checks:
      - name: not_null
      - name: non_negative
  - name: daily_return_pct
    type: FLOAT64
    description: Daily return % vs previous close
  - name: price_range
    type: FLOAT64
    description: 'Intraday range: high minus low'
    checks:
      - name: non_negative

@bruin */

SELECT
    ticker,
    trade_date,
    open_price,
    high_price,
    low_price,
    close_price,
    volume,
    ROUND(
        (close_price - LAG(close_price) OVER (PARTITION BY ticker ORDER BY trade_date))
        / NULLIF(LAG(close_price) OVER (PARTITION BY ticker ORDER BY trade_date), 0) * 100,
        4
    ) AS daily_return_pct,
    ROUND(high_price - low_price, 4) AS price_range
FROM `hale-mantra-431702-u3.raw.stock_prices`
WHERE
    close_price > 0
    AND open_price > 0
    AND high_price >= low_price
    AND trade_date IS NOT NULL
    AND ticker IS NOT NULL

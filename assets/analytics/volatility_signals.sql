/* @bruin

name: analytics.volatility_signals
type: bq.sql
description: Flags stock-days with abnormal price movements for anomaly detection and risk monitoring.
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
  - name: ticker
    type: STRING
    description: Stock ticker
    primary_key: true
    checks:
      - name: not_null
  - name: trade_date
    type: DATE
    description: Date of signal
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
  - name: close_price
    type: FLOAT64
    description: Closing price
    checks:
      - name: positive
  - name: daily_return_pct
    type: FLOAT64
    description: Daily return %
    checks:
      - name: not_null
  - name: signal_type
    type: STRING
    description: Type of anomaly detected
    checks:
      - name: not_null
      - name: accepted_values
        value:
          - EXTREME_GAIN
          - EXTREME_LOSS
          - HIGH_VOLUME_SPIKE
          - PRICE_RANGE_ANOMALY
  - name: signal_severity
    type: STRING
    description: Severity level of the signal
    checks:
      - name: accepted_values
        value:
          - LOW
          - MEDIUM
          - HIGH

@bruin */

WITH volume_stats AS (
    SELECT
        ticker,
        AVG(volume)    AS avg_volume,
        STDDEV(volume) AS std_volume
    FROM `hale-mantra-431702-u3.marts.fact_daily_prices`
    GROUP BY ticker
),
signals AS (
    SELECT
        f.ticker,
        f.company_name,
        f.trade_date,
        f.sector,
        f.close_price,
        f.daily_return_pct,
        CASE
            WHEN f.daily_return_pct >= 5                              THEN 'EXTREME_GAIN'
            WHEN f.daily_return_pct <= -5                             THEN 'EXTREME_LOSS'
            WHEN f.volume > vs.avg_volume + 2 * vs.std_volume         THEN 'HIGH_VOLUME_SPIKE'
            WHEN f.price_range > f.close_price * 0.05                THEN 'PRICE_RANGE_ANOMALY'
        END AS signal_type,
        CASE
            WHEN ABS(f.daily_return_pct) >= 10 THEN 'HIGH'
            WHEN ABS(f.daily_return_pct) >= 5  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS signal_severity
    FROM `hale-mantra-431702-u3.marts.fact_daily_prices` f
    LEFT JOIN volume_stats vs ON f.ticker = vs.ticker
    WHERE f.daily_return_pct IS NOT NULL
)
SELECT
    ticker,
    company_name,
    trade_date,
    sector,
    close_price,
    daily_return_pct,
    signal_type,
    signal_severity
FROM signals
WHERE signal_type IS NOT NULL

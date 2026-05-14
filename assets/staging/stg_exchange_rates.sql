/* @bruin

name: staging.stg_exchange_rates
type: bq.sql
description: Cleaned exchange rates with derived USD/MYR cross rate from Frankfurter API.
connection: bigquery_default

materialization:
  type: table
  strategy: create+replace

depends:
  - raw.exchange_rates

secrets:
  - key: bigquery_default
    inject_as: bigquery_default

columns:
  - name: rate_date
    type: DATE
    description: Date of exchange rate
    primary_key: true
    checks:
      - name: not_null
  - name: base_currency
    type: STRING
    description: Base currency (always EUR)
    checks:
      - name: not_null
  - name: target_currency
    type: STRING
    description: Target currency code (USD, MYR, SGD)
    primary_key: true
    checks:
      - name: not_null
  - name: rate
    type: FLOAT64
    description: 1 EUR = X target_currency
    checks:
      - name: not_null
      - name: positive
  - name: usd_myr_rate
    type: FLOAT64
    description: 'Derived cross rate: 1 USD = X MYR'

@bruin */

WITH pivoted AS (
    SELECT
        rate_date,
        MAX(CASE WHEN target_currency = 'USD' THEN rate END) AS eur_usd,
        MAX(CASE WHEN target_currency = 'MYR' THEN rate END) AS eur_myr
    FROM `hale-mantra-431702-u3.raw.exchange_rates`
    WHERE target_currency IN ('USD', 'MYR', 'SGD')
    GROUP BY rate_date
)
SELECT
    r.rate_date,
    r.base_currency,
    r.target_currency,
    r.rate,
    ROUND(p.eur_myr / NULLIF(p.eur_usd, 0), 6) AS usd_myr_rate
FROM `hale-mantra-431702-u3.raw.exchange_rates` r
LEFT JOIN pivoted p ON r.rate_date = p.rate_date
WHERE r.rate > 0

{{ config(
    materialized='table'
) }}

WITH pivoted AS (
    SELECT
        rate_date,
        MAX(CASE WHEN target_currency = 'USD' THEN rate END) AS eur_usd,
        MAX(CASE WHEN target_currency = 'MYR' THEN rate END) AS eur_myr
    FROM {{ source('raw', 'exchange_rates') }}
    WHERE target_currency IN ('USD', 'MYR', 'SGD')
    GROUP BY rate_date
)
SELECT
    r.rate_date,
    r.base_currency,
    r.target_currency,
    r.rate,
    ROUND(p.eur_myr / NULLIF(p.eur_usd, 0), 6) AS usd_myr_rate
FROM {{ source('raw', 'exchange_rates') }} r
LEFT JOIN pivoted p ON r.rate_date = p.rate_date
WHERE r.rate > 0

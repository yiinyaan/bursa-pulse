{{ config(
    materialized='table',
    partition_by={
      "field": "trade_date",
      "data_type": "date"
    },
    cluster_by=["sector", "ticker"]
) }}

WITH fx AS (
    SELECT DISTINCT rate_date, usd_myr_rate
    FROM {{ ref('stg_exchange_rates') }}
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
FROM {{ ref('stg_stock_prices') }} sp
LEFT JOIN {{ ref('dim_companies') }} dc ON sp.ticker = dc.ticker
LEFT JOIN fx ON sp.trade_date = fx.rate_date

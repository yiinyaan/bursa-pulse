{{ config(
    materialized='table'
) }}

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
FROM {{ source('raw', 'stock_prices') }}
WHERE
    close_price > 0
    AND open_price > 0
    AND high_price >= low_price
    AND trade_date IS NOT NULL
    AND ticker IS NOT NULL

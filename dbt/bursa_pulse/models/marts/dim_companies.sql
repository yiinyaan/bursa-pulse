{{ config(
    materialized='table'
) }}

SELECT
    REPLACE(ticker, '.', '_')           AS company_key,
    ticker,
    company_name,
    sector,
    subsector,
    market_cap_category,
    CASE WHEN is_shariah_compliant = 'Yes' THEN TRUE ELSE FALSE END AS is_shariah_compliant
FROM {{ ref('stg_klci_components') }}

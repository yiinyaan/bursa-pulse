{{ config(
    materialized='table'
) }}

SELECT
    ticker,
    company_name,
    sector,
    subsector,
    market_cap_category,
    is_shariah_compliant
FROM {{ source('seeds', 'klci_components') }}

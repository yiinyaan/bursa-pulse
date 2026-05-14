/* @bruin

name: marts.dim_companies
type: bq.sql
description: Dimension table for KLCI component companies.
connection: bigquery_default

materialization:
  type: table
  strategy: create+replace

depends:
  - staging.stg_klci_components

secrets:
  - key: bigquery_default
    inject_as: bigquery_default

columns:
  - name: company_key
    type: STRING
    description: Surrogate key
    checks:
      - name: not_null
      - name: unique
  - name: ticker
    type: STRING
    description: Yahoo Finance ticker symbol
    checks:
      - name: not_null
      - name: unique
  - name: company_name
    type: STRING
    description: Full company name
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
  - name: market_cap_category
    type: STRING
    description: Market cap tier
  - name: is_shariah_compliant
    type: BOOL
    description: Shariah compliance flag

@bruin */

SELECT
    REPLACE(ticker, '.', '_')           AS company_key,
    ticker,
    company_name,
    sector,
    subsector,
    market_cap_category,
    CASE WHEN is_shariah_compliant = 'Yes' THEN TRUE ELSE FALSE END AS is_shariah_compliant
FROM `hale-mantra-431702-u3.staging.stg_klci_components`

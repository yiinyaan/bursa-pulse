/* @bruin

name: staging.stg_klci_components
type: bq.sql
description: Reference table for KLCI 30 component stocks with sector classification.
connection: bigquery_default

materialization:
  type: table
  strategy: create+replace

secrets:
  - key: bigquery_default
    inject_as: bigquery_default

columns:
  - name: ticker
    type: STRING
    description: Yahoo Finance ticker symbol
    checks:
      - name: not_null
      - name: unique
  - name: company_name
    type: STRING
    description: Full legal company name
    checks:
      - name: not_null
  - name: sector
    type: STRING
    description: GICS sector classification
    checks:
      - name: not_null
      - name: accepted_values
        value:
          - Financials
          - Energy
          - Communications
          - Utilities
          - Consumer Staples
          - Consumer Discretionary
          - Healthcare
          - Real Estate
          - Industrials
  - name: subsector
    type: STRING
    description: Sub-sector within GICS sector
    checks:
      - name: not_null
  - name: market_cap_category
    type: STRING
    description: Market cap tier
    checks:
      - name: accepted_values
        value:
          - Large Cap
          - Mid Cap
          - Small Cap
  - name: is_shariah_compliant
    type: STRING
    description: Whether stock is Shariah-compliant per SC Malaysia
    checks:
      - name: accepted_values
        value:
          - "Yes"
          - "No"

@bruin */

SELECT
    ticker,
    company_name,
    sector,
    subsector,
    market_cap_category,
    is_shariah_compliant
FROM `hale-mantra-431702-u3.seeds.klci_components`

"""@bruin

name: raw.exchange_rates
description: Ingests daily USD/MYR and EUR/MYR exchange rates from Frankfurter API. No API key required.
connection: bigquery_default

materialization:
  type: table
  strategy: merge
  partition_by: rate_date

secrets:
  - key: bigquery_default
    inject_as: bigquery_default

columns:
  - name: rate_date
    type: DATE
    description: Date of the exchange rate
    primary_key: true
    checks:
      - name: not_null
  - name: base_currency
    type: STRING
    description: Base currency code
    primary_key: true
    checks:
      - name: not_null
  - name: target_currency
    type: STRING
    description: Target currency code (USD, MYR, SGD)
    primary_key: true
    checks:
      - name: not_null
  - name: rate
    type: FLOAT
    description: 'Exchange rate: 1 base = X target'
    checks:
      - name: not_null
      - name: positive
  - name: ingested_at
    type: TIMESTAMP
    description: Timestamp when this record was loaded
    checks:
      - name: not_null

@bruin"""

import requests
import pandas as pd
from datetime import datetime


def materialize():
    start_date = "2024-01-01"
    end_date = datetime.today().strftime("%Y-%m-%d")
    currencies = "USD,MYR,SGD"

    # Use v1 API — stable dict format
    url = f"https://api.frankfurter.dev/v1/{start_date}..{end_date}?base=EUR&symbols={currencies}"

    print(f"Fetching: {url}")
    response = requests.get(url, timeout=60)

    if response.status_code != 200:
        raise ValueError(f"Frankfurter API error: {response.status_code} — {response.text}")

    data = response.json()

    rows = []
    for date_str, rate_dict in data.get("rates", {}).items():
        for currency, rate in rate_dict.items():
            rows.append({
                "rate_date": date_str,
                "base_currency": data.get("base", "EUR"),
                "target_currency": currency,
                "rate": rate,
                "ingested_at": datetime.utcnow(),
            })

    if not rows:
        raise ValueError("No exchange rate data returned.")

    df = pd.DataFrame(rows)
    df["rate_date"] = pd.to_datetime(df["rate_date"]).dt.date
    df["rate"] = df["rate"].astype(float).round(6)

    print(f"Total rows ingested: {len(df)}")
    return df

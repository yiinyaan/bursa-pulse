"""@bruin

name: raw.stock_prices
description: Ingests daily OHLCV stock price data for KLCI 30 component stocks from Yahoo Finance via yfinance.
connection: bigquery_default

materialization:
  type: table
  strategy: merge
  partition_by: trade_date
  cluster_by:
    - ticker

secrets:
  - key: bigquery_default
    inject_as: bigquery_default

columns:
  - name: ticker
    type: STRING
    description: Yahoo Finance ticker symbol
    primary_key: true
    checks:
      - name: not_null
  - name: trade_date
    type: DATE
    description: Trading date
    primary_key: true
    checks:
      - name: not_null
  - name: open_price
    type: FLOAT
    description: Opening price in MYR
    checks:
      - name: not_null
      - name: positive
  - name: high_price
    type: FLOAT
    description: Intraday high price in MYR
    checks:
      - name: not_null
      - name: positive
  - name: low_price
    type: FLOAT
    description: Intraday low price in MYR
    checks:
      - name: not_null
      - name: positive
  - name: close_price
    type: FLOAT
    description: Closing price in MYR
    checks:
      - name: not_null
      - name: positive
  - name: volume
    type: INTEGER
    description: Number of shares traded
    checks:
      - name: not_null
      - name: non_negative
  - name: ingested_at
    type: TIMESTAMP
    description: Timestamp when this record was loaded
    checks:
      - name: not_null

@bruin"""

import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta


def materialize():
    tickers = [
        "1155.KL", "1023.KL", "1295.KL", "5183.KL", "6888.KL",
        "6012.KL", "4863.KL", "5347.KL", "1082.KL", "5819.KL",
        "4197.KL", "2291.KL", "4065.KL", "3816.KL", "3182.KL",
        "4715.KL", "1961.KL", "2445.KL", "5285.KL", "1066.KL",
        "5168.KL", "7277.KL", "5299.KL", "6033.KL", "4588.KL",
        "3026.KL", "5008.KL", "4308.KL", "5681.KL", "6947.KL",
    ]

    end_date = datetime.today()
    start_date = end_date - timedelta(days=730)

    all_frames = []

    for ticker in tickers:
        try:
            df = yf.download(
                ticker,
                start=start_date.strftime("%Y-%m-%d"),
                end=end_date.strftime("%Y-%m-%d"),
                progress=False,
                auto_adjust=True,
            )

            if df.empty:
                print(f"WARNING: No data returned for {ticker}, skipping.")
                continue

            df = df.reset_index()
            df.columns = [c[0] if isinstance(c, tuple) else c for c in df.columns]

            df_clean = pd.DataFrame({
                "ticker": ticker,
                "trade_date": pd.to_datetime(df["Date"]).dt.date,
                "open_price": df["Open"].round(4),
                "high_price": df["High"].round(4),
                "low_price": df["Low"].round(4),
                "close_price": df["Close"].round(4),
                "volume": df["Volume"].fillna(0).astype(int),
                "ingested_at": datetime.utcnow(),
            })

            df_clean = df_clean.dropna(subset=["close_price"])
            all_frames.append(df_clean)
            print(f"OK: {ticker} — {len(df_clean)} rows")

        except Exception as e:
            print(f"ERROR: {ticker} failed — {e}")
            continue

    if not all_frames:
        raise ValueError("No data ingested for any ticker.")

    result = pd.concat(all_frames, ignore_index=True)
    print(f"\nTotal rows ingested: {len(result)}")
    return result

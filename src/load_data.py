"""Load the raw Online Retail data into SQLite, unmodified.

No cleaning happens here. All cleaning is done later in SQL
so every decision is visible and reversible.
"""
from pathlib import Path
import sqlite3
import pandas as pd

RAW_XLSX = Path("data/raw/Online Retail.xlsx")
RAW_CSV = Path("data/raw/online_retail.csv")   # cache: the xlsx is slow to read
DB_PATH = Path("data/processed/retail.db")
TABLE = "raw_online_retail"

# InvoiceNo can start with 'C' (cancellations) and StockCode can be
# alphanumeric (e.g. 85123A), so both must stay text.
# CustomerID has nulls, so use nullable Int64 to avoid the 17850.0 float trap.
DTYPES = {"InvoiceNo": "string", "StockCode": "string", "CustomerID": "Int64"}


def read_raw() -> pd.DataFrame:
    if not RAW_CSV.exists():
        pd.read_excel(RAW_XLSX, dtype=DTYPES).to_csv(RAW_CSV, index=False)
    return pd.read_csv(RAW_CSV, dtype=DTYPES, parse_dates=["InvoiceDate"])


def main() -> None:
    df = read_raw()
    # SQLite has no datetime type: store ISO text so it sorts correctly.
    df["InvoiceDate"] = df["InvoiceDate"].dt.strftime("%Y-%m-%d %H:%M:%S")

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(DB_PATH) as conn:
        df.to_sql(TABLE, conn, if_exists="replace", index=False, chunksize=50_000)
        n = conn.execute(f"SELECT COUNT(*) FROM {TABLE}").fetchone()[0]

    print(f"Source rows: {len(df):,} | Rows in {TABLE}: {n:,}")
    assert n == len(df), "Row count mismatch after load"


if __name__ == "__main__":
    main()
"""Run every statement in a .sql file against the project database.

Usage: python src/run_sql_file.py sql/01_create_tables.sql
SELECT results are printed as tables, other statements print OK.
"""
import sqlite3
import sys
import pandas as pd

DB_PATH = "data/processed/retail.db"

with open(sys.argv[1], encoding="utf-8") as f:
    script = f.read()

# Split on semicolons so each statement runs separately.
statements = [s.strip() for s in script.split(";") if s.strip()]

conn = sqlite3.connect(DB_PATH)
conn.execute("PRAGMA foreign_keys = ON")  # must come right after connecting

for s in statements:
    print("-" * 60)
    print(s)
    cur = conn.execute(s)
    if cur.description:  # SELECT or PRAGMA: has columns
        cols = [d[0] for d in cur.description]
        print(pd.DataFrame(cur.fetchall(), columns=cols).to_string(index=False))
    else:
        print(f"OK ({cur.rowcount} rows affected)")

conn.commit()
conn.close()
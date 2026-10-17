-- ============================================================
-- 01_create_tables.sql
-- Purpose : Define the three clean tables (empty). They are filled in 02_clean_data.sql
-- Run     : python src/run_sql_file.py sql/01_create_tables.sql
-- ============================================================

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- One row per customer
CREATE TABLE customers (
    CustomerID INTEGER PRIMARY KEY,
    Country    TEXT NOT NULL
);

-- One row per product code
CREATE TABLE products (
    StockCode   TEXT PRIMARY KEY,
    Description TEXT
);

-- One row per invoice line
CREATE TABLE orders (
    OrderLineID INTEGER PRIMARY KEY,
    InvoiceNo   TEXT    NOT NULL,
    InvoiceDate TEXT    NOT NULL,
    CustomerID  INTEGER NOT NULL REFERENCES customers(CustomerID),
    StockCode   TEXT    NOT NULL REFERENCES products(StockCode),
    Quantity    INTEGER NOT NULL CHECK (Quantity > 0),
    UnitPrice   REAL    NOT NULL CHECK (UnitPrice > 0)
);

CREATE INDEX idx_orders_customer ON orders(CustomerID);
CREATE INDEX idx_orders_stock    ON orders(StockCode);
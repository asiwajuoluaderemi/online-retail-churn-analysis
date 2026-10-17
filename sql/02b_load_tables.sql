-- ============================================================
-- 02b_load_tables.sql
-- Purpose : Fill customers, products and orders from clean_lines
-- Run     : python src/run_sql_file.py sql/02b_load_tables.sql
-- Order   : customers first, then products, then orders (foreign keys)
-- ============================================================

-- One country per customer: most distinct invoices, ties to latest invoice
INSERT INTO customers (CustomerID, Country)
SELECT CustomerID,
       CASE Country WHEN 'EIRE' THEN 'Ireland'
                    WHEN 'RSA'  THEN 'South Africa'
                    ELSE Country END AS Country
FROM (
    SELECT CustomerID, Country,
           ROW_NUMBER() OVER (
               PARTITION BY CustomerID
               ORDER BY n_invoices DESC, last_invoice DESC, Country
           ) AS rnk
    FROM (
        SELECT CustomerID, Country,
               COUNT(DISTINCT InvoiceNo) AS n_invoices,
               MAX(InvoiceDate)          AS last_invoice
        FROM clean_lines
        GROUP BY CustomerID, Country
    )
)
WHERE rnk = 1;

-- One description per product: most frequent, ties to latest, then alphabetical
INSERT INTO products (StockCode, Description)
SELECT StockCode, Description
FROM (
    SELECT StockCode, Description,
           ROW_NUMBER() OVER (
               PARTITION BY StockCode
               ORDER BY n_rows DESC, last_seen DESC, Description
           ) AS rnk
    FROM (
        SELECT StockCode, Description,
               COUNT(*)         AS n_rows,
               MAX(InvoiceDate) AS last_seen
        FROM clean_lines
        GROUP BY StockCode, Description
    )
)
WHERE rnk = 1;

-- One row per clean invoice line
INSERT INTO orders (InvoiceNo, InvoiceDate, CustomerID, StockCode, Quantity, UnitPrice)
SELECT InvoiceNo, InvoiceDate, CustomerID, StockCode, Quantity, UnitPrice
FROM clean_lines;
-- ============================================================
-- 02_clean_data.sql
-- Purpose : Define clean_lines, the single place where cleaning rules live.
-- Run     : python src/run_sql_file.py sql/02_clean_data.sql
-- Note    : Keep comments free of semicolons, the runner splits on them.
-- ============================================================

DROP VIEW IF EXISTS clean_lines;

CREATE VIEW clean_lines AS
SELECT InvoiceNo, InvoiceDate, CustomerID, StockCode, Description, Country, Quantity, UnitPrice
FROM raw_online_retail
WHERE CustomerID IS NOT NULL                 -- rule 1: no customer ID, cannot be analysed per customer
  AND InvoiceNo NOT LIKE 'C%'                -- rule 2: cancellation invoices
  AND Quantity > 0                           -- rule 3: negative quantities (safety guard)
  AND UnitPrice > 0                          -- rule 4: zero and negative prices
  AND UPPER(StockCode) NOT IN                -- rule 5: fees, postage, adjustments (not merchandise)
      ('POST','DOT','M','C2','D','S','BANK CHARGES','AMAZONFEE','CRUK','B')
  AND InvoiceNo NOT IN                       -- rule 6: originals voided by a cancellation
      ('541431','581483','540815','540818','570094','570097');
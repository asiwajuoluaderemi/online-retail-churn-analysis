-- ============================================================
-- 00_profile_raw_data.sql
-- Purpose : Profile raw_online_retail BEFORE any cleaning.
-- Output  : Findings are logged in reports/profiling_notes.md
-- Run     : python src/run_sql_file.py sql/00_profile_raw_data.sql
-- Note    : Keep comments free of semicolons, the runner splits on them.
-- ============================================================


-- ============================================================
-- 1. VOLUME AND DATE RANGE
-- ============================================================

-- 1.1 Does the row count match the source file? What period does the data cover?
-- The max date becomes the reference date for days-since-last-order later.
SELECT COUNT(*)                     AS total_rows,
       COUNT(DISTINCT InvoiceNo)    AS invoices,
       COUNT(DISTINCT CustomerID)   AS customers,
       MIN(InvoiceDate)             AS first_date,
       MAX(InvoiceDate)             AS last_date
FROM raw_online_retail;


-- ============================================================
-- 2. COUNTRIES
-- ============================================================

-- 2.1 Rows, distinct customers and net revenue per country.
-- Many rows but few customers means revenue depends on a handful of accounts.
-- Customers = 0 means every row for that country has a NULL CustomerID.
SELECT Country,
       COUNT(*)                          AS n_rows,
       COUNT(DISTINCT CustomerID)        AS customers,
       ROUND(SUM(Quantity * UnitPrice), 2) AS net_revenue
FROM raw_online_retail
GROUP BY Country
ORDER BY n_rows DESC;


-- ============================================================
-- 3. CUSTOMER IDS
-- ============================================================

-- 3.1 How much of the data has no customer ID, in rows and in revenue?
SELECT SUM(CustomerID IS NULL)                                              AS null_id_rows,
       ROUND(100.0 * SUM(CustomerID IS NULL) / COUNT(*), 2)                 AS pct_of_rows,
       ROUND(SUM(CASE WHEN CustomerID IS NULL THEN Quantity * UnitPrice END), 2) AS null_id_net_revenue,
       ROUND(100.0 * SUM(CASE WHEN CustomerID IS NULL THEN Quantity * UnitPrice END)
             / SUM(Quantity * UnitPrice), 2)                                AS pct_of_net_revenue
FROM raw_online_retail;

-- 3.2 Why is the NULL-ID group worth less per row? Split revenue by sign.
SELECT CustomerID IS NULL AS is_null_id,
       COUNT(*)           AS n_rows,
       ROUND(SUM(CASE WHEN Quantity * UnitPrice > 0 THEN Quantity * UnitPrice END), 2) AS positive_revenue,
       ROUND(SUM(CASE WHEN Quantity * UnitPrice < 0 THEN Quantity * UnitPrice END), 2) AS negative_revenue
FROM raw_online_retail
GROUP BY is_null_id;

-- 3.3 Which customers appear under more than one country?
-- Each one needs a single country in the customers table.
SELECT CustomerID,
       COUNT(DISTINCT Country) AS n_countries
FROM raw_online_retail
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(DISTINCT Country) > 1;


-- ============================================================
-- 4. PRICE AND QUANTITY
-- ============================================================

-- 4.1 Ranges and counts of non-positive values.
SELECT MIN(UnitPrice)                AS min_price,
       MAX(UnitPrice)                AS max_price,
       MIN(Quantity)                 AS min_quantity,
       MAX(Quantity)                 AS max_quantity,
       SUM(UnitPrice < 0)            AS n_negative_price,
       SUM(UnitPrice = 0)            AS n_zero_price,
       SUM(Quantity <= 0)            AS n_nonpositive_quantity
FROM raw_online_retail;

-- 4.2 Zero price versus negative price. Do they need different treatment?
SELECT CASE WHEN UnitPrice < 0 THEN 'negative'
            WHEN UnitPrice = 0 THEN 'zero'
            ELSE 'positive' END      AS price_type,
       COUNT(*)                      AS n_rows,
       SUM(CustomerID IS NULL)       AS n_null_customer
FROM raw_online_retail
GROUP BY price_type;

-- 4.3 What are the extreme rows? Real sale or accounting entry?
SELECT InvoiceNo, StockCode, Description, Quantity, UnitPrice, CustomerID
FROM raw_online_retail
WHERE UnitPrice = (SELECT MIN(UnitPrice) FROM raw_online_retail)
   OR UnitPrice = (SELECT MAX(UnitPrice) FROM raw_online_retail)
   OR ABS(Quantity) = 80995;


-- ============================================================
-- 5. CANCELLATIONS AND INVOICE PREFIXES
-- ============================================================

-- 5.1 Which invoice prefixes exist? All-digit invoices are grouped together.
SELECT CASE WHEN InvoiceNo GLOB '[0-9]*' THEN 'digit'
            ELSE SUBSTR(InvoiceNo, 1, 1) END AS prefix,
       COUNT(*) AS n_rows
FROM raw_online_retail
GROUP BY prefix
ORDER BY n_rows DESC;

-- 5.2 Do C invoices and negative quantities overlap fully?
SELECT CASE WHEN InvoiceNo LIKE 'C%' THEN 'C invoice' ELSE 'not C' END AS invoice_type,
       CASE WHEN Quantity < 0 THEN 'negative qty'
            WHEN Quantity = 0 THEN 'zero qty'
            ELSE 'positive qty' END                                    AS qty_type,
       COUNT(*) AS n_rows
FROM raw_online_retail
GROUP BY invoice_type, qty_type;

-- 5.3 Negative quantity WITHOUT a C prefix: are they all zero price and no customer?
-- If n_rows = n_zero_price = n_null_customer, other rules already remove them.
SELECT COUNT(*)                  AS n_rows,
       SUM(UnitPrice = 0)        AS n_zero_price,
       SUM(CustomerID IS NULL)   AS n_null_customer
FROM raw_online_retail
WHERE Quantity < 0 AND InvoiceNo NOT LIKE 'C%';

-- 5.4 What do those rows say in Description? (top 10)
SELECT Description,
       COUNT(*) AS n_rows
FROM raw_online_retail
WHERE Quantity < 0 AND InvoiceNo NOT LIKE 'C%'
GROUP BY Description
ORDER BY n_rows DESC
LIMIT 10;


-- ============================================================
-- 6. NON-PRODUCT STOCK CODES
-- ============================================================

-- 6.1 Which StockCodes do not look like normal 5-digit product codes?
-- Review this list by eye, some entries are real products with unusual codes.
SELECT StockCode,
       Description,
       COUNT(*)                            AS n_rows,
       ROUND(SUM(Quantity * UnitPrice), 2) AS net_revenue
FROM raw_online_retail
WHERE StockCode NOT GLOB '[0-9][0-9][0-9][0-9][0-9]*'
GROUP BY StockCode, Description
ORDER BY n_rows DESC;


-- ============================================================
-- 7. CANCELLATION MATCHING
-- ============================================================

-- 7.1 How many C rows have an exact earlier original order?
-- Needs the index: CREATE INDEX idx_raw_cust_stock ON raw_online_retail(CustomerID, StockCode)
SELECT COUNT(*) AS c_rows,
       SUM(EXISTS (SELECT 1
                   FROM raw_online_retail o
                   WHERE o.CustomerID = c.CustomerID
                     AND o.StockCode  = c.StockCode
                     AND o.Quantity   = -c.Quantity
                     AND o.InvoiceNo NOT LIKE 'C%'
                     AND o.InvoiceDate <= c.InvoiceDate)) AS matched
FROM raw_online_retail c
WHERE c.InvoiceNo LIKE 'C%' AND c.CustomerID IS NOT NULL;

-- 7.2 Cancelled value vs gross value for identified customers, product codes only
SELECT ROUND(SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN -Quantity * UnitPrice END), 2) AS cancelled_value,
       ROUND(SUM(CASE WHEN InvoiceNo NOT LIKE 'C%' AND Quantity > 0 AND UnitPrice > 0
                      THEN Quantity * UnitPrice END), 2)                           AS gross_value
FROM raw_online_retail
WHERE CustomerID IS NOT NULL
  AND UPPER(StockCode) NOT IN ('POST','DOT','M','C2','D','S','BANK CHARGES','AMAZONFEE','CRUK','B');

-- 7.3 Which customers drive the cancelled value?
SELECT CustomerID,
       ROUND(SUM(-Quantity * UnitPrice), 2) AS cancelled_value
FROM raw_online_retail
WHERE InvoiceNo LIKE 'C%'
  AND CustomerID IS NOT NULL
  AND UPPER(StockCode) NOT IN ('POST','DOT','M','C2','D','S','BANK CHARGES','AMAZONFEE','CRUK','B')
GROUP BY CustomerID
ORDER BY cancelled_value DESC
LIMIT 5;

-- 7.4 The two orders behind the biggest cancellations
SELECT InvoiceNo, InvoiceDate, CustomerID, StockCode, Quantity, UnitPrice
FROM raw_online_retail
WHERE CustomerID = 12346
   OR (CustomerID = 16446 AND ABS(Quantity) = 80995)
ORDER BY CustomerID, InvoiceDate;
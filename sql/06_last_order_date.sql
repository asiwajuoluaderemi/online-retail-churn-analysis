-- Each customer's first and most recent order date, plus order count
SELECT c.CustomerID, c.Country,
       MIN(o.InvoiceDate)          AS first_order_date,
       MAX(o.InvoiceDate)       AS last_order_date,
       COUNT(DISTINCT o.InvoiceNo) AS n_orders
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Country
ORDER BY last_order_date DESC;
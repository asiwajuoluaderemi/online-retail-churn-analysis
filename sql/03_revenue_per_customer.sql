-- Revenue per customer: total spend and number of invoices
SELECT c.CustomerID, c.Country,
       COUNT(DISTINCT o.InvoiceNo) AS n_orders,
       ROUND(SUM(o.Quantity * o.UnitPrice), 2)       AS total_revenue
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Country
ORDER BY total_revenue DESC;
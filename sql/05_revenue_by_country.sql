-- Revenue by country (identified customers only)
SELECT c.Country,
       COUNT(DISTINCT c.CustomerID)  AS n_customers,
       COUNT(DISTINCT o.InvoiceNo)   AS n_orders,
       ROUND(SUM(o.Quantity * o.UnitPrice), 2) AS total_revenue,
       ROUND(100.0 * SUM(o.Quantity * o.UnitPrice)
             / (SELECT SUM(Quantity * UnitPrice) FROM orders), 2) AS pct_of_revenue
FROM orders o
JOIN customers c ON c.CustomerID = o.CustomerID
GROUP BY c.Country
ORDER BY total_revenue DESC;
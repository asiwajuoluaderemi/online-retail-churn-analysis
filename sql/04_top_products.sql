-- Top 10 products by quantity sold
SELECT p.StockCode, p.Description,
       SUM(o.Quantity) AS total_quantity,
       ROUND(SUM(o.Quantity * o.UnitPrice), 2) AS total_revenue
FROM orders o
JOIN products p ON o.StockCode = p.StockCode
GROUP BY p.StockCode, p.Description
ORDER BY total_quantity DESC
LIMIT 10;

-- Top 10 products by revenue
SELECT p.StockCode, p.Description,
       SUM(o.Quantity) AS total_quantity,
       ROUND(SUM(o.Quantity * o.UnitPrice), 2) AS total_revenue
FROM orders o
JOIN products p ON O.StockCode = p.StockCode
GROUP BY p.StockCode, p.Description
ORDER BY total_revenue DESC
LIMIT 10;
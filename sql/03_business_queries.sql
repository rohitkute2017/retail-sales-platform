-- =====================================================
-- Business Analysis Queries — Retail Sales Intelligence Platform
-- =====================================================

USE retail_sales;

-- Query 1: Total Sales, Profit, and Profit Margin by Year
SELECT 
    year,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM superstore
GROUP BY year
ORDER BY year ASC;


-- Query 2: Top 10 Most Profitable Products
SELECT 
    product_name,
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM superstore
GROUP BY product_name, category
ORDER BY total_profit DESC
LIMIT 10;


-- Query 3: Loss-Making Products
SELECT
    product_name,
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM superstore
GROUP BY product_name, category
HAVING total_profit < 0
ORDER BY total_profit ASC;


-- Query 4: Sales and Profit by Region and Segment
SELECT 
    region,
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM superstore
GROUP BY region, segment
ORDER BY total_profit DESC;


-- Query 5: Discount Impact on Profit
-- Note: bands match 02_eda.ipynb's discount_band definition (0-10%, 10-30%, 30-50%, >50%)
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount > 0 AND discount <= 0.10 THEN '0-10%'
        WHEN discount > 0.10 AND discount <= 0.30 THEN '10-30%'
        WHEN discount > 0.30 AND discount <= 0.50 THEN '30-50%'
        ELSE '>50%'
    END AS discount_band,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS average_profit_margin
FROM superstore
GROUP BY discount_band
ORDER BY total_profit DESC;


-- Query 6: Monthly Sales Trend
SELECT
    year,
    order_month,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY year, order_month
ORDER BY year ASC, order_month ASC;
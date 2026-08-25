-- =====================================================
-- Gold Layer: Medallion Architecture (Silver View + Star Schema)
-- Retail Sales Intelligence Platform
-- =====================================================

-- =====================================================
-- SILVER LAYER
-- =====================================================
-- View adds business logic columns on top of the raw superstore table:
-- profit_status, ship_performance, discount_tier. Excludes sales <= 0 rows.
CREATE OR REPLACE VIEW silver_superstore AS
SELECT 
    *,
    CASE WHEN profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    CASE 
        WHEN days_to_ship <= 2 THEN 'Fast'
        WHEN days_to_ship BETWEEN 3 AND 5 THEN 'Standard'
        ELSE 'Slow'
    END AS ship_performance,
    CASE 
        WHEN discount = 0 THEN 'No'
        WHEN discount > 0 AND discount <= 0.10 THEN 'Low'
        WHEN discount > 0.10 AND discount <= 0.30 THEN 'Medium'
        ELSE 'High'
    END AS discount_tier
FROM superstore
WHERE sales > 0;


-- =====================================================
-- GOLD LAYER — DIMENSION TABLES
-- =====================================================

-- gold_dim_date: continuous calendar (required for Power BI Date Table).
-- Built via recursive CTE spanning the full order_date range.
-- Requires an increased recursion depth for a multi-year range.
SET SESSION cte_max_recursion_depth = 2000;

CREATE TABLE gold_dim_date AS
WITH RECURSIVE date_range AS (
    SELECT MIN(order_date) AS order_date FROM silver_superstore
    UNION ALL
    SELECT DATE_ADD(order_date, INTERVAL 1 DAY)
    FROM date_range
    WHERE order_date < (SELECT MAX(order_date) FROM silver_superstore)
)
SELECT 
    order_date,
    YEAR(order_date) AS year,
    MONTH(order_date) AS order_month,
    QUARTER(order_date) AS order_quarter,
    WEEK(order_date) AS weeknum
FROM date_range;

ALTER TABLE gold_dim_date
ADD COLUMN date_id INT AUTO_INCREMENT PRIMARY KEY FIRST;


-- gold_dim_product: one row per product_id.
-- Note: raw data had duplicate product_id rows with inconsistent name/category
-- text (same ID, slightly different text) — deduplicated using GROUP BY + MIN().
CREATE TABLE gold_dim_product AS
SELECT 
    product_id,
    MIN(product_name) AS product_name,
    MIN(category) AS category,
    MIN(sub_category) AS sub_category
FROM silver_superstore
GROUP BY product_id;

ALTER TABLE gold_dim_product
ADD COLUMN product_key INT AUTO_INCREMENT PRIMARY KEY FIRST;


-- gold_dim_customer: one row per customer_id (no duplicates found).
CREATE TABLE gold_dim_customer AS
SELECT 
    DISTINCT customer_id, customer_name, segment
FROM silver_superstore;

ALTER TABLE gold_dim_customer
ADD COLUMN customer_key INT AUTO_INCREMENT PRIMARY KEY FIRST;


-- gold_dim_geography: one row per city.
-- Note: same duplicate-key issue as gold_dim_product — deduplicated on city
-- using GROUP BY + MIN() for the other geography fields.
CREATE TABLE gold_dim_geography AS
SELECT 
    MIN(country) AS country,
    city,
    MIN(state) AS state,
    MIN(region) AS region,
    MIN(market) AS market,
    MIN(market2) AS market2
FROM silver_superstore
GROUP BY city;

ALTER TABLE gold_dim_geography
ADD COLUMN geography_key INT AUTO_INCREMENT PRIMARY KEY FIRST;


-- =====================================================
-- GOLD LAYER — FACT TABLE
-- =====================================================

-- gold_fact_orders: one row per order, FKs to all four dimensions.
-- Note: an earlier join on gold_dim_date's original (non-continuous, 
-- non-deduplicated) version caused row fan-out; rebuilding the date 
-- dimension as a clean continuous calendar resolved it.
CREATE TABLE gold_fact_orders AS
SELECT 
    ss.order_id,
    gdd.date_id AS date_key,
    gdp.product_key,
    gdc.customer_key,
    gdg.geography_key,
    ss.sales,
    ss.profit,
    ss.quantity,
    ss.discount,
    ss.shipping_cost,
    ss.days_to_ship,
    ss.order_priority,
    ss.ship_mode,
    ss.ship_performance,
    ss.discount_tier,
    ss.profit_status
FROM silver_superstore ss
LEFT JOIN gold_dim_date gdd ON ss.order_date = gdd.order_date
LEFT JOIN gold_dim_product gdp ON ss.product_id = gdp.product_id
LEFT JOIN gold_dim_customer gdc ON ss.customer_id = gdc.customer_id
LEFT JOIN gold_dim_geography gdg ON ss.city = gdg.city;

ALTER TABLE gold_fact_orders
ADD COLUMN order_key INT AUTO_INCREMENT PRIMARY KEY FIRST;


-- =====================================================
-- VERIFICATION
-- =====================================================
SELECT COUNT(*) FROM gold_dim_date;
SELECT COUNT(*) FROM gold_dim_product;
SELECT COUNT(*) FROM gold_dim_customer;
SELECT COUNT(*) FROM gold_dim_geography;
SELECT COUNT(*) FROM gold_fact_orders;
SELECT * FROM gold_fact_orders LIMIT 5;


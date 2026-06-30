-- Creating view
Create View silver_superstore as 
Select 
	*    
From superstore
where sales > 0;

-- Creating dimension table gold_dim_date
Create Table gold_dim_date as
Select 
	   distinct
	   order_date,
	   year,
       order_month,
       order_quarter,
       weeknum
	
From silver_superstore;

-- Adding Primary Key to gold_dim_date table

Alter table gold_dim_date
add column date_id int auto_increment primary key first;
Select * from gold_dim_date limit 5;

-- Creating Dimension Table dim_product
Create Table dim_product as
Select
	distinct
	product_id,
    product_name,
    category,
    sub_category
    
From silver_superstore;

-- Adding Primary Key to gold_dim_date table
Alter Table dim_product
add column product_key int auto_increment primary key first;

-- Renamng table name to gold_dim_product
Rename table dim_product to gold_dim_product;

Select * From  gold_dim_product
limit 5;

-- creating dimension table gold_dim_customer
Create Table gold_dim_customer as
Select 
	distinct
    customer_id,
    customer_name,
    segment
    
From silver_superstore;

-- Adding Primary Key to gold_dim_date table
Alter Table gold_dim_customer
add column customer_key int auto_increment primary key first;  

Select * From gold_dim_customer
limit 5;

Show tables in retail_sales;

-- Creating dimensional gold_dim_geography table

Create Table gold_dim_geography as
Select 
	distinct
    country,
	city,
    state,
    region,
    market,
    market2
    
From silver_superstore;

-- Adding Primary Key 
Alter Table gold_dim_geography
Add column geography_key int auto_increment primary key first;

Select * From gold_dim_geography limit 5;


-- Creating fact table gold_fact_orders
Create Table gold_fact_orders
Select 
	distinct
    order_id,
    gdd.date_id as date_key,
    gdp.product_key as product_key,
    gdc.customer_key as customer_key,
    gdg.geography_key as geography_key,
    sales, 
    profit,
    quantity,
    discount,
    shipping_cost,
    days_to_ship,
    order_priority,
    ship_mode
    
From silver_superstore ss
left Join gold_dim_date gdd
on  ss.order_date = gdd.order_date
left join gold_dim_product gdp
on gdp.product_id = ss.product_id
left join gold_dim_customer gdc
on gdc.customer_id = ss.customer_id
left join gold_dim_geography gdg
on gdg.city = ss.city
and gdg.state = ss.state
and gdg.country = ss.country;

Select count(*) From gold_fact_orders;


-- DROP and recreate gold_fact_orders — fix JOIN fan-out on gold_dim_date
DROP TABLE gold_fact_orders;

Create Table gold_fact_orders
Select 
	distinct
    order_id,
    gdd.date_id as date_key,
    gdp.product_key as product_key,
    gdc.customer_key as customer_key,
    gdg.geography_key as geography_key,
    sales, 
    profit,
    quantity,
    discount,
    shipping_cost,
    days_to_ship,
    order_priority,
    ship_mode
    
From silver_superstore ss
left Join gold_dim_date gdd
ON gdd.order_date = ss.order_date
AND gdd.year = ss.year
AND gdd.order_month = ss.order_month
AND gdd.order_quarter = ss.order_quarter
AND gdd.weeknum = ss.weeknum
left join gold_dim_product gdp
on gdp.product_id = ss.product_id
left join gold_dim_customer gdc
on gdc.customer_id = ss.customer_id
left join gold_dim_geography gdg
on gdg.city = ss.city
and gdg.state = ss.state
and gdg.country = ss.country;

Select count(*) From gold_fact_orders;

-- Diagnosing fan-out issue in gold_dim_date — checking for duplicate order_date in gold_dim_date
SELECT order_date, COUNT(*) as cnt
FROM gold_dim_date
GROUP BY order_date
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 10;


-- Diagnosing fan-out issue in gold_fact_orders — checking for duplicate product_id in gold_dim_product
SELECT product_id, COUNT(*) as cnt
FROM gold_dim_product
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 10;


-- Checking what's causing duplicate product_ids in gold_dim_product
SELECT product_id, product_name, category, sub_category, COUNT(*) as cnt
FROM gold_dim_product
GROUP BY product_id, product_name, category, sub_category
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 5;


-- Check if product_id alone is unique in gold_dim_product
SELECT COUNT(*) as total_rows,
       COUNT(DISTINCT product_id) as unique_product_ids
FROM gold_dim_product;

-- Rebuild gold_dim_product — one row per product_id using GROUP BY
DROP TABLE gold_dim_product;

CREATE TABLE gold_dim_product AS
SELECT 
    product_id,
    MIN(product_name) as product_name,
    MIN(category) as category,
    MIN(sub_category) as sub_category
FROM silver_superstore
GROUP BY product_id;

ALTER TABLE gold_dim_product
ADD COLUMN product_key INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Verifying
SELECT COUNT(*) as total_rows,
       COUNT(DISTINCT product_id) as unique_product_ids
FROM gold_dim_product;

-- Checking gold_dim_customer
Select 
	count(*) as total_rows,
	count( distinct customer_id) as unique_customers
From gold_dim_customer;

-- Checking gold_dim_geography
Select 
	count(*) as total_rows,
    count(distinct city, state, country) as unique_geographies
From gold_dim_geography;

-- Rebuild gold_dim_geography — fix duplicate geographies using GROUP BY
DROP TABLE gold_dim_geography;

CREATE TABLE gold_dim_geography AS
SELECT 
    MIN(country) as country,
    city,
    MIN(state) as state,
    MIN(region) as region,
    MIN(market) as market,
    MIN(market2) as market2
FROM silver_superstore
GROUP BY city;

ALTER TABLE gold_dim_geography
ADD COLUMN geography_key INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Verify
SELECT COUNT(*) as total_rows,
       COUNT(DISTINCT city) as unique_cities
FROM gold_dim_geography;


-- Rebuild gold_fact_orders — all dimension tables now clean
DROP TABLE gold_fact_orders;

CREATE TABLE gold_fact_orders AS
SELECT 
    ss.order_id,
    gdd.date_id as date_key,
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
    ss.ship_mode
FROM silver_superstore ss
LEFT JOIN gold_dim_date gdd ON ss.order_date = gdd.order_date
LEFT JOIN gold_dim_product gdp ON ss.product_id = gdp.product_id
LEFT JOIN gold_dim_customer gdc ON ss.customer_id = gdc.customer_id
LEFT JOIN gold_dim_geography gdg ON ss.city = gdg.city;

-- Verify row count
SELECT COUNT(*) FROM gold_fact_orders;

-- Adding primary key to gold_fact_orders
ALTER TABLE gold_fact_orders
ADD COLUMN order_key INT AUTO_INCREMENT PRIMARY KEY FIRST;

SELECT * FROM gold_fact_orders LIMIT 5;


-- Rebuilding silver_superstore to add business logic columns (profit_status, ship_performance, discount_tier) per project plan
 
    Drop view silver_superstore;
    Create view silver_superstore as
    Select 
		*,
        Case When profit > 0 then "Profit" else "Loss" End as profit_status
        
	From superstore
    Where sales > 0;
    
  -- Rebuilding silver_superstore 
  Create or Replace view silver_superstore as
  Select 
	*,
    Case When profit > 0 then "Profit" else "Loss" End as profit_status,
    (Case When days_to_ship <= 2 then "Fast"
         When days_to_ship >= 3 and days_to_ship <= 5 then "Standard"
         else "Slow" end ) ship_performance,
	(Case when discount = 0 then "No"
		 When discount > 0 and discount <= 0.10 then "Low"
         When discount > 0.10 and discount <= 0.30 then "Medium"
         When discount > 0.30 then "High" end) discount_tier
         
	From superstore
    Where sales > 0;
    
  -- Rebuilding fact table gold_fact_orders
  Drop Table gold_fact_orders;
  CREATE TABLE gold_fact_orders AS
SELECT 
    ss.order_id,
    gdd.date_id as date_key,
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

Select count(*) From gold_fact_orders;

-- Adding Primary Key 
Alter Table gold_fact_orders
Add column order_key int auto_increment Primary key First;


-- Checking Tables
Show Tables In retail_sales; 

-- Cleanup: removing leftover dim_product table (superseded by gold_dim_product)
DROP TABLE dim_product;

-- Rebuilding gold_dim_date as a continuous calendar table (required for Power BI Date Table)
DROP TABLE gold_dim_date;

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
    YEAR(order_date) as year,
    MONTH(order_date) as order_month,
    QUARTER(order_date) as order_quarter,
    WEEK(order_date) as weeknum
FROM date_range;

ALTER TABLE gold_dim_date
ADD COLUMN date_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

SELECT COUNT(*) FROM gold_dim_date;

-- Increase recursion limit to handle 4-year date range
SET SESSION cte_max_recursion_depth = 2000;

-- Rebuilding gold_dim_date as a continuous calendar table
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
    YEAR(order_date) as year,
    MONTH(order_date) as order_month,
    QUARTER(order_date) as order_quarter,
    WEEK(order_date) as weeknum
FROM date_range;

ALTER TABLE gold_dim_date
ADD COLUMN date_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

SELECT COUNT(*) FROM gold_dim_date;

-- Rebuilding gold_fact_orders to re-link with new continuous gold_dim_date
DROP TABLE gold_fact_orders;

CREATE TABLE gold_fact_orders AS
SELECT 
    ss.order_id,
    gdd.date_id as date_key,
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

SELECT COUNT(*) FROM gold_fact_orders;

-- Rebuilding gold_dim_date as a continuous calendar table (required for Power BI Date Table)
DROP TABLE gold_dim_date;

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
    YEAR(order_date) as year,
    MONTH(order_date) as order_month,
    QUARTER(order_date) as order_quarter,
    WEEK(order_date) as weeknum
FROM date_range;

-- Increase recursion limit to handle 4-year date range
SET SESSION cte_max_recursion_depth = 2000;

-- Rebuilding gold_dim_date as a continuous calendar table
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
    YEAR(order_date) as year,
    MONTH(order_date) as order_month,
    QUARTER(order_date) as order_quarter,
    WEEK(order_date) as weeknum
FROM date_range;

ALTER TABLE gold_dim_date
ADD COLUMN date_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

SELECT COUNT(*) FROM gold_dim_date;

-- Rebuilding gold_fact_orders to re-link with new continuous gold_dim_date
DROP TABLE gold_fact_orders;

CREATE TABLE gold_fact_orders AS
SELECT 
    ss.order_id,
    gdd.date_id as date_key,
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

SELECT COUNT(*) FROM gold_fact_orders;
	
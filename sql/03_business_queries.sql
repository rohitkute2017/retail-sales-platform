Use retail_sales;

Select * From superstore;

-- 1. Total Sales, Profit and profit Margin by Year

Select 
	year,
    Round(Sum(sales),2) as total_sales,
    Round(Sum(profit),2) as total_profit,
    round(sum(profit)/sum(sales) * 100,2) as profit_margin_pct
    
from superstore
group by year
order by year ASC;


-- 2. Top 10 Most Profitable Products

Select 
	product_name,
    Category,
    Round(sum(sales),2) as total_sales,
    Round(sum(profit),2) as total_profit,
    Round(sum(profit)/sum(sales)*100,2) as profit_margin_pct
    
From superstore
group by product_name, category
order by total_profit Desc
Limit 10;


-- 3. Loss Making Products

Select
	product_name,
    category,
    Round(sum(sales),2) as total_sales,
    Round(sum(profit),2) as total_profit,
    Round(sum(profit)/sum(sales)*100,2) as profit_margin_pct
    
From superstore
group by product_name, category
having total_profit < 0 
order by total_profit Asc;


-- 4. Sales and Profit by Region and Segment

Select 
	region,
    segment,
    Round(sum(sales),2) as total_sales,
    Round(sum(profit),2) as total_profit,
    Round(sum(profit)/sum(sales)*100,2) as profit_margin_pct
    
From superstore
group by region, segment
order by total_profit DESC;

-- 5. Discount Impact On Profit

 Select 
	    (case 
        when discount = 0 then "No Discount"
        when discount > 0 and discount <= 0.10 then "1-10%"
        when discount > 0.10 and discount <= 0.30 then "11-30%"
        when discount > 0.30 and discount <= 0.50 then "31-50%"
        when discount > 0.50 then  ">50%"
        end
        ) as discount_band,
        
        Round(sum(profit),2) as total_profit,
        Round(sum(profit)/sum(sales)*100,2) as average_profit_margin
        
	From superstore
    group by discount_band
    order by total_profit Desc;
        
        
-- 6. Monthly Sales Trend

Select
	year,
    order_month,
    Round(sum(sales),2) as total_sales,
    Round(sum(profit),2) as total_profit
    
From superstore
group by year, order_month
Order by year Asc, order_month Asc;
        
    
    


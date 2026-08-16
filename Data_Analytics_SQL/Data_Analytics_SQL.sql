-- Q1 Change Over time

SELECT YEAR(order_date) as order_year, MONTH(order_date) as order_month, 
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM `datawarehouseanalytics`.`gold.fact_sales`
WHERE YEAR(order_date) IS NOT NULL AND MONTH(order_date) IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);

-- Q2 Calculate the total sales per month
-- and cummulative total of sales over time
SELECT order_date, total_sales, 
SUM(total_sales) OVER(PARTITION BY order_date ORDER BY order_date) as cumulative_sales,
ROUND(AVG(avg_price) OVER(PARTITION BY order_date ORDER BY order_date),2) as moving_avg_price
FROM(
SELECT date_format(order_date, '%Y-%m-01') as order_date, 
SUM(sales_amount) as total_sales,
AVG(price) as avg_price
FROM `datawarehouseanalytics`.`gold.fact_sales`
WHERE date_format(order_date, '%Y-%m-01')IS NOT NULL
GROUP BY date_format(order_date, '%Y-%m-01')) AS monthly_sales
ORDER BY order_date;

-- Q3 Analyze the yearly performance of products by comparing their sales
-- to both the average sales performance of the product and the previous year's sales
WITH yearly_product_sales AS (
SELECT YEAR(f.order_date) as order_year,
p.product_name, 
SUM(f.sales_amount) as current_sales
FROM `datawarehouseanalytics`.`gold.fact_sales` f
LEFT JOIN `datawarehouseanalytics`.`gold.dim_products` p
ON f.product_key=p.product_key
WHERE YEAR(f.order_date) IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
order_year,product_name, current_sales,
ROUND(AVG(current_sales) OVER(PARTITION BY product_name),0) as avg_sales,
current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name),0) as diff_avg,
CASE WHEN current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name),0) > 0 THEN "Above Avg"
	 WHEN current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name),0) < 0 THEN "Below Avg"
     ELSE "Avg"
END avg_change,
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales,
current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN "Increase"
	 WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN "Decrease"
     ELSE "No Change"
END py_change
FROM yearly_product_sales
order by product_name, order_year;

-- Q4 Which categories contribute the most to overall sales?
WITH category_sales AS(
SELECT category, SUM(sales_amount) total_sales
FROM `datawarehouseanalytics`.`gold.fact_sales` f
LEFT JOIN `datawarehouseanalytics`.`gold.dim_products` p
ON f.product_key=p.product_key
GROUP BY category)

SELECT category, total_sales, SUM(total_sales) OVER() overall_sales,
CONCAT(ROUND((total_sales/ SUM(total_sales) OVER())*100,2), "%") AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

-- Q5 Segment products into cost ranges and count how many products
-- fall into each segment
WITH product_segments AS(
SELECT product_key, product_name, cost,
CASE WHEN cost < 100 THEN "Below 100"
	 WHEN cost BETWEEN 100 AND 500 THEN "100-500"
     WHEN cost BETWEEN 500 AND 1000 THEN "500-1000"
     ELSE "Above 1000"
END cost_range
FROM `datawarehouseanalytics`.`gold.dim_products`
)
SELECT cost_range, COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

-- Q6 Group customers into 3segments based on their spending behaviour:
-- VIP: Customers with atleast 12 months of history and spending more than 5,000
-- Regular: Customers with atleast 12 months of history and spending 5,000 or less
-- New: Customers with a lifespan less than 12 months
-- And find total no of customers by each group

WITH customer_spending AS (
SELECT c.customer_key, SUM(f.sales_amount) AS total_spending, 
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM `datawarehouseanalytics`.`gold.fact_sales` f
LEFT JOIN `datawarehouseanalytics`.`gold.dim_customers` c
ON f.customer_key=c.customer_key
GROUP BY c.customer_key
)
SELECT
customer_segment, COUNT(customer_key) AS total_customers
FROM(
SELECT customer_key,
CASE WHEN lifespan > 12 AND total_spending >5000 THEN "VIP"
	 WHEN lifespan >= 12 AND total_spending <=5000 THEN "Regular"
     ELSE "New"
END customer_segment
FROM customer_spending) t
GROUP BY customer_segment
ORDER BY total_customers DESC;

/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/
-- 1) Base Query: Retrives core columns from tables
`gold.report_customers`CREATE VIEW `datawarehouseanalytics`.`gold.report_customers` AS
WITH base_query AS(
SELECT  f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
TIMESTAMPDIFF(year, c.birthdate, CURDATE()) age
FROM `datawarehouseanalytics`.`gold.fact_sales` f
LEFT JOIN `datawarehouseanalytics`.`gold.dim_customers` c
ON c.customer_key=f.customer_key
WHERE order_date IS NOT NULL)

, customer_aggregation AS (
SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order_date,
TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY
customer_key,
customer_number,
customer_name,
age
)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age < 20 THEN "Under 20"
	 WHEN age between 20 and 29 THEN "20-29"
     WHEN age between 30 and 39 THEN "30-39"
	 WHEN age between 40 and 49 THEN "40-49"
     ELSE "50 and above"
END AS age_group,
CASE WHEN lifespan > 12 AND total_sales >5000 THEN "VIP"
	 WHEN lifespan >= 12 AND total_sales <=5000 THEN "Regular"
     ELSE "New"
END customer_segment,
TIMESTAMPDIFF(month,last_order_date,CURDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products,
last_order_date,
lifespan,
CASE WHEN total_sales=0 THEN 0
     ELSE ROUND(total_sales/total_orders,0)
END AS avg_order_value,
CASE WHEN lifespan = 0 THEN total_sales
     ELSE ROUND(total_sales/lifespan,2)
END AS avg_monthly_spend
FROM customer_aggregation;

/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================


CREATE VIEW `datawarehouseanalytics`.`gold.report_products` AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
    SELECT
	    f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM `datawarehouseanalytics`.`gold.fact_sales` f
    LEFT JOIN `datawarehouseanalytics`.`gold.dim_products` p
	ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	TIMESTAMPDIFF(MONTH, last_sale_date, CURDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
	END AS avg_monthly_revenue

FROM product_aggregations;







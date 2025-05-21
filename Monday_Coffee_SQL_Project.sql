-- Monday Coffee -- Data Analysis

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;


-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT
    city_name,
	ROUND(
			(population * 0.25)/1000000,
			 2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC

-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date) = 2023
	AND
	EXTRACT(QUARTER FROM sale_date) = 4


SELECT
    ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
WHERE
    EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    p.product_name,
	COUNT(sale_id) as total_orders
FROM products as p
LEFT JOIN sales as s
ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC

-- Q.4
-- Total Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city and total sales
-- no. of cx in each these city

SELECT
    ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_per_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
GROUP BY 1
ORDER BY 2 DESC

-- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS
(
	SELECT
        city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers_in_millions
	FROM city
),
customers_table AS
(
	SELECT
        ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON c.city_id = ci.city_id
	GROUP BY 1
)
SELECT
    city_table.city_name,
	city_table.coffee_consumers_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN customers_table
ON city_table.city_name = customers_table.city_name

-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM
(
	SELECT
	    ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as ranking
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON c.city_id = ci.city_id
	GROUP BY 1,2
) AS t1
WHERE ranking <= 3

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;

SELECT
    ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
WHERE
   s.product_id IN (1, 2, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14)
GROUP BY 1

-- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_sales AS
(
	SELECT
	    ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT c.customer_id) as total_cx,
	    ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT c.customer_id)::numeric
				,2) as avg_sale_per_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON c.city_id = ci.city_id
	GROUP BY 1
	ORDER BY 4 DESC
),
city_rent AS
(
	SELECT
	    ci.city_name,
		ci.estimated_rent,
		COUNT(DISTINCT c.customer_id) as total_cx,
	    ROUND(
			  	(ci.estimated_rent)::numeric/
				  	COUNT(DISTINCT c.customer_id)::numeric
				,2) as avg_rent_per_cx
	FROM city as ci
	JOIN customers as c
	ON ci.city_id = c.city_id
	GROUP BY 1,2
	ORDER BY 4 DESC
)
SELECT
    cs.city_name,
	cs.total_revenue,
	cs.total_cx,
	cr.estimated_rent,
	cs.avg_sale_per_cx,
	cr.avg_rent_per_cx
FROM city_sales as cs
JOIN city_rent as cr
ON cs.city_name = cr.city_name
GROUP BY 1,2,3,4,5,6
ORDER BY 5 DESC

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS
(
	SELECT
	    ci.city_name,
		EXTRACT(YEAR FROM s.sale_date) as year,
		EXTRACT(MONTH FROM s.sale_date) as month,
		SUM(s.total) as total_sales
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON c.city_id = ci.city_id
	GROUP BY 1,2,3
	ORDER BY 1,2,3
),
growth_rate AS
(
	SELECT
	    city_name,
		year,
		month,
		total_sales as cr_month_sales,
		LAG(total_sales, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sales
	FROM monthly_sales
)
SELECT
    city_name,
	year,
	month,
	cr_month_sales,
	last_month_sales,
	ROUND(
			((cr_month_sales - last_month_sales)::numeric / last_month_sales::numeric) * 100
			,2) as mnthly_sales_growth_pct
FROM growth_rate
WHERE
   last_month_sales IS NOT NULL

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale,
-- total rent, total customers, estimated coffee consumer

WITH city_sales AS
(
	SELECT
	    ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT c.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT c.customer_id)::numeric
				,2) as avg_sale_per_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON c.city_id = ci.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent AS
(
	SELECT
	    city_name,
		estimated_rent as total_rent,
		ROUND(
				(population * 0.25)/1000000
				,2) as estimated_coffee_consumers_in_millions
	FROM city
)
SELECT
    cs.city_name,
	cs.total_revenue,
	cr.total_rent,
	cs.total_cx,
	cr.estimated_coffee_consumers_in_millions,
	cs.avg_sale_per_cx,
	ROUND(
			cr.total_rent::numeric/
				cs.total_cx::numeric
			,2) as avg_rent_per_cx
FROM city_sales as cs
JOIN city_rent as cr
ON cs.city_name = cr.city_name
ORDER BY 2 DESC

/*
-- Recommendations

City 1: Pune
  1. Highest total revenue (1.26M), indicating strong sales performance.
  2. Average sales per customer is high at 24.2k.
  3. Average rent per customer is also moderate at 294.

City 2: Delhi
  1. Largest estimated coffee-consuming population (7.75 million).
  2. High total number of customers (68).
  3. Average rent per customer is manageable at 330.

City 3: Jaipur
  1. Highest number of customers (69), showing strong reach.
  2. Average rent per customer is very low at 156.
  3. Average sales per customer is moderate at 11.6k.
*/

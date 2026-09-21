-- MONDAY COFFEE

/* The business aims to expand by opening 3 coffee shops in India's top 3 major cities. Since its
launch in 2023 the business has sold products online and recieved an overwhelming response from several 
cities. Your job is to analyse the data and provide insights to recommend the top 3 cities for this
expansion. */

/* Supporting questions:
	- Which cities have the best market potential?
	- Where are people already buying from Monday Coffee?
	- Which cities are generating the most revenue?
	- Which cities look commercially attractive relative to predicted rent?
*/

-- Monday Coffee SCHEMAS

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

-- Import Rules
-- 1st import to city
-- 2nd import to products
-- 3rd import to customers
-- 4th import to sales


CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- END of SCHEMAS
/* =================================================================================================== */

--Reports and Data Analysis:

/* How many people are estimated to consume coffee in each city given that roughly 25% of the 
population does? */

SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) as estimated_coffee_consumers_millions,
	city_rank
FROM city
ORDER BY 2 DESC

/* Top 5 (in millions): 
"Delhi"		7.75
"Mumbai"	5.10
"Kolkata"	3.73
"Bangalore"	3.08
"Chennai"	2.78 */

/* =================================================================================================== */

-- What is the total revenue generated from all cities in the last quarter of 2023?
SELECT 
	ci.city_name,
	SUM(s.total) as total_Q4_2023
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id

WHERE
	EXTRACT (QUARTER FROM s.sale_date) = 4
AND	
	EXTRACT (YEAR FROM s.sale_date) = 2023

GROUP BY 1
ORDER BY 2 DESC

/* TOP 5: (Q4 2023)
"Pune"	434330
"Chennai"	302500
"Bangalore"	270780
"Jaipur"	248580
"Delhi"	238490 */

/* =================================================================================================== */

-- How many units of each coffee product have been sold?

SELECT
	p.product_name,
	COUNT(s.sale_id) as units_sold
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
/* Top 5 products and figures:
	- Cold Brew Coffee Pack (6 Bottles)
		1326
	- Ground Esporesso Coffee (250g)
		1271
	- Instant Coffee Powder (100g)
		1226
	- Coffee Beans (500g)
		1218
	- Tote Bag with Coffee Design
		776
*/

/* =================================================================================================== */

-- What is the average sales amount per customer in each city?
SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT (DISTINCT s.customer_id) as total_customers,
	ROUND(
		SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id), 2) as average_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
GROUP BY 1
ORDER BY 4 DESC

/* Top 5 Cities By Average Customer Spend
	Pune
		24197.88
	Chennai
		22479.05
	Bangalore
		11644.20
	Jaipur
		11644.20
	Delhi
"SQL_P2_Library"		11035.59
*/

/* =================================================================================================== */

-- Provide a list of cities along with their populations and estimated coffee consumers.
WITH city_table as
(SELECT
	city_name,
	population,
	ROUND(population * 0.25/1000000, 2) as coffee_consumers_millions
FROM city),

customers_table
AS
(SELECT
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id 
GROUP BY 1 )

SELECT
	ct.city_name,
	ct.population,
	ct. coffee_consumers_millions,
	cit.unique_cx
FROM city_table as ct
JOIN
customers_table as cit
ON cit.city_name = ct.city_name 
ORDER BY 3 DESC

/* Top 5 cities by estimated coffee consumers (in millions)
	Delhi
		7.75
	Mumbai
		5.10
	Kolkata
		3.73
	Bangalore
		3.08
	Chennai
		2.78
*/

/* =================================================================================================== */

-- What are the top 3 selling products in each city based on sales volume?
WITH product_sales AS
(
    SELECT
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS sales_volume
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON c.city_id = ci.city_id
    JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY
        ci.city_name,
        p.product_name
),

ranked_products AS
(
    SELECT
        city_name,
        product_name,
        sales_volume,
        RANK() OVER (
            PARTITION BY city_name
            ORDER BY sales_volume DESC
        ) AS product_rank
    FROM product_sales
)

SELECT
    city_name,
    product_name,
    sales_volume
FROM ranked_products
WHERE product_rank <= 3
ORDER BY
    city_name,
    product_rank;

/* Top 3 product in each city by volume
	Ahmedabad
		Cold Brew Coffee Pack (6 Bottles)
			40
		Coffee Beans (500g)
			35
		Instant Coffee Powder (100g)
			26
	Bangalore
		Cold Brew Coffee Pack (6 Bottles)
			197
		Ground Espresso Coffee (250g)
			167
		Instant Coffee Powder (100g)
			150
	Chennai
		Cold Brew Coffee Pack (6 Bottles)
			192
		Coffee Beans (500g)
			181
		Instant Coffee Powder (100g)
			172
	Delhi
		Ground Espresso Coffee (250g)
			183
		Instant Coffee Powder (100g)
			170
		Coffee Beans (500g)
			161
	Hyderabad
		Instant Coffee Powder (100g)
			36
		Cold Brew Coffee Pack (6 Bottles)
			28
		Ground Espresso Coffee (250g)
			27
	Indore
		Instant Coffee Powder (100g)
			33
		Cold Brew Coffee Pack (6 Bottles)
			26
		Ground Espresso Coffee (250g)
			26
	Jaipur
		Cold Brew Coffee Pack (6 Bottles)
			178
		Coffee Beans (500g)
			175
		Instant Coffee Powder (100g)
			170
	Kanpur
		Cold Brew Coffee Pack (6 Bottles)
			57
		Ground Espresso Coffee (250g)
			55
		Coffee Beans (500g)
			50
	Kolkata
		Ground Espresso Coffee (250g)
			45
		Cold Brew Coffee Pack (6 Bottles)
			44
		Coffee Beans (500g)
			38
	Lucknow
		Instant Coffee Powder (100g)
			28
		Coffee Beans (500g)
			25
		Cold Brew Coffee Pack (6 Bottles)
			23
		Ground Espresso Coffee (250g)
			23
	Mumbai
		Ground Espresso Coffee (250g)
			62
		Instant Coffee Powder (100g)
			60
		Cold Brew Coffee Pack (6 Bottles)
			53
	Nagpur
		Ground Espresso Coffee (250g)
			39
		Instant Coffee Powder (100g)
			29
		Coffee Beans (500g)
			28
		Cold Brew Coffee Pack (6 Bottles)
			28
	Pune
		Cold Brew Coffee Pack (6 Bottles)
			259
		Ground Espresso Coffee (250g)
			254
		Instant Coffee Powder (100g)
			245
	Surat
		Coffee Beans (500g)
			48
		Cold Brew Coffee Pack (6 Bottles)
			45
		Ground Espresso Coffee (250g)
			41
*/

/* =================================================================================================== */

-- How many unique customers are there in each city who have purchased coffee products? 
SELECT 
	ci.city_name,
	COUNT (DISTINCT c.customer_id) as unique_cx
	
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1

/* 
	"Ahmedabad"	
		23
	"Bangalore"	
		39
	"Chennai"	
		42
	"Delhi"	
		68
	"Hyderabad"	
		21
	"Indore"	
		21
	"Jaipur"	
		69
	"Kanpur"	
		35
	"Kolkata"	
		28
	"Lucknow"	
		21
	"Mumbai"	
		27
	"Nagpur"	
		24
	"Pune"	
		52
	"Surat"	
		27
*/

/* =================================================================================================== */

-- Find each city and their average sale per customer and avg rent per customer
WITH city_table
AS
(SELECT
	ci.city_name,
	COUNT (DISTINCT s.customer_id) as total_customers,
	ROUND(
		SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id), 2) as average_revenue
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
GROUP BY 1),

city_rent 
AS
(SELECT  
	city_name, 
	estimated_rent
FROM city)

SELECT
	cr.city_name, 
	cr.estimated_rent,
	ct.total_customers,
	ct.average_revenue,
	ROUND (cr.estimated_rent::NUMERIC/ct.total_customers, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name=ct.city_name

/* Average rent and sale per customer */

/* =================================================================================================== */

/* Sales growth rate: Calculate the percentage growth (or decline) in sales over different
time periods (monthly). */
WITH
mothly_sales
AS
(SELECT 
	ci.city_name,
	EXTRACT(MONTH FROM sale_date) as month,
	EXTRACT (YEAR FROM sale_date) as year,
	SUM(s.total) as total_sale
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2, 3
ORDER BY 1, 3, 2 ASC	
),
growth_ratio
AS
	(SELECT
		city_name,
		month,
		year,
		total_sale as cr_month_sale,
		LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
	FROM mothly_sales
	)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
	(cr_month_sale - last_month_sale)::numeric/last_month_sale::numeric*100,
		2) as percent_increase
FROM growth_ratio
WHERE last_month_sale IS NOT NULL

/* =================================================================================================== */

/* Identify top 3 city based on highest sales. Return the city name, total sale, total rent, total customers and
estimated coffee consumers */
WITH city_table
AS
(SELECT
	ci.city_name,
	COUNT (DISTINCT s.customer_id) as total_customers,
	ROUND(
		SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id), 2) as average_revenue
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
GROUP BY 1),

city_rent 
AS
(SELECT  
	city_name, 
	estimated_rent,
	population * 0.25 as estimated_coffee_consumers
FROM city)

SELECT
	cr.city_name, 
	cr.estimated_rent as total_rent,
	ct.total_customers,
	ct.average_revenue,
	ROUND(cr.estimated_coffee_consumers/1000000::numeric, 2) as estimated_coffee_consumers_millions,
	ROUND (cr.estimated_rent::NUMERIC/ct.total_customers, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name=ct.city_name
ORDER BY 4 DESC




USE walmart_db;
SELECT COUNT(*) FROM walmart;
SELECT * FROM walmart;

SELECT payment_method, COUNT(*) FROM walmart
GROUP BY payment_method;

SELECT COUNT(DISTINCT Branch) FROM walmart;
SELECT DISTINCT payment_method FROM walmart;
SELECT invoice_id from walmart;

-- 1 Find different payment methods, Number of transactions and quantity sold by payment method
SELECT payment_method, COUNT(invoice_id) AS `No._of_Transactions`, SUM(quantity) AS `Quantity_sold` FROM walmart
GROUP BY payment_method
ORDER BY payment_method; 


-- 2 Identify the highest rated category in each branch display the branch category and average rating
SELECT Branch, category, average_rating
FROM (
    SELECT Branch, category, 
           AVG(rating) AS Average_rating,
           rank() OVER (PARTITION BY Branch ORDER BY AVG(rating) DESC) AS `rank`
    FROM walmart
    GROUP BY Branch, category
) AS subquery
WHERE `rank` = 1;


-- 3 Identify the busiest day for each branch based on the number of transactions 
SELECT Branch, day_name, no_of_transactions
FROM
(
   SELECT
   Branch, 
   dayname(date) AS day_name,
   COUNT(invoice_id) AS no_of_transactions,
   RANK() OVER(PARTITION BY Branch ORDER BY COUNT(invoice_id) DESC) AS `rank`
   FROM walmart
   GROUP BY Branch, day_name
) AS subquery
WHERE `rank` = 1;


-- 4 Calculate the total quantity of items sold per payment method
SELECT payment_method, SUM(quantity) AS `Total_items_sold_per_payment_method`
FROM walmart
GROUP BY payment_method
ORDER BY `Total_items_sold_per_payment_method` DESC;


-- 5 Determine the average, minimum, and maximum rating of categories for each city
SELECT City, category,
AVG(rating) AS average_rating,
MAX(rating) AS max_rating, 
MIN(rating) AS min_rating
FROM walmart
GROUP BY City, category
ORDER BY City;


-- 6 Calculate the total profit for each category
SELECT category, 
SUM(Total) AS total_revenue,
SUM(Total * profit_margin) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;


-- 7 Determine the most common payment method for each branch
WITH cte 
AS
( 
     SELECT Branch, payment_method, COUNT(*) AS total_transaction,
     RANK() OVER (PARTITION BY Branch ORDER BY Count(*) DESC) as `rank`
FROM walmart
GROUP BY Branch, payment_method
)
SELECT * FROM cte
WHERE `rank`= 1;


-- 8 Determine in each city which branch have the highest profit margin
WITH ranked_branches AS(
    SELECT
       City, Branch, profit_margin,
       ROW_NUMBER() OVER (PARTITION BY City ORDER BY profit_margin DESC) AS `number`
	FROM walmart
)
SELECT City, Branch, profit_margin
FROM ranked_branches
WHERE `number`=1
ORDER BY City;


-- 9 Categorise sales into 3 groups MORNING, AFTERNOON, EVENING and find out each of the shift and number of invoices
ALTER TABLE walmart
MODIFY time TIME;

SELECT Branch, 
   CASE 
	   WHEN EXTRACT(HOUR FROM time) < 12 THEN 'Morning'
       WHEN extract(HOUR FROM time) BETWEEN 12 AND 16 THEN 'Afternoon'
       ELSE 'Evening'
   END day_time,
   COUNT(*)
FROM walmart
GROUP BY day_time, Branch
ORDER BY Branch, COUNT(*) DESC;


-- 10 Identify 5 branch with the highest decree ratio in revenue compare to last year (current year 2023 and last year 2022)
WITH 
revenue_2022 AS (
     SELECT Branch, SUM(Total) AS `revenue` FROM walmart
	 WHERE YEAR(`date`) = 2022
     GROUP BY Branch
),
revenue_2023 AS (
     SELECT Branch, SUM(Total) AS `revenue` FROM walmart
	 WHERE YEAR(`date`) = 2023
     GROUP BY Branch
) 
SELECT last_year_sales.Branch,
       last_year_sales.revenue AS `last_year_revenue`,
       current_year_sales.revenue AS `current_year_revenue`,
       ROUND(
       (last_year_sales.revenue - current_year_sales.revenue) / (last_year_sales.revenue) * 100 , 2
       ) AS `revenue_decrease_ratio`
FROM revenue_2022 as `last_year_sales`
JOIN
revenue_2023 as `current_year_sales`
ON last_year_sales.Branch = current_year_sales.Branch
WHERE last_year_sales.revenue > current_year_sales.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;


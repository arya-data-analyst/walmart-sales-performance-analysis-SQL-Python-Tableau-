-- Walmart Project Queries - MySQL
use walmart;
select * from walmart_clean_data limit 10000;
select count(* ) from walmart_clean_data limit 10000;

-- DROP TABLE walmart;

-- DROP TABLE walmart;

-- Count total records
SELECT COUNT(*) FROM walmart_clean_data;

-- Count payment methods and number of transactions by payment method
SELECT 
    payment_method,
    COUNT(*) AS no_payments
FROM walmart_clean_data
GROUP BY payment_method;

-- Count distinct branches
SELECT COUNT(DISTINCT branch) FROM walmart_clean_data;

-- Find the minimum quantity sold
SELECT MIN(quantity) FROM walmart_clean_data;

-- Business Problem Q1: Find different payment methods, number of transactions, and quantity sold by payment method
SELECT 
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart_clean_data
GROUP BY payment_method;

-- Project Question #2: Identify the highest-rated category in each branch
-- Display the branch, category, and avg rating
SELECT branch, category, avg_rating
FROM (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rnk
    FROM walmart_clean_data
    GROUP BY branch, category
) AS ranked
WHERE rnk = 1;

-- Q3: Identify the busiest day for each branch based on the number of transactions
SELECT branch, day_name, no_transactions
FROM (
    SELECT 
        branch,
        DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart_clean_data
    GROUP BY branch, day_name
) AS ranked
WHERE rnk = 1;

-- Q4: Calculate the total quantity of items sold per payment method
SELECT 
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart_clean_data
GROUP BY payment_method;

-- Q5: Determine the average, minimum, and maximum rating of categories for each city
SELECT 
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart_clean_data
GROUP BY city, category;

-- Q6: Calculate the total profit for each category
SELECT 
    category,
    SUM(unit_price * quantity * profit_margin) AS total_profit
FROM walmart_clean_data
GROUP BY category
ORDER BY total_profit DESC;

-- Q7: Determine the most common payment method for each branch
WITH cte AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart_clean_data
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE rnk = 1 limit 10;

-- Q8: Categorize sales into Morning, Afternoon, and Evening shifts
SELECT
    branch,
    CASE 
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM walmart_clean_data
GROUP BY branch, shift
ORDER BY branch, num_invoices DESC;

-- Q9: Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)
WITH revenue_2022 AS (
    SELECT 
        branch,
        SUM(
            CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
            * quantity
        ) AS revenue
    FROM walmart_clean_data
    WHERE YEAR(`date`) = 2022
    GROUP BY branch
),

revenue_2023 AS (
    SELECT 
        branch,
        SUM(
            CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
            * quantity
        ) AS revenue
    FROM walmart_clean_data
    WHERE YEAR(`date`) = 2023
    GROUP BY branch
)

SELECT 
    r2022.branch,
    r2022.revenue AS revenue_2022,
    r2023.revenue AS revenue_2023,
    (r2022.revenue - r2023.revenue) AS revenue_drop
FROM revenue_2022 r2022
LEFT JOIN revenue_2023 r2023 
    ON r2022.branch = r2023.branch
ORDER BY revenue_drop DESC
LIMIT 5;

     -- Total Revenue & Profit
SELECT 
    SUM(
        CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity
    ) AS Total_Revenue,
    
    SUM(profit_margin * quantity) AS Total_Profit
FROM walmart_clean_data;

      -- Revenue & Profit by Branch
SELECT 
    Branch,sum(
    CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity
    ) AS Branch_Revenue,
    SUM(profit_margin * quantity) AS Branch_Profit
FROM walmart_clean_data
GROUP BY Branch
ORDER BY Branch_Revenue DESC limit 5;

     -- Month-over-Month Revenue Growth
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity
    ) AS revenue
    FROM walmart_clean_data
    GROUP BY DATE_FORMAT(date, '%Y-%m')
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) 
        / LAG(revenue) OVER (ORDER BY month) * 100, 2
    ) AS growth_percent
FROM monthly_sales;

         -- Branch Performance vs Company Average
SELECT 
    Branch,
    SUM(
        CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity
    ) AS Branch_Revenue,
    AVG(SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity
    ))OVER () AS Company_Avg_Revenue
FROM walmart_clean_data
GROUP BY Branch;

       -- RFM Analysis (Customer-Level Not Available)
SELECT 
    Branch,
    COUNT(invoice_id) AS Total_Transactions
FROM walmart_clean_data
GROUP BY Branch;

        -- Pareto Analysis (80/20 Rule)
WITH category_sales AS (
    SELECT 
        category,
        SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS revenue
    FROM walmart_clean_data
    GROUP BY category
)
SELECT 
    category,
    revenue,
    SUM(revenue) OVER (ORDER BY revenue DESC) /
    SUM(revenue) OVER () AS cumulative_percentage
FROM category_sales;

	   -- Repeat Transaction Detection (Invoice Frequency)
SELECT 
    invoice_id ,COUNT(*) AS line_count
FROM walmart_clean_data
GROUP BY invoice_id
HAVING COUNT(*) > 1;

      -- Profit Margin % by Category
SELECT 
    category,
    SUM(profit_margin * quantity) AS total_profit,
    SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS total_revenue,
    ROUND(
        SUM(profit_margin * quantity) / 
        SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) * 100, 2
    ) AS profit_margin_percent
FROM walmart_clean_data
GROUP BY category
ORDER BY profit_margin_percent DESC;

         -- Peak Sales Day
SELECT 
    DAYNAME(date) AS day_name,
    SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS revenue
FROM walmart_clean_data
GROUP BY DAYNAME(date)
ORDER BY revenue DESC;

        -- Sales by Shift
SELECT 
    CASE 
        WHEN HOUR(date) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(date) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(invoice_id) AS transactions,
    SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS revenue
FROM walmart_clean_data
GROUP BY shift;

        -- Payment Method Impact on Basket Size
SELECT 
    payment_method,
    AVG(quantity) AS avg_quantity,
    AVG(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS avg_order_value
FROM walmart_clean_data
GROUP BY payment_method
ORDER BY avg_order_value DESC;

        -- Revenue Volatility by Branch
SELECT 
    Branch,
    STDDEV(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS revenue_volatility
FROM walmart_clean_data
GROUP BY Branch;

        -- Correlation Between Rating & Revenue
SELECT 
(
    COUNT(*) * SUM((CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) * rating) -
    SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) * SUM(rating)
) /
SQRT(
    (COUNT(*) * SUM(POW(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity,2)) - POW(SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity),2)) *
    (COUNT(*) * SUM(POW(rating,2)) - POW(SUM(rating),2))
) AS correlation_rating_revenue
FROM walmart_clean_data;

          -- Top 3 Categories per Branch
WITH ranked_categories AS (
    SELECT 
        Branch,
        category,
        SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS revenue,
        RANK() OVER (
            PARTITION BY Branch 
            ORDER BY SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) DESC
        ) AS rnk
    FROM walmart_clean_data
    GROUP BY Branch, category
)
SELECT *
FROM ranked_categories
WHERE rnk <= 3;
  
          -- Outlier Transactions (Z-Score Method)
WITH stats AS (
    SELECT 
        AVG(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS avg_rev,
        STDDEV(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS std_rev
    FROM walmart_clean_data
)
SELECT 
    s.*,
    (CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity - avg_rev) / std_rev AS z_score
FROM walmart_clean_data s
CROSS JOIN stats
WHERE ABS((CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity - avg_rev) / std_rev) > 3;

		-- Contribution % by Branch
SELECT 
    Branch,
    SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS revenue,
    ROUND(
        SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) * 100 /
        SUM(SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity)) OVER (),
        2
    ) AS contribution_percent
FROM walmart_clean_data
GROUP BY Branch
ORDER BY contribution_percent DESC;
 
        -- Category Performance Ranking (Company Level)
SELECT 
    category,
    SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) AS revenue,
    DENSE_RANK() OVER (
        ORDER BY SUM(CAST(REPLACE(unit_price, '$', '') AS DECIMAL(10,2)) 
        * quantity) DESC
    ) AS revenue_rank
FROM walmart_clean_data
GROUP BY category;




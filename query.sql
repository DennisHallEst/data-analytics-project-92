/* =====================================================================
   📊 REPORT 1: TOP 10 SELLERS BY TOTAL INCOME
   =====================================================================
   Goal:
     Get a list of the ten best sellers by total revenue.

   Column descriptions:
     seller      — seller’s first and last name
     operations  — number of completed deals (sales)
     income      — total seller revenue for all time, rounded down

   Query logic:
     - Join tables sales, employees, and products:
         - sales connects seller, customer, and product
         - employees provides seller data
         - products provides product price
     - For each seller, calculate:
         - total number of sales (COUNT)
         - total revenue (SUM(price * quantity))
     - Round total revenue down using FLOOR().
     - Sort sellers by descending total revenue.
     - Take only the top 10 records.
===================================================================== */

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;



/* =====================================================================
   📊 REPORT 2: SELLERS BELOW AVERAGE REVENUE PER DEAL
   =====================================================================
   Goal:
     Find sellers whose average revenue per sale is lower than
     the overall average across all sellers.

   Column descriptions:
     seller          — seller’s first and last name
     average_income  — seller’s average revenue per sale, rounded down

   Query logic:
     - In the subquery seller_avg, calculate each seller’s
         average revenue per sale (AVG(price * quantity))
         and round it down with FLOOR().
     - In the subquery overall_avg, calculate the average
         of all sellers’ averages.
     - In the main query, select only sellers whose
         average_income < overall average.
     - Sort by average_income ascending.
===================================================================== */

WITH seller_avg AS (
    SELECT 
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        FLOOR(AVG(p.price * s.quantity)) AS average_income
    FROM sales s
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY seller
),
overall_avg AS (
    SELECT AVG(average_income) AS avg_all FROM seller_avg
)
SELECT 
    sa.seller,
    sa.average_income
FROM seller_avg sa, overall_avg oa
WHERE sa.average_income < oa.avg_all
ORDER BY sa.average_income ASC;



/* =====================================================================
   📊 REPORT 3: REVENUE BY DAY OF WEEK
   =====================================================================
   Goal:
     Show how much revenue each seller generates on each day of the week.

   Column descriptions:
     seller       — seller’s first and last name
     day_of_week  — day of the week (in English)
     income       — total seller revenue for that day, rounded down

   Query logic:
     - Join tables sales, employees, and products.
     - Use TO_CHAR(s.sale_date, 'day') to get the name of the weekday
         (e.g. 'monday', 'tuesday', etc.).
     - Trim extra spaces around the weekday name with TRIM().
     - Calculate total revenue (SUM(price * quantity)) and round down.
     - Group by seller and weekday name.
     - Sort results by:
         - weekday number (EXTRACT(ISODOW): 1 = Monday ... 7 = Sunday)
         - then by seller name.
===================================================================== */

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TRIM(TO_CHAR(s.sale_date, 'day')) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY seller, TRIM(TO_CHAR(s.sale_date, 'day')), EXTRACT(ISODOW FROM s.sale_date)
ORDER BY EXTRACT(ISODOW FROM s.sale_date), seller;


=====================================================================
   REPORT 4: CUSTOMERS BY AGE GROUP
   =====================================================================
   Goal:
   - Count how many customers fall into each age range:
       • 16–25
       • 26–40
       • 40+
   - The table must contain:
       age_category — age range
       age_count — number of customers in that group
   - Sort order: by age category in natural order (16–25, 26–40, 40+)
   ---------------------------------------------------------------------
   Explanation:
   - We use a CASE expression to classify each customer’s age.
   - Then group by that category and count how many customers belong to it.
   - ORDER BY uses CASE to maintain the desired category order.
   ===================================================================== */

WITH age_groups AS (
    SELECT
        CASE 
            WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
            WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
            WHEN c.age > 40 THEN '40+'
        END AS age_category
    FROM customers c
)
SELECT 
    age_category,
    COUNT(*) AS age_count
FROM age_groups
GROUP BY age_category
ORDER BY 
    CASE 
        WHEN age_category = '16-25' THEN 1
        WHEN age_category = '26-40' THEN 2
        WHEN age_category = '40+' THEN 3
    END;



/* =====================================================================
   REPORT 5: UNIQUE CUSTOMERS AND TOTAL INCOME BY MONTH
   =====================================================================
   Goal:
   - For each month (YYYY-MM format):
       • Count unique customers who made purchases.
       • Calculate total income (sum of price * quantity).
   - Round down the total income to whole numbers.
   - Sort by month ascending.
   ---------------------------------------------------------------------
   Explanation:
   - We join sales with products to get prices.
   - TO_CHAR formats the sale date to “YYYY-MM”.
   - COUNT(DISTINCT customer_id) ensures unique customer count per month.
   - FLOOR(SUM(...)) removes decimal parts from income.
   ===================================================================== */

SELECT 
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN products p 
    ON s.product_id = p.product_id
WHERE s.sale_date IS NOT NULL
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month;



/* =====================================================================
   REPORT 6: CUSTOMERS WHOSE FIRST PURCHASE WAS PROMOTIONAL (PRICE = 0)
   =====================================================================
   Goal:
   - Identify customers whose very first purchase was part of a promotion
     (i.e. total sale price = 0).
   - Output:
       customer — full name of customer
       sale_date — date of first purchase
       seller — full name of the employee (salesperson)
   - Sort by customer_id.
   ---------------------------------------------------------------------
   Explanation:
   - Step 1: Find each customer’s first-ever purchase date (MIN(sale_date)).
   - Step 2: Join back to the sales table to get details of that transaction.
   - Step 3: Join products to verify that sale was promotional (price * quantity = 0).
   - Step 4: Output only customers meeting that condition.
   - Step 5: Sort by customer_id.
   ===================================================================== */

WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(sale_date) AS first_sale_date
    FROM sales
    GROUP BY customer_id
)
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    s.sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_purchase fp
JOIN sales s 
    ON s.customer_id = fp.customer_id 
   AND s.sale_date = fp.first_sale_date
JOIN products p 
    ON s.product_id = p.product_id
JOIN customers c 
    ON s.customer_id = c.customer_id
JOIN employees e 
    ON s.sales_person_id = e.employee_id
WHERE (p.price * s.quantity) = 0
ORDER BY s.customer_id;

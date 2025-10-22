/* =====================================================================
   📊 REPORT 1: TOP 10 SELLERS BY TOTAL INCOME
   =====================================================================
   Цель:
     Получить список десяти лучших продавцов по общей выручке.

   Описание колонок:
     seller      — имя и фамилия продавца
     operations  — количество совершённых сделок (продаж)
     income      — суммарная выручка продавца за всё время, округлённая вниз

   Логика запроса:
     1️⃣ Соединяем таблицы sales, employees и products:
         - sales связывает продавца, клиента и товар;
         - employees даёт данные о продавце;
         - products даёт цену товара.
     2️⃣ Для каждого продавца считаем:
         - общее количество продаж (COUNT);
         - общую выручку (SUM(price * quantity)).
     3️⃣ Округляем сумму выручки вниз с помощью FLOOR().
     4️⃣ Сортируем продавцов по убыванию выручки.
     5️⃣ Берём только первые 10 записей.
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
   Цель:
     Найти продавцов, чья средняя выручка за сделку меньше средней
     по всем продавцам.

   Описание колонок:
     seller          — имя и фамилия продавца
     average_income  — средняя выручка за сделку, округлённая вниз

   Логика запроса:
     1️⃣ В подзапросе seller_avg считаем среднюю выручку каждого продавца:
         AVG(price * quantity)
         и округляем вниз (FLOOR()).
     2️⃣ В подзапросе overall_avg считаем среднее значение этих средних
         для всех продавцов.
     3️⃣ В основном запросе выбираем продавцов, у которых
         average_income < общая средняя.
     4️⃣ Сортируем по возрастанию средней выручки.
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
   Цель:
     Показать, сколько выручки приносит каждый продавец по дням недели.

   Описание колонок:
     seller       — имя и фамилия продавца
     day_of_week  — день недели (на английском)
     income       — суммарная выручка в этот день, округлённая вниз

   Логика запроса:
     1️⃣ Соединяем таблицы sales, employees и products.
     2️⃣ Используем TO_CHAR(s.sale_date, 'day'), чтобы получить название
         дня недели (например, 'monday', 'tuesday' и т.д.).
     3️⃣ Обрезаем пробелы вокруг названия (TRIM).
     4️⃣ Считаем суммарную выручку (SUM(price * quantity)) и округляем вниз.
     5️⃣ Группируем по продавцу и дню недели.
     6️⃣ Сортируем:
         - по порядковому номеру дня недели (EXTRACT(ISODOW): 1=Monday ... 7=Sunday),
         - затем по имени продавца.
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

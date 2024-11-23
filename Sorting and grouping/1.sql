
create table users(
	id int,
	gender VARCHAR(255),
	age int,
	education VARCHAR(255),
	city VARCHAR(255)
)
--Часть 1.1
SELECT 
    city,
    COUNT(id) AS customer_count
FROM users
GROUP BY city, age
ORDER BY customer_count DESC;
--
create table products(
	id int,
	name VARCHAR(255),
	category VARCHAR(255),
	price float
)
--
SELECT 
    category,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM 
    products
WHERE 
    name ILIKE '%hair%' OR name ILIKE '%home%'
GROUP BY 
    category;

--
CREATE table sellers(
	seller_id int,
	category VARCHAR(255),
	date_reg date,
	date date,
	revenue int,
	rating int,
	delivery_days int
	)
select * from sellers

--Часть 2.1
SELECT 
    seller_id,
    COUNT(DISTINCT category) AS total_categ,
    ROUND(AVG(rating), 2) AS avg_rating,
    SUM(revenue) AS total_revenue,
    CASE 
        WHEN COUNT(DISTINCT category) > 1 AND SUM(revenue) > 50000 THEN 'rich'
        WHEN COUNT(DISTINCT category) > 1 AND SUM(revenue) <= 50000 THEN 'poor'
    END AS seller_type
FROM 
    sellers
WHERE 
    category != 'Bedding'
GROUP BY 
    seller_id
HAVING 
    COUNT(DISTINCT category) > 1  -- Оставляем только тех, кто продает более одной категории
ORDER BY 
    seller_id;

--Часть 2.2
WITH earliest_registration AS (
    SELECT 
        seller_id,
        MIN(date_reg) AS earliest_date_reg --берем только самую раннюю дата т.к. для каждого продовца для каждой из категорий отдельная дата регистрации
    FROM 
        sellers
    WHERE 
        category != 'Bedding'
    GROUP BY 
        seller_id
),
unsuccessful_sellers AS (--как в предыдущем, только poor
    SELECT 
        s.seller_id,
        (SELECT er.earliest_date_reg FROM earliest_registration er WHERE er.seller_id = s.seller_id) AS earliest_date_reg,
        COUNT(DISTINCT s.category) AS total_categ,
        SUM(s.revenue) AS total_revenue,
        AVG(s.rating) AS avg_rating
    FROM 
        sellers s
    WHERE 
        s.category != 'Bedding'
    GROUP BY 
        s.seller_id
    HAVING 
        COUNT(DISTINCT s.category) > 1 AND SUM(s.revenue) <= 50000
),
delivery_stats AS (
    SELECT 
        MAX(delivery_days) - MIN(delivery_days) AS max_delivery_difference
    FROM 
        sellers
    WHERE 
        category != 'Bedding'
)
SELECT 
    us.seller_id,
    (EXTRACT(YEAR FROM AGE(CURRENT_DATE, us.earliest_date_reg)) * 12 + EXTRACT(MONTH FROM AGE(CURRENT_DATE, us.earliest_date_reg))) AS month_from_registration,
    ds.max_delivery_difference
FROM 
    unsuccessful_sellers us, delivery_stats ds
ORDER BY 
    us.seller_id;

--Часть 2.3
WITH filtered_sellers AS (
    SELECT 
        seller_id,
        STRING_AGG(DISTINCT category, ' - ' ORDER BY category) AS category_pair,
        COUNT(DISTINCT category) AS category_count,
        SUM(revenue) AS total_revenue
    FROM 
        sellers
    WHERE 
        EXTRACT(YEAR FROM date_reg) = 2022
    GROUP BY 
        seller_id
    HAVING 
        COUNT(DISTINCT category) = 2 
        AND SUM(revenue) > 75000
)
SELECT 
    seller_id,
    category_pair
FROM 
    filtered_sellers
ORDER BY 
    seller_id;
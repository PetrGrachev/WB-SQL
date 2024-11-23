CREATE table orders(
	order_id int,
	customer_id int,
	order_date timestamp,
	shipment_date timestamp,
	order_ammount int,
	order_status VARCHAR(255)
)
SELECT * from orders

CREATE TABLE customers(
	customer_id int,
	name VARCHAR(255)
)
select * from customers

--Часть 1.1
SELECT 
    c.name, 
    MAX(o.shipment_date - o.order_date) AS max_waiting_time
FROM 
    orders o
JOIN 
    customers c 
ON 
    o.customer_id = c.customer_id
WHERE 
    o.shipment_date IS NOT NULL
GROUP BY 
    c.customer_id, c.name
ORDER BY 
    max_waiting_time DESC
LIMIT 1;

--Часть 1.2
SELECT 
    c.name,
    AVG(o.shipment_date - o.order_date) AS avg_waiting_time,
    SUM(o.order_ammount) AS total_order_amount
FROM 
    orders o
JOIN 
    customers c 
ON 
    o.customer_id = c.customer_id
WHERE 
    o.customer_id IN (
        SELECT customer_id --ищем id для макс количества
        FROM orders
        GROUP BY customer_id
        HAVING COUNT(order_id) = (
            SELECT MAX(order_count) --ищем макксимальное количество
            FROM (
                SELECT customer_id, COUNT(order_id) AS order_count --считаем заказы
                FROM orders
                GROUP BY customer_id
            ) sub
        )
    )
GROUP BY 
    c.customer_id, c.name
ORDER BY 
    total_order_amount DESC;

--Часть 1.3
SELECT 
    c.name,
    COUNT(CASE WHEN o.shipment_date - o.order_date > INTERVAL '5 days' THEN 1 END) AS delayed_orders,
    COUNT(CASE WHEN o.order_status = 'Cancel' THEN 1 END) AS canceled_orders,
    SUM(o.order_ammount) AS total_order_amount
FROM 
    orders o
JOIN 
    customers c 
ON 
    o.customer_id = c.customer_id
WHERE 
    (o.shipment_date - o.order_date > INTERVAL '5 days' OR o.order_status = 'Cancel')
GROUP BY 
    c.customer_id, c.name
ORDER BY 
    total_order_amount DESC;
--
CREATE table orders (
	order_date timestamp,
	order_id int,
	product_id int,
	order_ammount int
)
--DROP TABLE orders
--\COPY orders FROM 'C:\\Users\\petrg\\Downloads\\orders_2.csv' DELIMITER ',' CSV HEADER;
SELECT * FROM orders

CREATE table products (
	product_id int,
	product_name VARCHAR(255),
	product_category VARCHAR(255)
)
SELECT * FROM products

--Часть 2
----------------

WITH category_sales AS ( --общая сумма продаж для каждой категории
    SELECT
        p.product_category,
        SUM(o.order_ammount) AS total_category_sales
    FROM
        orders o
        JOIN products p ON o.product_id = p.product_id
    GROUP BY
        p.product_category
),

max_category AS ( --Категория с наибольшей суммой
    SELECT
        product_category,
        total_category_sales
    FROM
        category_sales
    ORDER BY
        total_category_sales DESC
    LIMIT 1
),

product_sales AS ( --сумма продаж для каждого продукта
    SELECT
        p.product_category,
        p.product_id,
        p.product_name,
        SUM(o.order_ammount) AS total_product_sales
    FROM
        orders o
        JOIN products p ON o.product_id = p.product_id
    GROUP BY
        p.product_category,
        p.product_id,
        p.product_name
),

max_product_sales AS ( --максимальная сумма продаж для каждого продукта в категории
    SELECT
        product_category,
        MAX(total_product_sales) AS max_product_sales
    FROM
        product_sales
    GROUP BY
        product_category
),


top_products AS ( -- продукты с максимальной суммой продаж в их категориях
    SELECT
        ps.product_category,
        ps.product_id,
        ps.product_name,
        ps.total_product_sales
    FROM
        product_sales ps
        JOIN max_product_sales mps ON ps.product_category = mps.product_category
        AND ps.total_product_sales = mps.max_product_sales
)

-- Объединяем вот это все
SELECT
    cs.product_category,
    cs.total_category_sales,
    tp.product_name,
    tp.total_product_sales,
    CASE
        WHEN cs.product_category = mc.product_category THEN 'Yes' --для топ категории
        ELSE 'No'
    END AS is_max_category
FROM
    category_sales cs
    JOIN top_products tp ON cs.product_category = tp.product_category
    LEFT JOIN max_category mc ON cs.product_category = mc.product_category;


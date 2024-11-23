
--Часть 2
CREATE TABLE sales(
	DATE date,
	SHOPNUMBER int,
	ID_GOOD int,
	QTY int
)
select * from sales

CREATE TABLE shops(
	SHOPNUMBER int,
	CITY VARCHAR(255),
	ADDRESS VARCHAR(255)
)
select * from shops

CREATE TABLE goods(
	ID_GOOD int,
	CATEGORY VARCHAR(255),
	GOOD_NAME VARCHAR(255),
	PRICE int
)
select * from goods
-----------------

SELECT
sh.SHOPNUMBER , sh.CITY , sh.ADDRESS, SUM(sl.QTY) as SUM_QTY, SUM(sl.QTY * g.PRICE) as SUM_QTY_PRICE
from shops sh 
JOIN sales sl
ON sh.SHOPNUMBER = sl.SHOPNUMBER
JOIN goods g
ON sl.ID_GOOD = g.ID_GOOD
WHERE sl.date = '2016-01-02'
GROUP BY sh.SHOPNUMBER, sh.CITY, sh.ADDRESS
ORDER BY sh.SHOPNUMBER;
--Часть 2.2
SELECT 
    sl.DATE AS DATE_,
    sh.CITY,
    SUM(sl.QTY * g.PRICE) / SUM(SUM(sl.QTY * g.PRICE)) OVER (PARTITION BY sl.DATE) AS SUM_SALES_REL
FROM 
    sales sl
JOIN 
    shops sh 
ON 
    sl.SHOPNUMBER = sh.SHOPNUMBER
JOIN 
    goods g 
ON 
    sl.ID_GOOD = g.ID_GOOD
WHERE 
    g.CATEGORY = 'ЧИСТОТА'
GROUP BY 
    sl.DATE, sh.CITY
ORDER BY 
    sl.DATE, sh.CITY;
	
--Часть 2.3
WITH ranked_sales AS (
    SELECT
        sl.DATE AS DATE_,
        sl.SHOPNUMBER,
        sl.ID_GOOD,
        sl.QTY,
        RANK() OVER (PARTITION BY sl.DATE, sl.SHOPNUMBER ORDER BY sl.QTY DESC) AS rank --ранжируем по продажам
    FROM 
        sales sl
)
SELECT 
    DATE_,
    SHOPNUMBER,
    ID_GOOD
FROM 
    ranked_sales
WHERE 
    rank <= 3
ORDER BY 
    DATE_, SHOPNUMBER, rank;
	
--Часть 2.4
WITH sales_with_prev_date AS (
    SELECT
        s.DATE AS DATE_,
        s.SHOPNUMBER,
        g.CATEGORY,
        SUM(s.QTY * g.PRICE) AS sales_amount,
        LAG(s.DATE) OVER (PARTITION BY s.SHOPNUMBER, g.CATEGORY ORDER BY s.DATE) AS prev_date
    FROM 
        sales s
    JOIN 
        shops sh 
    ON 
        s.SHOPNUMBER = sh.SHOPNUMBER
    JOIN 
        goods g 
    ON 
        s.ID_GOOD = g.ID_GOOD
    WHERE 
        sh.CITY = 'СПб'
    GROUP BY 
        s.DATE, s.SHOPNUMBER, g.CATEGORY --для каждого магазина и товарного направления
)
SELECT
    prev_date AS DATE_,
    SHOPNUMBER,
    CATEGORY,
    sales_amount AS PREV_SALES
FROM 
    sales_with_prev_date
WHERE 
    prev_date IS NOT NULL --только те, у кого есть предыдущая дата
ORDER BY 
    SHOPNUMBER, CATEGORY, DATE_;

CREATE table salary(
	id int,
	first_name VARCHAR(255),
	last_name VARCHAR(255),
	salary int,
	industry VARCHAR(255)
)
select * from salary

--Часть 1
--Последний столбец - имя сотрудника для данного отдела с самой высокой зарплатой.
WITH max_salaries AS ( --Максимальные зарплаты в отделе
    SELECT
        industry,
        MAX(salary) AS max_salary
    FROM
        salary
    GROUP BY
        industry
),
highest_paid_employees AS ( -- только сотрудники с максимальной зарплатой
    SELECT
        s.industry,
        s.first_name,
        s.last_name,
        s.salary
    FROM
        salary s
    JOIN
        max_salaries m ON s.industry = m.industry AND s.salary = m.max_salary
)
SELECT
    s.first_name,
    s.last_name,
    s.salary,
    s.industry,
    h.first_name || ' ' || h.last_name AS name_highest_sal
FROM
    salary s
JOIN
    highest_paid_employees h ON s.industry = h.industry
ORDER BY 
    industry, salary DESC;
	
--С минимальной зарплатой
WITH min_salaries AS (
    SELECT
        industry,
        MIN(salary) AS min_salary
    FROM
        salary
    GROUP BY
        industry
),
lowest_paid_employees AS (
    SELECT
        s.industry,
        s.first_name,
        s.last_name,
        s.salary
    FROM
        salary s
    JOIN
        min_salaries m ON s.industry = m.industry AND s.salary = m.min_salary
)
SELECT
    s.first_name,
    s.last_name,
    s.salary,
    s.industry,
    l.first_name || ' ' || l.last_name AS name_lowest_sal
FROM
    salary s
JOIN
    lowest_paid_employees l ON s.industry = l.industry
ORDER BY 
    industry, salary ASC;
	
--Максимальная зарплата оконкой
SELECT DISTINCT
    first_name,
    last_name,
    salary,
    industry,
	first_value (first_name) OVER (PARTITION BY industry ORDER BY salary DESC) AS name_highest_sal
FROM 
    salary
ORDER BY 
    industry, salary DESC;
	
--Минимальная зарплата оконкой
SELECT DISTINCT
    first_value(first_name) OVER (PARTITION BY industry ORDER BY salary ASC) AS name_lowest_sal,
    first_name,
    last_name,
    salary,
    industry
FROM 
    salary
ORDER BY 
    industry, salary ASC;

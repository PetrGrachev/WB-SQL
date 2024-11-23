CREATE TABLE query (
    searchid SERIAL PRIMARY KEY,
    year int,
    month int,
    day int,
    userid int,
    ts int, -- UNIX
    devicetype VARCHAR(255),
    deviceid int,
    query VARCHAR(255)
);

--DROP TABLE query

INSERT INTO query (year, month, day, userid, ts, devicetype, deviceid, query) VALUES
-- Пользователь 1: Случай 1 (next_ts IS NULL)
(2024, 11, 1, 1, 1730419200, 'android', 101, 'куп'),
(2024, 11, 1, 1, 1730419202, 'android', 101, 'купить'),
(2024, 11, 1, 1, 1730419205, 'android', 101, 'купить тел'),
(2024, 11, 1, 1, 1730419207, 'android', 101, 'купить телефон'),

-- Пользователь 2: Случай 2 (delta_t > 180)
(2024, 11, 2, 2, 1730505600, 'android', 102, 'н'),
(2024, 11, 2, 2, 1730505603, 'android', 102, 'ноу'),
(2024, 11, 2, 2, 1730505608, 'android', 102, 'ноутб'),
(2024, 11, 2, 2, 1730505609, 'android', 102, 'ноутбук'),
(2024, 11, 2, 2, 1730505901, 'android', 102, 'ноутбук игровой'),

-- Пользователь 3: Случай 3 (следующий запрос короче и delta_t > 60)
(2024, 11, 3, 3, 1730592000, 'android', 103, 'т'),
(2024, 11, 3, 3, 1730592001, 'android', 103, 'тел'),
(2024, 11, 3, 3, 1730592003, 'android', 103, 'телев'),
(2024, 11, 3, 3, 1730592005, 'android', 103, 'телевиз'),
(2024, 11, 3, 3, 1730592007, 'android', 103, 'телевизор'),
(2024, 11, 3, 3, 1730592121, 'android', 103, 'тел'),

-- Пользователь 4: Дополнительные данные, как случай 1, выводиться только последний запрос
(2024, 11, 4, 4, 1730678400, 'android', 104, 'планшет'),
(2024, 11, 4, 4, 1730678460, 'android', 104, 'план'),
(2024, 11, 4, 4, 1730678520, 'android', 104, 'пл'),

-- Пользователь 5: Не android
(2024, 11, 5, 5, 1730764800, 'ios', 105, 'ка'),
(2024, 11, 5, 5, 1730764820, 'ios', 105, 'каме'),
(2024, 11, 5, 5, 1730764830, 'ios', 105, 'камера');

WITH cte AS (
    SELECT
        year,
        month,
        day,
        userid,
        ts,
        devicetype,
        deviceid,
        query,
        LEAD(ts) OVER (PARTITION BY userid, deviceid ORDER BY ts) AS next_ts, --следующее время запроса
        LEAD(query) OVER (PARTITION BY userid, deviceid ORDER BY ts) AS next_query, --следующий запрос
        LEAD(ts) OVER (PARTITION BY userid, deviceid ORDER BY ts) - ts AS delta_t, --разница времени
        LENGTH(query) AS query_length, --длина запроса
        LENGTH(LEAD(query) OVER (PARTITION BY userid, deviceid ORDER BY ts)) AS next_query_length --длина следующего запроса
    FROM query
)
SELECT
    year,
    month,
    day,
    userid,
    ts,
    devicetype,
    deviceid,
    query,
    next_query,
    CASE
        WHEN next_ts IS NULL THEN 1 --Если после данного запроса больше ничего не искал, то значение равно 1
        WHEN delta_t > 180 THEN 1 -- Если до следующего запроса прошло более 3х минут, то значение также равно 1
        WHEN (next_query_length < query_length AND delta_t > 60) THEN 2 --Следующий запрос короче и прошло более минуты то 2
        ELSE 0
    END AS is_final
FROM cte
WHERE devicetype = 'android' AND
      (CASE
          WHEN next_ts IS NULL THEN 1
          WHEN delta_t > 180 THEN 1
          WHEN (next_query_length < query_length AND delta_t > 60) THEN 2
          ELSE 0
      END) IN (1, 2) AND
      year = 2024 AND month = 11 AND day BETWEEN 1 AND 5;-- в задании для одно дня, но для удобства сделал по нескольким

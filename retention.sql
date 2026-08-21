-- ============================================================
-- Расчёт Retention (удержание пользователей)
-- ============================================================

SELECT 
    COUNT(DISTINCT user_id) AS active_users,      -- сколько пользователей вернулось
    toString(day_number) AS day_number,           -- день после первого визита (0, 1, 2...)
    toString(start_date) AS start_date            -- дата когорты (первый визит)
FROM (
    SELECT 
        t1.user_id,                               -- пользователь
        t1.start_date,                            -- его дата первого визита (когорта)
        t2.activity_date,                         -- дата любого визита
        dateDiff('day', t1.start_date, t2.activity_date) AS day_number  -- разница в днях
    FROM
        -- Подзапрос 1: дата первого визита для каждого пользователя
        (SELECT 
            user_id, 
            MIN(toDate(time)) AS start_date
         FROM default.feed_data_3k 
         WHERE toDate(time) <= today()            -- отсекаем будущие даты, если есть
         GROUP BY user_id) AS t1
    LEFT JOIN
        -- Подзапрос 2: все дни, в которые пользователь был активен
        (SELECT DISTINCT 
            user_id, 
            toDate(time) AS activity_date
         FROM default.feed_data_3k 
         WHERE toDate(time) <= today()
        ) AS t2
    USING user_id                                 -- соединяем по пользователю
    WHERE t2.activity_date >= t1.start_date       -- только визиты после первого
          AND t1.start_date >= today() - INTERVAL 30 DAY  -- только свежие когорты (30 дней)
)
GROUP BY day_number, start_date                   -- группируем по дню и когорте
ORDER BY day_number, start_date                   -- сортируем для тепловой карты
